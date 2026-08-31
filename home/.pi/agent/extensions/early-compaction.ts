import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

export const EARLY_COMPACTION_TOKENS = 272_000;

// Pi derives the compaction threshold, the footer denominator, and the per-request
// output budget from one number: model.contextWindow. Lowering it in models.json to
// buy earlier compaction also clamps maxTokens, which collapses to a single output
// token once a session passes the faked window. So the window stays truthful and the
// threshold lives here instead, applied to every model whose window exceeds it.
export function shouldCompactEarly(ctx: ExtensionContext): boolean {
  const contextWindow = ctx.model?.contextWindow;
  const tokens = ctx.getContextUsage()?.tokens;

  return (
    contextWindow !== undefined &&
    contextWindow > EARLY_COMPACTION_TOKENS &&
    tokens !== null &&
    tokens !== undefined &&
    tokens >= EARLY_COMPACTION_TOKENS
  );
}

export default function earlyCompaction(pi: ExtensionAPI): void {
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
