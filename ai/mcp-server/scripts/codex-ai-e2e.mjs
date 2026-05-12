#!/usr/bin/env node
import assert from "node:assert/strict";
import { createWriteStream, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { setTimeout as delay } from "node:timers/promises";
import { spawn } from "node:child_process";
import net from "node:net";
import process from "node:process";
import { Agent as HttpsAgent } from "node:https";
import { randomUUID } from "node:crypto";
import { SignJWT } from "jose";

process.env.NODE_TLS_REJECT_UNAUTHORIZED ??= "0";

const scriptDir = path.dirname(new URL(import.meta.url).pathname);
const mcpDir = path.resolve(scriptDir, "..");
const repoRoot = path.resolve(mcpDir, "../..");

const args = new Set(process.argv.slice(2));
const mode = valueArg("--mode") ?? process.env.HOSTR_AI_E2E_MODE ?? "full";
const supervised =
  args.has("--supervised") ||
  args.has("--visual") ||
  process.env.HOSTR_AI_E2E_SUPERVISED === "1";
const supervisedMaxChars = Number(
  process.env.HOSTR_AI_E2E_SUPERVISED_MAX_CHARS ?? 1800,
);
const supervisedPhasePauseMs = Number(
  process.env.HOSTR_AI_E2E_SUPERVISED_PHASE_PAUSE_MS ?? 0,
);
const promptVersions = (
  valueArg("--prompt-versions") ??
  process.env.HOSTR_AI_E2E_PROMPT_VERSIONS ??
  (mode === "smoke" ? "canonical" : "canonical,natural")
)
  .split(",")
  .map((value) => value.trim())
  .filter(Boolean);
const keep = args.has("--keep") || process.env.HOSTR_AI_E2E_KEEP === "1";
const runId = new Date().toISOString().replace(/[:.]/g, "-");
const logRoot = path.resolve(
  valueArg("--log-root") ??
    process.env.HOSTR_AI_E2E_LOG_ROOT ??
    path.join(repoRoot, "logs", `codex_ai_e2e_${runId}`),
);
const codexBin = resolveCodexBin();

const signetBaseUrl =
  process.env.HOSTR_AI_E2E_SIGNET_URL ??
  "https://bunker-nostr.hostr.development";
const albyBaseUrl =
  process.env.HOSTR_AI_E2E_ALBY_URL ?? "https://alby.hostr.development";
const albyPassword = process.env.ALBYHUB_PASSWORD ?? "Testing123!";

const roleQueue = [
  {
    role: "host",
    keyName: process.env.HOSTR_AI_E2E_HOST_KEY ?? "hostr-seed-1-host-0",
  },
  {
    role: "guest",
    keyName: process.env.HOSTR_AI_E2E_GUEST_KEY ?? "hostr-seed-1-guest-25",
  },
  {
    role: "escrow",
    keyName: process.env.HOSTR_AI_E2E_ESCROW_KEY ?? "hostr-seed-1-escrow",
  },
];

mkdirSync(logRoot, { recursive: true });
const codexStdoutPath = path.join(logRoot, "codex.jsonl");
const codexStderrPath = path.join(logRoot, "codex.stderr.log");
const mcpLogPath = path.join(logRoot, "mcp.log");
const summaryPath = path.join(logRoot, "summary.json");
const fixtureImagePath = path.join(logRoot, "ai-e2e-listing.png");

const events = [];
const toolCalls = [];
const approvals = [];
const signingApprovals = [];
const payments = [];
const failures = [];
let latestTradeId = null;

let paidInvoices = new Set();
let approvalIndex = 0;
let codexHome;
let codexWorkspace;
let mcpStateDir;
let mcpProcess;
let mcpPort;
let mcpAccessToken;
let mcpStopping = false;
let stopApprovalPoller = null;
const pendingLoginUris = [];

main().catch(async (error) => {
  console.error(error.stack || String(error));
  try {
    await cleanup();
  } catch (cleanupError) {
    console.error(`Cleanup failed: ${cleanupError.message}`);
  }
  process.exitCode = 1;
});

async function main() {
  mcpPort = await freePort();
  mcpStateDir = mkdtempSync(path.join(tmpdir(), "hostr_ai_mcp_state_"));
  codexHome = mkdtempSync(path.join(tmpdir(), "hostr_ai_codex_home_"));
  codexWorkspace = mkdtempSync(path.join(tmpdir(), "hostr_ai_codex_workspace_"));

  writeFixtureImage();
  copyCodexAuth(codexHome);
  await startMcpServer({ port: mcpPort, stateDir: mcpStateDir });
  await prepareCodexHome({ codexHome, port: mcpPort });

  stopApprovalPoller = startApprovalPoller();
  const result = { exitCode: 0 };
  const phases = buildPhases(mode);
  for (let index = 0; index < phases.length; index += 1) {
    const phase = phases[index];
    const label = phase.label ?? `Phase ${index + 1}`;
    if (supervised) {
      supervisedBanner(`${index + 1}/${phases.length} ${label}`);
    }
    if (phase.restartServer) {
      await restartMcpServer();
      continue;
    }
    const prompt =
      typeof phase.prompt === "function" ? phase.prompt() : phase.prompt;
    if (prompt.includes("{{tradeId}}")) {
      failures.push("A full-suite phase needed a tradeId before one was observed");
      result.exitCode = 1;
      break;
    }
    const promptProblem = unnaturalPromptReason(prompt);
    if (promptProblem) {
      failures.push(`Prompt for "${label}" is not end-user-natural: ${promptProblem}`);
      result.exitCode = 1;
      break;
    }
    if (supervised) {
      supervisedLog("Prompt");
      supervisedLog(indent(prompt.trim()));
      supervisedLog("");
    }
    const phaseStart = {
      messageCount: agentMessages().length,
      toolCount: toolCalls.length,
    };
    let phaseResult = await runCodex({
      codexHome,
      prompt,
      label,
    });
    if (phaseResult.exitCode === 0 && noHostrToolCalls(phaseStart)) {
      const followupPrompt =
        "Please use the Hostr app in this chat for this. Stop reading local files, ports, databases, logs, or HTTP endpoints; check my Hostr session there and continue the Hostr request.";
      if (supervised) {
        supervisedLog("Follow-up");
        supervisedLog(indent(followupPrompt));
        supervisedLog("");
      }
      phaseResult = await runCodex({
        codexHome,
        prompt: followupPrompt,
        label: `${label} follow-up`,
        resume: true,
      });
    }
    for (const followup of phase.followups ?? []) {
      if (phaseResult.exitCode !== 0) break;
      if (!followup.when(phaseStart)) continue;
      if (supervised) {
        supervisedLog("Follow-up");
        supervisedLog(indent(followup.prompt));
        supervisedLog("");
      }
      phaseResult = await runCodex({
        codexHome,
        prompt: followup.prompt,
        label: `${label} follow-up`,
        resume: true,
      });
    }
    if (phaseResult.exitCode !== 0) {
      result.exitCode = phaseResult.exitCode;
      break;
    }
    validatePhase(label, phase, phaseStart, result);
    if (result.exitCode !== 0) {
      break;
    }
    if (supervisedPhasePauseMs > 0) {
      await delay(supervisedPhasePauseMs);
    }
  }
  stopApprovalPoller?.();
  stopApprovalPoller = null;
  const summary = evaluate(result);
  writeFileSync(summaryPath, `${JSON.stringify(summary, null, 2)}\n`);

  if (!summary.ok) {
    console.error(`Hostr Codex AI e2e failed. Logs: ${logRoot}`);
    for (const failure of summary.failures) {
      console.error(`- ${failure}`);
    }
    process.exitCode = 1;
  } else {
    console.log(`Hostr Codex AI e2e passed. Logs: ${logRoot}`);
  }

  await cleanup();
}

function valueArg(name) {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : undefined;
}

function resolveCodexBin() {
  const explicit = valueArg("--codex-bin") ?? process.env.HOSTR_AI_E2E_CODEX_BIN;
  if (explicit) return explicit;

  const fromPath = findOnPath("codex");
  if (fromPath) return fromPath;

  const home = process.env.HOME ?? "";
  const candidates = [
    "/Applications/Codex.app/Contents/Resources/codex",
    "/Applications/Codex.app/Contents/MacOS/codex",
    "/opt/homebrew/bin/codex",
    "/usr/local/bin/codex",
    path.join(home, ".codex", "bin", "codex"),
    path.join(home, ".local", "bin", "codex"),
  ];
  const found = candidates.find((candidate) => existsSync(candidate));
  if (found) return found;

  throw new Error(
    "Could not find the Codex CLI. Set HOSTR_AI_E2E_CODEX_BIN=/path/to/codex or pass --codex-bin /path/to/codex.",
  );
}

function findOnPath(command) {
  const paths = (process.env.PATH ?? "").split(path.delimiter).filter(Boolean);
  for (const directory of paths) {
    const candidate = path.join(directory, command);
    if (existsSync(candidate)) return candidate;
  }
  return null;
}

async function freePort() {
  return await new Promise((resolve, reject) => {
    const server = net.createServer();
    server.once("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const address = server.address();
      server.close(() => resolve(address.port));
    });
  });
}

