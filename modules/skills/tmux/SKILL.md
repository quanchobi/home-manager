---
name: tmux
description: Create and drive tmux panes, windows, and sessions — run commands where the user can watch, wait for them to finish or print something, read pane output, and operate interactive CLIs/TUIs in other panes. Use when the user mentions tmux/panes/windows, or when work benefits from a visible, persistent, or user-attachable terminal. For coding agents (omp, Claude Code, Codex) in panes, also use the agent-indicator skill.
---

# tmux control

Everything below goes through the `tmux` CLI from your bash tool. Every tmux call returns immediately; nothing attaches.

## Check first

```bash
test -n "${TMUX:-}" && test -n "${TMUX_PANE:-}" && echo "self=$TMUX_PANE"
```

If this fails, you are not running inside tmux: say so and stop, unless the user explicitly asked you to manage a tmux server from outside. Your own pane is `$TMUX_PANE`.

## When to use

- User asks for a pane/window/session, or to run/watch something "in tmux".
- Long-running or interactive work the user should see or take over: dev servers, watchers, REPLs, debuggers, TUIs.
- Reading or nudging something already running in one of the user's panes.
- Coding agents in panes: create the pane here, then follow the agent-indicator skill (`tmux-agent`) when `tmux show-environment -g TMUX_AGENT_INDICATOR_DIR` succeeds. Without the plugin, drive them as interactive programs (below).

Not for: one-off commands or background jobs only you consume — use your own bash/background jobs; they are simpler and don't clutter the user's screen.

## Rules

1. **Never send input to `$TMUX_PANE`.** That types into your own input.
2. **Address panes by ID** (`%N`), read from creation output or listings. Never derive targets from window/pane indices or examples; indices shift when windows close (if `renumber-windows` is on).
3. **Don't steal focus.** Always `-d` on `new-window`/`split-window`/`new-session`. Only `select-window`/`select-pane`/`switch-client` when the user asks.
4. **Ownership.** Tag panes you create with `@agent_owner`. Without explicit user instruction: never type into, `C-c`, or close a pane, window, or session you didn't create, and never `kill-server`.
5. **Look before typing.** Check `pane_current_command` and `pane_in_mode` first (see below).
6. **Placement.** Honor what the user asked for. Otherwise use a sibling pane next to yours in your working directory (placement rule below). Create windows, sessions, or other directories only when asked, or when your pane is too small to split. Tell the user the pane ID you created.
7. **Agent CLIs.** Never run `omp`/`claude`/`codex` from your own shell with tmux variables inherited; see the headless rule in the agent-indicator skill.
8. **A timeout doesn't prove nothing happened.** Read the pane before re-sending a command or input.

## Orient

```bash
tmux list-panes -a -F '#{pane_id} #{session_name}:#{window_index}.#{pane_index} #{window_name} cmd=#{pane_current_command} active=#{pane_active} size=#{pane_width}x#{pane_height} cwd=#{pane_current_path}'
tmux list-panes -a -f "#{==:#{@agent_owner},$TMUX_PANE}" -F '#{pane_id} #{window_name} cmd=#{pane_current_command}'   # panes you own
```

## Create

Placement rule: split wide panes to the right and tall or narrow panes down, keeping each half usable (≥ 80 columns side by side, ≥ 12 rows stacked). If neither fits, use a new background window right after yours.

```bash
read -r w h < <(tmux display -p -t "$TMUX_PANE" '#{pane_width} #{pane_height}')
if [ $((w / 2)) -ge 80 ]; then
  P=$(tmux split-window -d -h -t "$TMUX_PANE" -c "$PWD" -P -F '#{pane_id}')
elif [ $((h / 2)) -ge 12 ]; then
  P=$(tmux split-window -d -v -t "$TMUX_PANE" -c "$PWD" -P -F '#{pane_id}')
else
  W=$(tmux display -p -t "$TMUX_PANE" '#{window_id}')
  P=$(tmux new-window -d -a -t "$W" -n NAME -c "$PWD" -P -F '#{pane_id}')
fi
tmux set -p -t "$P" @agent_owner "$TMUX_PANE"
```

When asked for one explicitly:

```bash
P=$(tmux new-window -d -a -t "$W" -n NAME -c "$PWD" -P -F '#{pane_id}')   # window (W as above)
P=$(tmux new-session -d -s NAME -c "$PWD" -P -F '#{pane_id}')             # session; user joins with: tmux switch-client -t NAME
```

`new-window -t` takes a window or session, not a pane ID — hence the `window_id` lookup. `-n NAME` stops tmux from renaming the window automatically.

## Run a command and wait for it

The pane runs the user's interactive shell. Wait until it shows a prompt (`pane_current_command` is the shell), then type the command followed by a sentinel. The sentinel records the exit status on the pane and signals a unique `wait-for` channel:

```bash
CH=agent-$RANDOM
tmux set -pqu -t "$P" @agent_rc
tmux send-keys -t "$P" -l -- " make test; tmux set -p -t $P @agent_rc \$?; tmux wait-for -S $CH"
tmux send-keys -t "$P" Enter
timeout 600 tmux wait-for "$CH"; echo "wait=$?"   # 0 = finished, 124 = still running
tmux show -pqv -t "$P" @agent_rc                  # exit status (empty if not finished)
```

