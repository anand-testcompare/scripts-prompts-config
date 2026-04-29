---
name: workos-convex-authkit
description: Implement and debug WorkOS AuthKit + Convex (customJwt) auth in a SvelteKit, Next.js, or React app. Use for issues like preview redirect-uri-invalid, hosted social provider errors, protected route redirect failures, token refresh loops, Convex auth rejecting WorkOS JWTs (issuer/JWKS/aud mismatches), production deploy-key AuthKit failures, preview WorkOS environment sprawl, or accidental sign-outs from prefetch/GET sign-out routes.
---

# WorkOS AuthKit + Convex Playbook

## Canonical Doc

Primary reference: `references/playbook.md`.

If you are working inside a repo with a mirrored human doc, prefer keeping that doc aligned after changing this skill.

## Workflow (Fast Triage)

1. Repro in the browser.
   - Prefer lower envs (dev/preview) with real AuthKit accounts instead of any auth bypass.
   - If social sign-in is enabled, verify the hosted social button reaches the provider page before changing UI.
2. Use the repo's auth-debug page if one exists.
   - Goal: disambiguate WorkOS session vs WorkOS token vs Convex token acceptance.
3. Inspect the deployment contract.
   - `convex.json`
   - `convex/auth.config.ts`
   - app auth hooks/routes
   - deploy handoff scripts
   - CI workflow
4. Map the symptom to the known failure modes below.
5. Validate with real CLI/browser signals before calling it fixed:
   - Convex env/list/run/logs
   - deployed app route responses
   - hosted AuthKit URL and client id
   - relevant CI/deploy logs

## Decision Tree

- If WorkOS `user` is `null`:
  - Check route protection/redirects and that `/callback` exactly matches the configured redirect URI.
  - Confirm `WORKOS_COOKIE_PASSWORD` is set and sufficiently long.
- If WorkOS `user` exists but token hook errors / token loading flaps:
  - Inspect the auth-debug token hook `error`.
  - Check runtime logs for WorkOS refresh errors (429 / `invalid_grant`).
  - Audit the Convex auth bridge: do not force refresh in a retry loop; prefer cached/normal `getAccessToken()` behavior.
- If WorkOS token fetch succeeds but Convex is `authenticated: false`:
  - Decode JWT claims (Auth Debug page shows them).
  - Verify `iss` and `aud` align with `convex/auth.config.ts`.
  - Confirm `WORKOS_CLIENT_ID` is set for the Convex deployment env (JWKS URL depends on it).
- If preview login fails with `redirect-uri-invalid`:
  - WorkOS redirect URIs are exact-match.
  - Ensure preview config uses the actual app URL the browser hits, not a guessed alias.
- If hosted social sign-in fails with provider `invalid_request`:
  - Do not hide social buttons in dev/test as a fix.
  - Verify the deployed app is using the intended WorkOS client id.
  - Check whether a per-preview auto-provisioned WorkOS environment lacks provider configuration or differs from the shared/staging environment.
- If users are “randomly” logged out:
  - Look for background `GET /sign-out` in HAR/network.
  - Prefer POST-only sign-out.
  - For WorkOS logout, preserve session-clearing headers and redirect through the WorkOS logout URL with an app `return_to`.
- If production deploy fails before app/API deploy:
  - Inspect merge commit check-runs, not only the PR rollup.
  - Deployment-specific Convex deploy keys can fail Convex `authKit.prod.configure` unless WorkOS credentials already exist in build env or target Convex env.
  - If Convex is the WorkOS source of truth, the dashboard integration may be needed once to populate prod Convex env, and `WORKOS_COOKIE_PASSWORD` may still need to be set separately.
- If preview deploys create many WorkOS environments:
  - Distinguish deployment-specific Convex AuthKit envs from a Convex Shared AuthKit Environment.
  - Evaluate a shared preview AuthKit environment before large preview volume.

## Commands (Copy/Paste)

```bash
# Local Convex
cd packages/backend
bun run dev:setup

# Prod env/debugging
npx convex env list --prod
npx convex logs --prod --tail

# Confirm merge commit check-runs after a PR merges
gh api repos/OWNER/REPO/commits/main/check-runs \
  --jq '.check_runs[] | {name,status,conclusion,details_url,started_at,completed_at}'
```

## Test Accounts (Lower Envs)

- Preferred: create AuthKit email+password users in dev/preview using throwaway inboxes.
- Use `tmp/authkit_test_accounts.json` (gitignored) as the repeatable source for the current machine’s test credentials.
- For inboxing, use Maildrop or plus-addressing (see `docs/workos-convex-authkit-playbook.md`).