function copyCodexAuth(home) {
  const source = path.join(process.env.HOME ?? "", ".codex", "auth.json");
  if (!existsSync(source)) {
    throw new Error(`Missing Codex auth file: ${source}`);
  }
  writeFileSync(path.join(home, "auth.json"), readFileSync(source));
}

function writeFixtureImage() {
  const png = Buffer.from(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAFgwJ/l6S1NwAAAABJRU5ErkJggg==",
    "base64",
  );
  writeFileSync(fixtureImagePath, png);
}

async function startMcpServer({ port, stateDir }) {
  supervisedLog(`Starting Hostr MCP server on http://127.0.0.1:${port}/mcp`);
  const out = createWriteStream(mcpLogPath, { flags: "a" });
  mcpProcess = spawn("npm", ["run", "dev:local"], {
    cwd: mcpDir,
    env: {
      ...process.env,
      PORT: String(port),
      MCP_PUBLIC_BASE_URL: `http://127.0.0.1:${port}`,
      MCP_PUBLIC_ASSET_BASE_URL: "https://ai.hostr.development",
      HOSTR_DAEMON_STATE_DIR: stateDir,
      HOSTR_DAEMON_TIMEOUT_MS: process.env.HOSTR_DAEMON_TIMEOUT_MS ?? "180000",
      HOSTR_DAEMON_LOG_LEVEL: process.env.HOSTR_DAEMON_LOG_LEVEL ?? "info",
      HOSTR_DAEMON_NDK_LOG_LEVEL:
        process.env.HOSTR_DAEMON_NDK_LOG_LEVEL ?? "warning",
      NODE_TLS_REJECT_UNAUTHORIZED: "0",
    },
    stdio: ["ignore", "pipe", "pipe"],
  });
  mcpProcess.stdout.pipe(out);
  mcpProcess.stderr.pipe(out);
  mcpProcess.once("exit", (code, signal) => {
    if (mcpStopping) return;
    if (code !== 0 && code !== null) {
      failures.push(`MCP server exited early with code ${code}`);
    } else if (signal) {
      failures.push(`MCP server exited early with signal ${signal}`);
    }
  });

  const healthUrl = `http://127.0.0.1:${port}/health`;
  for (let attempt = 0; attempt < 90; attempt++) {
    try {
      const response = await fetch(healthUrl);
      if (response.ok) {
        supervisedLog("Hostr MCP server is healthy");
        return;
      }
    } catch {}
    await delay(1000);
  }
  throw new Error(`MCP server did not become healthy at ${healthUrl}`);
}

async function restartMcpServer() {
  supervisedLog("Restarting Hostr MCP server with the same state directory");
  if (!mcpProcess || mcpProcess.killed) {
    await startMcpServer({ port: mcpPort, stateDir: mcpStateDir });
    return;
  }
  mcpStopping = true;
  const exited = new Promise((resolve) => mcpProcess.once("exit", resolve));
  mcpProcess.kill("SIGTERM");
  await Promise.race([exited, delay(5000)]);
  if (!mcpProcess.killed) mcpProcess.kill("SIGKILL");
  await delay(500);
  mcpStopping = false;
  await startMcpServer({ port: mcpPort, stateDir: mcpStateDir });
}

async function prepareCodexHome({ codexHome, port }) {
  mcpAccessToken = await signMcpAccessToken(port);

  supervisedLog(`Preparing isolated Codex home: ${codexHome}`);
  supervisedLog(`Using Codex CLI: ${codexBin}`);
  await runCommand(codexBin, ["plugin", "marketplace", "add", path.join(repoRoot, "ai", "codex-marketplace")], {
    env: { ...process.env, CODEX_HOME: codexHome },
    logPath: path.join(logRoot, "marketplace-add.log"),
  });

  writeFileSync(
    path.join(codexHome, "config.toml"),
    [
      `model = "${process.env.HOSTR_AI_E2E_MODEL ?? "gpt-5.4-mini"}"`,
      `model_reasoning_effort = "${process.env.HOSTR_AI_E2E_REASONING ?? "low"}"`,
      'sandbox_mode = "danger-full-access"',
      'approval_policy = "never"',
      "",
      '[plugins."hostr-development@hostr-development"]',
      "enabled = true",
      "",
      "[mcp_servers.hostr-development]",
      `url = "http://127.0.0.1:${port}/mcp"`,
      'bearer_token_env_var = "HOSTR_AI_E2E_MCP_TOKEN"',
      "",
    ].join("\n"),
  );
}

async function signMcpAccessToken(port) {
  const now = Math.floor(Date.now() / 1000);
  const issuer = `http://127.0.0.1:${port}`;
  const sessionId = `codex-ai-e2e-${randomUUID()}`;
  const secret = new TextEncoder().encode(
    process.env.MCP_JWT_SECRET || "hostr-development-mcp-secret-change-me",
  );

  return new SignJWT({
    sid: sessionId,
    scope: "hostr:read hostr:write",
  })
    .setProtectedHeader({ alg: "HS256", typ: "JWT" })
    .setIssuer(issuer)
    .setAudience(`${issuer}/mcp`)
    .setSubject(sessionId)
    .setIssuedAt(now)
    .setExpirationTime(now + 60 * 60)
    .sign(secret);
}

