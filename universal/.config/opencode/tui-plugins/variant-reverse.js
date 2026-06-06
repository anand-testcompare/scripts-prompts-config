import { readFileSync } from "node:fs"
import { join } from "node:path"

const command = "scryu.variant.reverse"
const defaultKey = { name: ",", meta: true }
const fallbackSteps = 59

function parseModel(value) {
  if (typeof value !== "string") return undefined
  const [providerID, ...rest] = value.split("/")
  const modelID = rest.join("/")
  if (!providerID || !modelID) return undefined
  return { providerID, modelID }
}

function recentModel(api) {
  try {
    const file = join(api.state.path.state, "model.json")
    const state = JSON.parse(readFileSync(file, "utf8"))
    const recent = Array.isArray(state.recent) ? state.recent[0] : undefined
    if (typeof recent?.providerID === "string" && typeof recent?.modelID === "string") return recent
  } catch {
    return undefined
  }
}

function currentModel(api) {
  return recentModel(api) ?? parseModel(api.state.config.model)
}

function variantCount(api) {
  const model = currentModel(api)
  if (!model) return 0
  const provider = api.state.provider.find((item) => item.id === model.providerID)
  const variants = provider?.models?.[model.modelID]?.variants
  return variants && typeof variants === "object" ? Object.keys(variants).length : 0
}

function reverseStepCount(api) {
  const count = variantCount(api)
  if (!count) return undefined
  // OpenCode cycles default -> variants... -> default, so reverse is N forward steps.
  return count
}

function dispatchForward(api) {
  if (api.keymap?.dispatchCommand) {
    api.keymap.dispatchCommand("variant.cycle")
    return
  }
  if (api.command?.trigger) {
    api.command.trigger("variant.cycle")
    return
  }
  throw new Error("No OpenCode TUI command dispatcher available")
}

function reverseVariant(api, options) {
  const configuredSteps = Number.isInteger(options?.steps) && options.steps > 0 ? options.steps : undefined
  const steps = configuredSteps ?? reverseStepCount(api) ?? fallbackSteps
  for (let i = 0; i < steps; i += 1) dispatchForward(api)
}

export default {
  id: "scryu.variant-reverse",
  async tui(api, options) {
    const key = options?.key ?? defaultKey

    if (api.keymap?.registerLayer) {
      api.keymap.registerLayer({
        commands: [
          {
            name: command,
            title: "Variant cycle reverse",
            category: "Agent",
            namespace: "palette",
            hidden: true,
            run: () => reverseVariant(api, options),
          },
        ],
        bindings: [{ key, cmd: command, desc: "Previous model variant" }],
      })
      return
    }

    if (api.command?.register) {
      api.command.register(() => [
        {
          title: "Variant cycle reverse",
          value: command,
          category: "Agent",
          hidden: true,
          keybind: options?.legacyKey ?? "alt+,",
          onSelect: () => reverseVariant(api, options),
        },
      ])
      return
    }

    throw new Error("No OpenCode TUI command registration API available")
  },
}
