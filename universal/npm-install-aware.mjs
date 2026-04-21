#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import process from "node:process";

const argv = process.argv.slice(2);
const commandName = argv[0] ?? "";
const ANALYZE_COMMANDS = new Set(["install", "i", "add"]);
const DAY_MS = 24 * 60 * 60 * 1000;
const colors = process.stdout.isTTY
	? {
		reset: "\u001b[0m",
		dim: "\u001b[2m",
		bold: "\u001b[1m",
		cyan: "\u001b[36m",
		green: "\u001b[32m",
		yellow: "\u001b[33m",
		red: "\u001b[31m",
	}
	: {
		reset: "",
		dim: "",
		bold: "",
		cyan: "",
		green: "",
		yellow: "",
		red: "",
	};

function runNpm(args) {
	const result = spawnSync("npm", args, {
		stdio: "inherit",
		env: { ...process.env, NPM_INSTALL_REPORT_BYPASS: "1" },
	});

	if (result.error) {
		console.error(`npm wrapper failed to launch npm: ${result.error.message}`);
		return 1;
	}

	if (typeof result.status === "number") {
		return result.status;
	}

	return 1;
}

function runNpmJson(args) {
	const result = spawnSync("npm", args, {
		encoding: "utf8",
		env: { ...process.env, NPM_INSTALL_REPORT_BYPASS: "1" },
	});

	return {
		status: typeof result.status === "number" ? result.status : 1,
		stdout: result.stdout ?? "",
		stderr: result.stderr ?? "",
		error: result.error,
	};
}

function parseInstallArgs(args) {
	const global = args.some((arg) => arg === "-g" || arg === "--global" || arg === "--location=global");
	const rest = args.slice(1);
	const specs = [];
	let expectValueFor = false;

	const flagsWithValue = new Set([
		"--access",
		"--auth-type",
		"--before",
		"--cache",
		"--cafile",
		"--call",
		"--cidr",
		"--fetch-retries",
		"--fetch-retry-factor",
		"--fetch-retry-maxtimeout",
		"--fetch-retry-mintimeout",
		"--https-proxy",
		"--include",
		"--install-links",
		"--install-strategy",
		"--location",
		"--min-release-age",
		"--noproxy",
		"--omit",
		"--otp",
		"--prefer-dedupe",
		"--prefix",
		"--proxy",
		"--registry",
		"--save-prefix",
		"--scope",
		"--script-shell",
		"--tag",
		"--userconfig",
		"--workspace",
		"-C",
		"-w",
	]);

	for (let i = 0; i < rest.length; i += 1) {
		const token = rest[i];
		if (!token) continue;

		if (expectValueFor) {
			expectValueFor = false;
			continue;
		}

		if (token === "--") {
			specs.push(...rest.slice(i + 1));
			break;
		}

		if (token.startsWith("--")) {
			if (token.includes("=")) continue;
			if (flagsWithValue.has(token)) {
				expectValueFor = true;
			}
			continue;
		}

		if (token.startsWith("-") && token !== "-") {
			if (token === "-g") continue;
			if (flagsWithValue.has(token)) {
				expectValueFor = true;
			}
			continue;
		}

		specs.push(token);
	}

	return { global, specs };
}

function isLocalOrNonRegistrySpec(spec) {
	return /^(?:\.{1,2}\/|\/|~\/|file:|link:|workspace:|https?:|git\+|git:|github:|ssh:|npm:)/.test(spec);
}

function parsePackageSpec(spec) {
	if (!spec || isLocalOrNonRegistrySpec(spec)) {
		return {
			raw: spec,
			name: null,
			requestKind: "non-registry",
			selector: null,
		};
	}

	if (spec.startsWith("@")) {
		const secondSlash = spec.indexOf("/", 1);
		if (secondSlash === -1) {
			return { raw: spec, name: null, requestKind: "unknown", selector: null };
		}
		const versionAt = spec.indexOf("@", secondSlash + 1);
		const name = versionAt === -1 ? spec : spec.slice(0, versionAt);
		const selector = versionAt === -1 ? null : spec.slice(versionAt + 1);
		if (selector?.startsWith("npm:")) {
			return { raw: spec, name: null, requestKind: "alias", selector };
		}
		return {
			raw: spec,
			name,
			requestKind: classifySelector(selector),
			selector,
		};
	}

	const versionAt = spec.indexOf("@");
	const name = versionAt === -1 ? spec : spec.slice(0, versionAt);
	const selector = versionAt === -1 ? null : spec.slice(versionAt + 1);
	if (!name || selector?.startsWith("npm:")) {
		return { raw: spec, name: null, requestKind: "alias", selector };
	}
	return {
		raw: spec,
		name,
		requestKind: classifySelector(selector),
		selector,
	};
}

function classifySelector(selector) {
	if (!selector) return "implicit-latest";
	if (selector === "latest") return "latest-tag";
	return "explicit-selector";
}

