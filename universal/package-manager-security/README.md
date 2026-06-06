# Package Manager Security Configs

Keep it simple:

- **pnpm 11 is the default package manager**. Use Corepack to activate pnpm 11 and keep persistent install policy in pnpm's user config.
- **npm**: do **not** use `min-release-age` or `--before` workarounds in `~/.npmrc`.
- **bun**: use `bunfig-toml-reference` in `~/.bunfig.toml` when needed.
- **yarn**: use `yarnrc-yml-reference` in `~/.yarnrc.yml` when needed.

## Standard defaults

### pnpm 11

macOS user config path:
- `~/Library/Preferences/pnpm/config.yaml`

Linux/Omarchy user config path:
- `~/.config/pnpm/config.yaml`

Reference file:
- `pnpm-config-yaml-reference`

```yaml
globalBinDir: ~/Library/pnpm
minimumReleaseAge: 1440
minimumReleaseAgeExclude: '["@nyrra/*","@openontology/*","@openai/*","@shpitdev/*","@sketchi-app/*","@pnpm/*"]'
blockExoticSubdeps: true
strictDepBuilds: true
```

### bun
```toml
[install]
minimumReleaseAge = 86400
```

### yarn
```yaml
enableScripts: false
```

## Notes

- `pnpm` uses **minutes** for release age.
- `bun` uses **seconds** for release age.
- Prefer lockfiles in CI: `pnpm install --frozen-lockfile`, `bun install --frozen-lockfile`, or `npm ci` only for npm-owned projects.
- On macOS, run `osx/scripts/configure_pnpm_defaults.sh` to activate `pnpm@11.5.1` and write the config.
