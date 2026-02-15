---
name: workos-convex-authkit
description: Implement and debug WorkOS AuthKit + Convex (customJwt) auth in a Next.js app. Use for issues like preview redirect-uri-invalid, /admin spinner or "Loading session…" loops, WorkOS token refresh 429/invalid_grant, Convex auth rejecting WorkOS JWTs (issuer/JWKS/aud mismatches), or accidental sign-outs from Next.js Link prefetch hitting /sign-out.
---

# WorkOS AuthKit + Convex Playbook

## Canonical Doc

Primary reference: `references/playbook.md`.

If you are working inside this repo, the same content is mirrored at `docs/workos-convex-authkit-playbook.md` for humans.

## Workflow (Fast Triage)

1. Repro in the browser.
   - Prefer lower envs (dev/preview) with real AuthKit accounts instead of any auth bypass.
2. Open `/admin/auth-debug`.
   - Goal: disambiguate WorkOS session vs WorkOS token vs Convex token acceptance.
3. Map the symptom to the known failure modes below.
4. Validate with real CLI signals (Convex logs + a `convex run`) before calling it fixed.

## Decision Tree

- If WorkOS `user` is `null`:
  - Check `apps/web/src/proxy.ts` route protection/redirects and that `/callback` matches the configured redirect URI.
  - Confirm `WORKOS_COOKIE_PASSWORD` is set and sufficiently long.
- If WorkOS `user` exists but token hook errors / token loading flaps:
  - Inspect `/admin/auth-debug` token hook `error`.
  - Check Vercel logs for WorkOS refresh errors (429 / `invalid_grant`).
  - Audit `apps/web/src/components/providers.tsx`: do not force refresh in a retry loop; prefer `getAccessToken()`.
- If WorkOS token fetch succeeds but Convex is `authenticated: false`:
  - Decode JWT claims (Auth Debug page shows them).
  - Verify `iss` and `aud` align with `packages/backend/convex/auth.config.ts`.
  - Confirm `WORKOS_CLIENT_ID` is set for the Convex deployment env (JWKS URL depends on it).
- If preview login fails with `redirect-uri-invalid`:
  - WorkOS redirect URIs are exact-match.
  - Ensure preview config uses the canonical deployment domain:
    - `packages/backend/convex.json` preview uses `buildEnv.VERCEL_URL`.
    - `apps/web/src/proxy.ts` uses `https://${VERCEL_URL}` for previews.
- If users are “randomly” logged out:
  - Look for background `GET /sign-out` in HAR/network.
  - If present, fix UI to avoid prefetch-triggered side effects:
    - `apps/web/src/components/header.tsx` sets `prefetch={false}` on the sign-out link.

## Commands (Copy/Paste)

```bash
# Local web
cd apps/web
bun run dev

# Local convex
cd packages/backend
bun run dev:setup

# Prod debugging
npx convex logs --prod --tail
npx convex run --prod tpwdAdmin:listPlans '{}'
```

## Test Accounts (Lower Envs)

- Preferred: create AuthKit email+password users in dev/preview using throwaway inboxes.
- Use `tmp/authkit_test_accounts.json` (gitignored) as the repeatable source for the current machine’s test credentials.
- For inboxing, use Maildrop or plus-addressing (see `docs/workos-convex-authkit-playbook.md`).