function getConfigPath(key) {
	const result = runNpmJson(["config", "get", key]);
	if (result.error) return null;
	const value = result.stdout.trim();
	if (!value || value === "null" || value === "undefined") return null;
	return value;
}

function readMinReleaseAgeFromNpmrc(configPath) {
	if (!configPath || !fs.existsSync(configPath)) return null;

	try {
		const content = fs.readFileSync(configPath, "utf8");
		let value = null;
		for (const rawLine of content.split(/\r?\n/)) {
			const line = rawLine.replace(/^[\t ]+|[\t ]+$/g, "");
			if (!line || line.startsWith("#") || line.startsWith(";")) continue;
			const match = line.match(/^min-release-age\s*=\s*(.+)$/);
			if (!match) continue;
			const parsed = Number(match[1].trim());
			if (Number.isFinite(parsed)) {
				value = parsed;
			}
		}
		return value && value > 0 ? value : null;
	} catch {
		return null;
	}
}

function detectMinReleaseAgeFromFiles() {
	const configPaths = [getConfigPath("globalconfig"), getConfigPath("userconfig"), path.join(process.cwd(), ".npmrc")];
	let detected = null;
	for (const configPath of configPaths) {
		const value = readMinReleaseAgeFromNpmrc(configPath);
		if (value) detected = value;
	}
	return detected;
}

function getReleaseAgePolicy() {
	const minReleaseAgeResult = runNpmJson(["config", "get", "min-release-age"]);
	if (!minReleaseAgeResult.error) {
		const raw = minReleaseAgeResult.stdout.trim();
		const value = Number(raw);
		if (raw && raw !== "null" && raw !== "undefined" && Number.isFinite(value) && value > 0) {
			return {
				kind: "min-release-age",
				windowDays: value,
				label: `min-release-age=${value}`,
				hint: "--min-release-age=0",
			};
		}
	}

	const configuredMinReleaseAge = detectMinReleaseAgeFromFiles();
	if (configuredMinReleaseAge) {
		return {
			kind: "min-release-age",
			windowDays: configuredMinReleaseAge,
			label: `min-release-age=${configuredMinReleaseAge}`,
			hint: "--min-release-age=0",
		};
	}

	const beforeResult = runNpmJson(["config", "get", "before"]);
	if (beforeResult.error) return null;
	const beforeRaw = beforeResult.stdout.trim();
	if (!beforeRaw || beforeRaw === "null" || beforeRaw === "undefined") return null;
	const beforeTime = new Date(beforeRaw).getTime();
	if (!Number.isFinite(beforeTime)) return null;
	const windowDays = (Date.now() - beforeTime) / DAY_MS;
	if (!Number.isFinite(windowDays) || windowDays <= 0) return null;
	return {
		kind: "before",
		windowDays,
		label: `before=${beforeRaw}`,
		hint: null,
	};
}

function getInstalledVersions(names, globalInstall) {
	if (names.length === 0) return new Map();
	const args = ["ls", "--depth=0", "--json"];
	if (globalInstall) args.push("-g");
	args.push(...names);

	const result = runNpmJson(args);
	if (!result.stdout.trim()) return new Map();

	try {
		const data = JSON.parse(result.stdout);
		const deps = data?.dependencies ?? {};
		return new Map(names.map((name) => [name, deps?.[name]?.version ?? null]));
	} catch {
		return new Map();
	}
}

function getUpstreamMetadata(name) {
	const result = runNpmJson(["view", name, "version", "time", "--json"]);
	if (!result.stdout.trim()) {
		return { latestVersion: null, latestPublishedAt: null };
	}

	try {
		const data = JSON.parse(result.stdout);
		const latestVersion = typeof data?.version === "string" ? data.version : null;
		const latestPublishedAt = latestVersion && data?.time ? data.time[latestVersion] ?? null : null;
		return { latestVersion, latestPublishedAt };
	} catch {
		return { latestVersion: null, latestPublishedAt: null };
	}
}

function formatAge(ageMs) {
	if (!Number.isFinite(ageMs) || ageMs < 0) return null;
	const totalHours = Math.floor(ageMs / (60 * 60 * 1000));
	if (totalHours < 1) {
		const minutes = Math.max(1, Math.floor(ageMs / (60 * 1000)));
		return `${minutes}m old`;
	}
	if (totalHours < 48) return `${totalHours}h old`;
	const days = Math.floor(totalHours / 24);
	return `${days}d old`;
}

