import type { ExtensionAPI, SlashCommandInfo } from "@earendil-works/pi-coding-agent";
import type {
  AutocompleteItem,
  AutocompleteProvider,
  AutocompleteSuggestions,
} from "@earendil-works/pi-tui";

const SKILL_COMMAND_PREFIX = "skill:";
const SKILL_TAG_AT_CURSOR = /(?:^|[ \t])\$([a-z0-9-]*)$/;
const SKILL_TAG = /(^|\s)\$([a-z0-9][a-z0-9-]*)(?=\s|$)/g;
const MAX_SUGGESTIONS = 20;

type SkillCommand = SlashCommandInfo & { source: "skill" };

function getSkillCommands(pi: ExtensionAPI): SkillCommand[] {
  return pi
    .getCommands()
    .filter((command): command is SkillCommand => command.source === "skill")
    .sort((a, b) => a.name.localeCompare(b.name));
}

function skillName(command: SkillCommand): string {
  return command.name.startsWith(SKILL_COMMAND_PREFIX)
    ? command.name.slice(SKILL_COMMAND_PREFIX.length)
    : command.name;
}

export function extractSkillTagAtCursor(textBeforeCursor: string): string | undefined {
  return textBeforeCursor.match(SKILL_TAG_AT_CURSOR)?.[1];
}

export function transformDollarSkillTag(text: string, availableSkills: ReadonlySet<string>): string | undefined {
  if (text.startsWith("/skill:")) return undefined;

  SKILL_TAG.lastIndex = 0;
  for (const match of text.matchAll(SKILL_TAG)) {
    const name = match[2];
    if (!name || !availableSkills.has(name)) continue;

    const start = match.index + match[1].length;
    const beforeTag = text.slice(0, start);
    let afterTag = text.slice(start + name.length + 1);
    if (/[ \t]$/.test(beforeTag) && /^[ \t]/.test(afterTag)) {
      afterTag = afterTag.slice(1);
    }
    const remaining = `${beforeTag}${afterTag}`.trim();
    return remaining ? `/skill:${name} ${remaining}` : `/skill:${name}`;
  }

  return undefined;
}

function filterSkills(commands: SkillCommand[], query: string): AutocompleteItem[] {
  const normalized = query.toLowerCase();
  return commands
    .map((command) => ({ command, name: skillName(command) }))
    .filter(({ command, name }) => {
      if (!normalized) return true;
      return name.includes(normalized) || command.description?.toLowerCase().includes(normalized);
    })
    .sort((a, b) => {
      const aStarts = a.name.startsWith(normalized) ? 0 : 1;
      const bStarts = b.name.startsWith(normalized) ? 0 : 1;
      return aStarts - bStarts || a.name.localeCompare(b.name);
    })
    .slice(0, MAX_SUGGESTIONS)
    .map(({ command, name }) => ({
      value: `$${name}`,
      label: `$${name}`,
      description: command.description,
    }));
}

function createSkillTagAutocompleteProvider(
  pi: ExtensionAPI,
  current: AutocompleteProvider,
): AutocompleteProvider {
  return {
    triggerCharacters: ["$"],

    async getSuggestions(lines, cursorLine, cursorCol, options): Promise<AutocompleteSuggestions | null> {
      const textBeforeCursor = (lines[cursorLine] ?? "").slice(0, cursorCol);
      const query = extractSkillTagAtCursor(textBeforeCursor);
      if (query === undefined) {
        return current.getSuggestions(lines, cursorLine, cursorCol, options);
      }

      const items = filterSkills(getSkillCommands(pi), query);
      if (options.signal.aborted || items.length === 0) {
        return current.getSuggestions(lines, cursorLine, cursorCol, options);
      }

      return { prefix: `$${query}`, items };
    },

    applyCompletion(lines, cursorLine, cursorCol, item, prefix) {
      if (!prefix.startsWith("$")) {
        return current.applyCompletion(lines, cursorLine, cursorCol, item, prefix);
      }

      const currentLine = lines[cursorLine] ?? "";
      const beforePrefix = currentLine.slice(0, cursorCol - prefix.length);
      const afterCursor = currentLine.slice(cursorCol);
      const suffix = afterCursor.startsWith(" ") ? "" : " ";
      const newLines = [...lines];
      newLines[cursorLine] = `${beforePrefix}${item.value}${suffix}${afterCursor}`;
      return {
        lines: newLines,
        cursorLine,
        cursorCol: beforePrefix.length + item.value.length + suffix.length,
      };
    },

    shouldTriggerFileCompletion(lines, cursorLine, cursorCol) {
      return current.shouldTriggerFileCompletion?.(lines, cursorLine, cursorCol) ?? true;
    },
  };
}

export default function (pi: ExtensionAPI): void {
  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode === "tui") {
      ctx.ui.addAutocompleteProvider((current) => createSkillTagAutocompleteProvider(pi, current));
    }
  });

  pi.on("input", (event) => {
    if (event.source === "extension") return { action: "continue" };

    const availableSkills = new Set(getSkillCommands(pi).map(skillName));
    const transformed = transformDollarSkillTag(event.text, availableSkills);
    if (!transformed) return { action: "continue" };

    // Reuse Pi's native skill-command expansion so the tagged skill is loaded
    // exactly like /skill:name, including its normal skill invocation rendering.
    return { action: "transform", text: transformed };
  });
}
