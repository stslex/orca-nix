{
  appimageTools,
  fetchurl,
  lib,
  makeWrapper,
  stdenv,
}:

let
  versionData = builtins.fromJSON (builtins.readFile ./version.json);

  assetMap = {
    "x86_64-linux" = "orca-linux.AppImage";
    "aarch64-linux" = "orca-linux-arm64.AppImage";
  };

  asset =
    assetMap.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  hash =
    versionData.hashes.${stdenv.hostPlatform.system}
      or (throw "No hash for system: ${stdenv.hostPlatform.system}");

  version = versionData.version;
  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/${asset}";
    inherit hash;
  };

  contents = appimageTools.extract {
    pname = "orca";
    inherit version src;
  };
in
appimageTools.wrapType2 {
  pname = "orca";
  inherit version src;
  nativeBuildInputs = [ makeWrapper ];

  extraInstallCommands = ''
    wrapProgram $out/bin/orca --add-flags --no-sandbox

    install -Dm444 ${contents}/orca-ide.desktop $out/share/applications/orca.desktop
    substituteInPlace $out/share/applications/orca.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=orca %U'

    install -Dm444 ${contents}/usr/share/icons/hicolor/512x512/apps/orca-ide.png \
      $out/share/icons/hicolor/512x512/apps/orca-ide.png
  '';

  meta = {
    description = "Agentic development environment for working with parallel coding agents";
    homepage = "https://onorca.dev";
    downloadPage = "https://github.com/stablyai/orca/releases";
    license = lib.licenses.mit;
    platforms = builtins.attrNames assetMap;
    mainProgram = "orca";
  };
}
