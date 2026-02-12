#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";

const USAGE = `Usage:
  node scripts/validate_mermaid_in_md.mjs <markdown-file> [--keep-tmp]

Description:
  Extracts all \`\`\`mermaid blocks from a Markdown file and attempts to render them
  via Mermaid CLI. This catches syntax errors before you paste into GitHub.

Requirements:
  - Node.js
  - Either \`npx\` or \`bunx\` available on PATH (script prefers \`npx\`)

Examples:
  node scripts/validate_mermaid_in_md.mjs /tmp/issue.md
  node scripts/validate_mermaid_in_md.mjs /tmp/issue.md --keep-tmp
`;

const main = async () => {
  const { file, keepTmp } = parseArgs(process.argv.slice(2));
  if (!file) {
    process.stderr.write(USAGE);
    process.exit(2);
  }

  const markdown = await fs.readFile(file, "utf8");
  const blocks = extractMermaidBlocks(markdown);

  if (blocks.length === 0) {
    process.stdout.write("No Mermaid blocks found.\n");
    return;
  }

  const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "issue-grooming-mermaid-"));
  const renderedDir = path.join(tmpDir, "rendered");
  await fs.mkdir(renderedDir, { recursive: true });

  const runner = findRunner();
  if (!runner) {
    process.stderr.write("Neither `npx` nor `bunx` found on PATH.\n");
    process.stderr.write("Install Node tooling (npm) or Bun, then validate with:\n");
    process.stderr.write("  npx -y @mermaid-js/mermaid-cli -i diagram.mmd -o diagram.svg\n");
    process.stderr.write(`Extracted Mermaid blocks were written to: ${tmpDir}\n`);
    process.exit(1);
  }

  let hadError = false;
  for (let index = 0; index < blocks.length; index += 1) {
    const source = blocks[index];
    const inputPath = path.join(tmpDir, `diagram-${index + 1}.mmd`);
    const outputPath = path.join(renderedDir, `diagram-${index + 1}.svg`);
    await fs.writeFile(inputPath, source, "utf8");

    const result = runMermaidCli(runner, inputPath, outputPath);
    if (result.status !== 0) {
      hadError = true;
      process.stderr.write(`Mermaid render failed for block ${index + 1}.\n`);
      if (result.stderr) process.stderr.write(result.stderr);
      if (result.stdout) process.stderr.write(result.stdout);
      process.stderr.write("\n");
    }
  }

  if (keepTmp) {
    process.stderr.write(`Kept validation artifacts at: ${tmpDir}\n`);
  } else if (!hadError) {
    await fs.rm(tmpDir, { recursive: true, force: true });
  } else {
    process.stderr.write(`Validation artifacts kept at: ${tmpDir}\n`);
  }

  if (hadError) process.exit(1);
  process.stdout.write(`Validated ${blocks.length} Mermaid block(s).\n`);
};

const extractMermaidBlocks = (markdown) => {
  /** @type {string[]} */
  const blocks = [];

  // Capture fenced blocks: ```mermaid\n...\n```
  const pattern = /```mermaid[^\n]*\n([\s\S]*?)\n```/g;
  let match = null;
  while ((match = pattern.exec(markdown)) !== null) {
    blocks.push(match[1].trimEnd());
  }

  // Handle EOF without trailing newline before closing fence (rare, but happens)
  const eofPattern = /```mermaid[^\n]*\n([\s\S]*?)```/g;
  while ((match = eofPattern.exec(markdown)) !== null) {
    const candidate = match[1].trimEnd();
    if (candidate.length > 0 && !blocks.includes(candidate)) blocks.push(candidate);
  }

  return blocks;
};

const findRunner = () => {
  // Prefer npx: it is the most common way to run mermaid-cli without preinstall.
  const npx = spawnSync("npx", ["--version"], { encoding: "utf8" });
  if (npx.status === 0) return { cmd: "npx", argsPrefix: ["-y", "@mermaid-js/mermaid-cli"] };

  const bunx = spawnSync("bunx", ["--version"], { encoding: "utf8" });
  if (bunx.status === 0) return { cmd: "bunx", argsPrefix: ["@mermaid-js/mermaid-cli"] };

  return null;
};

const runMermaidCli = (runner, inputPath, outputPath) => {
  const args = [
    ...runner.argsPrefix,
    "-i",
    inputPath,
    "-o",
    outputPath,
  ];

  return spawnSync(runner.cmd, args, {
    encoding: "utf8",
    stdio: "pipe",
    env: {
      ...process.env,
      // Some environments set PUPPETEER_* vars; keep them as-is.
    },
  });
};

const parseArgs = (argv) => {
  /** @type {{file: string | null, keepTmp: boolean}} */
  const opts = { file: null, keepTmp: false };

  for (const token of argv) {
    if (token === "--keep-tmp") {
      opts.keepTmp = true;
      continue;
    }
    if (token === "--help" || token === "-h") {
      process.stdout.write(USAGE);
      process.exit(0);
    }
    if (opts.file) {
      process.stderr.write(`Unexpected extra argument: ${token}\n\n`);
      process.stderr.write(USAGE);
      process.exit(2);
    }
    opts.file = token;
  }

  return opts;
};

await main();

