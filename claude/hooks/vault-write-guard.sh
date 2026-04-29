#!/bin/bash
# vault-write-guard.sh
#
# PreToolUse hook for the Write tool. Blocks creation of new knowledge artefacts
# (type: meeting|decision|learning|session-log|concept|person|organization)
# anywhere inside ~/Documents/Second-Brain/ EXCEPT 01_Inbox/ and 00_Meta/.
#
# Rationale: The /sync-meetings skill body says "ausnahmslos Inbox", but in
# scheduled (autonomous) runs the LLM has dropped that constraint twice and
# written meeting files directly into 02_Projects/<slug>/. This hook is the
# deterministic safety net.
#
# Allowed:
#   - Any path outside ~/Documents/Second-Brain/         → exit 0
#   - Existing files (Edits/Updates)                     → exit 0
#   - 01_Inbox/, 00_Meta/                                → exit 0
#   - Project/Area hub pages (type: project|area)        → exit 0
#   - Files without a knowledge-artefact `type:` field   → exit 0
#
# Blocked:
#   - New file in Vault outside Inbox/Meta with type:
#     meeting, decision, learning, session-log, concept, person, organization

set -e

INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.content // empty')

# Empty inputs → not our concern
[ -z "$FILE_PATH" ] && exit 0

# Only guard Vault paths
case "$FILE_PATH" in
  *"/Second-Brain/"*) ;;
  *) exit 0 ;;
esac

# Allow Inbox + Meta
case "$FILE_PATH" in
  *"/Second-Brain/01_Inbox/"*) exit 0 ;;
  *"/Second-Brain/00_Meta/"*) exit 0 ;;
esac

# Updates to existing files are always allowed
[ -f "$FILE_PATH" ] && exit 0

# Extract `type:` from frontmatter (between the first two `---` lines)
TYPE=$(printf '%s\n' "$CONTENT" | awk '
  BEGIN { in_fm=0; done=0 }
  /^---[[:space:]]*$/ {
    if (in_fm == 0 && done == 0) { in_fm=1; next }
    if (in_fm == 1) { done=1; exit }
  }
  in_fm == 1 && /^type:[[:space:]]/ {
    sub(/^type:[[:space:]]*/, "")
    gsub(/["'"'"']/, "")
    sub(/[[:space:]]+$/, "")
    print
    exit
  }
')

case "$TYPE" in
  meeting|decision|learning|session-log|concept|person|organization)
    cat >&2 <<EOF
WRITE-GUARD blocked: new "$TYPE" artefact must land in 01_Inbox/ first.

  Path:    $FILE_PATH
  Type:    $TYPE

Vault rule (vault-workflow.md): "Vault-Dateien landen AUSNAHMSLOS in 01_Inbox/.
NIEMALS direkt in Zielordner. Einsortieren macht ALLEIN /context-sweep."

Fix:
  1. Write to: ~/Documents/Second-Brain/01_Inbox/$(basename "$FILE_PATH")
  2. Run /context-sweep when ready, it routes to the correct project folder.

Override: edit \$HOME/.claude/hooks/vault-write-guard.sh if this is a false positive.
EOF
    exit 2
    ;;
esac

# project, area, and untyped writes pass through
exit 0
