- Do not assume or guess facts, APIs, configs, or behavior you are not certain about. When unsure, research first (read the code, check docs, search) before answering. If you cannot verify something, say so explicitly rather than presenting a guess as fact.

- Before marking any task as done, re-read the user's original request and verify every criterion was actually met. Do not stop at "good enough" — check each specific ask against what was delivered. If something was missed or only partially addressed, fix it before declaring completion.

- we should never resort to a dummy/mocked result in the event of some type of failure. masking errors is counter productive and its critical we instead gracefully catch the errors and expose them so they can be fixed, but never just introduce a fallback to a fake dataset because a real result failed.

- Railway monorepo deployment: Leave Root Directory empty and set Dockerfile path to the full path from repo root (e.g., `apps/my-app/Dockerfile`). The Dockerfile should reference files relative to the repo root (e.g., `COPY apps/my-app/package.json ./`). Do NOT set both Root Directory and Dockerfile path as they stack and cause "not found" errors.

- **AI SDK (v6 or @beta)**: Use `ai` or `ai@beta` package only. Do NOT add provider-specific SDKs (`@ai-sdk/openai`, `@ai-sdk/google`, `openai`, `anthropic`, etc. unless specifically requested). However if openrouter is being used `@openrouter/ai-sdk-provider` is acceptable. Pass model strings directly (e.g., `"google/gemini-3.1-flash-lite-preview"`). Env var: `AI_GATEWAY_API_KEY` if using vercel gateway or `OPENROUTER_API_KEY` if using the openrouter provider.

- **Model preferences**:
  - Smart: `google/gemini-3.1-pro-preview`, `openai/gpt-5.4`
  - Medium: `openai/gpt-5.4-mini`, `google/gemini-3.1-flash-lite-preview`, `x-ai/grok-4.20-beta`
  - Fast: `nvidia/nemotron-3-super-120b-a12b`, `openai/gpt-5.4-nano`
