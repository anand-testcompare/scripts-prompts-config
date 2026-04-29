---
name: workos-agent-access
description: Provision and authenticate lower-env WorkOS/AuthKit users for this repo. Use when the agent needs its own reusable dev or preview login, must configure WorkOS redirect/CORS/homepage settings, create or update a password user, attach org memberships, or establish browser auth via agent-browser or a direct sealed session cookie.
---

# WorkOS Agent Access

Use this skill for lower-environment access only.

- Good fits:
  - the agent needs its own reusable WorkOS account in dev or preview
  - a preview env is failing because redirect, CORS, or homepage settings are missing
  - the app uses AuthKit and the agent should log in without human inbox handling
  - the agent needs a repeatable browser session for `agent-browser`
- Do not use this as a production access pattern.
- Do not default to WorkOS impersonation. That is a separate admin/support flow.

## Repo Clues

Confirm the current auth shape before choosing a login path. Common files:

- SvelteKit: `src/hooks.server.ts`, `src/routes/sign-in`, `src/routes/callback`, `src/routes/sign-out`
- Next.js: `proxy.ts`, `middleware.ts`, `app/callback/route.ts`, `app/sign-out/route.ts`
- Convex: `convex.json`, `convex/auth.config.ts`
- Deploy: `.depot/workflows/*.yml`, `.github/workflows/*.yml`, app deploy scripts

When a repo uses WorkOS hosted AuthKit plus `@workos/authkit-session` or `@workos/authkit-sveltekit`, both of these login paths may be valid:

1. real browser sign-in with persisted browser state
2. direct sealed-session cookie injection

## Workflow

1. Read `references/playbook.md`.
2. Prefer the repo's existing Convex/AuthKit deployment contract. Do not assume Convex `authKit` automation is always safe for every environment:
   - Dev/simple lower envs can usually auto-provision.
   - Preview auto-provisioning can create one WorkOS env per preview deployment.
   - Production deploys that use deployment-specific Convex deploy keys may require a pre-existing Convex WorkOS integration/env vars before `convex deploy` can configure AuthKit.
   - A Convex "Shared AuthKit Environment" is distinct from an ad hoc WorkOS CLI environment.
3. Only reach for direct WorkOS CLI config when you are working outside the normal Convex dev/deploy path or the deploy handoff intentionally configures WorkOS from Convex-stored credentials.
4. Ensure the target WorkOS environment is selected and the app origin is configured.
5. Provision or update the lower-env agent user with `scripts/provision-workos-user.mjs`.
6. Choose a login path:
   - If the app uses `@workos/authkit-session` and you have the cookie password, prefer the sealed-session path with `scripts/issue-sealed-session.mjs`.
   - Otherwise use the hosted `/sign-in` flow and persist the browser session with `agent-browser`.
7. Store transient credentials and session state in `.memory/workos-agent-access/`.
8. Validate the authenticated app route you actually need, not just the homepage.
9. If social sign-in is enabled in dev/test, do not hide or bypass it to paper over errors. Hosted social providers should reach the provider page; immediate Google/Microsoft/GitHub errors usually indicate WorkOS environment/config drift.

## Default Preference Order

1. Deterministic WorkOS user provisioning
2. Sealed-session cookie injection
3. Real browser sign-in plus persisted browser state
4. Manual human intervention only if the env or policy blocks the above

## Files

- `references/playbook.md`
- `scripts/provision-workos-user.mjs`
- `scripts/issue-sealed-session.mjs`
