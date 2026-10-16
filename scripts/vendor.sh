#!/usr/bin/env bash
# vendor.sh <app repo> [kit commit]: copy the kit into the app's view directory (src/qml, else
# qml) as accountkit/, beside any other kit. The qmldir names the module after the app, as the
# builder names each view's own directory, so two apps' copies in one host never share a name.
set -euo pipefail
kit=$(cd "$(dirname "$0")/.." && pwd)
app=${1:?usage: vendor.sh <app repo> [kit commit]}
name=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["name"])' "$app/metadata.json")
rev=${2:-$(git -C "$kit" rev-parse HEAD)}
view=src/qml
[ -d "$app/src/qml" ] || [ ! -d "$app/qml" ] || view=qml
dest="$app/$view/accountkit"
rm -rf "${dest:?}"
mkdir -p "$dest"
cp "$kit"/qml/*.qml "$kit"/qml/*.js "$dest/"
{
    echo "module com.logos.module.$name.accountkit"
    for f in "$kit"/qml/*.qml; do t=$(basename "$f" .qml); echo "$t 1.0 $t.qml"; done
} > "$dest/qmldir"
echo "$rev" > "$dest/VERSION"
echo "logos-account-kit $rev -> $dest (com.logos.module.$name.accountkit)"
