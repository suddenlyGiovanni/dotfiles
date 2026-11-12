# bitwarden-cli that can exit right after printing its response, opt in with
# BW_EXIT_AFTER_RESPONSE=true.
# Ported from dev.thingos.io/infrastructure/developer (pkgs/bitwarden-cli.nix).
#
# bw prints its result after ~0.4 s, but only sets process.exitCode and waits for the
# event loop to drain. Leftover rxjs intervals keep it alive for another ~1.1 s, on every
# call. With the variable set, processResponse exits once stdout and stderr are
# flushed, the same output 1 s sooner. with-secrets sets it for the read-only calls of
# secretspec (status, list items) only; a writing command could still have a state
# update in flight.
#
# Only bw.js is patched, everything else links to the nixpkgs package, so this costs
# no npm build. The substitutions fail the build when an update changes processResponse.
{
  stdenvNoCC,
  bitwarden-cli,
}:
stdenvNoCC.mkDerivation {
  pname = "bitwarden-cli-exit-after-response";
  inherit (bitwarden-cli) version;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    clients=lib/node_modules/@bitwarden/clients
    mkdir -p $out/bin $out/$clients/build
    ln -s ${bitwarden-cli}/share $out/share
    for f in ${bitwarden-cli}/$clients/*; do
      [ "$(basename "$f")" = build ] || ln -s "$f" $out/$clients/
    done
    for f in ${bitwarden-cli}/$clients/build/*; do
      [ "$(basename "$f")" = bw.js ] || ln -s "$f" $out/$clients/build/
    done
    cp ${bitwarden-cli}/$clients/build/bw.js $out/$clients/build/bw.js
    chmod u+w $out/$clients/build/bw.js
    substituteInPlace $out/$clients/build/bw.js \
      --replace-fail 'process.exitCode = exitCode;' \
                     'process.exitCode = exitCode; if (process.env.BW_EXIT_AFTER_RESPONSE === "true") process.stdout.write("", () => process.stderr.write("", () => process.exit(exitCode)));' \
      --replace-fail 'process.exitCode = 0;' \
                     'process.exitCode = 0; if (process.env.BW_EXIT_AFTER_RESPONSE === "true") process.stdout.write("", () => process.stderr.write("", () => process.exit(0)));'
    substitute ${bitwarden-cli}/bin/bw $out/bin/bw --replace-fail ${bitwarden-cli} $out
    chmod +x $out/bin/bw
    runHook postInstall
  '';

  meta =
    bitwarden-cli.meta
    // {
      description = "${bitwarden-cli.meta.description}, exits right after its response with BW_EXIT_AFTER_RESPONSE=true";
      mainProgram = "bw";
    };
}
