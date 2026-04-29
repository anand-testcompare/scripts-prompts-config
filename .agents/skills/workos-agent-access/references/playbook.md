# WorkOS Agent Access Playbook

This playbook is intentionally lower-env focused. The goal is to give the agent a repeatable way to access dev and preview environments without inbox roulette or one-off dashboard clicking.

## Verified Capability Summary

- WorkOS User Management can create a user with:
  - `email`
  - `password`
  - `email_verified`
  - `external_id`
- WorkOS can authenticate a password user and return a `sealedSession` when `session.sealSession` is enabled.
- The WorkOS CLI can:
  - authenticate the operator
  - manage configured WorkOS environments
  - add redirect URIs, CORS origins, and homepage URL
  - run `doctor`
- The WorkOS CLI does not currently expose `user create`, so user provisioning should use the API or SDK directly.
- Convex AuthKit can provision WorkOS environments and write `WORKOS_*` values into Convex env, but this behavior depends on deployment type and credentials:
  - Dev and simple lower-env flows can auto-provision.
  - Preview auto-provisioning can create WorkOS environment sprawl.
  - Production deploys using deployment-specific Convex deploy keys may need a pre-existing Convex WorkOS integration before `convex deploy` can configure AuthKit.

Canonical sources:

- https://workos.com/docs/reference/authkit/user
- https://workos.com/docs/reference/authkit/authentication
- https://workos.com/docs/authkit/cli-installer
- https://workos.com/docs/sso/redirect-uris
- https://docs.convex.dev/auth/authkit/auto-provision

## Lower-Env Rules

- Use this for `dev`, `preview`, or equivalent non-production environments.
- Prefer password users with `email_verified: true`.
- Keep generated credentials and saved browser state under `.memory/workos-agent-access/`.
- Never commit those files.
- Do not rely on impersonation as the default agent path.

## Inputs To Gather

- WorkOS API key for the target environment
- WorkOS client ID for the app
- App origin, for example:
  - `http://localhost:3001`
  - `https://app.example.com`
- If sealed-session login is desired:
  - `WORKOS_COOKIE_PASSWORD`
- If org-scoped access is required:
  - WorkOS organization ID
  - optional role slug or role slugs

Derive `APP_ORIGIN` from the actual app URL the browser uses. For Cloudflare Workers this can be either a workers.dev preview URL or a custom domain. Do not assume some other hosting platform will supply the right origin automatically.

For Convex-backed deploys, inspect the repo before choosing a source of truth:

- `packages/backend/convex.json`
- app deploy handoff scripts, for example `apps/app/scripts/deploy-from-convex.mjs`
- CI deploy workflows, for example `.depot/workflows/deploy.yml`
- `convex/auth.config.ts`, because Convex JWT validation usually reads `WORKOS_CLIENT_ID`

The intended source of truth should be explicit. In some repos, Convex `authKit` automation owns redirect/CORS/homepage. In others, the app deploy handoff fetches WorkOS credentials from Convex env and configures WorkOS with `workos config`.

## Step 1: Select And Configure The WorkOS Environment

There are four configuration paths:

1. Convex `authKit` automation for dev or simple deployment-specific environments
2. Convex Shared AuthKit Environment for sharing one WorkOS environment across preview deployments
3. `workos install` for greenfield or disposable setup
4. explicit `workos config` commands for an already-integrated repo when you are working outside the Convex flow

### Option A: Convex `authKit` Automation

Convex documents that when `convex.json` includes an `authKit` section, the CLI configures AuthKit environments for `dev`, `preview`, and `prod` code pushes using `WORKOS_CLIENT_ID` and `WORKOS_API_KEY` from local env, the build env, or the Convex deployment. Source: https://docs.convex.dev/auth/authkit/auto-provision

This is often a good default for local dev. Be more careful in preview and production:

