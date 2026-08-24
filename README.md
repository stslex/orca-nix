# orca-nix

Nix flake for [Orca](https://github.com/stablyai/orca), the agentic
development environment for working with parallel coding agents.

## Usage

### Flake input

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    orca.url = "github:stslex/orca-nix";
    orca.inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

### Home Manager

```nix
{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.orca.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

### NixOS via overlay

```nix
{ inputs, ... }:
{
  nixpkgs.overlays = [ inputs.orca.overlays.default ];
  environment.systemPackages = [ pkgs.orca ];
}
```

### Ad-hoc run

```bash
nix run github:stslex/orca-nix
```

## Updating

Update to the latest stable release:

```bash
./scripts/update.sh
```

Pin a specific stable release:

```bash
./scripts/update.sh 1.4.188
```

The updater reads the official SHA-256 digests from GitHub Releases for both
Linux AppImages and writes a reproducible `version.json`.

## Automatic updates

GitHub Actions checks for a new stable release daily, builds the x86_64 Linux
package, verifies the version embedded in the extracted AppImage desktop entry,
verifies the rewritten launcher command, then commits and pushes the version
bump. The AppImage wrapper itself uses bubblewrap and cannot run on GitHub-hosted
runners, which disable the required uid mapping.

Consumers remain pinned by their own `flake.lock`. Update a consumer with:

```bash
nix flake update orca
```

## License

Packaging code and Orca are licensed under the MIT License.
