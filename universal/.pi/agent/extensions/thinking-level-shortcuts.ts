import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import type { ModelThinkingLevel } from "@earendil-works/pi-ai";

const THINKING_LEVELS: readonly ModelThinkingLevel[] = [
  "off",
  "minimal",
  "low",
  "medium",
  "high",
  "xhigh",
  "max",
];

type ModelCapabilities = Pick<
  NonNullable<ExtensionContext["model"]>,
  "reasoning" | "thinkingLevelMap"
>;

export function supportedThinkingLevels(
  model: ModelCapabilities | undefined,
): readonly ModelThinkingLevel[] {
  if (!model) return THINKING_LEVELS;
  if (!model.reasoning) return ["off"];

  return THINKING_LEVELS.filter((level) => {
    const mapped = model.thinkingLevelMap?.[level];
    if (mapped === null) return false;
    if (level === "xhigh" || level === "max") return mapped !== undefined;
    return true;
  });
}

export function adjacentThinkingLevel(
  levels: readonly ModelThinkingLevel[],
  current: ModelThinkingLevel,
  direction: -1 | 1,
): ModelThinkingLevel {
  const currentIndex = levels.indexOf(current);
  const startIndex = currentIndex >= 0 ? currentIndex : 0;
  const nextIndex = Math.max(0, Math.min(levels.length - 1, startIndex + direction));
  return levels[nextIndex] ?? "off";
}

export default function (pi: ExtensionAPI) {
  const changeThinkingLevel = (direction: -1 | 1, ctx: ExtensionContext) => {
    const current = pi.getThinkingLevel();
    const levels = supportedThinkingLevels(ctx.model);
    const next = adjacentThinkingLevel(levels, current, direction);

    pi.setThinkingLevel(next);
    const applied = pi.getThinkingLevel();
    ctx.ui.notify(`Reasoning effort: ${applied}`, "info");
  };

  pi.registerShortcut("alt+.", {
    description: "Increase reasoning effort",
    handler: (ctx) => changeThinkingLevel(1, ctx),
  });

  pi.registerShortcut("alt+,", {
    description: "Decrease reasoning effort",
    handler: (ctx) => changeThinkingLevel(-1, ctx),
  });
}
