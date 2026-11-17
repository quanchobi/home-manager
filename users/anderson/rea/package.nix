# REA's `rea-agents` npm release, unpacked as published. The tarball bundles
# every runtime dependency and the skill, so there is no npx (and no
# project-local npm config) at omp start, and server and skill cannot drift.
#
# To bump: set `version` and copy `dist.integrity` from
# https://registry.npmjs.org/rea-agents/<version> into `hash`, then update
# `frida` below from the new tarball's npm-shrinkwrap.json.
{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  nodejs-slim,
}:
let
  npm =
    name: version: hash:
    fetchurl {
      url = "https://registry.npmjs.org/${name}/-/${name}-${version}.tgz";
      inherit hash;
    };

  # Frida's Node bindings are REA's one optional dependency, so the tarball
  # leaves them out. These are that dependency's runtime modules at the versions
  # and hashes in npm-shrinkwrap.json (`frida` and what it requires), plus the
  # prebuilt addon frida's install script would download.
  frida = {
    modules = {
      "balanced-match" =
        npm "balanced-match" "4.0.4"
          "sha512-BLrgEcRTwX2o6gGxGOCNyMvGSp35YofuYzw9h1IMTRmKqttAZZVU67bdb9Pr2vUHA8+j3i2tJfjO6C6+4myGTA==";
      "bindings" =
        npm "bindings" "1.5.0"
          "sha512-p2q/t/mhvuOj/UeLlV6566GD/guowlr0hHxClI0W9m7MWYkL1F0hLo+0Aexs9HSPCtR1SXQ0TD3MMKrXZajbiQ==";
      "brace-expansion" =
        npm "brace-expansion" "5.0.12"
          "sha512-YovQ3rzhaLMIrDjNDMkNS01tea93qhEhG5xy8f6+R0l+dw3Ki+5sCoIoI942iuLZTHWogWktgwVDhU09iNEimQ==";
      "file-uri-to-path" =
        npm "file-uri-to-path" "1.0.0"
          "sha512-0Zt+s3L7Vf1biwWZ29aARiVYLx7iMGnEUl9x33fbB/j3jR81u/O2LbqK+Bm1CDSNDKVtJ/YjwY7TUd5SkeLQLw==";
      "frida" =
        npm "frida" frida.version
          "sha512-gRCmmTUFdEILyHRN1b66erRoXafwsfWTqXyoBBqkSCFX0Ue7Jhvs/KhA3JO0XrgITNlPd91QAGsFvWzh0mhVgg==";
      "minimatch" =
        npm "minimatch" "10.2.5"
          "sha512-MULkVLfKGYDFYejP07QOurDLLQpcjk7Fw+7jXS2R2czRQzR56yHRveU5NDJEOviH+hETZKSkIk5c+T23GjFUMg==";
    };

    version = "17.23.2";

    addon =
      let
        prebuilt =
          {
            x86_64-linux = {
              arch = "x64";
              hash = "sha256-n6j2aM6R6wNxPoVk3k+PveIyIz7pHXKcFnc/3hHbrpU=";
            };
            aarch64-linux = {
              arch = "arm64";
              hash = "sha256-EQg/AWpCnodQbNaBZr0URdqP69UGok7fP2xKmno+qf4=";
            };
          }
          .${stdenvNoCC.hostPlatform.system};
      in
      fetchurl {
        url = "https://github.com/frida/frida/releases/download/${frida.version}/frida-v${frida.version}-napi-v8-linux-${prebuilt.arch}.tar.gz";
        inherit (prebuilt) hash;
      };
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "rea-agents";
  version = "6.9.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/rea-agents/-/rea-agents-${finalAttrs.version}.tgz";
    hash = "sha512-KqDn1UR5BMqHoQ3MGAnPuWiSKwgdFaz1L/uUNgrKt+1W8kPtgYP8AWEOXIF1lDIOBVyPuYIIst2iamo1Wf3r8g==";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontFixup = true; # keep the prebuilt native addons byte-identical

  installPhase = ''
    package=$out/lib/node_modules/rea-agents
    mkdir -p $out/lib/node_modules
    cp -r . $package

    ${lib.concatMapAttrsStringSep "\n" (name: src: ''
      mkdir $package/node_modules/${name}
      tar -xzf ${src} -C $package/node_modules/${name} --strip-components=1
    '') frida.modules}
    tar -xzf ${frida.addon} -C $package/node_modules/frida

    makeWrapper ${lib.getExe nodejs-slim} $out/bin/rea --add-flags $out/${finalAttrs.passthru.entry}
  '';

  passthru = {
    # What `rea setup` registers with an MCP client: this runtime and script.
    node = lib.getExe nodejs-slim;
    entry = "lib/node_modules/rea-agents/scripts/rea.mjs";
    skill = "lib/node_modules/rea-agents/skills/reverse-engineer-anything";
  };

  meta.mainProgram = "rea";
})