async function runCommand(command, args, { env, logPath, timeoutMs = 120000 }) {
  const output = [];
  const child = spawn(command, args, {
    cwd: repoRoot,
    env,
    stdio: ["ignore", "pipe", "pipe"],
  });
  child.stdout.on("data", (chunk) => output.push(chunk));
  child.stderr.on("data", (chunk) => output.push(chunk));
  const timeout = setTimeout(() => child.kill("SIGTERM"), timeoutMs);
  let code;
  try {
    code = await new Promise((resolve, reject) => {
      child.once("error", reject);
      child.once("exit", resolve);
    });
  } catch (error) {
    throw new Error(`${command} ${args.join(" ")} failed to start: ${error.message}`);
  } finally {
    clearTimeout(timeout);
  }
  const text = Buffer.concat(output).toString("utf8");
  if (logPath) writeFileSync(logPath, text);
  if (code !== 0) {
    throw new Error(`${command} ${args.join(" ")} failed with ${code}\n${text}`);
  }
  return text;
}

function buildPhases(runMode) {
  if (runMode === "smoke") {
    return [{ label: "Smoke: login and search", prompt: buildSmokePrompt() }];
  }
  const versions = promptVersions.length > 0 ? promptVersions : ["canonical"];
  return [
    {
      label: "Host listing setup",
      prompt: buildHostListingSetupPrompt(),
      expectedRoleAction: "host",
      followups: [
        {
          prompt: "Please do this in Hostr, not by looking for local project files.",
          when: noHostrToolCalls,
        },
        {
          prompt: "Use Plaza Libertad, San Salvador, El Salvador.",
          when: needsAddressClarification,
        },
        { prompt: "Yes, publish it.", when: needsPublishConfirmation },
      ],
    },
    {
      label: `Guest booking (${versions[0]})`,
      prompt: buildFullGuestPrompt(versions[0]),
      expectedRoleAction: "guest",
      followups: [
        {
          prompt: "Yes, please help me log in with my guest account and then book it.",
          when: needsGuestLogin,
        },
        { prompt: "Yes, book it.", when: needsBookingConfirmation },
        { prompt: "A place to stay.", when: needsStayClarification },
        {
          prompt: "Any simple private room under $50 a night is fine.",
          when: needsGuestPreferences,
        },
        { prompt: "I paid it.", when: needsPaymentConfirmation },
        {
          prompt:
            "The invoice is paid; please monitor the Hostr payment completion before checking the trip again.",
          when: missingSwapWatchAfterBooking,
        },
      ],
    },
    ...versions.map((version) => ({
      label: `Post-booking follow-up (${version})`,
      prompt: () => buildPostBookingFollowupPrompt(requireLatestTradeId(), version),
    })),
    ...versions.map((version) => ({
      label: `Reservation concern (${version})`,
      prompt: () => buildReservationConcernPrompt(requireLatestTradeId(), version),
    })),
    {
      label: "Guest tool coverage",
      prompt: () => buildGuestCoveragePrompt(requireLatestTradeId(), versions[0]),
      followups: [
        {
          prompt:
            "Please open the booked place's reviews and availability views directly for Aug 1-3.",
          when: missingAnyTool(
            "hostr_listings_reviews",
            "hostr_listings_availability",
          ),
        },
        {
          prompt:
            "Please open the host's public Hostr profile card directly, not just infer it from the trip.",
          when: missingTool("hostr_profile_lookup"),
        },
        {
          prompt:
            "Please use Hostr's public profile lookup for Taylor instead of switching into Taylor's account, then switch me back to my guest account.",
          when: missingTool("hostr_profile_lookup"),
        },
        {
          prompt:
            "Please draft that five-star Hostr trip review now and show me the preview. If it cannot be published yet, the preview is enough.",
          when: missingTool("hostr_reservations_review"),
        },
      ],
    },
    {
      label: "Manual reservation coverage",
      prompt: () => buildManualReservationCoveragePrompt(requireLatestTradeId()),
      followups: [
        {
          prompt:
            "Please show the saved Hostr payment and swap list itself before previewing any recovery.",
          when: missingTool("hostr_swaps_list"),
        },
        {
          prompt:
            "Please open the saved Hostr payment or swap list directly, not from memory or from a recovery summary.",
          when: missingTool("hostr_swaps_list"),
        },
        {
          prompt:
            "Please show me what Hostr would do to recover any stuck saved payment operations, but only as a preview.",
          when: missingTool("hostr_swaps_recoverAll"),
        },
        {
          prompt:
            "For the reservation offer examples, use the same $20 stay total. Preview sending that counteroffer and preview accepting the latest offer; don't send or pay anything.",
          when: missingAnyTool(
            "hostr_reservations_negotiateOffer",
            "hostr_reservations_negotiateAccept",
          ),
        },
        {
          prompt:
            "Please retry the reservation offer preview with the same $20 total; don't send it.",
          when: failedTool("hostr_reservations_negotiateOffer"),
        },
        {
          prompt:
            "Please retry the latest-offer acceptance preview; don't accept it live.",
          when: failedTool("hostr_reservations_negotiateAccept"),
        },
        {
          prompt:
            "Please switch back to my guest account and preview the negotiated payment check for this reservation; don't pay anything.",
          when: failedTool("hostr_reservations_pay"),
        },
        {
          prompt:
            "Please also preview the final reservation publication check from a saved paid proof or payment record; don't publish anything.",
          when: missingTool("hostr_reservations_commit"),
        },
        {
          prompt:
            "Please try the final reservation publication preview anyway; if the proof is missing, let Hostr return that as the preview result. Don't publish anything.",
          when: missingTool("hostr_reservations_commit"),
        },
      ],
    },
    {
      label: `Host actions (${versions[0]})`,
      prompt: () => buildFullHostPrompt(requireLatestTradeId(), versions[0]),
      expectedRoleAction: "host",
      followups: [
        {
          prompt:
            "Please use my host-side bookings or hosting reservations view for that stay, not my guest trips.",
          when: missingTool("hostr_bookings_list"),
        },
        {
          prompt:
            "Please also send the guest a normal Hostr reservation-thread check-in message, separate from the escrow help request.",
          when: missingTool("hostr_thread_message"),
        },
        {
          prompt:
            "Please involve Hostr escrow through the reservation's escrow/help flow for this stay, not only by sending an ordinary thread message.",
          when: missingTool("hostr_escrow_involve"),
        },
      ],
    },
    {
      label: "Host tool coverage",
      prompt: () => buildHostCoveragePrompt(requireLatestTradeId(), versions[0]),
      followups: [
        {
          prompt:
            "Please show my host-side bookings or hosting reservations too, especially that reservation.",
          when: missingTool("hostr_bookings_list"),
        },
        {
          prompt:
            "Please open my Hostr listings list directly too; I want the listing cards, not just updates or booking summaries.",
          when: missingTool("hostr_listings_list"),
        },
        {
          prompt:
            "Please open the reservation groups view for the newest City Center Spare Room listing itself.",
          when: missingTool("hostr_listings_reservationGroups"),
        },
      ],
    },
    { label: "Escrow login", prompt: () => buildEscrowLoginPrompt(), expectedRoleAction: "escrow" },
    {
      label: `Escrow actions (${versions[0]})`,
      prompt: () => buildFullEscrowPrompt(requireLatestTradeId(), versions[0]),
      followups: [
        {
          prompt:
            "Please run Hostr's escrow audit/check on that trade too, so I can see whether anything looks inconsistent.",
          when: missingTool("hostr_escrow_trades_audit"),
        },
        {
          prompt:
            "Please preview an even-split Hostr arbitration for that escrow trade if arbitration is still available; don't finalize it.",
          when: missingTool("hostr_escrow_trades_arbitrate"),
        },
      ],
    },
    {
      label: "Escrow tool coverage",
      prompt: () => buildEscrowCoveragePrompt(requireLatestTradeId(), versions[0]),
      followups: [
        {
          prompt:
            "Please open the payment-methods view for this escrow trade so I can see how funds can be released or returned.",
          when: missingTool("hostr_escrow_methods"),
        },
        {
          prompt:
            "Please show the escrow service fee-change preview and the service deletion preview too; don't publish either one.",
          when: missingAnyTool(
            "hostr_escrow_service_edit",
            "hostr_escrow_service_delete",
          ),
        },
        {
          prompt:
            "For the revocation preview, use one existing published badge award from the badge awards list instead of the draft award you just sketched.",
          when: failedTool("hostr_escrow_badges_revoke"),
        },
        {
          prompt:
            "Please open the existing badge awards list and preview revoking one existing award, not a draft award.",
          when: missingAnyTool(
            "hostr_escrow_badges_awards_list",
            "hostr_escrow_badges_revoke",
          ),
        },
      ],
    },
    { label: "MCP restart", restartServer: true },
    {
      label: "Session rehydration",
      prompt: () => buildRehydrationPrompt(requireLatestTradeId()),
      followups: [
        {
          prompt: "Please check this inside Hostr, not by reading local files.",
          when: noHostrToolCalls,
        },
      ],
    },
    { label: "Session cleanup", prompt: () => buildSessionCleanupPrompt() },
  ];
}

