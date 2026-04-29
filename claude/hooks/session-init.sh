#!/bin/bash
# Session-Init Hook — Vault Context Loader (compact mode)
# Outputs Project Status + Project-scoped Decisions + Learning titles.
# Target: <2KB so harness inlines full output (no preview truncation).

VAULT="$HOME/Documents/Second-Brain"

# --- Projekt-Slug aus CLAUDE.md (Vault-Integration Abschnitt) ---
PROJECT_SLUG=""
if [ -n "$CLAUDE_PROJECT_DIR" ] && [ -f "$CLAUDE_PROJECT_DIR/CLAUDE.md" ]; then
  PROJECT_SLUG=$(grep 'Projekt-Tag:' "$CLAUDE_PROJECT_DIR/CLAUDE.md" 2>/dev/null | sed -E 's|.*project/([a-zA-Z0-9_-]+).*|\1|' | head -1)
fi

# Helper: Datum aus Frontmatter created_date ODER Dateiname extrahieren
get_date() {
  local f="$1"
  local d
  d=$(awk '/^---$/{n++; next} n==1 && /^created_date:/{print; exit}' "$f" | sed -E 's/created_date: *//;s/ *$//')
  if [ -z "$d" ]; then
    d=$(basename "$f" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
  fi
  echo "$d"
}

echo "=== SESSION CONTEXT ==="
echo ""

# --- 1. PROJECT STATUS (from STATE.md) ---
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
  STATE_FILE=""
  [ -f "$CLAUDE_PROJECT_DIR/.planning/STATE.md" ] && STATE_FILE="$CLAUDE_PROJECT_DIR/.planning/STATE.md"
  [ -z "$STATE_FILE" ] && [ -f "$CLAUDE_PROJECT_DIR/STATE.md" ] && STATE_FILE="$CLAUDE_PROJECT_DIR/STATE.md"

  if [ -n "$STATE_FILE" ]; then
    echo "[PROJECT STATUS]"
    PHASE=$(grep -m1 "^Phase:" "$STATE_FILE" 2>/dev/null | head -1)
    [ -z "$PHASE" ] && PHASE=$(grep -m1 "Phase:" "$STATE_FILE" 2>/dev/null | head -1)
    LAST=$(grep -m1 "Last activity:" "$STATE_FILE" 2>/dev/null | head -1)
    [ -z "$LAST" ] && LAST=$(grep -m1 "Letzte Aktualisierung:" "$STATE_FILE" 2>/dev/null | head -1)
    NEXT=$(grep -m1 "Naechster Schritt:" "$STATE_FILE" 2>/dev/null | head -1)
    [ -z "$NEXT" ] && NEXT=$(grep -m1 "Next step:" "$STATE_FILE" 2>/dev/null | head -1)
    PROGRESS=$(grep -m1 "Progress:" "$STATE_FILE" 2>/dev/null | head -1)
    STATUS_LINE=$(grep -m1 "^## Status:" "$STATE_FILE" 2>/dev/null | sed 's/^## //')

    [ -n "$STATUS_LINE" ] && echo "  $STATUS_LINE"
    [ -n "$PHASE" ] && echo "  $PHASE"
    [ -n "$PROGRESS" ] && echo "  $PROGRESS"
    [ -n "$LAST" ] && echo "  $LAST"
    [ -n "$NEXT" ] && echo "  $NEXT"
    echo ""
  fi
fi

# --- 2. DECISIONS (project-scoped, validity: active, one line each) ---
if [ -n "$PROJECT_SLUG" ] && [ -d "$VAULT" ]; then
  ALL_DECISIONS=$(grep -rl "type: decision" "$VAULT" 2>/dev/null | xargs grep -l "project/$PROJECT_SLUG" 2>/dev/null)

  ACTIVE_LINES=""
  SKIPPED_COUNT=0
  for f in $ALL_DECISIONS; do
    VALIDITY=$(awk '/^---$/{n++; next} n==1 && /^validity:/{print; exit}' "$f" | sed 's/validity: *//;s/ *$//')
    if [ -z "$VALIDITY" ] || [ "$VALIDITY" = "active" ]; then
      TITLE=$(grep "^title:" "$f" | head -1 | sed 's/title: *"*//;s/"*$//;s/^Decision: *//')
      [ -z "$TITLE" ] && TITLE=$(awk '/^---$/{n++} n==2{found=1} found && /^# /{print; exit}' "$f" | sed 's/^# //;s/^Decision: *//')
      DATE=$(get_date "$f")
      if [ -n "$TITLE" ]; then
        ACTIVE_LINES="${ACTIVE_LINES}${DATE}|${TITLE}"$'\n'
      fi
    else
      SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    fi
  done

  if [ -n "$ACTIVE_LINES" ]; then
    CAP=25
    SORTED=$(echo "$ACTIVE_LINES" | sed '/^$/d' | sort -r)
    TOTAL=$(echo "$SORTED" | wc -l | tr -d ' ')
    HEADER="[DECISIONS — project/$PROJECT_SLUG]"
    [ $SKIPPED_COUNT -gt 0 ] && HEADER="$HEADER ($SKIPPED_COUNT superseded)"
    echo "$HEADER"
    echo "$SORTED" | head -n $CAP | awk -F'|' '{printf "  - %s: %s\n", $1, $2}'
    HIDDEN=$((TOTAL - CAP))
    [ $HIDDEN -gt 0 ] && echo "  ... plus $HIDDEN aeltere (grep vault-index.md)"
    echo ""
  fi
fi

# --- 3. LEARNINGS (project-scoped only, newest first, cap 40) ---
if [ -n "$PROJECT_SLUG" ] && [ -d "$VAULT" ]; then
  LEARNING_FILES=$(grep -rl "type: learning" "$VAULT" 2>/dev/null | xargs grep -l "project/$PROJECT_SLUG" 2>/dev/null)

  if [ -n "$LEARNING_FILES" ]; then
    LEARNING_LINES=""
    TOTAL=0
    for f in $LEARNING_FILES; do
      TITLE=$(grep "^title:" "$f" | head -1 | sed 's/title: *"*//;s/"*$//;s/^Learning: *//')
      DATE=$(get_date "$f")
      if [ -n "$TITLE" ]; then
        LEARNING_LINES="${LEARNING_LINES}${DATE}|${TITLE}"$'\n'
        TOTAL=$((TOTAL + 1))
      fi
    done

    if [ -n "$LEARNING_LINES" ]; then
      CAP=25
      SORTED=$(echo "$LEARNING_LINES" | sed '/^$/d' | sort -r)
      SHOWN=$(echo "$SORTED" | head -n $CAP | awk -F'|' '{printf "  - %s: %s\n", $1, $2}')
      HIDDEN=$((TOTAL - CAP))

      echo "[LEARNINGS — project/$PROJECT_SLUG]"
      echo "$SHOWN"
      [ $HIDDEN -gt 0 ] && echo "  ... plus $HIDDEN aeltere Learnings (grep vault-index.md)"
      echo ""
    fi
  fi
fi

# --- Footer ---
echo "INFO: Volltext via 'grep \"<Title>\" ~/Documents/Second-Brain/00_Meta/system/vault-index.md' + Read."
echo "=== END SESSION CONTEXT ==="

exit 0
