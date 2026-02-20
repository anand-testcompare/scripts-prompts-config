---
name: openai-image-generation
description: Generate or edit images with OpenAI's Images API without Python. Use when the user asks to create, generate, modify, or inpaint images and wants a CLI workflow runnable with `sh` or `bun` from any directory via an absolute script path.
---

# OpenAI Image Generation

Use this skill to generate new images or edit existing images with OpenAI APIs using bundled shell tooling.

## Commands

Run scripts by absolute path. Do not `cd` into the skill directory.

Generate a new image:
```bash
sh ~/.agents/skills/openai-image-generation/scripts/generate_image.sh \
  --prompt "A poster of a red panda astronaut" \
  --filename "2026-02-20-red-panda-astronaut.png" \
  --quality high \
  --size 1536x1024
```

Edit an existing image:
```bash
sh ~/.agents/skills/openai-image-generation/scripts/generate_image.sh \
  --prompt "Make this look like a watercolor painting" \
  --filename "2026-02-20-watercolor.png" \
  --input-image "./source.png"
```

Edit with mask (inpainting):
```bash
sh ~/.agents/skills/openai-image-generation/scripts/generate_image.sh \
  --prompt "Replace masked area with a neon sign" \
  --filename "2026-02-20-neon-edit.png" \
  --input-image "./source.png" \
  --mask "./mask.png"
```

Equivalent Bun wrapper:
```bash
bun ~/.agents/skills/openai-image-generation/scripts/generate_image.ts --prompt "..." --filename "..."
```

Always run from the user's working directory so relative output paths save where the user is working.

## Options

Required:
- `--prompt` / `-p`: generation or editing prompt.
- `--filename` / `-f`: output image path.

Editing:
- `--input-image` / `-i`: source image file to edit.
- `--mask` / `-m`: optional PNG mask for inpainting.

Generation controls:
- `--quality` / `-q`: `low|medium|high` (default `medium`).
- `--size` / `-s`: `1024x1024|1024x1536|1536x1024|auto` (default `1024x1024`).
- `--background` / `-b`: `transparent|opaque|auto` (default `auto`, generation only).

Common:
- `--model`: defaults to `gpt-image-1`.
- `--api-key` / `-k`: overrides `OPENAI_API_KEY`.

## API Key Resolution

Script checks:
1. `--api-key`
2. `OPENAI_API_KEY`

If neither is set, fail fast with an actionable error.

## Output and Filenames

Default filename pattern:
- `yyyy-mm-dd-hh-mm-ss-short-description.png`

Examples:
- `2026-02-20-16-11-03-japanese-garden.png`
- `2026-02-20-16-13-20-logo-mascot.png`

Script prints the final saved path. Do not read the image file back unless user explicitly asks.

## Script
- `scripts/generate_image.sh`: main implementation.
- `scripts/generate_image.ts`: Bun wrapper that forwards args to the shell script.
