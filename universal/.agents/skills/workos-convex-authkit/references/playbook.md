# WorkOS AuthKit + Convex (custom JWT) Playbook

This is the debugging + implementation runbook for the WorkOS AuthKit + Convex auth integration in this repo (Next.js app + Convex backend). It focuses on real failures we hit in preview/prod and how to diagnose/fix them quickly.

## Architecture (What Talks To What)

- **Next.js** runs WorkOS AuthKit in the `proxy` (Next middleware-equivalent) and exposes auth utility routes:
  - `apps/web/src/proxy.ts` protects `/admin/*` and routes unauthenticated users to `/sign-in`.
  - `apps/web/src/app/callback/route.ts` handles the WorkOS redirect callback (`/callback` must exactly match the configured redirect URI).
  - `apps/web/src/app/sign-out/route.ts` signs the user out (GET route handler).
- **WorkOS** issues JWT access tokens for the logged-in user.
- **Convex** validates the JWT via JWKS and treats it as the auth identity:
  - `packages/backend/convex/auth.config.ts` configures `customJwt` providers for WorkOS issuers + JWKS.
- **Convex React** uses `ConvexProviderWithAuth` and fetches the WorkOS access token client-side:
  - `apps/web/src/components/providers.tsx` bridges WorkOS `getAccessToken()` into Convex.

## Local Dev: Known-Good Setup

1. Install deps (once):
   - `bun install`
2. Start Convex dev (terminal 1):
   - `cd packages/backend`
   - `bun run dev:setup` (first time / whenever auth config changed)
   - or `bun run dev` (subsequent runs)
3. Start the web app (terminal 2):
   - `cd apps/web`
   - `bun run dev` (runs Next on port `3005`)
4. Environment variables (local only, never commit):
   - `apps/web/.env.local`:
     - `NEXT_PUBLIC_CONVEX_URL=...` (the Convex dev deployment URL printed by `convex dev`)
     - `WORKOS_CLIENT_ID=...`
     - `WORKOS_API_KEY=...` (required by AuthKit server helpers)
     - `WORKOS_COOKIE_PASSWORD=...` (must be long; generate with `openssl rand -base64 32`)
     - `NEXT_PUBLIC_WORKOS_REDIRECT_URI=http://localhost:3005/callback`
   - `packages/backend/.env.local`:
     - `WORKOS_CLIENT_ID=...` (Convex needs this for `auth.config.ts` and JWKS URL)
     - `WORKOS_API_KEY=...` (used by `convex dev --configure` via `packages/backend/convex.json`)

## Non-Prod Testing: Creating Repeatable Test Accounts

Avoid “local bypass” auth. Prefer real AuthKit sessions in dev/preview with throwaway accounts so the exact same token flow is exercised.

Practical ways to create many accounts safely:

- **Maildrop**: Use a unique inbox per environment (no signup required).
  - Example: `inquirydb-preview-<anything>@maildrop.cc`
  - Mailbox URL pattern: `https://maildrop.cc/inbox/<local-part>`
- **Plus-addressing** (if your email provider supports it):
  - Example: `you+inquirydb-preview-001@gmail.com`, `you+inquirydb-preview-002@gmail.com`
- **Your own domain catch-all** (best long-term): route all `*@yourdomain` to one inbox.

Repo-local storage for *your* machine (gitignored):

- `tmp/authkit_test_accounts.json` contains the current dev/preview credentials used for repeatable runs.
- `tmp/agent-browser-state-preview.json` and `tmp/agent-browser-state-local.json` store agent-browser session state if you want deterministic “log in again” runs.

Never put passwords/tokens into tracked docs or PRs.

## Debugging Checklist (Fast Triage)

When `/admin/*` is broken or “Loading session…” spins:

1. **Check the Auth Debug page**
   - Visit `/admin/auth-debug`.
   - Confirm:
     - WorkOS `user` is non-null
     - WorkOS token hook `error` is null
     - “Fetch Token” returns claims (JWT decodes)
     - Convex shows `authenticated: true`
2. **Inspect JWT claims**
   - From `/admin/auth-debug`, verify:
     - `iss` matches a WorkOS issuer that Convex accepts (see `packages/backend/convex/auth.config.ts`)
     - `aud` includes your WorkOS client id for AuthKit tokens (Convex config uses `applicationID` for shared issuers)
