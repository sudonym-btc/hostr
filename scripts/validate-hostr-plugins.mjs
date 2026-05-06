#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const root = process.cwd();
const envs = ['development', 'staging', 'production'];
const expectedUrls = {
  development: 'https://ai.hostr.development/mcp',
  staging: 'https://ai.staging.hostr.network/mcp',
  production: 'https://ai.hostr.network/mcp',
};

const expectedDisplayNames = {
  development: 'Hostr Development',
  staging: 'Hostr Staging',
  production: 'Hostr',
};

const sharedShortDescription =
  'Use Hostr to rent accommodation via the Nostr network. Plan a vacation, trip, or long-term stay, or put up your room for rent and earn sats.';

const errors = [];

function fail(message) {
  errors.push(message);
}

function readJson(file) {
  return JSON.parse(fs.readFileSync(path.join(root, file), 'utf8'));
}

function readLink(file) {
  const absolute = path.join(root, file);
  try {
    return fs.readlinkSync(absolute);
  } catch (error) {
    fail(`${file} must be a symlink (${error.message})`);
    return null;
  }
}

function assertEqual(actual, expected, label) {
  if (actual !== expected) {
    fail(`${label}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

function normalizeEnvironmentText(value) {
  return value
    .replaceAll('Hostr Development', 'Hostr <ENV>')
    .replaceAll('Hostr Staging', 'Hostr <ENV>')
    .replaceAll('Hostr Production', 'Hostr <ENV>')
    .replaceAll('(Development)', '(<ENV>)')
    .replaceAll('(Staging)', '(<ENV>)')
    .replaceAll('(Production)', '(<ENV>)')
    .replaceAll('Development', '<ENV>')
    .replaceAll('Staging', '<ENV>')
    .replaceAll('Production', '<ENV>');
}

const sharedSkill = 'ai/plugins/shared/hostr/SKILL.md';
const sharedSkillText = fs.readFileSync(path.join(root, sharedSkill), 'utf8');
for (const required of ['hostr_upload_image', 'Do not base64 encode', '1/100,000,000']) {
  if (!sharedSkillText.includes(required)) {
    fail(`${sharedSkill} must mention ${JSON.stringify(required)}`);
  }
}

const manifests = {};
for (const env of envs) {
  const pluginDir = `ai/plugins/hostr-${env}`;
  const plugin = readJson(`${pluginDir}/.codex-plugin/plugin.json`);
  const mcp = readJson(`${pluginDir}/.mcp.json`);
  const serverName = `hostr-${env}`;

  manifests[env] = plugin;

  assertEqual(plugin.name, serverName, `${env} plugin name`);
  assertEqual(plugin.skills, './skills/', `${env} skills path`);
  assertEqual(plugin.mcpServers, './.mcp.json', `${env} mcpServers path`);
  assertEqual(plugin.interface.displayName, expectedDisplayNames[env], `${env} displayName`);
  assertEqual(plugin.interface.shortDescription, sharedShortDescription, `${env} shortDescription`);

  const servers = Object.keys(mcp.mcpServers ?? {});
  assertEqual(servers.length, 1, `${env} MCP server count`);
  assertEqual(servers[0], serverName, `${env} MCP server name`);
  assertEqual(mcp.mcpServers?.[serverName]?.url, expectedUrls[env], `${env} MCP URL`);

  assertEqual(
    readLink(`${pluginDir}/skills/hostr-${env}/SKILL.md`),
    '../../../shared/hostr/SKILL.md',
    `${env} skill symlink`,
  );
  assertEqual(
    readLink(`${pluginDir}/assets/icon.png`),
    '../../shared/hostr/assets/icon.png',
    `${env} icon symlink`,
  );
  assertEqual(
    readLink(`${pluginDir}/assets/logo.png`),
    '../../shared/hostr/assets/logo.png',
    `${env} logo symlink`,
  );
}

const base = manifests.development;
const invariantKeys = [
  'version',
  'author',
  'homepage',
  'repository',
  'license',
  'keywords',
  'skills',
  'mcpServers',
  'interface.developerName',
  'interface.category',
  'interface.capabilities',
  'interface.websiteURL',
  'interface.defaultPrompt',
  'interface.brandColor',
  'interface.composerIcon',
  'interface.logo',
  'interface.screenshots',
];

function get(object, dottedPath) {
  return dottedPath.split('.').reduce((current, key) => current?.[key], object);
}

for (const env of ['staging', 'production']) {
  for (const key of invariantKeys) {
    assertEqual(JSON.stringify(get(manifests[env], key)), JSON.stringify(get(base, key)), `${env} invariant ${key}`);
  }
  assertEqual(
    normalizeEnvironmentText(manifests[env].description),
    normalizeEnvironmentText(base.description),
    `${env} normalized description`,
  );
  assertEqual(
    normalizeEnvironmentText(manifests[env].interface.longDescription),
    normalizeEnvironmentText(base.interface.longDescription),
    `${env} normalized longDescription`,
  );
}

if (errors.length > 0) {
  console.error('Hostr plugin validation failed:');
  for (const error of errors) {
    console.error(`- ${error}`);
  }
  process.exit(1);
}

console.log('Hostr plugin validation passed');
