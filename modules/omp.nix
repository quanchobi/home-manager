# oh-my-pi (omp) config for every user. There is no home-manager module, so
# files are placed under ~/.omp/agent directly. Skills are in ./skills; users
# add MCP servers through `omp.mcpServers` (see users/anderson).
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # omp rewrites config.yml itself (model selector, /settings), so these keys
  # are merged into it on activation instead of linking a read-only store file.
  # Keys set here win on every switch; everything else omp writes is kept. The
  # merge only adds: a key removed here stays in config.yml until deleted there.
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

  # omp rewrites mcp.json itself too (/mcp add, enable, disable, reauth), so
  # `omp.mcpServers` is merged the same way: a server removed from the Nix
  # config stays in mcp.json until deleted there.
  mcpServers = (pkgs.formats.json { }).generate "omp-mcp.json" {
    "$schema" =
      "https://raw.githubusercontent.com/can1357/oh-my-pi/main/packages/coding-agent/src/config/mcp-schema.json";
    inherit (config.omp) mcpServers;
  };

  # Task subagents that pin the same implementation brief to one model each.
  devAgent = name: description: models: {
    ".omp/agent/agents/${name}.md".text = ''
      ---
      name: ${name}
      description: ${builtins.toJSON description}
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
  options.omp.mcpServers = lib.mkOption {
    type = lib.types.attrsOf (pkgs.formats.json { }).type;
    default = { };
    description = "MCP servers merged into ~/.omp/agent/mcp.json on activation, by name.";
  };

  config = {
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
    ];

    home.activation = {
      ompConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        config="$HOME/.omp/agent/config.yml"
        run mkdir -p "$(dirname "$config")"
        tmp=$(mktemp)
        if { [ -s "$config" ] && cat "$config" || echo '{}'; } \
          | ${lib.getExe pkgs.yq-go} eval-all '. as $f ireduce ({}; . * $f)' - ${settings} > "$tmp"; then
          run cp "$tmp" "$config"
        fi
        rm -f "$tmp"
      '';

      ompMcpServers = lib.mkIf (config.omp.mcpServers != { }) (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mcp="$HOME/.omp/agent/mcp.json"
          run mkdir -p "$(dirname "$mcp")"
          tmp=$(mktemp)
          if { [ -s "$mcp" ] && cat "$mcp" || echo '{}'; } \
            | ${lib.getExe pkgs.jq} --slurpfile nix ${mcpServers} '. * $nix[0]' > "$tmp"; then
            run cp "$tmp" "$mcp"
          fi
          rm -f "$tmp"
        ''
      );
    };
  };
}
