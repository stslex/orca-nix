{
  description = "Nix flake for the Orca agentic development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachSystem
      [
        "x86_64-linux"
        "aarch64-linux"
      ]
      (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          orca = pkgs.callPackage ./pkgs/orca { };
        in
        {
          packages = {
            default = orca;
            inherit orca;
          };

          apps.default = {
            type = "app";
            program = "${orca}/bin/orca";
            meta.description = "Run Orca";
          };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              jq
              nixfmt
              shellcheck
            ];
          };
        }
      )
    // {
      overlays.default = final: _prev: {
        orca = final.callPackage ./pkgs/orca { };
      };
    };
}
