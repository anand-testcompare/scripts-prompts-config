# WorkOS AuthKit + Convex Custom JWT Playbook

This is the debugging and implementation runbook for WorkOS AuthKit apps backed by Convex `customJwt` auth. It is framework-neutral by default and calls out SvelteKit, Next.js, Cloudflare, Depot, and Convex-specific edges where they matter.

## Architecture Checklist

Confirm the actual repo shape before acting:

- App auth runtime:
  - SvelteKit: `src/hooks.server.ts`, `src/routes/sign-in`, `src/routes/callback`, `src/routes/sign-out`
  - Next.js: `proxy.ts` or `middleware.ts`, `app/callback/route.ts`, `app/sign-out/route.ts`
  - React SPA: token bridge/provider components and backend callback/session routes
- Convex auth:
  - `convex/auth.config.ts` usually reads `WORKOS_CLIENT_ID`
  - WorkOS JWT issuer/JWKS/audience must match the app's WorkOS client id
- Deployment:
  - `convex.json` `authKit` section
  - app deploy handoff scripts that fetch `WORKOS_*`
  - CI workflow and deploy keys

## Convex AuthKit Environment Types

Do not blur these together:

- Deployment-specific Convex AuthKit environment: belongs to one Convex deployment. Good isolation, but PR previews can create many WorkOS envs.
- Convex Shared AuthKit Environment: belongs to a Convex project and can be shared across preview deployments. Better for avoiding WorkOS env sprawl, but verify how preview deployment env vars are populated before relying on it.
- WorkOS CLI environment: local operator config used by `workos env switch` / `workos config`. This is not automatically a Convex Shared AuthKit Environment.

## Deployment Rules Learned The Hard Way

- Convex remains the preferred source of truth for WorkOS env values when the repo says so. Do not copy `WORKOS_CLIENT_ID` or `WORKOS_API_KEY` into CI secrets unless the repo explicitly chooses that tradeoff.
- Convex `authKit` automation can auto-provision in dev and some lower-env flows.
- Production deploys using deployment-specific Convex deploy keys can fail before app/API deploy with:

  ```text
  AuthKit configuration in convex.json requires WorkOS credentials.
  When using a deployment-specific key, you cannot automatically provision WorkOS environments.
  ```

- The Convex dashboard WorkOS integration button can create/link a WorkOS environment and write `WORKOS_CLIENT_ID`, `WORKOS_API_KEY`, and `WORKOS_ENVIRONMENT_ID` into Convex env. It may not set app-specific session secrets such as `WORKOS_COOKIE_PASSWORD`.
- If `convex.json` keeps `authKit.prod.configure`, prod deploy may still require those WorkOS credentials to exist before `convex deploy` starts.
- If the app deploy handoff fetches WorkOS credentials from Convex, verify the target deployment has all required values:

  ```bash
  cd packages/backend
  npx convex env list --prod
  npx convex env get WORKOS_CLIENT_ID --prod
  npx convex env get WORKOS_API_KEY --prod >/dev/null
  npx convex env get WORKOS_COOKIE_PASSWORD --prod >/dev/null
  ```

## Preview Environment Sprawl

If `convex.json` enables `authKit.preview.configure`, preview deploys may provision separate WorkOS/AuthKit environments. That can be useful for isolated test environments, but it can also create 100+ WorkOS envs over time.

Before switching to shared previews:

1. Create or inspect a Convex Shared AuthKit Environment.
2. Run a disposable preview deploy.
3. Verify whether Convex writes `WORKOS_CLIENT_ID` and `WORKOS_API_KEY` into the preview deployment env.
4. Verify `convex/auth.config.ts` works in that preview.
5. Verify the app Worker can fetch the required `WORKOS_*` values without CI secrets.
6. Decide whether preview `WORKOS_COOKIE_PASSWORD` should be unique per preview or shared.
7. Document cleanup for old per-preview WorkOS environments.

## Local Dev

Use the repo's normal setup script first. In Scryu-like repos this is usually:

```bash
bun run dev:setup
bun run dev:app
```

Expected local app env includes:

- public Convex URL (`PUBLIC_CONVEX_URL`, `NEXT_PUBLIC_CONVEX_URL`, or framework equivalent)
- `WORKOS_CLIENT_ID`
- `WORKOS_API_KEY`
- `WORKOS_COOKIE_PASSWORD`
- callback/redirect URI env if the app uses one

Convex needs `WORKOS_CLIENT_ID` for `auth.config.ts`. AuthKit server helpers usually need `WORKOS_API_KEY` and `WORKOS_COOKIE_PASSWORD`.

