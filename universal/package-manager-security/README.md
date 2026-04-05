# Package Manager Supply Chain Security Configs

Quick reference for hardening npm, pnpm, yarn, and bun against supply chain attacks.

## Core Principle

Block **day-zero attacks**: Malicious packages published and removed within hours. A 1-day release age threshold would have blocked the March 2026 axios attack (published ~00:00 UTC, removed ~03:30 UTC).

## Config Files

| File | Location | Package Manager |
|------|----------|----------------|
| `npmrc-reference` | `~/.npmrc` | npm |
| `pnpm-config-reference` | `pnpm config set` or `~/.npmrc` | pnpm |
| `yarnrc-yml-reference` | `~/.yarnrc.yml` | Yarn Berry (v2+) |
| `bunfig-toml-reference` | `~/.bunfig.toml` | Bun |

## Key Settings

### Release Age Protection
- **npm**: `min-release-age=1` (days)
- **pnpm**: `minimumReleaseAge=1440` (minutes)
- **bun**: `minimumReleaseAge = 86400` (seconds, in `[install]` section)
- **yarn**: No release age feature (rely on script disabling)

Important: npm, pnpm, and Bun use different units here. npm uses days, pnpm uses minutes, and Bun uses seconds.

### Script Protection
- **npm**: `ignore-scripts=true` (all-or-nothing, use in CI)
- **pnpm**: `strictDepBuilds=true` + `onlyBuiltDependencies` allowlist
- **yarn**: `enableScripts: false` (per-package re-enable via `dependenciesMeta`)
- **bun**: `trustedDependencies` in package.json (explicit allowlist)

### Additional Protections
- **pnpm**: `blockExoticSubdeps=true` — Blocks non-registry transitive deps
- **pnpm**: `strictDepBuilds=true` — Fails install on unreviewed scripts

## Emergency Override

When you need to install a just-published package from your own org:

```bash
# npm (no per-scope exclusions)
npm install package@version --min-release-age=0

# pnpm (with org in minimumReleaseAgeExclude - no action needed)
pnpm add @yourorg/package@version

# bun (no per-scope exclusions)
# Set in project bunfig.toml: minimumReleaseAge = 0
bun add package@version
```

## CI Best Practices

1. **Use frozen lockfiles**: `npm ci`, `pnpm install --frozen-lockfile`, `bun install --frozen-lockfile`
2. **Lockfiles bypass age checks** — once pinned, reinstalls work immediately
3. **Keep strict settings in CI** — only override on dev machines for fresh installs

## Reference

- npm `min-release-age`: https://docs.npmjs.com/cli/v11/commands/npm-install
- pnpm `minimumReleaseAge`: https://pnpm.io/settings#minimumreleaseage
- Bun `minimumReleaseAge`: https://bun.sh/docs/runtime/bunfig
