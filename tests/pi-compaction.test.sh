#!/usr/bin/env bash
# Regression coverage for the independent 272K compaction threshold.
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

EXTENSION="$ROOT/home/.pi/agent/extensions/early-compaction.ts"
MODELS="$ROOT/home/.pi/agent/models.json"
PI_PACKAGE_DIR=${PI_COMPACTION_TEST_PACKAGE_DIR:-"$(npm root -g 2>/dev/null)/@earendil-works/pi-coding-agent"}

[ -f "$EXTENSION" ] || fail "early-compaction extension is missing"

# No provider may buy earlier compaction by shrinking a context window: that number
# also budgets output tokens. The extension above is the only 272K mechanism.
if [ -f "$MODELS" ] &&
	jq -e '[.providers // {} | .[] | .modelOverrides // {} | .[] | .contextWindow] | any' \
		"$MODELS" >/dev/null 2>&1; then
	fail "models.json overrides a model context window"
fi

if [ ! -f "$PI_PACKAGE_DIR/package.json" ]; then
	echo "skip: installed @earendil-works/pi-coding-agent package not found"
	exit 0
fi

EXTENSION="$EXTENSION" PI_PACKAGE_DIR="$PI_PACKAGE_DIR" node --input-type=module <<'JS'
import { pathToFileURL } from "node:url";

const check = (condition, message) => {
  if (!condition) throw new Error(message);
};

const extension = await import(`${pathToFileURL(process.env.EXTENSION).href}?test=${Date.now()}`);
const handlers = new Map();
extension.default({
  on(event, handler) {
    const eventHandlers = handlers.get(event) ?? [];
    eventHandlers.push(handler);
    handlers.set(event, eventHandlers);
  },
});

const fire = async (event, ctx) => {
  for (const handler of handlers.get(event) ?? []) {
    await handler({ type: event }, ctx);
  }
};

let tokens = 271_999;
const compactions = [];
const notifications = [];
const model = {
  provider: "amazon-bedrock",
  id: "global.openai.gpt-5.6-sol",
  contextWindow: 1_050_000,
};
const ctx = {
  model,
  hasUI: true,
  getContextUsage: () => ({
    tokens,
    contextWindow: model.contextWindow,
    percent: tokens === null ? null : tokens / model.contextWindow,
  }),
  compact: (options) => compactions.push(options),
  ui: {
    notify: (message, level) => notifications.push([message, level]),
  },
};

check(!handlers.has("turn_end"), "extension can abort an active tool-driven run");
await fire("agent_settled", ctx);
check(compactions.length === 0, "compaction triggered below 272K");

tokens = extension.EARLY_COMPACTION_TOKENS;
await fire("agent_settled", ctx);
check(compactions.length === 1, "compaction did not trigger at 272K");
check(model.contextWindow === 1_050_000, "extension changed the provider context window");
check(
  extension.shouldCompactEarly({
    ...ctx,
    model: { ...model, id: "openai.gpt-5.6-sol" },
  }),
  "regional Bedrock GPT-5.6 Sol does not use the 272K threshold",
);

await fire("agent_settled", ctx);
check(compactions.length === 1, "duplicate compaction started while one was pending");
compactions[0].onComplete();

tokens = 300_000;
await fire("session_start", ctx);
check(compactions.length === 2, "loaded oversized session was not compacted");
compactions[1].onError(new Error("expected test failure"));
check(
  notifications.some(([message, level]) =>
    level === "error" && message.includes("expected test failure")
  ),
  "compaction failure was not reported",
);

// The threshold follows the window, not the provider, so a large-context model on any
// backend gets the same 272K treatment and a model already inside 272K is left to Pi.
check(
  extension.shouldCompactEarly({
    ...ctx,
    model: { ...model, provider: "openai-codex", id: "gpt-5.6-luna" },
  }),
  "a large-context model outside Bedrock does not use the 272K threshold",
);
check(
  !extension.shouldCompactEarly({
    ...ctx,
    model: { ...model, contextWindow: 272_000 },
  }),
  "extension treated a constrained model as large-context",
);

const piAiDir = `${process.env.PI_PACKAGE_DIR}/node_modules/@earendil-works/pi-ai/dist`;
const { getModels } = await import(pathToFileURL(`${piAiDir}/compat.js`).href);
const { clampMaxTokensToContext } = await import(
  pathToFileURL(`${piAiDir}/api/simple-options.js`).href
);
const catalogModel = getModels("amazon-bedrock").find(
  (candidate) => candidate.id === "global.openai.gpt-5.6-sol",
);
const regionalCatalogModel = getModels("amazon-bedrock").find(
  (candidate) => candidate.id === "openai.gpt-5.6-sol",
);
check(catalogModel?.contextWindow === 1_050_000, "Bedrock GPT-5.6 Sol is not a 1.05M model");
check(
  regionalCatalogModel?.contextWindow === 1_050_000,
  "regional Bedrock GPT-5.6 Sol is not a 1.05M model",
);

// Pi ships 272K for Codex GPT-5.6 itself, so pinning it locally only risks drifting
// into the clamp below the day Pi publishes the backend's larger window.
for (const id of ["gpt-5.6-luna", "gpt-5.6-sol", "gpt-5.6-terra"]) {
  const codexModel = getModels("openai-codex").find((candidate) => candidate.id === id);
  check(
    codexModel?.contextWindow === 272_000,
    `Codex ${id} no longer ships a 272K window, so the extension must cover it`,
  );
}

const failedSessionEstimate = {
  systemPrompt: "",
  messages: [{
    role: "user",
    content: "x".repeat(290_174 * 4),
    timestamp: Date.now(),
  }],
  tools: [],
};
const realBudget = clampMaxTokensToContext(
  catalogModel,
  failedSessionEstimate,
  catalogModel.maxTokens,
);
const fakeBudget = clampMaxTokensToContext(
  { ...catalogModel, contextWindow: 272_000 },
  failedSessionEstimate,
  catalogModel.maxTokens,
);
check(fakeBudget === 1, "regression fixture no longer reproduces the one-token clamp");
check(realBudget === 128_000, `real model window unexpectedly clamps output to ${realBudget}`);
JS

pass "context windows stay truthful and every large-context model compacts at 272K"
