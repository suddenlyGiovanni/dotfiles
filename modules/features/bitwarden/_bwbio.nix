# bwbio (bitwarden-cli-bio): Touch ID unlock for the Bitwarden CLI through the desktop app.
# https://github.com/jeanregisser/bitwarden-cli-bio
# Ported from dev.thingos.io/infrastructure/developer (pkgs/bwbio.nix).
#
# The npm tarball already contains the bundled dist/ and the package has no runtime
# dependencies, so there is nothing to build. bwbio spawns `bw` from PATH, and the
# wrapper puts the given one first.
#
# bwbio reads and writes bw's data.json itself (dist/index.js, getCliDataDir), so it
# needs the same BITWARDENCLI_APPDATA_DIR as bw. The caller passes it as appDataDir.
{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  nodejs,
  bitwarden-cli,
  appDataDir ? null,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "bwbio";
  version = "1.4.2";

  src = fetchurl {
    url = "https://registry.npmjs.org/bitwarden-cli-bio/-/bitwarden-cli-bio-${finalAttrs.version}.tgz";
    hash = "sha256-o4cBcq2tfLpEwGw7IIIoyystdefLrGM/YYiLVMM8TiY=";
  };

  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/bwbio
    cp -r . $out/lib/bwbio
    makeWrapper ${lib.getExe nodejs} $out/bin/bwbio \
      --add-flags $out/lib/bwbio/dist/index.js \
      --prefix PATH : ${lib.makeBinPath [bitwarden-cli]} \
      ${lib.optionalString (appDataDir != null) "--set-default BITWARDENCLI_APPDATA_DIR ${lib.escapeShellArg appDataDir}"}
    runHook postInstall
  '';

  meta = {
    description = "Bitwarden CLI with biometric unlock via the desktop app";
    homepage = "https://github.com/jeanregisser/bitwarden-cli-bio";
    license = lib.licenses.mit;
    mainProgram = "bwbio";
    platforms = lib.platforms.darwin;
  };
})