function commonPrompt() {
  return "";
}

function buildSmokePrompt() {
  return `I want to use Hostr. Am I logged in? If not, please help me log in. Then find a place to stay in San Salvador and show me one that looks bookable. Do not book anything yet.`;
}

function buildHostListingSetupPrompt() {
  return `Hostr, in Hostr I'm hosting now. Please publish my spare room at Plaza Libertad, San Salvador, El Salvador. Call it "City Center Spare Room". It's a simple private room near the city center for one guest, with one bed, one bedroom, one bathroom, and instant booking is fine. Charge 10 USD per night. Use this photo: https://placehold.co/800x600.jpg`;
}

function buildFullGuestPrompt(version = "canonical") {
  return version === "natural"
    ? `I want to book a place to stay with my guest account via Hostr in San Salvador for Aug 1-3, 2027. If I'm on the wrong account, help me sign into the guest one.`
    : `I want to make a Hostr reservation with my guest account for a place to stay in San Salvador from Aug 1 to Aug 3, 2027. If I'm on the wrong account, help me sign into the guest one.`;
}

function buildPostBookingFollowupPrompt(tradeId, version = "canonical") {
  const ask =
    version === "natural"
      ? "Hostr, I finished booking. Please check my trip and tell me anything useful I should do next."
      : "My reservation is booked. Check my Hostr trip if needed and tell me the next useful follow-up, including whether I should message the host now.";
  return `${ask} My reservation reference is ${tradeId}. Don't message anyone yet.`;
}

function buildReservationConcernPrompt(tradeId, version = "canonical") {
  const ask =
    version === "natural"
      ? "Hostr, I'm uneasy about my stay. Please check my Hostr reservation thread first. The host seems quiet and I want to know what I can say or do. If I may need to involve escrow later, tell me how to ask for that without doing it now."
      : "Hostr, please check my reservation thread. The host has not replied and I may need help, but do not involve escrow yet. If I may need to involve escrow later, tell me how to ask for that without doing it now.";
  return `${ask} My reservation reference is ${tradeId}. Don't send anything yet; just tell me what I can do and what I could say.`;
}

function buildGuestCoveragePrompt(tradeId, version = "canonical") {
  return `Hostr, what are my updates? Also show me my account, my profile, and my trip ${tradeId}. Open the host's full profile record too. I want to see the place I booked. Please use Hostr's listing reviews and listing availability views for that place, explicitly check whether those Aug 1-3 dates still look available, and tell me whether payment looks okay. Don't change anything unless I already said yes. If I can review this trip, leave 5 stars and say "Great stay, smooth check-in, and helpful communication." If it isn't ready for a live review yet, just show me a review preview instead. Also upload this image to Hostr media so I can use it later: ${fixtureImagePath}.`;
}

function buildManualReservationCoveragePrompt(tradeId) {
  return `Hostr, in the Hostr app, something seems off with reservation ${tradeId}. Use my guest account if needed. Can you check my trip, see whether payment got stuck, list my saved payment or swap operations, and preview what recovery would do? Also show me what it would look like to send a new offer, accept the latest offer, pay a negotiated reservation, and preview publishing the final reservation record from a paid proof. Don't actually send, pay, recover, or publish anything.`;
}

function buildFullHostPrompt(tradeId, version = "canonical") {
  return `Hostr, use my host account now; switch accounts if needed. Show my recent bookings, especially ${tradeId}. Open the conversation and tell the guest: "Hi, just checking in on your stay details." Then ask escrow to help with it. After that, cancel the reservation if it looks like I can.`;
}

function buildHostCoveragePrompt(tradeId, version = "canonical") {
  return `Hostr, as host, show my profile and my listings. Look up the guest profile for reservation ${tradeId}. I might want to change my about text to "I enjoy hosting travelers and sharing local recommendations" and tweak the newest City Center Spare Room listing description to "Updated preview description for a clean, comfortable stay." Show the reservation groups for that listing too. Also sketch out a new San Salvador listing called "Preview City Stay" for 10 USD a night using one of my existing photos. Don't publish those changes yet. Then tell me my latest updates.`;
}

function buildEscrowLoginPrompt() {
  return `Hostr, in the Hostr app I'm handling escrow now. Switch me to my escrow account and show me the Hostr accounts you know about.`;
}

function buildFullEscrowPrompt(tradeId, version = "canonical") {
  return `Hostr, as escrow, show me my trades and open the full details for ${tradeId}. Check whether anything looks wrong. If arbitration is still possible, split it evenly. Don't message the people in the trade yet; just tell me what you would say.`;
}

function buildEscrowCoveragePrompt(tradeId, version = "canonical") {
  return `Hostr, as escrow, look at ${tradeId} again and show me how the host and buyer can be paid. Open the trade details. Show my escrow services and open the service details too. Use the service management previews to show changing the fee to 1.5% and deleting that service; don't actually do either. Also show me the badges area; try drafting a "Trusted Host Preview" badge, awarding it, revoking an award, and previewing deletion of that badge definition, but don't make live badge changes.`;
}

function buildRehydrationPrompt(tradeId) {
  return `Hostr, after that restart, check inside Hostr: what account am I on? Show me the Hostr accounts you remember, go back to escrow if needed, and make sure ${tradeId} still shows up in Hostr.`;
}

function buildSessionCleanupPrompt() {
  return `Hostr, show me my login status and the accounts connected to this session, then log me out of all Hostr accounts and confirm I am logged out.`;
}

