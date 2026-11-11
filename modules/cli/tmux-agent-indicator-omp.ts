// Drives tmux-agent-indicator from omp lifecycle events, mirroring the plugin's
// Claude/OpenCode integrations. @agentState@ is replaced by Nix (replaceVars).
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const AGENT_STATE = "@agentState@";

type State = "running" | "needs-input" | "done" | "off";

export default function tmuxAgentIndicator(pi: ExtensionAPI) {
	if (!process.env.TMUX) return;

	let last: State = "off";
	// Serialize calls without blocking omp's event dispatch.
	let queue: Promise<unknown> = Promise.resolve();

	const set = (state: State, { reset = false } = {}) => {
		if (state === last) return;
		last = state;
		const states: State[] = reset ? ["off", state] : [state];
		queue = queue.then(async () => {
			for (const s of states) {
				await pi.exec(AGENT_STATE, ["--agent", "omp", "--state", s]).catch(() => {});
			}
		});
	};

	// Subagent sessions share this factory; only the session in the pane counts.
	const main = (ctx: { agent?: { kind?: string } }) => ctx.agent?.kind !== "sub";

	pi.on("agent_start", (_e, ctx) => {
		if (main(ctx)) set("running", { reset: true });
	});
	pi.on("agent_end", (_e, ctx) => {
		if (main(ctx)) set("done");
	});
	pi.on("tool_approval_requested", (_e, ctx) => {
		if (main(ctx)) set("needs-input");
	});
	pi.on("tool_approval_resolved", (_e, ctx) => {
		if (main(ctx)) set("running");
	});
	pi.on("tool_execution_start", (e, ctx) => {
		if (main(ctx) && e.toolName === "ask") set("needs-input");
	});
	pi.on("tool_execution_end", (e, ctx) => {
		if (main(ctx) && e.toolName === "ask") set("running");
	});
	pi.on("session_shutdown", () => set("off"));
}
