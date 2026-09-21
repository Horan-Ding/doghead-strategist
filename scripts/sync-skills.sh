#!/usr/bin/env bash
# Download upstream candidates for review; preserve locally adapted skills.
set -euo pipefail

STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/doghead-skills-sync.XXXXXX")"
git clone --depth 1 https://github.com/tomwong001/qingsheng-skill.git "$STAGING_DIR/qingsheng"
git clone --depth 1 https://github.com/Mayuqi-crypto/HowToGetAlongWithGirls.git "$STAGING_DIR/howto"

test -f "$STAGING_DIR/qingsheng/skill/SKILL.md"
test -d "$STAGING_DIR/howto/.claude/skills/dating-coach/references"
printf 'Upstream candidates downloaded to: %s\n' "$STAGING_DIR"
printf 'Compare qingsheng with: %s\n' "$STAGING_DIR/qingsheng/skill"
printf 'Compare howto with: %s\n' "$STAGING_DIR/howto/.claude/skills/dating-coach/references"
printf '%s\n' 'Local skills were not overwritten. Merge selected changes using .cursor/skills/qingsheng/qingsheng-upgrade.md.'