- Preview: deployment-specific AuthKit automation can create one WorkOS environment per preview deployment. That is useful for isolation, but can become dashboard/env sprawl.
- Production: if CI uses a deployment-specific Convex deploy key, `convex deploy` may refuse to auto-provision/configure AuthKit unless WorkOS credentials already exist in build env or the target Convex deployment.
- Dashboard integration buttons can create/link a WorkOS environment and write `WORKOS_CLIENT_ID`, `WORKOS_API_KEY`, and often `WORKOS_ENVIRONMENT_ID` into Convex env. App session secrets such as `WORKOS_COOKIE_PASSWORD` may still need to be set separately.

Use this path when it matches the repo's intended deployment contract and will not create unwanted WorkOS environment sprawl.

### Option B: Convex Shared AuthKit Environment

Convex Shared AuthKit Environments belong to a project rather than one deployment and are a better fit when many preview deployments should share one lower-env WorkOS app.

Before implementing this path, verify:

- whether preview deploys automatically receive `WORKOS_CLIENT_ID` and `WORKOS_API_KEY` from the shared AuthKit environment
- whether `convex/auth.config.ts` can read `WORKOS_CLIENT_ID` in each preview deployment after deploy
- whether app Worker deploys can fetch the needed `WORKOS_*` values from Convex without storing them in CI secrets
- whether per-preview `WORKOS_COOKIE_PASSWORD` should be unique or shared
- whether old per-preview WorkOS environments need cleanup

### Option C: Installer Path

The official installer can derive and configure the dashboard linkage for you.
WorkOS documents that `workos install` automatically sets redirect URIs, CORS origins, and homepage URL. In practice, the redirect URI is the main input and the homepage/CORS origin are derived from its origin.

Example:

```bash
npx workos@latest install \
  --integration tanstack-start \
  --redirect-uri "$APP_ORIGIN/callback" \
  --homepage-url "$APP_ORIGIN" \
  --install-dir apps/app
```

Use this only when you actually want the installer to analyze and potentially edit the project. It is not the right default for a repo that already has WorkOS integrated.

### Option D: Explicit Dashboard Config

Use these only when you intentionally need to repair or inspect linkage outside the normal Convex dev or deploy path. They keep the same effective dashboard linkage without asking the installer to touch code:

```bash
npx workos@latest auth login
npx workos@latest env add app-preview "$WORKOS_API_KEY" --client-id "$WORKOS_CLIENT_ID"
npx workos@latest env switch app-preview
npx workos@latest config redirect add "$APP_ORIGIN/callback"
npx workos@latest config cors add "$APP_ORIGIN"
npx workos@latest config homepage-url set "$APP_ORIGIN"
npx workos@latest doctor --install-dir "$PWD"
```

Notes:

- The desired redirect URI, homepage URL, and CORS origin should match the values already declared in `convex.json` or supplied to the app deploy handoff.
- Redirect URIs must exist in WorkOS before hosted auth will succeed.
- `workos doctor` is useful to confirm the current env, dashboard settings, and callback URI without mutating anything.
- Wildcard redirect URIs are supported, but not on public suffix domains. Use them only when the preview domain pattern actually supports it.

## Step 2: Provision The Agent User

Use the bundled script:

```bash
node .agents/skills/workos-agent-access/scripts/provision-workos-user.mjs \
  --api-key "$WORKOS_API_KEY" \
  --email "codex+preview@example.com" \
  --password "$WORKOS_AGENT_PASSWORD" \
  --first-name "Codex" \
  --last-name "Preview" \
  --external-id "agent:app:preview" \
  --organization-id "$WORKOS_ORGANIZATION_ID" \
  --role-slug "admin"
```

What it does:

- prefers stable `external_id` lookup before falling back to email lookup
- finds an existing user by email
- creates the user if missing
- otherwise updates the existing user
- defaults `emailVerified` to `true`
- optionally ensures the requested org membership exists

## Step 3A: Fast Login Path With A Sealed Session

Use this when the app uses `@workos/authkit-session` and you have the cookie password.

Issue a sealed session:

