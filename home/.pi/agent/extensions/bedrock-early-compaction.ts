import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

export const EARLY_COMPACTION_TOKENS = 272_000;

const BEDROCK_LARGE_CONTEXT_MODELS = new Set([
  "global.openai.gpt-5.6-luna",
  "global.openai.gpt-5.6-sol",
  "global.openai.gpt-5.6-terra",
  "openai.gpt-5.6-luna",
  "openai.gpt-5.6-sol",
  "openai.gpt-5.6-terra",
]);

export function shouldCompactEarly(ctx: ExtensionContext): boolean {
  const model = ctx.model;
  const tokens = ctx.getContextUsage()?.tokens;

  return (
    model?.provider === "amazon-bedrock" &&
    BEDROCK_LARGE_CONTEXT_MODELS.has(model.id) &&
    model.contextWindow > EARLY_COMPACTION_TOKENS &&
    tokens !== null &&
    tokens !== undefined &&
    tokens >= EARLY_COMPACTION_TOKENS
  );
}

export default function bedrockEarlyCompaction(pi: ExtensionAPI): void {
  let compactionInProgress = false;

  const compactIfNeeded = (ctx: ExtensionContext): void => {
    if (compactionInProgress || !shouldCompactEarly(ctx)) return;

    compactionInProgress = true;
    ctx.compact({
      onComplete: () => {
        compactionInProgress = false;
      },
      onError: (error) => {
        compactionInProgress = false;
        if (ctx.hasUI) {
          ctx.ui.notify(`272K compaction failed: ${error.message}`, "error");
        }
      },
    });
  };

  // Waiting for agent_settled avoids aborting a tool-driven run. session_start
  // also covers an oversized session loaded from disk before another prompt.
  pi.on("agent_settled", (_event, ctx) => {
    compactIfNeeded(ctx);
  });
  pi.on("session_start", (_event, ctx) => {
    compactIfNeeded(ctx);
  });
  pi.on("model_select", (_event, ctx) => {
    compactIfNeeded(ctx);
  });
  pi.on("session_shutdown", () => {
    compactionInProgress = false;
  });
}
