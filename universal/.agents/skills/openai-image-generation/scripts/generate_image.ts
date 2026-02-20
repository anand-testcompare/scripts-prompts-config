#!/usr/bin/env bun
import { spawn } from "bun";
import path from "node:path";
import { fileURLToPath } from "node:url";

const currentFile = fileURLToPath(import.meta.url);
const scriptDir = path.dirname(currentFile);
const shellScript = path.join(scriptDir, "generate_image.sh");

const proc = spawn(["sh", shellScript, ...process.argv.slice(2)], {
  stdin: "inherit",
  stdout: "inherit",
  stderr: "inherit",
});

const exitCode = await proc.exited;
process.exit(exitCode);
