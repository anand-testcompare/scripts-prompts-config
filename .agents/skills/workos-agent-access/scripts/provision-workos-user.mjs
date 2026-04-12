#!/usr/bin/env node

function usage() {
	console.error(`Usage:
  node provision-workos-user.mjs --email <email> --password <password> [options]

Options:
  --api-key <key>                  Defaults to WORKOS_API_KEY
  --first-name <name>
  --last-name <name>
  --external-id <id>
  --organization-id <org_id>
  --role-slug <slug>
  --role-slugs <slug1,slug2>
  --metadata-json <json>
  --email-verified <true|false>    Default: true
  --base-url <url>                 Default: https://api.workos.com
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

function parseBoolean(value, fallback) {
	if (value == null) {
		return fallback;
	}

	if (value === "true") {
		return true;
	}

	if (value === "false") {
		return false;
	}

	throw new Error(`Expected true or false, received: ${value}`);
}

function parseRoleSlugs(roleSlug, roleSlugs) {
	if (roleSlugs) {
		return roleSlugs
			.split(",")
			.map((item) => item.trim())
			.filter(Boolean);
	}

	if (roleSlug) {
		return [roleSlug];
	}

	return [];
}

function getWorkosApiKey(args) {
	return args["api-key"] ?? process.env.WORKOS_API_KEY;
}

function buildUrl(baseUrl, pathname, query) {
	const url = new URL(pathname, baseUrl);

	for (const [key, value] of Object.entries(query ?? {})) {
		if (value == null) {
			continue;
		}

		url.searchParams.set(key, String(value));
	}

	return url;
}

async function requestJson({ apiKey, baseUrl, method, pathname, query, body }) {
	const response = await fetch(buildUrl(baseUrl, pathname, query), {
		method,
		headers: {
			Authorization: `Bearer ${apiKey}`,
			"Content-Type": "application/json",
		},
		body: body == null ? undefined : JSON.stringify(body),
	});

	const text = await response.text();
	const json = text ? JSON.parse(text) : null;

	if (!response.ok) {
		const message =
			json?.message ??
			json?.error?.message ??
			`${method} ${pathname} failed with ${response.status}`;
		throw new Error(`${response.status}: ${message}`);
	}

	return json;
}

function normalizeRoleSlugs(membership) {
	return [
		...new Set(
			[
				membership?.role?.slug,
				...(membership?.roles?.map((role) => role.slug) ?? []),
			].filter(Boolean),
		),
	].sort();
}

async function main() {
	const args = parseArgs(process.argv.slice(2));

	if (args.help) {
		usage();
		process.exit(0);
	}

	const apiKey = getWorkosApiKey(args);
	const email = args.email;
	const password = args.password;

	if (!apiKey || !email || !password) {
		usage();
		throw new Error(
			"--email and --password are required, and WorkOS API key must come from --api-key or WORKOS_API_KEY",
		);
	}

	const baseUrl = args["base-url"] ?? "https://api.workos.com";
	const metadata = args["metadata-json"]
		? JSON.parse(args["metadata-json"])
		: undefined;
	const emailVerified = parseBoolean(args["email-verified"], true);
	const desiredRoleSlugs = parseRoleSlugs(
		args["role-slug"],
		args["role-slugs"],
	);
	const organizationId = args["organization-id"];
	const externalId = args["external-id"];

	let existingUser = null;

	if (externalId) {
		existingUser = await getUserByExternalId({
			apiKey,
			baseUrl,
			externalId,
		});
	}

	if (!existingUser) {
		const listedUsers = await requestJson({
			apiKey,
			baseUrl,
			method: "GET",
			pathname: "/user_management/users",
			query: {
				email,
				limit: 1,
			},
		});
		existingUser = listedUsers?.data?.[0] ?? null;
	}

	const userPayload = {
		email,
		password,
		first_name: args["first-name"],
		last_name: args["last-name"],
		email_verified: emailVerified,
		external_id: externalId,
		metadata,
	};

	const user = existingUser
		? await requestJson({
				apiKey,
				baseUrl,
				method: "PUT",
				pathname: `/user_management/users/${existingUser.id}`,
				body: userPayload,
			})
		: await requestJson({
				apiKey,
				baseUrl,
				method: "POST",
				pathname: "/user_management/users",
				body: userPayload,
			});

	let membership = null;

	if (organizationId) {
		const listedMemberships = await requestJson({
			apiKey,
			baseUrl,
			method: "GET",
			pathname: "/user_management/organization_memberships",
			query: {
				organization_id: organizationId,
				user_id: user.id,
				limit: 100,
			},
		});

		membership =
			listedMemberships?.data?.find(
				(candidate) => candidate.organization_id === organizationId,
			) ?? null;

		if (!membership) {
			membership = await requestJson({
				apiKey,
				baseUrl,
				method: "POST",
				pathname: "/user_management/organization_memberships",
				body: {
					organization_id: organizationId,
					user_id: user.id,
					role_slug: desiredRoleSlugs[0],
					role_slugs:
						desiredRoleSlugs.length > 0 ? desiredRoleSlugs : undefined,
				},
			});
		} else if (desiredRoleSlugs.length > 0) {
			const currentRoleSlugs = normalizeRoleSlugs(membership);
			const normalizedDesiredRoleSlugs = [...desiredRoleSlugs].sort();
			const hasDifferentRoles =
				currentRoleSlugs.length !== normalizedDesiredRoleSlugs.length ||
				currentRoleSlugs.some(
					(slug, index) => slug !== normalizedDesiredRoleSlugs[index],
				);

			if (hasDifferentRoles) {
				membership = await requestJson({
					apiKey,
					baseUrl,
					method: "PUT",
					pathname: `/user_management/organization_memberships/${membership.id}`,
					body: {
						role_slug: desiredRoleSlugs[0],
						role_slugs: desiredRoleSlugs,
					},
				});
			}
		}
	}

	console.log(
		JSON.stringify(
			{
				action: existingUser ? "updated" : "created",
				user: {
					id: user.id,
					email: user.email,
					emailVerified: user.email_verified,
					firstName: user.first_name,
					lastName: user.last_name,
					externalId: user.external_id,
				},
				membership: membership
					? {
							id: membership.id,
							organizationId: membership.organization_id,
							userId: membership.user_id,
							status: membership.status,
							roleSlug: membership.role?.slug ?? null,
							roleSlugs: membership.roles?.map((role) => role.slug) ?? [],
						}
					: null,
			},
			null,
			2,
		),
	);
}

async function getUserByExternalId({ apiKey, baseUrl, externalId }) {
	try {
		return await requestJson({
			apiKey,
			baseUrl,
			method: "GET",
			pathname: `/user_management/users/external_id/${encodeURIComponent(externalId)}`,
		});
	} catch (error) {
		if (error instanceof Error && error.message.includes("404")) {
			return null;
		}

		if (error instanceof Error && /user not found/i.test(error.message)) {
			return null;
		}

		throw error;
	}
}

main().catch((error) => {
	console.error(error instanceof Error ? error.message : String(error));
	process.exit(1);
});