function unnaturalPromptReason(prompt) {
  const checks = [
    [/hostr_[a-zA-Z0-9_]+/, "contains a raw MCP tool name"],
    [/\bMCP\b/i, "mentions MCP"],
    [/test harness/i, "mentions the test harness"],
    [/AI under test/i, "mentions the AI under test"],
    [/dryRun/i, "mentions dryRun"],
    [/wait\s*=\s*(true|false)/i, "mentions Nostr Connect wait flags"],
    [/call\s+(the\s+)?[a-zA-Z0-9_]+\s+tool/i, "tells the AI to call a tool"],
    [/Lightning invoice/i, "tells the AI to show a Lightning invoice"],
    [/\bQR\b/i, "tells the AI to show a QR"],
    [/payment flow/i, "mentions payment flow internals"],
    [/swapId|tradeId/i, "mentions internal swap/trade ids"],
  ];
  for (const [pattern, reason] of checks) {
    if (pattern.test(prompt)) return reason;
  }
  return null;
}

function requireLatestTradeId() {
  if (!latestTradeId) return "{{tradeId}}";
  return latestTradeId;
}

async function runCodex({ codexHome, prompt, label, resume = false }) {
  supervisedLog(`Launching isolated Codex exec for: ${label}`);
  const stdout = createWriteStream(codexStdoutPath, { flags: "a" });
  const stderr = createWriteStream(codexStderrPath, { flags: "a" });
  const codexArgs = resume
    ? [
        "exec",
        "resume",
        "--last",
        "--skip-git-repo-check",
        "--json",
        "-",
      ]
    : [
        "exec",
        "--skip-git-repo-check",
        "--json",
        "-s",
        "danger-full-access",
        "-C",
        codexWorkspace,
        "-",
      ];
  const child = spawn(
    codexBin,
    codexArgs,
    {
      cwd: codexWorkspace,
      env: {
        ...process.env,
        CODEX_HOME: codexHome,
        HOSTR_AI_E2E_MCP_TOKEN: mcpAccessToken,
        NODE_TLS_REJECT_UNAUTHORIZED: "0",
      },
      stdio: ["pipe", "pipe", "pipe"],
    },
  );

  child.stdin.end(prompt);
  child.stderr.pipe(stderr);

  let buffer = "";
  child.stdout.on("data", (chunk) => {
    stdout.write(chunk);
    buffer += chunk.toString("utf8");
    let newline;
    while ((newline = buffer.indexOf("\n")) >= 0) {
      const line = buffer.slice(0, newline).trim();
      buffer = buffer.slice(newline + 1);
      if (line) {
        void handleCodexLine(line).catch((error) => {
          failures.push(`Codex event handler failed: ${error.message}`);
        });
      }
    }
  });

  const timeoutMs = Number(process.env.HOSTR_AI_E2E_CODEX_TIMEOUT_MS ?? 20 * 60 * 1000);
  const timeout = setTimeout(() => {
    failures.push(`Codex timed out after ${timeoutMs}ms`);
    child.kill("SIGTERM");
  }, timeoutMs);

  const code = await new Promise((resolve) => child.once("exit", resolve));
  clearTimeout(timeout);
  stdout.end();
  stderr.end();

  if (buffer.trim()) await handleCodexLine(buffer.trim());
  return { exitCode: code };
}

async function handleCodexLine(line) {
  let event;
  try {
    event = JSON.parse(line);
  } catch {
    failures.push(`Non-JSON Codex stdout line: ${line.slice(0, 160)}`);
    return;
  }
  events.push(event);
  renderCodexEvent(event);
  const item = event.item;
  if (
    item?.type === "mcp_tool_call" &&
    item.status === "in_progress" &&
    item.tool === "hostr_session_connect" &&
    item.arguments?.wait === true
  ) {
    const nostrconnect = pendingLoginUris.shift();
    if (nostrconnect) {
      void approveNextLogin(nostrconnect).catch((error) => {
        failures.push(`Nostr Connect approval failed: ${error.message}`);
      });
    }
  }

  if (
    !item ||
    item.type !== "mcp_tool_call" ||
    !["completed", "failed"].includes(item.status)
  ) {
    return;
  }
  toolCalls.push({
    server: item.server,
    tool: item.tool,
    arguments: item.arguments,
    result: item.result,
    error: item.error,
    status: item.status,
  });

  if (item.status !== "completed" || item.error) {
    return;
  }

  const observedTradeId = findStringByKey(item.result, "tradeId");
  if (
    observedTradeId &&
    ["hostr_reservations_bookAndPay", "hostr_swaps_watch"].includes(item.tool)
  ) {
    latestTradeId = observedTradeId;
  }

  if (item.tool === "hostr_session_connect") {
    const uri = findString(item.result, (value) =>
      value.startsWith("nostrconnect://"),
    );
    if (uri) pendingLoginUris.push(uri);
  }

  const invoice = findString(item.result, (value) =>
    /^ln[a-z0-9]{20,}/i.test(value.trim()),
  );
  if (invoice && !paidInvoices.has(invoice)) {
    paidInvoices.add(invoice);
    await payInvoice(invoice);
  }
}

async function approveNextLogin(nostrconnect) {
  const role = roleQueue[Math.min(approvalIndex, roleQueue.length - 1)];
  approvalIndex += 1;
  supervisedLog(`Approving Nostr Connect login as ${role.role} (${role.keyName})`);
  await signetRequest("POST", "/nostrconnect", {
    uri: nostrconnect,
    keyName: role.keyName,
    trustLevel: "full",
    description: `Hostr Codex AI e2e ${role.role}`,
  });
  approvals.push({ role: role.role, keyName: role.keyName });
}

function startApprovalPoller() {
  let stopped = false;
  const approvedIds = new Set();
  const allowedKeys = new Set(roleQueue.map((role) => role.keyName));

  const loop = async () => {
    while (!stopped) {
      try {
        const response = await signetRequest("GET", "/requests?status=pending&limit=100");
        const requests = Array.isArray(response.requests) ? response.requests : [];
        for (const request of requests) {
          const id = String(request.id ?? "");
          const keyName = request.keyName;
          if (!id || approvedIds.has(id) || !allowedKeys.has(keyName)) continue;
          approvedIds.add(id);
          await signetRequest("POST", `/requests/${encodeURIComponent(id)}`, {
            trustLevel: "full",
            alwaysAllow: true,
            appName: "Hostr",
          });
          supervisedLog(`Approved signing request ${id} for ${keyName}`);
          signingApprovals.push({
            id,
            keyName,
            method: request.method ?? request.eventType ?? null,
            eventKind: request.eventPreview?.kind ?? null,
          });
        }
      } catch (error) {
        failures.push(`Signet approval poll failed: ${error.message}`);
      }
      await delay(500);
    }
  };

  void loop();
  return () => {
    stopped = true;
  };
}

