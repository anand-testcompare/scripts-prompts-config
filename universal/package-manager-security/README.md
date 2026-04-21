# Package Manager Security Configs

Keep it simple:

- **npm**: do **not** use `min-release-age` in `~/.npmrc`
- **pnpm**: use `pnpm-config-reference` in `~/.config/pnpm/rc`
- **bun**: use `bunfig-toml-reference` in `~/.bunfig.toml`
- **yarn**: use `yarnrc-yml-reference` in `~/.yarnrc.yml`

## Standard defaults

### pnpm
```ini
minimum-release-age=1440
minimum-release-age-exclude="[\"@nyrra\", \"@openontology\", \"@openai\", \"@shpitdev\", \"@sketchi-app\"]"
block-exotic-subdeps=true
strict-dep-builds=true
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

- `pnpm` uses **minutes** for release age
- `bun` uses **seconds** for release age
- `npm` is **not** part of the standard persistent release-age setup anymore
- prefer lockfiles in CI: `npm ci`, `pnpm install --frozen-lockfile`, `bun install --frozen-lockfile`
