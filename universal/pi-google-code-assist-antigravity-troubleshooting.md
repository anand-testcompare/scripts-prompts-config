# Pi + Google providers troubleshooting (Gemini CLI / Antigravity)

This playbook documents what to check and what to set when Pi can use `google-gemini-cli` but fails on `google-antigravity` with errors like:

- `Cloud Code Assist API error (403): The caller does not have permission`
- `Permission "cloudaicompanion.companions.generateCode" denied`

---

## TL;DR fix that worked

1. In `~/.pi/agent/auth.json`, both providers used the same Google account, but **different projects**:
   - `google-gemini-cli` → working project
   - `google-antigravity` → failing project
2. Updated `google-antigravity.projectId` to the same working project.
3. Launched Pi with project vars scoped to Pi process:

```bash
GOOGLE_CLOUD_PROJECT="<WORKING_PROJECT_ID>" \
GOOGLE_CLOUD_PROJECT_ID="<WORKING_PROJECT_ID>" \
pi
```

---

## Why this happens

Pi stores OAuth for each provider separately in `~/.pi/agent/auth.json`.
Even with the same email, provider entries can point to different `projectId` values.

If Antigravity points to a project without required API/IAM setup, requests fail with 403.

---

## Step-by-step checks

### 1) Confirm active Google account and Pi provider projects

```bash
echo "gcloud account: $(gcloud config get-value account 2>/dev/null)"

jq -r '."google-gemini-cli"|"google-gemini-cli  email=\(.email)  project=\(.projectId)"' ~/.pi/agent/auth.json
jq -r '."google-antigravity"|"google-antigravity email=\(.email)  project=\(.projectId)"' ~/.pi/agent/auth.json
```

If the Antigravity project differs from the known-good Gemini CLI project, that is a likely root cause.

### 2) Validate each provider directly via `loadCodeAssist`

> This uses provider OAuth tokens from `~/.pi/agent/auth.json`. Do not share command output publicly if it contains sensitive data.

```bash
for p in google-gemini-cli google-antigravity; do
  PROJECT=$(jq -r ".\"$p\".projectId" ~/.pi/agent/auth.json)
  TOKEN=$(jq -r ".\"$p\".access" ~/.pi/agent/auth.json)

  echo "== $p (project=$PROJECT) =="
  curl -sS 'https://cloudcode-pa.googleapis.com/v1internal:loadCodeAssist' \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -d "{\"cloudaicompanionProject\":\"$PROJECT\",\"metadata\":{\"ideType\":\"IDE_UNSPECIFIED\",\"platform\":\"PLATFORM_UNSPECIFIED\",\"pluginType\":\"GEMINI\",\"duetProject\":\"$PROJECT\"}}" \
  | jq '{currentTier:(.currentTier.id // null), paidTier:(.paidTier.id // null), cloudaicompanionProject, projectValidationError:(.projectValidationError.message // null), deniedPermission:(.projectValidationError.details[0].metadata.permission // null)}'
done
```

Look for:

- `projectValidationError != null`
- `deniedPermission = "cloudaicompanion.companions.generateCode"`

That means the selected project is not entitled/configured correctly for that provider flow.

### 3) Check API enablement for both projects

```bash
for project in $(jq -r '."google-gemini-cli".projectId, ."google-antigravity".projectId' ~/.pi/agent/auth.json | sort -u); do
  echo "-- $project"
  gcloud services list --project "$project" --enabled --format='value(config.name)' \
    | rg 'cloudaicompanion.googleapis.com|geminicloudassist.googleapis.com|cloudcode-pa.googleapis.com' || true
done
```

At minimum, ensure the working project has `cloudaicompanion.googleapis.com` enabled.

### 4) Check IAM (if using org/workspace project model)

```bash
ACCOUNT=$(gcloud config get-value account 2>/dev/null)
PROJECT="<PROJECT_ID>"

gcloud projects get-iam-policy "$PROJECT" \
  --flatten='bindings[].members' \
  --filter="bindings.members:user:${ACCOUNT} AND (bindings.role:roles/cloudaicompanion.user OR bindings.role:roles/serviceusage.serviceUsageConsumer)" \
  --format='table(bindings.role,bindings.members)'
```

Roles to confirm (or grant):

- `roles/cloudaicompanion.user`
- `roles/serviceusage.serviceUsageConsumer`

---

## What to set

### Option A (recommended): Re-auth Antigravity and pick the known-good project

Inside Pi:

1. `/logout` (Google Antigravity)
2. `/login` (Google Antigravity)
3. Select the same project that works for Gemini CLI

### Option B: Patch projectId in Pi auth file (fast local fix)

```bash
AUTH="$HOME/.pi/agent/auth.json"
cp "$AUTH" "$AUTH.bak-$(date +%Y%m%d-%H%M%S)"

jq '."google-antigravity".projectId = "<WORKING_PROJECT_ID>"' "$AUTH" > /tmp/auth.json && mv /tmp/auth.json "$AUTH"
chmod 600 "$AUTH"
```

### Option C: Scope env vars only to Pi process

```bash
GOOGLE_CLOUD_PROJECT="<WORKING_PROJECT_ID>" \
GOOGLE_CLOUD_PROJECT_ID="<WORKING_PROJECT_ID>" \
pi
```

This does not affect other shells/apps globally.

---

## Verification

After changes:

1. Restart Pi
2. Use `/model` and select an Antigravity model
3. If still stale, run `/logout` + `/login` for Antigravity once

Optional API-level verification:

```bash
TOKEN=$(jq -r '."google-antigravity".access' ~/.pi/agent/auth.json)
PROJECT=$(jq -r '."google-antigravity".projectId' ~/.pi/agent/auth.json)

curl -sS 'https://cloudcode-pa.googleapis.com/v1internal:loadCodeAssist' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{\"cloudaicompanionProject\":\"$PROJECT\",\"metadata\":{\"ideType\":\"IDE_UNSPECIFIED\",\"platform\":\"PLATFORM_UNSPECIFIED\",\"pluginType\":\"GEMINI\",\"duetProject\":\"$PROJECT\"}}" \
| jq '{project:.cloudaicompanionProject, projectValidationError:(.projectValidationError.message // null)}'
```

Expected: `projectValidationError: null`.