async function payInvoice(invoice) {
  const token = await unlockAlby();
  supervisedLog(`Paying Lightning invoice ${invoice.slice(0, 24)}...`);
  try {
    await albyRequest("POST", `/api/payments/${encodeURIComponent(invoice)}`, undefined, token);
    payments.push({ invoice: `${invoice.slice(0, 24)}...`, status: "paid" });
    supervisedLog(`Paid Lightning invoice ${invoice.slice(0, 24)}...`);
  } catch (error) {
    const message = String(error?.message ?? error);
    if (/expired|already|duplicate|paid/i.test(message)) {
      payments.push({
        invoice: `${invoice.slice(0, 24)}...`,
        status: "skipped",
        reason: message,
      });
      supervisedLog(`Skipped Lightning payment ${invoice.slice(0, 24)}... (${message})`);
      return;
    }
    throw error;
  }
}

async function unlockAlby() {
  let lastToken = null;
  for (let attempt = 0; attempt < 5; attempt += 1) {
    let response = await albyRequest(
      "POST",
      "/api/unlock",
      { permission: "full", unlockPassword: albyPassword },
      lastToken,
      false,
    );
    let token = tokenFromAlby(response) ?? lastToken;
    if (token) return token;

    const message = String(response.body?.message ?? response.body?.error ?? "").toLowerCase();
    if (message.includes("invalid password")) {
      throw new Error(`AlbyHub unlock failed: ${message}`);
    }
    if (message.includes("rate limit") || message.includes("too many requests")) {
      await delay((attempt + 1) * 1000);
      continue;
    }

    response = await albyRequest(
      "POST",
      "/api/start",
      { unlockPassword: albyPassword },
      null,
      false,
    );
    lastToken = tokenFromAlby(response) ?? lastToken;
    if (lastToken) return lastToken;
    await delay((attempt + 1) * 1000);
  }
  throw new Error("AlbyHub unlock did not return an auth token");
}

function tokenFromAlby(response) {
  const cookieToken = response.headers
    ?.get("set-cookie")
    ?.split(";")
    .find((part) => part.trim().startsWith("token="))
    ?.trim()
    .slice("token=".length);
  return (
    response.body?.token ??
    response.body?.authToken ??
    response.body?.accessToken ??
    response.body?.access_token ??
    cookieToken ??
    null
  );
}

async function signetRequest(method, route, body) {
  const agent = new HttpsAgent({ rejectUnauthorized: false });
  const csrfResponse = await fetch(`${signetBaseUrl}/csrf-token`, { agent });
  assert.equal(csrfResponse.ok, true, `Signet CSRF failed: ${csrfResponse.status}`);
  const csrfBody = await csrfResponse.json();
  const csrf = csrfBody.csrfToken ?? csrfBody.token;
  const cookie = csrfResponse.headers.get("set-cookie")?.split(";")[0];
  const response = await fetch(`${signetBaseUrl}${route}`, {
    method,
    agent,
    headers: {
      accept: "application/json",
      "content-type": "application/json",
      "x-csrf-token": csrf,
      ...(cookie ? { cookie } : {}),
    },
    body: JSON.stringify(body),
  });
  const text = await response.text();
  if (!response.ok) {
    throw new Error(`Signet ${method} ${route} failed ${response.status}: ${text}`);
  }
  return text ? JSON.parse(text) : {};
}

