# oh-my-pi (omp) config. There is no home-manager module, so files are placed
# under ~/.omp/agent directly. Host-specific bits live in ./desktop.nix.
{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  # omp rewrites config.yml itself (model selector, /settings), so these keys
  # are merged into it on activation instead of linking a read-only store file.
  # Keys set here win on every switch; everything else omp writes is kept.
  settings = (pkgs.formats.yaml { }).generate "omp-config.yml" {
    symbolPreset = "nerd";
    composer.shape = "band";
    theme.dark = "titanium";
    modelRoles.default = "anthropic/claude-opus-5-5";
    tui.vimMode = true;
    claudeResets.autoRedeem = "yes";
    codexResets.autoRedeem = "yes";
    dev.autoqaConsent = "granted";
  };

  # Task subagents that pin the same implementation brief to one model each.
  devAgent = name: description: models: {
    ".omp/agent/agents/${name}.md".text = ''
      ---
      name: ${name}
      description: ${description}
      model: ${builtins.toJSON models}
      ---

      You are a senior software engineer implementing an assigned slice of a larger change. Read the task and shared
      context fully, research the existing code before editing, reuse existing patterns, and implement the slice end to
      end: no stubs, placeholders or TODOs. Keep edits inside the files your task assigns; coordinate with sibling agents
      named in the context (write agent://<name>) when an interface needs a change, instead of editing their files.
      Verify with the build/test commands given in the context once your edits are complete, and fix what you broke.
      Finish with a concise report: public API shipped (signatures), decisions and deviations from the brief, verification
      actually run with results, and anything integrators must know.
    '';
  };
in
{
  home.file = lib.mkMerge [
    (devAgent "argon-dev"
      "General-purpose implementation agent pinned to Gemini 4 Argon (via OpenRouter)."
      [
        "openrouter/google/gemini-4-argon"
      ]
    )
    (devAgent "astra-dev"
      "General-purpose implementation agent pinned to GPT-6 Astra (via the openai-codex login)."
      [
        "openai-codex/gpt-6-astra"
      ]
    )
    (devAgent "haiku-dev" "General-purpose implementation agent pinned to Claude Haiku 5.5." [
      "anthropic/claude-haiku-5-5"
      "openrouter/anthropic/claude-haiku-5.5"
    ])
    (devAgent "opus-dev" "General-purpose implementation agent pinned to Claude Opus 5.5." [
      "anthropic/claude-opus-5-5"
      "openrouter/anthropic/claude-opus-5.5"
    ])
    (devAgent "sonnet-dev" "General-purpose implementation agent pinned to Claude Sonnet 5.5." [
      "anthropic/claude-sonnet-5-5"
      "openrouter/anthropic/claude-sonnet-5.5"
    ])
    {
      ".omp/agent/skills/frontend-design".source = "${inputs.anthropic-skills}/skills/frontend-design";
    }
  ];

  home.activation.ompConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config="$HOME/.omp/agent/config.yml"
    run mkdir -p "$(dirname "$config")"
    tmp=$(mktemp)
    if { [ -s "$config" ] && cat "$config" || echo '{}'; } \
      | ${lib.getExe pkgs.yq-go} eval-all '. as $f ireduce ({}; . * $f)' - ${settings} > "$tmp"; then
      run cp "$tmp" "$config"
    fi
    rm -f "$tmp"
  '';
}
