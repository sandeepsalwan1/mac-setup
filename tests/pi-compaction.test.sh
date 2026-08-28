#!/usr/bin/env bash
# Regression coverage for the independent 272K Bedrock compaction threshold.
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

EXTENSION="$ROOT/home/.pi/agent/extensions/bedrock-early-compaction.ts"
MODELS="$ROOT/home/.pi/agent/models.json"
PI_PACKAGE_DIR=${PI_COMPACTION_TEST_PACKAGE_DIR:-"$(npm root -g 2>/dev/null)/@earendil-works/pi-coding-agent"}

[ -f "$EXTENSION" ] || fail "Bedrock early-compaction extension is missing"

if jq -e '.providers["amazon-bedrock"].modelOverrides["global.openai.gpt-5.6-sol"].contextWindow' \
	"$MODELS" >/dev/null 2>&1; then
	fail "Bedrock GPT-5.6 Sol context window is still overridden"
fi
if jq -e '.providers["amazon-bedrock"].modelOverrides["openai.gpt-5.6-sol"].contextWindow' \
	"$MODELS" >/dev/null 2>&1; then
	fail "regional Bedrock GPT-5.6 Sol context window is still overridden"
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

ctx.model = { ...model, provider: "openai-codex" };
await fire("agent_settled", ctx);
check(compactions.length === 2, "extension compacted a non-Bedrock model");

ctx.model = { ...model, contextWindow: 272_000 };
await fire("agent_settled", ctx);
check(compactions.length === 2, "extension treated a constrained model as large-context");

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

pass "Bedrock keeps its 1.05M request window and compacts independently at 272K"
