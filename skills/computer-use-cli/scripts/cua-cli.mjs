#!/usr/bin/env node

import { spawn } from "node:child_process";
import { once } from "node:events";
import { promises as fs } from "node:fs";
import os from "node:os";
import path from "node:path";
import { createInterface } from "node:readline";

const defaultClient = path.join(
  os.homedir(),
  ".codex/computer-use/Codex Computer Use.app/Contents/SharedSupport/" +
    "SkyComputerUseClient.app/Contents/MacOS/SkyComputerUseClient",
);
const client = process.env.CUA_CLIENT || defaultClient;
const timeoutMs = Number.parseInt(process.env.CUA_TIMEOUT_MS || "30000", 10);

const usage = `Usage: cua-cli <command> [options]

Context-efficient CLI for the local Codex Computer Use service.

Commands:
  list-apps
  state       --app APP
  click       --app APP [--element ID | --x N --y N]
  secondary   --app APP --element ID --action ACTION
  set-value   --app APP --element ID --value VALUE
  select-text --app APP --element ID --text TEXT [--prefix TEXT] [--suffix TEXT]
              [--selection text|cursor_before|cursor_after]
  scroll      --app APP --element ID --direction up|down|left|right [--pages N]
  drag        --app APP --from-x N --from-y N --to-x N --to-y N
  key         --app APP --key KEY
  type        --app APP --text TEXT
  tools       [--schemas]
  call        TOOL [JSON|-]

Global options:
  --approve   Accept a per-app Computer Use permission prompt for this call.
  --json      Print the raw MCP result as JSON.
  -h, --help  Show this help.

Environment:
  CUA_CLIENT      Override the Computer Use client binary.
  CUA_TIMEOUT_MS  Request timeout in milliseconds (default: 30000).
`;

function fail(message, code = 2) {
  process.stderr.write(`cua-cli: ${message}\n`);
  process.exit(code);
}

function parseFlags(argv) {
  const flags = {};
  const positional = [];
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith("--")) {
      positional.push(token);
      continue;
    }
    const equals = token.indexOf("=");
    if (equals !== -1) {
      flags[token.slice(2, equals)] = token.slice(equals + 1);
      continue;
    }
    const key = token.slice(2);
    if (["approve", "json", "schemas"].includes(key)) {
      flags[key] = true;
      continue;
    }
    const value = argv[index + 1];
    if (value === undefined || value.startsWith("--")) fail(`--${key} requires a value`);
    flags[key] = value;
    index += 1;
  }
  return { flags, positional };
}

function requireFlag(flags, name) {
  if (flags[name] === undefined || flags[name] === "") fail(`--${name} is required`);
  return flags[name];
}

function numberFlag(flags, name, required = false) {
  if (flags[name] === undefined) {
    if (required) fail(`--${name} is required`);
    return undefined;
  }
  const value = Number(flags[name]);
  if (!Number.isFinite(value)) fail(`--${name} must be a number`);
  return value;
}

async function readStdin() {
  let value = "";
  process.stdin.setEncoding("utf8");
  process.stdin.on("data", (chunk) => {
    value += chunk;
  });
  await once(process.stdin, "end");
  return value;
}

function buildCall(command, flags, positional) {
  const app = () => requireFlag(flags, "app");
  const element = () => String(requireFlag(flags, "element"));
  switch (command) {
    case "list-apps":
      return { name: "list_apps", arguments: {} };
    case "state":
      return { name: "get_app_state", arguments: { app: app() } };
    case "click": {
      const args = { app: app() };
      if (flags.element !== undefined) args.element_index = String(flags.element);
      if (flags.x !== undefined) args.x = numberFlag(flags, "x");
      if (flags.y !== undefined) args.y = numberFlag(flags, "y");
      if (flags["mouse-button"] !== undefined) args.mouse_button = flags["mouse-button"];
      if (flags.count !== undefined) args.click_count = numberFlag(flags, "count");
      if (args.element_index === undefined && (args.x === undefined || args.y === undefined)) {
        fail("click requires --element ID or both --x N and --y N");
      }
      return { name: "click", arguments: args };
    }
    case "secondary":
      return {
        name: "perform_secondary_action",
        arguments: { app: app(), element_index: element(), action: requireFlag(flags, "action") },
      };
    case "set-value":
      return {
        name: "set_value",
        arguments: { app: app(), element_index: element(), value: requireFlag(flags, "value") },
      };
    case "select-text": {
      const args = { app: app(), element_index: element(), text: requireFlag(flags, "text") };
      for (const name of ["prefix", "suffix", "selection"]) {
        if (flags[name] !== undefined) args[name] = flags[name];
      }
      return { name: "select_text", arguments: args };
    }
    case "scroll": {
      const args = {
        app: app(),
        element_index: element(),
        direction: requireFlag(flags, "direction"),
      };
      if (flags.pages !== undefined) args.pages = numberFlag(flags, "pages");
      return { name: "scroll", arguments: args };
    }
    case "drag":
      return {
        name: "drag",
        arguments: {
          app: app(),
          from_x: numberFlag(flags, "from-x", true),
          from_y: numberFlag(flags, "from-y", true),
          to_x: numberFlag(flags, "to-x", true),
          to_y: numberFlag(flags, "to-y", true),
        },
      };
    case "key":
      return { name: "press_key", arguments: { app: app(), key: requireFlag(flags, "key") } };
    case "type":
      return { name: "type_text", arguments: { app: app(), text: requireFlag(flags, "text") } };
    case "call":
      if (!positional[0]) fail("call requires a tool name");
      return { name: positional[0], deferredJson: positional[1] ?? "{}" };
    default:
      fail(`unknown command: ${command}`);
  }
}

