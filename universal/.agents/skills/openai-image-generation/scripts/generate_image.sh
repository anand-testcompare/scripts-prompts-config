#!/usr/bin/env sh
set -eu

usage() {
  cat <<'EOF'
Generate or edit images with OpenAI Images API.

Usage:
  Generate:
    sh .../generate_image.sh --prompt "text" --filename "output.png" [options]

  Edit:
    sh .../generate_image.sh --prompt "edit instruction" --filename "output.png" --input-image "input.png" [--mask "mask.png"] [options]

Options:
  -p, --prompt         Required prompt text
  -f, --filename       Required output path
  -i, --input-image    Optional source image for edits
  -m, --mask           Optional mask image for inpainting edits
  -q, --quality        low|medium|high (default: medium)
  -s, --size           1024x1024|1024x1536|1536x1024|auto (default: 1024x1024)
  -b, --background     transparent|opaque|auto (default: auto, generation only)
      --model          Image model (default: gpt-image-1)
  -k, --api-key        OpenAI API key (fallback: OPENAI_API_KEY env var)
  -h, --help           Show this help
EOF
}

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

validate_choice() {
  value="$1"
  name="$2"
  allowed="$3"
  case " $allowed " in
    *" $value "*) ;;
    *) die "Invalid $name '$value'. Allowed: $allowed" ;;
  esac
}

decode_base64_to_file() {
  b64="$1"
  out="$2"
  if printf '%s' "$b64" | base64 --decode >"$out" 2>/dev/null; then
    return 0
  fi
  if printf '%s' "$b64" | base64 -D >"$out" 2>/dev/null; then
    return 0
  fi
  die "Unable to decode base64 output with system base64 command."
}

full_path() {
  path="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath "$path"
    return 0
  fi
  dir=$(cd "$(dirname "$path")" && pwd)
  printf '%s/%s\n' "$dir" "$(basename "$path")"
}

PROMPT=""
FILENAME=""
INPUT_IMAGE=""
MASK=""
QUALITY="medium"
SIZE="1024x1024"
BACKGROUND="auto"
MODEL="gpt-image-1"
API_KEY_ARG=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    -p|--prompt)
      [ "$#" -ge 2 ] || die "Missing value for $1"
      PROMPT="$2"
      shift 2
      ;;
    -f|--filename)
      [ "$#" -ge 2 ] || die "Missing value for $1"
      FILENAME="$2"
      shift 2
      ;;
    -i|--input-image)
      [ "$#" -ge 2 ] || die "Missing value for $1"
      INPUT_IMAGE="$2"
      shift 2
      ;;
    -m|--mask)
      [ "$#" -ge 2 ] || die "Missing value for $1"
      MASK="$2"
      shift 2
      ;;
    -q|--quality)
      [ "$#" -ge 2 ] || die "Missing value for $1"
      QUALITY="$2"
      shift 2
      ;;
    -s|--size)
      [ "$#" -ge 2 ] || die "Missing value for $1"
      SIZE="$2"
      shift 2
      ;;
    -b|--background)
      [ "$#" -ge 2 ] || die "Missing value for $1"
      BACKGROUND="$2"
      shift 2
      ;;
    --model)
      [ "$#" -ge 2 ] || die "Missing value for $1"
      MODEL="$2"
      shift 2
      ;;
    -k|--api-key)
      [ "$#" -ge 2 ] || die "Missing value for $1"
      API_KEY_ARG="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

[ -n "$PROMPT" ] || die "--prompt is required"
[ -n "$FILENAME" ] || die "--filename is required"

if [ -n "$MASK" ] && [ -z "$INPUT_IMAGE" ]; then
  die "--mask requires --input-image"
fi

if [ -n "$INPUT_IMAGE" ] && [ ! -f "$INPUT_IMAGE" ]; then
  die "Input image not found: $INPUT_IMAGE"
fi

if [ -n "$MASK" ] && [ ! -f "$MASK" ]; then
  die "Mask image not found: $MASK"
fi

validate_choice "$QUALITY" "quality" "low medium high"
validate_choice "$SIZE" "size" "1024x1024 1024x1536 1536x1024 auto"
validate_choice "$BACKGROUND" "background" "transparent opaque auto"

API_KEY="${API_KEY_ARG:-${OPENAI_API_KEY:-}}"
[ -n "$API_KEY" ] || die "No API key set. Use --api-key or OPENAI_API_KEY."

require_cmd curl
require_cmd jq
require_cmd base64

output_dir=$(dirname "$FILENAME")
mkdir -p "$output_dir"

response_json="$(mktemp -t openai-image-response.XXXXXX.json)"
trap 'rm -f "$response_json"' EXIT INT TERM

if [ -z "$INPUT_IMAGE" ]; then
  payload="$(
    jq -cn \
      --arg model "$MODEL" \
      --arg prompt "$PROMPT" \
      --arg size "$SIZE" \
      --arg quality "$QUALITY" \
      --arg background "$BACKGROUND" \
      '{
        model: $model,
        prompt: $prompt
      }
      + (if $size == "auto" then {} else {size: $size} end)
      + {quality: $quality}
      + (if $background == "auto" then {} else {background: $background} end)'
  )"

  curl -sS "https://api.openai.com/v1/images/generations" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    >"$response_json"
else
  if [ -n "$MASK" ]; then
    if [ "$SIZE" = "auto" ]; then
      curl -sS "https://api.openai.com/v1/images/edits" \
        -H "Authorization: Bearer $API_KEY" \
        -F "model=$MODEL" \
        -F "prompt=$PROMPT" \
        -F "image=@$INPUT_IMAGE" \
        -F "mask=@$MASK" \
        >"$response_json"
    else
      curl -sS "https://api.openai.com/v1/images/edits" \
        -H "Authorization: Bearer $API_KEY" \
        -F "model=$MODEL" \
        -F "prompt=$PROMPT" \
        -F "size=$SIZE" \
        -F "image=@$INPUT_IMAGE" \
        -F "mask=@$MASK" \
        >"$response_json"
    fi
  else
    if [ "$SIZE" = "auto" ]; then
      curl -sS "https://api.openai.com/v1/images/edits" \
        -H "Authorization: Bearer $API_KEY" \
        -F "model=$MODEL" \
        -F "prompt=$PROMPT" \
        -F "image=@$INPUT_IMAGE" \
        >"$response_json"
    else
      curl -sS "https://api.openai.com/v1/images/edits" \
        -H "Authorization: Bearer $API_KEY" \
        -F "model=$MODEL" \
        -F "prompt=$PROMPT" \
        -F "size=$SIZE" \
        -F "image=@$INPUT_IMAGE" \
        >"$response_json"
    fi
  fi
fi

api_error="$(jq -r '.error.message // empty' "$response_json")"
if [ -n "$api_error" ]; then
  die "OpenAI API error: $api_error"
fi

b64="$(jq -r '.data[0].b64_json // empty' "$response_json")"
[ -n "$b64" ] || die "OpenAI response did not include image data."

decode_base64_to_file "$b64" "$FILENAME"
printf 'Image saved: %s\n' "$(full_path "$FILENAME")"
