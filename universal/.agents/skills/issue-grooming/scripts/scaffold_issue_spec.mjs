#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const USAGE = `Usage:
  node scripts/scaffold_issue_spec.mjs --issue <number|url> [--kind feature|bug|chore] [--repo OWNER/REPO] [--out file] [--stdout]

Examples:
  node scripts/scaffold_issue_spec.mjs --issue 123 --stdout > /tmp/issue.md
  node scripts/scaffold_issue_spec.mjs --issue 123 --kind bug --stdout > /tmp/issue.md
  node scripts/scaffold_issue_spec.mjs --issue https://github.com/org/repo/issues/123 --stdout
  node scripts/scaffold_issue_spec.mjs --issue 123 --repo lonestar-outdoor/inquiry-db --out ./issue-123.md
`;

const main = async () => {
  const opts = parseArgs(process.argv.slice(2));
  if (opts.help) {
    process.stdout.write(USAGE);
    process.exit(0);
  }

  if (!opts.issue) {
    process.stderr.write("Missing required flag: --issue\n\n");
    process.stderr.write(USAGE);
    process.exit(2);
  }

  const kind = normalizeKind(opts.kind);
  if (!kind) {
    process.stderr.write(`Invalid --kind value: ${opts.kind}\n\n`);
    process.stderr.write(USAGE);
    process.exit(2);
  }

  const templateRelPath = kind === "bug" ? "assets/issue-body-template-bug.md" : "assets/issue-body-template.md";
  const templatePath = resolveFromHere(`../${templateRelPath}`);
  const template = await fs.readFile(templatePath, "utf8");

  const issueMeta = readIssueMetaViaGh(opts.issue, opts.repo);
  const now = new Date();
  const date = now.toISOString().slice(0, 10);

  const rendered = applyReplacements(template, {
    DATE: date,
    ISSUE_URL: issueMeta?.url ?? "[issue url]",
    TITLE: issueMeta?.title ?? "[issue title]",
  });

  if (opts.stdout || !opts.out) {
    process.stdout.write(rendered);
    return;
  }

  await fs.mkdir(path.dirname(opts.out), { recursive: true });
  await fs.writeFile(opts.out, rendered, "utf8");
  process.stderr.write(`Wrote ${opts.out}\n`);
};

const normalizeKind = (raw) => {
  if (!raw) return "feature";
  const value = String(raw).trim().toLowerCase();
  if (value === "feature" || value === "bug" || value === "chore") return value;
  return null;
};

const applyReplacements = (input, replacements) => {
  let out = input;
  for (const [key, value] of Object.entries(replacements)) {
    out = out.replaceAll(`{{${key}}}`, value);
  }
  return out;
};

const readIssueMetaViaGh = (issue, repo) => {
  const gh = spawnSync("gh", ["--version"], { encoding: "utf8" });
  if (gh.status !== 0) return null;

  const args = ["issue", "view", issue, "--json", "title,url"];
  if (repo) args.push("--repo", repo);

  const result = spawnSync("gh", args, { encoding: "utf8" });
  if (result.status !== 0) return null;

  try {
    const parsed = JSON.parse(result.stdout);
    const title = typeof parsed.title === "string" ? parsed.title : null;
    const url = typeof parsed.url === "string" ? parsed.url : null;
    if (!title || !url) return null;
    return { title, url };
  } catch {
    return null;
  }
};

const parseArgs = (argv) => {
  /** @type {{issue: string | null, kind: string | null, out: string | null, stdout: boolean, repo: string | null, help: boolean}} */
  const opts = {
    issue: null,
    kind: null,
    out: null,
    stdout: false,
    repo: null,
    help: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];

    if (token === "--help" || token === "-h") {
      opts.help = true;
      continue;
    }

    if (token === "--stdout") {
      opts.stdout = true;
      continue;
    }

    if (token === "--issue") {
      opts.issue = argv[index + 1] ?? null;
      index += 1;
      continue;
    }

    if (token === "--kind") {
      opts.kind = argv[index + 1] ?? null;
      index += 1;
      continue;
    }

    if (token === "--repo") {
      opts.repo = argv[index + 1] ?? null;
      index += 1;
      continue;
    }

    if (token === "--out") {
      opts.out = argv[index + 1] ?? null;
      index += 1;
      continue;
    }

    process.stderr.write(`Unknown argument: ${token}\n\n`);
    process.stderr.write(USAGE);
    process.exit(2);
  }

  return opts;
};

const resolveFromHere = (relativePath) => {
  const here = path.dirname(fileURLToPath(import.meta.url));
  return path.resolve(here, relativePath);
};

await main();