async function connect(approveElicitation = false) {
  try {
    await fs.access(client);
  } catch {
    fail(
      `Computer Use client not found at ${client}. ` +
        "Reinstall the Computer Use plugin once to restore the local runtime.",
    );
  }

  const child = spawn(client, ["mcp"], { stdio: ["pipe", "pipe", "inherit"] });
  const lines = createInterface({ input: child.stdout });
  const pending = new Map();
  let requestId = 0;

  function send(message) {
    child.stdin.write(`${JSON.stringify(message)}\n`);
  }

  lines.on("line", (line) => {
    let message;
    try {
      message = JSON.parse(line);
    } catch {
      return;
    }
    if (message.id === undefined) return;
    if (message.method === "elicitation/create") {
      const result = approveElicitation
        ? { action: "accept", content: {} }
        : { action: "decline" };
      send({ jsonrpc: "2.0", id: message.id, result });
      return;
    }
    if (message.method) {
      send({
        jsonrpc: "2.0",
        id: message.id,
        error: { code: -32601, message: `Unsupported server request: ${message.method}` },
      });
      return;
    }
    const waiter = pending.get(message.id);
    if (!waiter) return;
    pending.delete(message.id);
    if (message.error) waiter.reject(new Error(message.error.message || JSON.stringify(message.error)));
    else waiter.resolve(message.result);
  });

  child.on("exit", (code, signal) => {
    const error = new Error(`Computer Use client exited (${signal || code})`);
    for (const waiter of pending.values()) waiter.reject(error);
    pending.clear();
  });

  function request(method, params = {}) {
    const id = ++requestId;
    return new Promise((resolve, reject) => {
      pending.set(id, { resolve, reject });
      send({ jsonrpc: "2.0", id, method, params });
    });
  }

  await request("initialize", {
    protocolVersion: "2025-06-18",
    capabilities: {},
    clientInfo: { name: "cua-cli", version: "1.0.0" },
  });
  send({ jsonrpc: "2.0", method: "notifications/initialized", params: {} });
  return { child, request };
}

function extensionFor(mimeType) {
  if (mimeType === "image/jpeg") return "jpg";
  if (mimeType === "image/webp") return "webp";
  return "png";
}

async function printResult(result, rawJson) {
  if (rawJson) {
    process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
    return;
  }
  const blocks = Array.isArray(result?.content) ? result.content : [];
  let wroteText = false;
  for (let index = 0; index < blocks.length; index += 1) {
    const block = blocks[index];
    if (block.type === "text") {
      process.stdout.write(`${block.text}${block.text.endsWith("\n") ? "" : "\n"}`);
      wroteText = true;
    } else if (block.type === "image" && block.data) {
      const file = path.join(
        os.tmpdir(),
        `cua-${Date.now()}-${process.pid}-${index}.${extensionFor(block.mimeType)}`,
      );
      await fs.writeFile(file, Buffer.from(block.data, "base64"));
      process.stdout.write(`IMAGE: ${file}\n`);
    } else {
      process.stdout.write(`${JSON.stringify(block)}\n`);
    }
  }
  if (!blocks.length && result !== undefined) process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
  if (result?.structuredContent && !wroteText) {
    process.stdout.write(`${JSON.stringify(result.structuredContent, null, 2)}\n`);
  }
  if (result?.isError) process.exitCode = 1;
}

async function main() {
  const argv = process.argv.slice(2);
  if (!argv.length || argv[0] === "-h" || argv[0] === "--help") {
    process.stdout.write(usage);
    return;
  }

  const command = argv.shift();
  const { flags, positional } = parseFlags(argv);
  const session = await connect(Boolean(flags.approve));
  const timer = setTimeout(() => {
    session.child.kill("SIGTERM");
    fail(`request timed out after ${timeoutMs}ms`, 124);
  }, timeoutMs);

  try {
    if (command === "tools") {
      const result = await session.request("tools/list", {});
      if (flags.schemas) process.stdout.write(`${JSON.stringify(result.tools || [], null, 2)}\n`);
      else {
        for (const tool of result.tools || []) {
          process.stdout.write(`${tool.name}\t${tool.description || ""}\n`);
        }
      }
      return;
    }

    const call = buildCall(command, flags, positional);
    if (call.deferredJson !== undefined) {
      const source = call.deferredJson === "-" ? await readStdin() : call.deferredJson;
      try {
        call.arguments = JSON.parse(source || "{}");
      } catch (error) {
        fail(`invalid JSON arguments: ${error.message}`);
      }
    }
    const result = await session.request("tools/call", {
      name: call.name,
      arguments: call.arguments || {},
    });
    await printResult(result, Boolean(flags.json));
  } finally {
    clearTimeout(timer);
    session.child.kill("SIGTERM");
  }
}

main().catch((error) => fail(error.message || String(error), 1));