3. **Look for unexpected requests that mutate auth**
   - Browser network/HAR: watch for any background `GET /sign-out`.
   - This can happen due to Next `<Link>` prefetching route handlers.
4. **Check Convex production logs (if prod only)**
   - `npx convex logs --prod --tail`
   - Watch for Unauthorized / JWKS / issuer mismatches.
5. **Check Vercel runtime logs (if prod only)**
   - If you see `TokenRefreshError` 429 rate limits or `invalid_grant` “session ended”, focus on refresh storms (see below).
6. **Sanity-check the Convex URL**
   - A wrong/empty `NEXT_PUBLIC_CONVEX_URL` can look like “Convex never authenticates”.
   - Quick signal: `https://<deployment>.convex.cloud/api/query` should exist (a non-existent deployment commonly returns 404).

## Failure Modes We Hit (Symptoms -> Root Cause -> Fix)

### 1) Preview `redirect-uri-invalid` in WorkOS

**Symptoms**
- WorkOS hosted UI shows `redirect-uri-invalid` (or login loops back to sign-in).

**Root cause**
- WorkOS redirect URIs are exact-match.
- On Vercel previews, `request.nextUrl.origin` can be a branch alias domain that does not match the canonical deployment domain used in WorkOS config.

**Fix**
- Configure preview redirect URIs using Vercel’s canonical deployment domain:
  - `packages/backend/convex.json` uses `buildEnv.VERCEL_URL` for preview `redirectUris`, `corsOrigins`, `appHomepageUrl`.
- Compute the redirect URI in middleware/proxy using `VERCEL_URL` when `VERCEL_ENV=preview`:
  - `apps/web/src/proxy.ts` uses `https://${VERCEL_URL}` for previews, otherwise uses `request.nextUrl.origin`.

### 2) Prod “Loading session…” loop / `/admin` keeps thrashing

**Symptoms**
- `/admin/*` flashes then spins.
- `/admin/auth-debug` shows WorkOS user but Convex `authenticated: false`, token `loading` flips.
- Vercel logs show WorkOS refresh failures (429 rate limit or `invalid_grant`).

**Root cause**
- Convex can retry auth quickly; if `fetchAccessToken()` always forces refresh, WorkOS can rate limit token refresh, or a refresh can fail after a session ends, trapping the UI in a loading loop.

**Fix**
- In `apps/web/src/components/providers.tsx`:
  - Ignore Convex’s `forceRefreshToken` and call WorkOS `getAccessToken()` (which refreshes when needed).
  - Treat WorkOS token hook errors as “not authenticated” so the UI can route the user back through sign-in instead of spinning forever.

### 3) Users were getting logged out “by themselves”

**Symptoms**
- Random sign-outs or sudden redirects to sign-in.
- HAR/network shows background `GET /sign-out` (often with an RSC prefetch request header).

**Root cause**
- Next.js `<Link>` prefetch can issue background GETs to route handlers. If the route handler has side effects (like `GET /sign-out`), you can log users out via prefetch.

**Fix**
- Disable prefetch on the sign-out link:
  - `apps/web/src/components/header.tsx` sets `prefetch={false}` for the “Sign Out” link.
- Longer-term pattern: avoid GET side-effects for auth mutations (or ensure the UI uses a POST-only server action).

## Convex CLI Notes (Prod / Preview)

- Tail logs:
  - `npx convex logs --prod --tail`
- Run a function to verify auth expectations:
  - `npx convex run --prod tpwdAdmin:listPlans '{}'`
  - If you’re not authenticated, “Unauthorized” is expected. If you *are* authenticated in the browser but see auth failures, focus on the JWT issuer/JWKS configuration and token fetch path.

## Local Debugging With d3k (dev3000)

If you have the `d3k` tooling available in this repo, it can drastically speed up “what is the browser doing vs what is the server doing” correlation:

```bash
d3k errors --context
d3k logs --type browser
d3k logs --type server
```

## Operational Guardrails

- Keep `/admin/auth-debug` around. It’s the quickest way to disambiguate:
  - “WorkOS session missing” vs “WorkOS token missing” vs “Convex rejecting token”.
- Treat preview/prod URL differences as first-class:
  - Redirect URIs, CORS origins, and `appHomepageUrl` must match what the user’s browser actually hits.
- Avoid auth mutations in GET routes if any UI element can prefetch them.
