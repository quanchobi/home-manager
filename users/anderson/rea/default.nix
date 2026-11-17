# REA (Reverse Engineer Anything, github.com/morluto/rea): the `rea` CLI, its
# MCP server for omp, the skill that drives both, and the analysis engines and
# tools REA uses but never installs itself.
{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  # nixos-unstable, for what nixos-26.05 lacks or has too old.
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  rea = pkgs.callPackage ./package.nix { };

  # Ghidra 12.2 wants JDK 25; JADX needs a full JDK. Ghidra's own, so one copy.
  jdk = unstable.openjdk25;

  # The exact JAR REA pins (src/android/JadxRelease.ts).
  jadx = pkgs.fetchurl {
    url = "https://github.com/1013503897/jadx-headless-mcp/releases/download/v0.7.1/jadx-headless-mcp-0.7.1-all.jar";
    sha256 = "6e5eacf500b64292bfb73c49797c1958f6ee44646e43e868039ae7feb573ff75";
  };

  # REA checks versions: these are not in either nixpkgs at the release it
  # accepts (WABT >=1.0.42, sigrok-cli 0.7.2, and for pwntools 4.15.0 exactly
  # pyelftools 0.33 and unicorn 2.1.2).
  wabt = pkgs.wabt.overrideAttrs (old: {
    version = "1.0.42";
    src = old.src.override { hash = "sha256-33XpYt42Jw2xfwBR64jVI3VYVIKD1YjND9SSI6CdkaM="; };
  });

  pwntools =
    (pkgs.python3.override {
      packageOverrides = _: prev: {
        pyelftools = prev.pyelftools.overridePythonAttrs (old: rec {
          version = "0.33";
          src = old.src.override {
            tag = "v${version}";
            hash = "sha256-NqF5A6PRl4uncwNS9j44fIV7ovlljiucvV2Msv0LK/w=";
          };
        });
        unicorn =
          (prev.unicorn.override {
            unicorn = pkgs.unicorn.overrideAttrs (old: {
              version = "2.1.2";
              src = old.src.override { hash = "sha256-qA84xBztyWmt/rUExhhZMkQzvDPx0UE9MAIPG/Su3iE="; };
            });
          }).overridePythonAttrs
            (old: {
              # 2.1.2 takes its version from git through versioningit.
              postPatch = ''
                substituteInPlace pyproject.toml \
                  --replace-fail ', "versioningit"' "" \
                  --replace-fail 'dynamic = ["version"]' 'version = "${old.version}"' \
                  --replace-fail '[tool.versioningit]' ""
              '';
            });
      };
    }).withPackages
      (ps: [ ps.pwntools ]);

  sigrok = pkgs.sigrok-cli.overrideAttrs (_: rec {
    version = "0.7.2";
    src = pkgs.fetchurl {
      url = "https://sigrok.org/download/source/sigrok-cli/sigrok-cli-${version}.tar.gz";
      hash = "sha256-cdBEPzaJe/Vlcy3sIGgw2+oPJ4m2YBzxBTayhtEUCrg=";
    };
  });

  # Upstream's release binary, the one REA's CI verifies; not in nixpkgs.
  wakaru = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "wakaru";
    version = "1.14.0";

    src = pkgs.fetchurl {
      url = "https://github.com/pionxzh/wakaru/releases/download/v${finalAttrs.version}/wakaru-linux-x64.tar.gz";
      hash = "sha256-2w5iADRyMZWrQm6U0A1V29j9AQapKK2iVj8RAxltCfo=";
    };
    sourceRoot = ".";

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];
    installPhase = "install -Dm755 wakaru $out/bin/wakaru";

    meta.mainProgram = "wakaru";
  });

  # REA defaults to /usr/bin/prlimit, which NixOS does not have.
  prlimit = "${pkgs.util-linux}/bin/prlimit";

  # REA reads all of this from its own environment only, so it goes on the
  # `rea` wrapper and the MCP registration rather than into the session.
  environment = {
    # Native analysis. With two engines `auto` is ambiguous, so Ghidra is the
    # default and Kuna is chosen per target (`provider_id`, `--provider`).
    GHIDRA_INSTALL_DIR = "${unstable.ghidra}/lib/ghidra";
    JAVA_HOME = jdk.home;
    REA_KUNA_COMMAND = lib.getExe unstable.kuna;
    REA_ANALYSIS_PROVIDER = "ghidra";
    REA_RIZIN_COMMAND = lib.getExe pkgs.rizin;
    REA_OBJDUMP_COMMAND = "${pkgs.binutils-unwrapped}/bin/objdump";
    REA_GDB_COMMAND = lib.getExe pkgs.gdb;
    REA_WABT_BIN_DIRECTORY = "${wabt}/bin";
    REA_EVM_PRLIMIT_COMMAND = prlimit;

    # Android.
    REA_JADX_MCP_JAR = "${jadx}";
    REA_ADB_PATH = "${pkgs.android-tools}/bin/adb";

    # Firmware. nixos-26.05 has Unblob 26.3; REA accepts 26.6.x.
    REA_BINWALK_COMMAND = lib.getExe pkgs.binwalk;
    REA_UNBLOB_COMMAND = lib.getExe unstable.unblob;
    REA_FIRMWARE_PRLIMIT_COMMAND = prlimit;

    # Packet, web and signal captures.
    REA_TSHARK_COMMAND = "${pkgs.wireshark-cli}/bin/tshark";
    REA_CAPINFOS_COMMAND = "${pkgs.wireshark-cli}/bin/capinfos";
    REA_TSHARK_PRLIMIT_COMMAND = prlimit;
    REA_MITMDUMP_COMMAND = "${pkgs.mitmproxy}/bin/mitmdump";
    REA_SIGROK_COMMAND = lib.getExe sigrok;
    REA_SIGROK_PRLIMIT_COMMAND = prlimit;

    # JavaScript.
    REA_JAVASCRIPT_PRLIMIT_COMMAND = prlimit;
  }
  # x86_64 only: REA supports pwntools and Wakaru nowhere else, and nixpkgs
  # builds Apktool's aapt nowhere else on Linux.
  // lib.optionalAttrs pkgs.stdenv.hostPlatform.isx86_64 {
    REA_PWNTOOLS_PYTHON = lib.getExe pwntools;
    REA_WAKARU_COMMAND = lib.getExe wakaru;
    REA_APKTOOL_COMMAND = lib.getExe pkgs.apktool;
  };
in
{
  home.packages = [
    (pkgs.symlinkJoin {
      name = "rea";
      paths = [ rea ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/rea ${
          lib.concatMapAttrsStringSep " " (
            name: value: "--set-default ${name} ${lib.escapeShellArg value}"
          ) environment
        }
      '';
    })
  ];

  home.file.".omp/agent/skills/reverse-engineer-anything".source = "${rea}/${rea.skill}";

  # The runtime and entry script themselves, as `rea setup` registers them:
  # `rea doctor` reports a registration through a wrapper as foreign.
  omp.mcpServers.rea = {
    type = "stdio";
    command = rea.node;
    args = [
      "${rea}/${rea.entry}"
      "mcp"
    ];
    env = environment;
    # Ghidra may spend its whole 330 s startup deadline on a first query.
    timeout = 660000;
  };
}
