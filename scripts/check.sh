#!/usr/bin/env bash
# check.sh <app repo>: fail unless the app's accountkit/ is exactly this kit, vendored at the
# commit its VERSION names. Run from a checkout of the kit at that commit.
set -euo pipefail
kit=$(cd "$(dirname "$0")/.." && pwd)
app=$(cd "${1:?usage: check.sh <app repo>}" && pwd)
view=src/qml
[ -d "$app/src/qml" ] || [ ! -d "$app/qml" ] || view=qml
want=$(cat "$app/$view/accountkit/VERSION")
have=$(git -C "$kit" rev-parse HEAD)
[ "$want" = "$have" ] || { echo "the app pins $want; this kit checkout is $have"; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cp "$app/metadata.json" "$tmp/"
mkdir -p "$tmp/$view"
"$kit/scripts/vendor.sh" "$tmp" "$want" > /dev/null
diff -r "$tmp/$view/accountkit" "$app/$view/accountkit" && echo "$view/accountkit is logos-account-kit $want"