function buildNote(pkg, installedVersion, upstream, releaseAgePolicy) {
	if (!pkg.name) {
		return { text: "skipped non-registry/path spec", color: colors.dim };
	}

	if (!installedVersion) {
		return { text: "not present after install", color: colors.red };
	}

	if (!upstream.latestVersion) {
		return { text: "could not read upstream latest", color: colors.yellow };
	}

	if (installedVersion === upstream.latestVersion) {
		return { text: "matches upstream latest", color: colors.green };
	}

	if (pkg.requestKind === "explicit-selector") {
		return {
			text: `requested ${pkg.selector}`,
			color: colors.cyan,
		};
	}

	if (releaseAgePolicy && upstream.latestPublishedAt) {
		const latestAgeMs = Date.now() - new Date(upstream.latestPublishedAt).getTime();
		if (latestAgeMs >= 0 && latestAgeMs < releaseAgePolicy.windowDays * DAY_MS) {
			const ageLabel = formatAge(latestAgeMs);
			const cutoffLabel = formatAge(releaseAgePolicy.windowDays * DAY_MS) ?? `${releaseAgePolicy.windowDays.toFixed(1)}d cutoff`;
			return {
				text: `blocked by release-age policy${releaseAgePolicy.label ? ` [${releaseAgePolicy.label}]` : ""}${ageLabel ? ` (${ageLabel}; cutoff ${cutoffLabel})` : ""}`,
				color: colors.yellow,
			};
		}
	}

	if (pkg.requestKind === "latest-tag") {
		return { text: "requested @latest but installed older", color: colors.yellow };
	}

	return { text: "installed differs from upstream latest", color: colors.yellow };
}

function printSummary(rows, meta) {
	if (rows.length === 0) return;

	const packageWidth = Math.max("PACKAGE".length, ...rows.map((row) => row.package.length));
	const requestedWidth = Math.max("REQUESTED".length, ...rows.map((row) => row.requested.length));
	const upstreamWidth = Math.max("UPSTREAM".length, ...rows.map((row) => row.upstream.length));
	const installedWidth = Math.max("INSTALLED".length, ...rows.map((row) => row.installed.length));

	const pad = (value, width) => value.padEnd(width, " ");
	const header = [
		pad("PACKAGE", packageWidth),
		pad("REQUESTED", requestedWidth),
		pad("UPSTREAM", upstreamWidth),
		pad("INSTALLED", installedWidth),
		"NOTE",
	].join("  ");

	const scope = meta.globalInstall ? "global" : "local";
	console.error(`\n${colors.bold}npm install report${colors.reset} ${colors.dim}(${scope})${colors.reset}`);
	console.error(header);
	console.error(`${colors.dim}${"-".repeat(header.length)}${colors.reset}`);

	for (const row of rows) {
		const note = `${row.note.color}${row.note.text}${colors.reset}`;
		console.error(
			[
				pad(row.package, packageWidth),
				pad(row.requested, requestedWidth),
				pad(row.upstream, upstreamWidth),
				pad(row.installed, installedWidth),
				note,
			].join("  "),
		);
	}

	if (meta.blockedRows.length > 0) {
		const policyHint = meta.releaseAgePolicy?.hint
			? ` rerun with ${colors.bold}${meta.releaseAgePolicy.hint}${colors.reset} for just that install,`
			: " inspect your npm release-age policy settings, or";
		console.error(
			`${colors.yellow}Hint:${colors.reset}${policyHint} or wait until the upstream release ages past your npm policy.`,
		);
	}
}

if (!ANALYZE_COMMANDS.has(commandName)) {
	process.exit(runNpm(argv));
}

const parsedArgs = parseInstallArgs(argv);
const parsedPackages = parsedArgs.specs.map(parsePackageSpec);
const uniquePackages = [];
const seenNames = new Set();

for (const pkg of parsedPackages) {
	if (!pkg.name) {
		uniquePackages.push(pkg);
		continue;
	}
	if (seenNames.has(pkg.name)) continue;
	seenNames.add(pkg.name);
	uniquePackages.push(pkg);
}

const exitCode = runNpm(argv);

if (parsedArgs.specs.length === 0) {
	process.exit(exitCode);
}

const registryPackages = uniquePackages.filter((pkg) => pkg.name);
const installedVersions = getInstalledVersions(
	registryPackages.map((pkg) => pkg.name),
	parsedArgs.global,
);
const releaseAgePolicy = getReleaseAgePolicy();

const rows = uniquePackages.map((pkg) => {
	const upstream = pkg.name ? getUpstreamMetadata(pkg.name) : { latestVersion: null, latestPublishedAt: null };
	const installedVersion = pkg.name ? installedVersions.get(pkg.name) ?? null : null;
	const note = buildNote(pkg, installedVersion, upstream, releaseAgePolicy);
	return {
		package: pkg.name ?? pkg.raw,
		requested: pkg.raw,
		upstream: upstream.latestVersion ?? "-",
		installed: installedVersion ?? "-",
		note,
	};
});

const blockedRows = rows.filter((row) => row.note.text.startsWith("blocked by release-age policy"));
printSummary(rows, { globalInstall: parsedArgs.global, blockedRows, releaseAgePolicy });

process.exit(exitCode);