- `-t $P` in the sentinel is required: a bare `tmux set -p` inside the pane targets the session's _active_ pane, not the one running the command.
- Use a fresh channel per run. `wait-for -S` latches if nobody is waiting yet, so there is no race, but a stale unconsumed signal on a reused name would release the next wait immediately.
- Keep `timeout` below your bash tool's own deadline. On 124 the command is still running; read output and decide whether to wait again, interrupt, or report.
- The command must be a single line. The leading space keeps it out of history (if `histignorespace` is on).
- The sentinel is visible in the pane. That's expected; don't hide it.

For a process you didn't start (e.g. the user's build), poll instead: it's done when `pane_current_command` is back to the shell.

## Wait for output

Wait until the pane prints something, such as a server's "listening" line or a test summary. The check covers output already on screen, so text printed before you started waiting still matches:

```bash
found=0
for i in $(seq 120); do                                               # ~2 min cap
  tmux capture-pane -p -J -t "$P" -S -200 | grep -qE -- '^test result' && { found=1; break; }   # -F for a literal
  sleep 1
done; echo "found=$found"
```

The capture also contains the command line you typed and everything earlier in the pane, and those match too. A test that echoed `'test result: ok'` matched its own command line before the output appeared. Anchor the pattern (`^…`) or choose text the command line doesn't contain, and use a fresh pane when earlier runs could match.

## Read output

| Want                                                 | Command                                             |
| ---------------------------------------------------- | --------------------------------------------------- |
| Current screen                                       | `tmux capture-pane -p -t "$P"`                      |
| Recent output, soft wraps joined (logs, transcripts) | `tmux capture-pane -p -J -t "$P" -S -120 \| cat -s` |
| Recent output as rendered (wraps kept)               | `tmux capture-pane -p -t "$P" -S -120 \| cat -s`    |
| Colors/styling as evidence                           | add `-e`                                            |
| Full scrollback (huge; filter it)                    | `-S -`                                              |

`-S -N` starts N lines above the visible screen; `cat -s` squeezes the blank padding below the last output. Full-screen programs on the alternate screen (vim, less, htop) have no scrollback, only their visible screen.

For long or continuous output (builds, server logs), mirror the pane to a file and read the file:

```bash
tmux pipe-pane -o -t "$P" "cat >> /tmp/agent-${P#%}.log"   # -o: only if not already piping; `tmux pipe-pane -t "$P"` stops it
sed -E 's/\x1b\[[0-9;?]*[ -\/]*[@-~]//g; s/\x1b[=>]//g; s/\r//g' "/tmp/agent-${P#%}.log" | cat -s
```

- tmux format-expands the pipe command, so keep `%` and `#` out of it (`/tmp/agent-%14.log` silently breaks; hence `${P#%}`).
- The log is raw terminal bytes. Fine for streaming output once escapes are stripped; useless for TUIs and line editors that redraw — use `capture-pane` for those.

## Drive interactive programs (REPLs, TUIs)

- Send literal text with `-l`, then `Enter` as a **separate** call. Combining them can trigger paste/multiline handling in TUIs.
- Multi-line text: paste it as one bracketed paste, then send Enter: `printf '%s' "$text" | tmux load-buffer -b agent - && tmux paste-buffer -p -d -b agent -t "$P"`.
- Special keys are separate arguments: `Enter`, `Escape`, `C-c`, `C-d`, `Up`, `Tab`, `BSpace`. Unknown key names are typed literally, so `esc` types "esc".
- If `#{pane_in_mode}` is `1`, the pane is in copy mode (someone may be scrolling it) and keys go to copy mode. In your own panes, leave it with `tmux send-keys -t "$P" -X cancel`; otherwise ask.

```bash
tmux display -p -t "$P" 'cmd=#{pane_current_command} mode=#{pane_in_mode}'
tmux send-keys -t "$P" -l -- "print(6*7)"
sleep 0.1
tmux send-keys -t "$P" Enter
```

Interactive programs give no completion signal. Poll every 2–5 s (don't spin), with a cap, until the program's prompt or idle marker is the last non-blank line:

```bash
for i in $(seq 60); do   # ~2 min cap
  tmux capture-pane -p -t "$P" | awk 'NF{l=$0} END{exit !(l ~ /^>>> *$/)}' && break   # adjust the prompt regex
  sleep 2
done
```

Output unchanged between two polls does **not** mean done; a silent computation looks identical. Only fall back to "unchanged for several consecutive polls" when the program has no recognizable prompt, and say so when reporting.

Before answering a program's confirmation prompt (`y/n`, permission dialogs), confirm that matches what the user asked for.

## Clean up

```bash
tmux send-keys -t "$P" C-c          # stop the foreground job (your panes only)
tmux kill-pane -t "$P"              # remove your pane when its work is done and the user doesn't need it
```

Leave panes the user may want to inspect (servers, failed runs) open, and say so.
