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

For Prismantix Studio, confirm the current auth shape in:

- `apps/studio/src/start.ts`
- `apps/studio/src/routes/sign-in.tsx`
- `apps/studio/src/routes/callback.tsx`
- `convex.json`
- `.github/workflows/studio-deploy.yml`

Today this repo uses WorkOS hosted AuthKit plus `@workos/authkit-session`, so both of these login paths are valid:

1. real browser sign-in with persisted browser state
2. direct sealed-session cookie injection

## Workflow

1. Read `references/playbook.md`.
2. Prefer the existing Convex `authKit` automation to configure redirect URIs, homepage URL, and CORS origins. Only reach for direct WorkOS CLI config when you are working outside the normal Convex dev or deploy path.
3. Ensure the target WorkOS environment is selected and the app origin is configured.
4. Provision or update the lower-env agent user with `scripts/provision-workos-user.mjs`.
5. Choose a login path:
   - If the app uses `@workos/authkit-session` and you have the cookie password, prefer the sealed-session path with `scripts/issue-sealed-session.mjs`.
   - Otherwise use the hosted `/sign-in` flow and persist the browser session with `agent-browser`.
6. Store transient credentials and session state in `.memory/workos-agent-access/`.
7. Validate the authenticated app route you actually need, not just the homepage.

## Default Preference Order

1. Deterministic WorkOS user provisioning
2. Sealed-session cookie injection
3. Real browser sign-in plus persisted browser state
4. Manual human intervention only if the env or policy blocks the above

## Files

- `references/playbook.md`
- `scripts/provision-workos-user.mjs`
- `scripts/issue-sealed-session.mjs`