async function albyRequest(method, route, body, token, throwOnHttpError = true) {
  const agent = new HttpsAgent({ rejectUnauthorized: false });
  const response = await fetch(`${albyBaseUrl}${route}`, {
    method,
    agent,
    headers: {
      accept: "application/json",
      ...(body ? { "content-type": "application/json" } : {}),
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await response.text();
  let decoded = {};
  try {
    decoded = text ? JSON.parse(text) : {};
  } catch {
    decoded = { text };
  }
  if (throwOnHttpError && !response.ok) {
    throw new Error(`Alby ${method} ${route} failed ${response.status}: ${text}`);
  }
  return { status: response.status, body: decoded, headers: response.headers };
}

function findString(value, predicate) {
  if (typeof value === "string") return predicate(value) ? value : null;
  if (!value || typeof value !== "object") return null;
  if (Array.isArray(value)) {
    for (const entry of value) {
      const found = findString(entry, predicate);
      if (found) return found;
    }
    return null;
  }
  for (const entry of Object.values(value)) {
    const found = findString(entry, predicate);
    if (found) return found;
  }
  return null;
}

function findStringByKey(value, key) {
  if (!value || typeof value !== "object") return null;
  if (Array.isArray(value)) {
    for (const entry of value) {
      const found = findStringByKey(entry, key);
      if (found) return found;
    }
    return null;
  }
  for (const [entryKey, entryValue] of Object.entries(value)) {
    if (entryKey === key && typeof entryValue === "string" && entryValue) {
      return entryValue;
    }
    const found = findStringByKey(entryValue, key);
    if (found) return found;
  }
  return null;
}

function supervisedBanner(title) {
  if (!supervised) return;
  const line = "=".repeat(Math.max(20, Math.min(88, title.length + 8)));
  supervisedLog(`\n${line}\n${title}\n${line}`);
}

function supervisedLog(message = "") {
  if (!supervised) return;
  console.log(message);
}

function renderCodexEvent(event) {
  if (!supervised) return;
  if (event.type === "thread.started") {
    supervisedLog(`Codex thread started: ${event.thread_id ?? "unknown"}`);
    return;
  }
  if (event.type === "turn.started") {
    supervisedLog("Codex turn started");
    return;
  }
  if (event.type === "turn.completed") {
    supervisedLog("Codex turn completed");
    return;
  }

  const item = event.item;
  if (!item) return;

  if (item.type === "agent_message" && item.text) {
    supervisedLog("AI response");
    supervisedLog(indent(truncate(item.text.trim())));
    return;
  }

  if (item.type !== "mcp_tool_call") return;
  if (item.status === "in_progress") {
    const argsText = summarizeJson(item.arguments);
    supervisedLog(`-> ${item.tool}${argsText ? ` ${argsText}` : ""}`);
    return;
  }
  if (item.status === "completed" && !item.error) {
    const result = summarizeToolResult(item.result);
    supervisedLog(`<- ${item.tool} OK${result ? `\n${indent(result)}` : ""}`);
    return;
  }
  if (item.status === "failed" || item.error) {
    const errorText = item.error ? summarizeJson(item.error) : "failed";
    supervisedLog(`<- ${item.tool} FAILED ${errorText}`);
  }
}

function summarizeToolResult(result) {
  const structured = result?.structuredContent ?? result?.structured_content;
  const display =
    structured?.displayMarkdown ??
    structured?.displayText ??
    structured?.summary ??
    structured?.message;
  if (typeof display === "string" && display.trim()) {
    return truncate(display.trim());
  }
  if (Array.isArray(result?.content)) {
    const text = result.content
      .map((entry) => entry?.text)
      .filter((value) => typeof value === "string" && value.trim())
      .join("\n\n");
    if (text.trim()) return truncate(text.trim());
  }
  const string = findString(
    result,
    (value) => value.trim().length > 0 && !value.startsWith("data:"),
  );
  return string ? truncate(string.trim()) : truncate(summarizeJson(result));
}

function summarizeJson(value) {
  if (value === undefined || value === null) return "";
  try {
    return truncate(JSON.stringify(value));
  } catch {
    return truncate(String(value));
  }
}

function truncate(value, max = supervisedMaxChars) {
  const text = normalizeWhitespace(String(value));
  if (text.length <= max) return text;
  return `${text.slice(0, Math.max(0, max - 1))}…`;
}

function normalizeWhitespace(value) {
  return value.replace(/\s+/g, " ").trim();
}

function indent(value) {
  return String(value)
    .split("\n")
    .map((line) => `  ${line}`)
    .join("\n");
}

function agentMessages() {
  return events
    .map((event) => event.item)
    .filter((item) => item?.type === "agent_message")
    .map((item) => item.text);
}

function phaseAgentMessages(phaseStart) {
  return agentMessages().slice(phaseStart.messageCount);
}

function phaseToolCalls(phaseStart) {
  return toolCalls.slice(phaseStart.toolCount);
}

function noHostrToolCalls(phaseStart) {
  return phaseToolCalls(phaseStart).every((call) => !call.tool?.startsWith("hostr_"));
}

function missingSwapWatchAfterBooking(phaseStart) {
  const calls = phaseToolCalls(phaseStart);
  return (
    calls.some((call) => call.tool === "hostr_reservations_bookAndPay") &&
    calls.every((call) => call.tool !== "hostr_swaps_watch")
  );
}

function missingTool(tool) {
  return (phaseStart) => !phaseToolCalls(phaseStart).some((call) => call.tool === tool);
}

function missingAnyTool(...tools) {
  return (phaseStart) => tools.some((tool) => missingTool(tool)(phaseStart));
}

function failedTool(tool) {
  return (phaseStart) =>
    phaseToolCalls(phaseStart).some(
      (call) => call.tool === tool && (call.status === "failed" || call.error),
    );
}

function missingOrFailedTool(requiredTool, failureTool = requiredTool) {
  return (phaseStart) => missingTool(requiredTool)(phaseStart) || failedTool(failureTool)(phaseStart);
}

function validatePhase(label, phase, phaseStart, result) {
  if (phase.restartServer) return;
  const calls = phaseToolCalls(phaseStart);
  const hostrCalls = calls.filter((call) => call.tool?.startsWith("hostr_"));
  if (hostrCalls.length === 0) {
    failures.push(`Phase "${label}" did not call any Hostr MCP tools`);
    result.exitCode = 1;
  }

  if (phase.expectedRoleAction) {
    const transitioned = calls.some((call) =>
      ["hostr_session_connect", "hostr_session_switch"].includes(call.tool),
    );
    if (!transitioned && !roleActionWasSatisfied(phase.expectedRoleAction, calls)) {
      failures.push(
        `Phase "${label}" did not connect or switch to the requested ${phase.expectedRoleAction} account`,
      );
      result.exitCode = 1;
    }
  }
}

function roleActionWasSatisfied(role, calls) {
  if (role === "guest") {
    return calls.some((call) => call.tool === "hostr_reservations_bookAndPay");
  }
  if (role === "host") {
    return (
      calls.some((call) => call.tool === "hostr_bookings_list") &&
      calls.some((call) =>
        ["hostr_thread_message", "hostr_reservations_cancel"].includes(call.tool),
      )
    );
  }
  if (role === "escrow") {
    return calls.some((call) => call.tool?.startsWith("hostr_escrow_"));
  }
  return false;
}

function needsBookingConfirmation(phaseStart) {
  const calls = phaseToolCalls(phaseStart);
  if (calls.some((call) => call.tool === "hostr_reservations_bookAndPay")) {
    return false;
  }
  const lastMessage = phaseAgentMessages(phaseStart).at(-1) ?? "";
  return /\b(confirm|approve|go ahead|proceed|book it|should i book|want me to book|ready to book)\b/i.test(
    lastMessage,
  );
}

function needsGuestLogin(phaseStart) {
  const calls = phaseToolCalls(phaseStart);
  if (calls.some((call) => call.tool === "hostr_reservations_bookAndPay")) {
    return false;
  }
  const connectedGuest = calls.some(
    (call) => call.tool === "hostr_session_connect" && call.status === "completed",
  );
  if (connectedGuest) return false;
  const lastMessage = phaseAgentMessages(phaseStart).at(-1) ?? "";
  return /\b(guest account|guest profile|connect.*guest|sign in.*guest|logged in.*host|only.*host|not.*guest)\b/i.test(
    lastMessage,
  );
}

function needsStayClarification(phaseStart) {
  const calls = phaseToolCalls(phaseStart);
  if (
    calls.some((call) =>
      ["hostr_listings_search", "hostr_reservations_bookAndPay"].includes(
        call.tool,
      ),
    )
  ) {
    return false;
  }
  const lastMessage = phaseAgentMessages(phaseStart).at(-1) ?? "";
  return /\b(what kind|what type|hotel|restaurant|car|something else|place to stay|lodging)\b/i.test(
    lastMessage,
  );
}

function needsGuestPreferences(phaseStart) {
  const calls = phaseToolCalls(phaseStart);
  if (
    calls.some((call) =>
      ["hostr_listings_search", "hostr_reservations_bookAndPay"].includes(
        call.tool,
      ),
    )
  ) {
    return false;
  }
  const lastMessage = phaseAgentMessages(phaseStart).at(-1) ?? "";
  return /\b(budget|price|per night|room preferences|must-haves|preferred area|1 bed|2 beds)\b/i.test(
    lastMessage,
  );
}

function needsAddressClarification(phaseStart) {
  const calls = phaseToolCalls(phaseStart);
  if (calls.some((call) => call.tool === "hostr_listings_create")) {
    return false;
  }
  const lastMessage = phaseAgentMessages(phaseStart).at(-1) ?? "";
  return /\b(address|where is it|location|exact)\b/i.test(lastMessage);
}

function needsPaymentConfirmation(phaseStart) {
  const calls = phaseToolCalls(phaseStart);
  const hasInvoice = calls.some((call) => {
    if (call.tool !== "hostr_reservations_bookAndPay" || call.status !== "completed") {
      return false;
    }
    return Boolean(
      findString(call.result, (value) => /^ln[a-z0-9]{20,}/i.test(value.trim())),
    );
  });
  if (!hasInvoice) {
    return false;
  }
  const lastMessage = phaseAgentMessages(phaseStart).at(-1) ?? "";
  return /\b(after you pay|once paid|when you'?ve paid|tell me.*paid|let me know.*paid|did you pay|have you paid)\b/i.test(
    lastMessage,
  );
}

function needsPublishConfirmation(phaseStart) {
  const calls = phaseToolCalls(phaseStart);
  const hasPreview = calls.some(
    (call) =>
      call.tool === "hostr_listings_create" &&
      call.status === "completed" &&
      call.arguments?.dryRun !== false,
  );
  const hasPublished = calls.some(
    (call) =>
      call.tool === "hostr_listings_create" &&
      call.status === "completed" &&
      call.arguments?.dryRun === false,
  );
  if (!hasPreview || hasPublished) return false;
  const lastMessage = phaseAgentMessages(phaseStart).at(-1) ?? "";
  return /\b(publish|list it|go ahead|approve|confirm|looks good|ready)\b/i.test(
    lastMessage,
  );
}

function evaluate({ exitCode }) {
  const finalMessages = agentMessages();
  const tools = toolCalls.map((call) => call.tool);
  const expected =
    mode === "smoke"
      ? ["hostr_session_status", "hostr_session_connect", "hostr_listings_search"]
      : [
          "hostr_session_status",
          "hostr_session_connect",
          "hostr_session_accounts",
          "hostr_session_switch",
          "hostr_session_logout",
          "hostr_images_upload",
          "hostr_listings_search",
          "hostr_listings_list",
          "hostr_listings_create",
          "hostr_listings_edit",
          "hostr_listings_availability",
          "hostr_listings_reviews",
          "hostr_listings_reservationGroups",
          "hostr_reservations_bookAndPay",
          "hostr_reservations_negotiateOffer",
          "hostr_reservations_negotiateAccept",
          "hostr_reservations_pay",
          "hostr_reservations_commit",
          "hostr_reservations_review",
          "hostr_swaps_watch",
          "hostr_swaps_list",
          "hostr_swaps_recoverAll",
          "hostr_updates",
          "hostr_thread_view",
          "hostr_trips_list",
          "hostr_bookings_list",
          "hostr_thread_message",
          "hostr_escrow_involve",
          "hostr_reservations_cancel",
          "hostr_profile_show",
          "hostr_profile_lookup",
          "hostr_profile_edit",
          "hostr_escrow_methods",
          "hostr_escrow_service_list",
          "hostr_escrow_service_get",
          "hostr_escrow_service_edit",
          "hostr_escrow_service_delete",
          "hostr_escrow_trades_list",
          "hostr_escrow_trades_view",
          "hostr_escrow_trades_audit",
          "hostr_escrow_trades_arbitrate",
          "hostr_escrow_badges_definitions_list",
          "hostr_escrow_badges_definitions_edit",
          "hostr_escrow_badges_definitions_delete",
          "hostr_escrow_badges_awards_list",
          "hostr_escrow_badges_award",
          "hostr_escrow_badges_revoke",
        ];

  const checkFailures = [...failures];
  if (exitCode !== 0) checkFailures.push(`Codex exited with ${exitCode}`);
  for (const tool of expected) {
    if (!tools.includes(tool)) checkFailures.push(`Missing expected tool call: ${tool}`);
  }

  for (const [index, call] of toolCalls.entries()) {
    if (call.status === "failed" || call.error) {
      if (toolFailureWasRecovered(index, call)) continue;
      checkFailures.push(`MCP tool failed: ${call.tool} ${summarizeJson(call.error)}`.trim());
    }
  }

  const finalFailures = finalMessages.filter((message) =>
    /(^|\n)\s*FAIL\b/i.test(message),
  );
  if (finalFailures.length > 0) {
    checkFailures.push(`AI reported FAIL: ${truncate(finalFailures.at(-1), 500)}`);
  }

  if (mode === "smoke" && !smokeObservedListing()) {
    checkFailures.push(
      "Smoke did not observe a listing result from hostr_listings_search or hostr_listings_list",
    );
  }

  if (
    mode !== "smoke" &&
    !finalMessages.some((message) => /message\s+the\s+host|host.*message/i.test(message))
  ) {
    checkFailures.push(
      'Missing expected post-booking follow-up suggestion to message the host',
    );
  }
  if (
    mode !== "smoke" &&
    !finalMessages.some((message) => /involve\s+(the\s+)?escrow/i.test(message))
  ) {
    checkFailures.push(
      'Missing expected reservation concern suggestion to involve escrow',
    );
  }
  if (mode !== "smoke" && !finalMessages.some((message) => /you could say|suggested message|say:/i.test(message))) {
    checkFailures.push("Missing expected useful suggested message for escrow/host concern");
  }
  if (mode !== "smoke" && payments.length === 0) {
    checkFailures.push("No Lightning invoice was paid by the harness");
  }
  const bookingInvoice = observedBookAndPayInvoice();
  if (
    mode !== "smoke" &&
    bookingInvoice &&
    !(
      aiDisplayedLightningInvoice(finalMessages, bookingInvoice) ||
      toolDisplayedLightningInvoice(bookingInvoice)
    )
  ) {
    checkFailures.push("AI did not show the Lightning invoice from the booking result");
  }
  if (
    mode !== "smoke" &&
    bookingInvoice &&
    !(aiDisplayedPaymentQr(finalMessages) || toolDisplayedPaymentQr())
  ) {
    checkFailures.push("AI did not show a Lightning payment QR/image for the booking result");
  }
  if (mode !== "smoke" && approvals.length < 3) {
    checkFailures.push(`Expected 3 account approvals, observed ${approvals.length}`);
  }

  return {
    ok: checkFailures.length === 0,
    mode,
    logRoot,
    failures: checkFailures,
    approvals,
    signingApprovals,
    payments,
    tools,
    finalMessages,
  };
}

function toolFailureWasRecovered(index, failedCall) {
  return toolCalls
    .slice(index + 1)
    .some(
      (call) =>
        call.tool === failedCall.tool &&
        call.status === "completed" &&
        !call.error,
    );
}

function observedBookAndPayInvoice() {
  for (const call of toolCalls) {
    if (call.tool !== "hostr_reservations_bookAndPay" || call.status !== "completed") {
      continue;
    }
    const invoice = findString(call.result, (value) =>
      /^ln[a-z0-9]{20,}/i.test(value.trim()),
    );
    if (invoice) return invoice;
  }
  return null;
}

function aiDisplayedLightningInvoice(messages, invoice) {
  return messages.some((message) => {
    const text = String(message);
    return text.includes(invoice) || /^.*ln[a-z0-9]{20,}.*$/im.test(text);
  });
}

function aiDisplayedPaymentQr(messages) {
  return messages.some((message) =>
    /!\[[^\]]*(qr|payment|invoice|lightning)[^\]]*\]\([^)]+\)|payment-qr|qr code|scan/i.test(
      String(message),
    ),
  );
}

