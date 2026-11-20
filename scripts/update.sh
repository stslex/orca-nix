#!/usr/bin/env bash
set -euo pipefail

REPO="stablyai/orca"
ASSET_API="https://api.github.com/repos/$REPO/releases"
VERSION_FILE="$(cd "$(dirname "$0")/../pkgs/orca" && pwd)/version.json"

if [[ $# -gt 1 ]]; then
  echo "usage: $0 [version]" >&2
  exit 2
fi

if [[ $# -eq 1 ]]; then
  REQUESTED_VERSION="${1#v}"
  RELEASE_URL="$ASSET_API/tags/v$REQUESTED_VERSION"
else
  RELEASE_URL="$ASSET_API/latest"
fi

RELEASE_FILE=$(mktemp)
trap 'rm -f "$RELEASE_FILE"' EXIT
# File output lets curl discard a partial response before retrying.
curl -fsSL --connect-timeout 10 --max-time 30 \
  --retry 3 --retry-connrefused --retry-max-time 120 \
  --output "$RELEASE_FILE" "$RELEASE_URL"
RELEASE=$(cat "$RELEASE_FILE")

if [[ $(jq -r '.draft == false and .prerelease == false' <<<"$RELEASE") != true ]]; then
  echo "orca: release is not stable" >&2
  exit 1
fi

TAG=$(jq -er '.tag_name' <<<"$RELEASE")
if [[ ! "$TAG" =~ ^v[0-9]+(\.[0-9]+){2,3}([.-][0-9A-Za-z.-]+)?$ ]]; then
  echo "orca: invalid release tag: $TAG" >&2
  exit 1
fi
NEW_VERSION="${TAG#v}"
OLD_VERSION=$(jq -r '.version' "$VERSION_FILE")

if [[ "$OLD_VERSION" == "$NEW_VERSION" ]]; then
  echo "orca: already at $NEW_VERSION"
  exit 0
fi

declare -A SYSTEM_TO_ASSET=(
  ["x86_64-linux"]="orca-linux.AppImage"
  ["aarch64-linux"]="orca-linux-arm64.AppImage"
)

HASHES="{}"
for system in x86_64-linux aarch64-linux; do
  asset="${SYSTEM_TO_ASSET[$system]}"
  count=$(jq --arg asset "$asset" '[.assets[] | select(.name == $asset)] | length' <<<"$RELEASE")
  if [[ "$count" != 1 ]]; then
    echo "orca: expected one $asset asset, found $count" >&2
    exit 1
  fi

  digest=$(jq -er --arg asset "$asset" '.assets[] | select(.name == $asset) | .digest' <<<"$RELEASE")
  if [[ ! "$digest" =~ ^sha256:[0-9a-f]{64}$ ]]; then
    echo "orca: $asset has no valid SHA-256 digest" >&2
    exit 1
  fi

  sri=$(nix hash convert --hash-algo sha256 --to sri "${digest#sha256:}")
  HASHES=$(jq --arg system "$system" --arg sri "$sri" '.[$system] = $sri' <<<"$HASHES")
done

jq -n --arg version "$NEW_VERSION" --argjson hashes "$HASHES" \
  '{ version: $version, hashes: $hashes }' >"$VERSION_FILE"

echo "orca: $OLD_VERSION → $NEW_VERSION"
