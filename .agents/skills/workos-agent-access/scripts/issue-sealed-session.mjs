#!/usr/bin/env node

import { spawnSync } from "node:child_process";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

function usage() {
	console.error(`Usage:
  node issue-sealed-session.mjs --client-id <id> --email <email> --password <password> --cookie-password <password> [options]

Options:
  --api-key <key>                 Defaults to WORKOS_API_KEY
  --cookie-name <name>            Default: wos-session
  --help
`);
}

function parseArgs(argv) {
	const args = {};
	for (let index = 0; index < argv.length; index += 1) {
		const token = argv[index];
		if (!token.startsWith("--")) {
			throw new Error(`Unexpected argument: ${token}`);
		}

		const key = token.slice(2);
		if (key === "help") {
			args.help = true;
			continue;
		}

		const value = argv[index + 1];
		if (value == null || value.startsWith("--")) {
			throw new Error(`Missing value for --${key}`);
		}

		args[key] = value;
		index += 1;
	}

	return args;
}

async function main() {
	const args = parseArgs(process.argv.slice(2));

	if (args.help) {
		usage();
		process.exit(0);
	}

	const apiKey = args["api-key"] ?? process.env.WORKOS_API_KEY;
	const clientId = args["client-id"] ?? process.env.WORKOS_CLIENT_ID;
	const email = args.email;
	const password = args.password;
	const cookiePassword =
		args["cookie-password"] ?? process.env.WORKOS_COOKIE_PASSWORD;

	if (!apiKey || !clientId || !email || !password || !cookiePassword) {
		usage();
		throw new Error(
			"--client-id, --email, --password, and --cookie-password are required, and WorkOS API key must come from --api-key or WORKOS_API_KEY",
		);
	}

	const runtimePayload = JSON.stringify({
		apiKey,
		clientId,
		email,
		password,
		cookiePassword,
		cookieName: args["cookie-name"] ?? "wos-session",
	});

	const runtimeSource = `
import { WorkOS } from "@workos-inc/node";

const payload = JSON.parse(process.argv[1]);
const workos = new WorkOS(payload.apiKey);
const authResponse = await workos.userManagement.authenticateWithPassword({
  clientId: payload.clientId,
  email: payload.email,
  password: payload.password,
  session: {
    sealSession: true,
    cookiePassword: payload.cookiePassword,
  },
});

if (!authResponse.sealedSession) {
  throw new Error("WorkOS did not return a sealedSession");
}

console.log(
  JSON.stringify(
    {
      cookieName: payload.cookieName,
      sealedSession: authResponse.sealedSession,
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
      authenticationMethod: authResponse.authenticationMethod ?? null,
      organizationId: authResponse.organizationId ?? null,
      user: {
        id: authResponse.user.id,
        email: authResponse.user.email,
        firstName: authResponse.user.firstName,
        lastName: authResponse.user.lastName,
      },
    },
    null,
    2,
  ),
);
`;

	const scriptDir = path.dirname(fileURLToPath(import.meta.url));
	const runtimeDir = path.resolve(
		scriptDir,
		"../../../../.memory/workos-agent-access/runtime",
	);
	await ensureRuntime(runtimeDir);

	const command = process.execPath;
	const result = spawnSync(
		command,
		["--input-type=module", "-e", runtimeSource, runtimePayload],
		{
			encoding: "utf8",
			cwd: runtimeDir,
		},
	);

	if (result.status !== 0) {
		const stderr = result.stderr?.trim();
		throw new Error(stderr || "Failed to issue sealed WorkOS session");
	}

	process.stdout.write(result.stdout);
}

async function ensureRuntime(runtimeDir) {
	await mkdir(runtimeDir, { recursive: true });

	const packageJsonPath = path.join(runtimeDir, "package.json");
	const sdkPackagePath = path.join(
		runtimeDir,
		"node_modules",
		"@workos-inc",
		"node",
		"package.json",
	);

	try {
		await readFile(sdkPackagePath, "utf8");
		return;
	} catch {
		// Install below.
	}

	try {
		await readFile(packageJsonPath, "utf8");
	} catch {
		await writeFile(
			packageJsonPath,
			JSON.stringify(
				{
					name: "workos-agent-access-runtime",
					private: true,
					type: "module",
				},
				null,
				2,
			),
		);
	}

	const npmCommand = process.platform === "win32" ? "npm.cmd" : "npm";
	const installResult = spawnSync(
		npmCommand,
		["install", "--no-save", "@workos-inc/node@8.0.0"],
		{
			encoding: "utf8",
			cwd: runtimeDir,
		},
	);

	if (installResult.status !== 0) {
		const stderr = installResult.stderr?.trim();
		throw new Error(
			stderr ||
				"Failed to bootstrap @workos-inc/node for sealed-session helper",
		);
	}
}

main().catch((error) => {
	console.error(error instanceof Error ? error.message : String(error));
	process.exit(1);
});
