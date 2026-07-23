import assert from "node:assert/strict";
import test from "node:test";
import {
  adjacentThinkingLevel,
  supportedThinkingLevels,
} from "../agent/extensions/thinking-level-shortcuts.ts";

test("uses the full standard scale when no model is selected", () => {
  assert.deepEqual(supportedThinkingLevels(undefined), [
    "off",
    "minimal",
    "low",
    "medium",
    "high",
    "xhigh",
    "max",
  ]);
});

test("keeps non-reasoning models off", () => {
  assert.deepEqual(
    supportedThinkingLevels({ reasoning: false, thinkingLevelMap: undefined }),
    ["off"],
  );
});

test("honors model-specific effort support", () => {
  assert.deepEqual(
    supportedThinkingLevels({
      reasoning: true,
      thinkingLevelMap: { minimal: null, xhigh: "xhigh", max: null },
    }),
    ["off", "low", "medium", "high", "xhigh"],
  );
});

test("moves up and down without wrapping", () => {
  const levels = ["off", "low", "high"] as const;
  assert.equal(adjacentThinkingLevel(levels, "low", 1), "high");
  assert.equal(adjacentThinkingLevel(levels, "low", -1), "off");
  assert.equal(adjacentThinkingLevel(levels, "high", 1), "high");
  assert.equal(adjacentThinkingLevel(levels, "off", -1), "off");
});