```bash
node .agents/skills/workos-agent-access/scripts/issue-sealed-session.mjs \
  --api-key "$WORKOS_API_KEY" \
  --client-id "$WORKOS_CLIENT_ID" \
  --email "codex+preview@example.com" \
  --password "$WORKOS_AGENT_PASSWORD" \
  --cookie-password "$WORKOS_COOKIE_PASSWORD"
```

Then inject it into the browser:

```bash
sealed_session="$(
  node .agents/skills/workos-agent-access/scripts/issue-sealed-session.mjs \
    --api-key "$WORKOS_API_KEY" \
    --client-id "$WORKOS_CLIENT_ID" \
    --email "codex+preview@example.com" \
    --password "$WORKOS_AGENT_PASSWORD" \
    --cookie-password "$WORKOS_COOKIE_PASSWORD" \
  | jq -r '.sealedSession'
)"

agent-browser --session-name app-preview open "$APP_ORIGIN"
agent-browser cookies set wos-session "$sealed_session"
agent-browser open "$APP_ORIGIN/prompt-lab"
```

Notes:

- Many AuthKit integrations use the default WorkOS cookie name, `wos-session`; verify the app has not overridden it.
- The helper bootstraps the official WorkOS Node SDK into `.memory/workos-agent-access/runtime/` the first time it runs, so it stays self-contained instead of depending on workspace packages.
- This browser cookie injection path is for lower-env automation. It does not preserve `HttpOnly`, but the server only needs the cookie value to be sent back on requests.
- If the app has overridden `WORKOS_COOKIE_NAME`, use that value instead.
- This helper assumes password authentication resolves to a single org context. If the user belongs to multiple orgs and WorkOS requires organization selection, use the hosted sign-in fallback or extend the helper to handle the pending-authentication-token flow.

## Step 3B: Hosted Sign-In Fallback

If sealed-session login is not available or is behaving oddly, use the real login flow once and persist the session:

```bash
agent-browser --session-name app-preview open "$APP_ORIGIN/sign-in"
agent-browser wait --load networkidle
agent-browser snapshot -i
```

Then fill the hosted WorkOS form, finish the redirect, and reuse the same `--session-name` later.

For a one-off handoff from a human-authenticated browser:

```bash
agent-browser --auto-connect state save ./.memory/workos-agent-access/app-preview-auth.json
agent-browser --state ./.memory/workos-agent-access/app-preview-auth.json open "$APP_ORIGIN/prompt-lab"
```

## When To Prefer Which Path

- Prefer sealed-session login when:
  - the repo uses `@workos/authkit-session`
  - the cookie password is available
  - you want a fast, deterministic path
- Prefer hosted sign-in when:
  - the cookie password is unavailable
  - you need to validate the real end-user sign-in flow
  - the app uses a different session abstraction

## Validation Checklist

- The target route loads authenticated content, not just the marketing shell.
- The app no longer redirects to `/sign-in`.
- Protected backend requests succeed.
- The session persists across a page refresh.
- If org-scoped behavior matters, the correct org is selected after login.
- If social sign-in is enabled in dev/test, click the hosted social button and confirm it reaches the provider page. Do not remove/hide social buttons as a workaround for a broken lower-env WorkOS configuration.

## Sharp Edges

- If email verification is enabled and the user is not verified, password auth can fail into the email-verification flow.
- Some email domains can be forced into SSO by WorkOS environment policy. In this repo's current test environment, `example.com` was rejected for password auth with `sso_required`, while `example.org` worked.
- If the app origin is wrong or missing from WorkOS redirect config, hosted sign-in will fail with redirect URI errors.
- If the cookie password is wrong, the sealed-session path will produce a session the app cannot read.
- If the app rotates cookie config or session handling, re-check the app auth hook/startup files before assuming the fast path still applies.
- WorkOS-hosted social buttons in dev/test are expected to work. An immediate provider error such as Google `invalid_request` usually points to the wrong WorkOS environment or incomplete provider configuration, not a reason to disable social sign-in.