## Browser Verification

Do real browser verification for auth changes:

1. Unauthenticated protected route redirects to sign-in.
2. Sign-in page loads.
3. Hosted AuthKit page opens with the expected WorkOS client id.
4. If social sign-in is enabled in dev/test, click the provider button and confirm it reaches the provider page. Do not hide social buttons to work around provider errors.
5. Callback returns to the app.
6. App home and at least one protected route load.
7. Convex auth probe or authenticated query succeeds.
8. Refresh persists session.
9. POST logout clears the app session and returns to sign-in.

## Failure Modes

### Hosted Social Provider `invalid_request`

Symptoms:

- WorkOS hosted UI displays social buttons.
- Clicking Google/Microsoft/GitHub reaches an immediate provider error, for example Google `invalid_request`.

Likely causes:

- The deployed app is using a different WorkOS client id than the one you expected.
- A freshly auto-provisioned preview WorkOS environment exists but lacks provider configuration or differs from the known-good lower-env app.

Fix posture:

- Do not remove or hide social buttons in dev/test.
- Verify the hosted AuthKit URL `client_id`.
- Verify the target Convex deployment `WORKOS_CLIENT_ID`.
- Prefer fixing WorkOS/Convex env source-of-truth drift.

### Convex Rejects WorkOS JWT

Check:

- JWT `iss`
- JWT `aud`
- `convex/auth.config.ts` JWKS URL
- target Convex deployment env `WORKOS_CLIENT_ID`

Typical WorkOS providers:

- shared issuer: `https://api.workos.com/` with `applicationID` set to client id
- user management issuer: `https://api.workos.com/user_management/<client_id>`
- JWKS: `https://api.workos.com/sso/jwks/<client_id>`

### Production Deploy Fails Before App/API Deploy

Check the failed job log, not just PR status. Then verify:

```bash
gh api repos/OWNER/REPO/commits/main/check-runs \
  --jq '.check_runs[] | {name,status,conclusion,details_url,started_at,completed_at}'
```

If Convex says AuthKit config requires WorkOS credentials:

- Use the Convex dashboard integration or the repo's documented provisioning path to populate prod Convex env.
- Set `WORKOS_COOKIE_PASSWORD` if the dashboard did not.
- Rerun deploy from a clean checkout.

### Sign-Out Does Not End WorkOS Session

For SvelteKit/WorkOS AuthKit:

- Prefer a POST-only sign-out endpoint.
- Preserve session-clearing headers from the AuthKit sign-out response.
- Redirect through the WorkOS logout URL.
- Set `return_to` back to an app route such as `/sign-in`.

For Next.js:

- Avoid side-effectful GET sign-out routes, or ensure no link prefetch can hit them.
- If a GET route is unavoidable, disable prefetch on any sign-out link.

### Session Loading Loops

If the app has a Convex auth bridge:

- Avoid retry loops that force WorkOS refresh on every Convex auth request.
- Prefer the SDK's normal `getAccessToken()` behavior.
- Treat token hook errors as unauthenticated so the UI can route back through sign-in.

## Depot / CI Rerun Traps

- `depot ci run` can upload local dirty changes as a patch. If another agent is editing the checkout, run from a clean clone/worktree.
- Running a single job locally can still respect workflow `if:` conditions and skip the job. If you temporarily patch workflow conditions to rerun a prod stage, do it from a disposable clean clone and do not commit the patch.
- PR check rollups can differ from merge commit check-runs. After merge, inspect the commit on `main`.

## Useful Commands

```bash
# Convex env
cd packages/backend
npx convex env list
npx convex env list --prod
npx convex env get WORKOS_CLIENT_ID --prod

# Convex function smoke
npx convex run --prod authProbe:viewer '{}'

# Deploy logs
gh api repos/OWNER/REPO/commits/main/check-runs \
  --jq '.check_runs[] | {name,status,conclusion,details_url}'

# WorkOS CLI command tree, before assuming a command exists
npx workos --help --json
```

## Operational Guardrails

- Keep an auth-debug or auth-probe surface around. It separates WorkOS session, WorkOS token, and Convex JWT acceptance failures.
- Treat redirect URI, homepage URL, and CORS origin as exact deployed URL contracts.
- Treat social-login failures in lower envs as real config bugs.
- Keep WorkOS keys out of CI secrets when the repo's contract says Convex is the source of truth.
- Document whether previews use per-deployment AuthKit envs or a Convex Shared AuthKit Environment.
