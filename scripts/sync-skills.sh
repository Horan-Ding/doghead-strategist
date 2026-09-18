#!/usr/bin/env bash
# Refresh vendored qingsheng + partial HowTo references. Requires network.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="${TMPDIR:-/tmp}/doghead-skills-sync"
rm -rf "$TMP"
mkdir -p "$TMP"

echo "==> tomwong001/qingsheng-skill"
git clone --depth 1 https://github.com/tomwong001/qingsheng-skill.git "$TMP/qingsheng"
rm -rf "$ROOT/.cursor/skills/qingsheng"
cp -R "$TMP/qingsheng/skill" "$ROOT/.cursor/skills/qingsheng"
cp "$TMP/qingsheng/VERSION" "$ROOT/.cursor/skills/qingsheng/VERSION"

echo "==> HowTo partial references"
git clone --depth 1 https://github.com/Mayuqi-crypto/HowToGetAlongWithGirls.git "$TMP/howto"
HOWTO_REF="$TMP/howto/.claude/skills/dating-coach/references"
DEST="$ROOT/.cursor/skills/goutou-junshi/references/howto"
mkdir -p "$DEST"
for f in damage-control.md hard-value-reality.md self-diagnosis.md signal-patterns.md realistic-scenarios.md lifecycle.md profile-template.md; do
  cp "$HOWTO_REF/$f" "$DEST/"
done
# Keep our README attribution
test -f "$DEST/README.md" || echo "missing README.md"

echo "Done. Review git diff before commit."
