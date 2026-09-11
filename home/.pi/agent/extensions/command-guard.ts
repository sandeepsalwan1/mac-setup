import { spawnSync } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event) => {
    if (event.toolName !== "bash" || typeof event.input.command !== "string") return undefined;
    try {
      const result = spawnSync(join(homedir(), ".agents/hooks/deny-dangerous.sh"), {
        input: JSON.stringify({ tool_input: { command: event.input.command } }),
        encoding: "utf8",
        timeout: 3000,
      });
      if (result.status === 2) {
        return {
          block: true,
          reason: result.stderr.trim() || "Command guard blocked a catastrophic command.",
        };
      }
    } catch {}
    return undefined;
  });
}
