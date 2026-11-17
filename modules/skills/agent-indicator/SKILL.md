---
name: agent-indicator
description: Inspect and drive coding agents (omp, Claude Code, Codex) running in tmux panes through tmux-agent-indicator state — list agents and whether they are running, blocked on input, or done; start an agent in a pane; prompt it and wait; handle its approvals. Also the rule for launching agent CLIs headlessly. Use when asked to start, prompt, check on, or coordinate another agent in tmux, and before running omp/claude/codex from a shell.
---

# Agents in tmux (tmux-agent-indicator)

tmux-agent-indicator is a tmux plugin. Agent hooks (the omp extension, Claude Code hooks, Codex hooks) report each agent's state into the tmux global environment, keyed by pane. `tmux-agent` (on `PATH`; source in this skill's `scripts/`) reads that state and drives the agent's pane. Pane creation and plain commands belong to the `tmux` skill.

## Check first

`tmux-agent` refuses to run unless you are inside tmux and the plugin is loaded:

```bash
tmux-agent list
```

If it reports that you are not inside tmux, say so and stop; don't control a tmux server from outside it. If the plugin is not loaded, agent state is unavailable: drive the agent as a plain interactive program (see the `tmux` skill).

## Headless rule

Never run an agent CLI (`omp`, `claude`, `codex`, …) from your own shell with the tmux variables inherited. Its hooks report state into whatever pane `$TMUX_PANE` names — yours — and leave stale running/done markers in the user's status bar. Either start it in its own pane (below), or strip the variables:

```bash
env -u TMUX -u TMUX_PANE omp -p "…"
env -u TMUX -u TMUX_PANE claude -p "…"
```

The hooks do nothing when `TMUX` is unset. This applies to any child agent you spawn from a shell, including inside scripts.

## States

| State | Meaning |
|---|---|
| `running` | A turn is in progress. |
| `needs-input` | Blocked on an approval or question dialog. |
| `done` | The last turn finished and the user hasn't looked at that pane yet. |
| `idle` | Nothing recorded: the agent hasn't run a turn since starting, or it finished and the user has since focused its pane or window (focusing clears `done`). |

States come only from agents whose hooks are installed (omp, Claude Code, Codex). Other agents in `@agent-indicator-processes` (aider, cursor, opencode) are listed but always `idle`. `prompt --wait` reports them as stalled, so use the `tmux` skill's prompt polling for those.

`idle` and `done` usually mean ready for input, but neither proves the agent is in the foreground or that an unrecognized dialog isn't open. Read the pane before typing into it.

## Discover

```bash
tmux-agent list            # PANE NAME AGENT STATE LOCATION CWD; * marks your own pane
tmux-agent get reviewer    # key=value: pane, name, cmd, location, cwd, size, in_mode, owner, agent, state, self
```

Targets are a pane ID (`%N`) or an agent name. Names match `[a-z][a-z0-9_-]{0,31}` and are unique among live agents. A name is a pane label (`@agent_name`). It stays on the pane after the agent exits, but then commands that need an agent fail on it, and reusing the name for another pane takes it over. `tmux-agent name %N -` clears one.

## Start an agent

Default placement: a sibling pane next to yours, in your working directory, without taking focus. Create it with the `tmux` skill's placement rule, then start the agent in that pane. Use another window, session, or directory only when the user asks for it.

```bash
tmux-agent start reviewer --kind omp --pane "$P"                 # kind = the agent's command
tmux-agent start reviewer --kind claude --pane "$P" -- --model sonnet   # native args after --
```

`start` requires the pane to sit at a shell prompt (shell in the foreground, not in copy mode). It names the pane, types the command, and returns once the agent owns the foreground and its screen has stopped changing (default timeout 30 s). Exit 3 means a dialog blocked startup: read the pane and ask the user. Use the kind the user asked for.

## Prompt and wait

```bash
tmux-agent prompt reviewer "Review the current diff; report only actionable findings." --wait --timeout 900
tmux-agent prompt reviewer - --wait < /tmp/brief.md      # long or multi-line prompts from stdin
```

- The text goes in as one bracketed paste followed by Enter, so multi-line prompts arrive as a single message.
- An agent at `needs-input` is rejected (exit 3) before anything is sent. Read the dialog and ask the user before answering it.
- A `done` state from the previous turn is cleared before sending, so with `--wait` any new state proves the prompt landed. No state within 5 s → exit 4, stalled.
- `--wait` then returns at the first settled state: `state=done` (exit 0), `state=done seen=1` (finished, and the user already looked), or `state=needs-input` (exit 3).
- Prompting an agent that is still `running` adds to its current turn (omp treats it as steering); the wait then covers that turn.
- A timeout (124) or stall (4) does **not** prove the prompt wasn't delivered. Read the pane before deciding to resend; never resend blindly.

Wait separately:

```bash
tmux-agent wait reviewer --timeout 600                  # settled: done | idle | needs-input (3)
tmux-agent wait reviewer --until needs-input --timeout 600
tmux-agent wait reviewer --changed --timeout 600        # first wait for the current state to change
```

Use `--changed` right after `keys`: the old `needs-input` stays visible until the agent's hooks catch up, so a plain `wait` would return it immediately.

## Dialogs, keys, and output

```bash
tmux-agent read reviewer --lines 120     # last N lines, soft wraps joined
tmux-agent read reviewer --visible       # the current screen (dialogs, menus)
tmux-agent read reviewer --ansi          # keep colors when styling is evidence
tmux-agent keys reviewer Down Enter      # tmux key names: Enter Escape C-c Up Down Tab y …
tmux-agent wait reviewer --changed
```

`keys` validates every key name before sending anything; send text with `prompt`, not `keys`. For `needs-input`, read the dialog, relay it to the user, and answer it only as they say, or as they already told you to.

If a long reply has scrolled out of reach, ask the agent to write it to a Markdown file under `/tmp` and reply with only the path, then read the file. Use this as a fallback; don't ask for file output in the first prompt.

## Finish

Exit an agent you started with `tmux-agent prompt reviewer /exit` (omp; `/exit` also works in Claude Code). That clears its indicator state; then close the pane with the `tmux` skill if the user doesn't need it.

## Rules

- Never send input to your own pane; `tmux-agent` refuses it.
- Address agents by name or `%N` from `list`/`start` output, never by window index or position.
- Don't prompt, interrupt, or exit agents you didn't start unless the user asks. The panes in `list` are mostly the user's own sessions.
- Exit codes: 0 ok, 1 error, 2 usage, 3 needs-input, 4 stalled, 124 timeout. On anything but 0, read the pane before acting.