function toolDisplayedLightningInvoice(invoice) {
  return toolCalls.some((call) => {
    if (call.tool !== "hostr_reservations_bookAndPay" || call.status !== "completed") {
      return false;
    }
    const text = summarizeToolResult(call.result);
    return text.includes(invoice) || text.includes(encodeURIComponent(invoice));
  });
}

function toolDisplayedPaymentQr() {
  return toolCalls.some((call) => {
    if (call.tool !== "hostr_reservations_bookAndPay" || call.status !== "completed") {
      return false;
    }
    return /!\[[^\]]*(qr|payment|invoice|lightning)[^\]]*\]\([^)]+\)|payment-qr|qr code|scan|create-qr-code/i.test(
      summarizeToolResult(call.result),
    );
  });
}

function smokeObservedListing() {
  return toolCalls.some((call) => {
    if (
      call.status !== "completed" ||
      !["hostr_listings_search", "hostr_listings_list"].includes(call.tool)
    ) {
      return false;
    }
    const resultText = summarizeToolResult(call.result);
    return (
      !/No matching Hostr listings found/i.test(resultText) &&
      /(Open listing|Price:|instant-book|instantBook|active)/i.test(resultText)
    );
  });
}

async function cleanup() {
  if (mcpProcess && !mcpProcess.killed) {
    mcpProcess.kill("SIGTERM");
    await delay(500);
  }
  if (!keep) {
    for (const directory of [codexHome, codexWorkspace, mcpStateDir]) {
      if (directory) rmSync(directory, { recursive: true, force: true });
    }
  }
}
