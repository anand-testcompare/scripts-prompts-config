import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const MERGED_PROMPT = `Switch to main, pull the latest changes, and do a lightweight post-merge check. Verify any production actions, including a smoke test if there is a relevant deployed app or service; otherwise note why it does not apply. Then suggest one sensible next feature or improvement.`;

export default function mergedCommand(pi: ExtensionAPI) {
	pi.registerCommand("merged", {
		description: "Post-merge main pull, prod verification, and next feature prompt",
		handler: async (args, ctx) => {
			const notes = args.trim();
			const prompt = notes ? `${MERGED_PROMPT}\n\nNotes: ${notes}` : MERGED_PROMPT;

			if (ctx.isIdle()) {
				pi.sendUserMessage(prompt);
			} else {
				pi.sendUserMessage(prompt, { deliverAs: "followUp" });
				ctx.ui.notify("Queued /merged follow-up", "info");
			}
		},
	});
}
