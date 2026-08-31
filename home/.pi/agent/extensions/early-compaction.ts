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

// A compaction that loses a race with another compaction is transient, not a real
// failure. Pi runs manual and automatic compaction through two separate abort
// controllers and nulls one in a `finally` the instant that path ends; a second
// compaction still reading `<controller>.signal` across an await then throws
// "Cannot read properties of undefined (reading 'signal')". A deliberate cancel and
// a "prompt while compaction is in progress" rejection are the same class of benign
// interleaving. None mean the 272K threshold failed - the next agent_settled retries
// cleanly - so they must not be surfaced to the captain as an error.
export function isTransientCompactionRace(error: Error): boolean {
  const message = error.message ?? "";
  return (
    error.name === "AbortError" ||
    /reading 'signal'/.test(message) ||
    /compaction cancelled/i.test(message) ||
    /compaction is in progress/i.test(message)
  );
}

export default function earlyCompaction(pi: ExtensionAPI): void {
  // True whenever ANY compaction is running: one this extension started, a user
  // `/compact`, or Pi's own automatic threshold compaction. Triggering a second
  // compaction while one is in flight is exactly what nulls an abort controller mid
  // read and produces the signal race above, so the guard must reflect every path.
  // Our own onComplete/onError only observe the compaction we start; the lifecycle
  // events below are the only way to see Pi's automatic path and hold the guard for it.
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
        if (isTransientCompactionRace(error)) return;
        if (ctx.hasUI) {
          ctx.ui.notify(`272K compaction failed: ${error.message}`, "error");
        }
      },
    });
  };

  // Pi emits all three for both the manual and the automatic compaction path, so they
  // keep the guard truthful even when Pi, not this extension, started the compaction.
  // These observe only; returning nothing neither cancels nor overrides the summary.
  pi.on("session_before_compact", () => {
    compactionInProgress = true;
  });
  pi.on("session_compact", () => {
    compactionInProgress = false;
  });
  pi.on("session_compact_failed", () => {
    compactionInProgress = false;
  });

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
