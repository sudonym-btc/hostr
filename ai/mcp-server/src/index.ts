import { config } from "./config.js";
import { createHostrDaemonClient } from "./daemon/client.js";
import { createApp } from "./http/app.js";

const daemon = createHostrDaemonClient(config);
const app = createApp(config, daemon);

const server = app.listen(config.port, () => {
  console.log(`Hostr MCP server listening on :${config.port}`);
});

const shutdown = async () => {
  server.close();
  await daemon.close();
};

process.once("SIGINT", () => {
  void shutdown().then(() => process.exit(0));
});
process.once("SIGTERM", () => {
  void shutdown().then(() => process.exit(0));
});
