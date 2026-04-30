#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — AI Mastermind Workshop: AI Operating System Setup
# =============================================================================
# Idempotent: safe to run multiple times.
# Second run after successful first run produces 0 changes.
#
# SAFETY GUARANTEES (was dieses Skript schreibt und NIEMALS anfasst):
#
# Was das Skript schreibt:
#   - ~/.claude/           (globale Claude Code Konfig: CLAUDE.md, rules/, commands/, hooks/)
#   - ~/Documents/Second-Brain/  (Obsidian Vault — nur ergaenzend, niemals ueberschreibend)
#
# Was das Skript NIEMALS anfasst:
#   - Andere Projekt-Ordner (~/projects/..., ~/dev/..., etc.)
#   - Projekt-spezifische CLAUDE.md-Files in deinen bestehenden Repos
#   - User-PATH, zsh-Config, Shell-Aliases (~/.zshrc, ~/.zprofile, etc.)
#   - Claude Code Binary selbst (nur Config-Files)
#   - Obsidian App (nur Vault-Struktur und Template-Files)
#   - ~/.claude.json (OAuth-Token-Datei — niemals anfassen!)
#
# Was Backups bekommt:
#   - Alle existierenden Files in ~/.claude/, die mit Repo-Files kollidieren
#     UND unterschiedlichen Inhalt haben -> .bak.<timestamp>-Suffix
#   - Vault-Files niemals Backup, niemals Overwrite (copy_if_absent)
#
# Voraussetzung:
#   Claude Code muss bereits installiert sein (Pre-Call mit Affom).
#   bootstrap.sh installiert NUR die Config-Files, NICHT Claude Code selbst.
# =============================================================================

set -euo pipefail

# --- Error trap ---
trap 'echo "[ERROR] Script failed at line $LINENO. See output above. Re-run is safe (idempotent)." >&2' ERR

# --- Variables ---
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"
CLAUDE_DIR="$HOME/.claude"
VAULT_DIR="$HOME/Documents/Second-Brain"
DRY_RUN=0

# --- Counters ---
COUNT_BACKED=0
COUNT_NEW=0
COUNT_UNCHANGED=0
COUNT_SKIPPED=0
COUNT_DRY=0

# --- Color output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()  { echo -e "${YELLOW}[!!]${NC}   $*"; }
drylog(){ echo -e "${CYAN}[DRY]${NC}  $*"; }
error() { echo -e "${RED}[ERR]${NC}  $*" >&2; }

# =============================================================================
# Argument parsing
# =============================================================================
parse_args() {
  for arg in "$@"; do
    case "$arg" in
      --dry-run)
        DRY_RUN=1
        ;;
      --help|-h)
        echo "Usage: bash bootstrap.sh [--dry-run]"
        echo ""
        echo "  --dry-run   Show what would be done without making any changes"
        exit 0
        ;;
      *)
        warn "Unknown argument: $arg (ignored)"
        ;;
    esac
  done
}

# =============================================================================
# Prerequisites
# =============================================================================
prereq_check() {
  # macOS PATH: source Homebrew in non-interactive mode so 'claude' can be found
  [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true

  echo "Checking prerequisites..."

  # macOS version >= 13
  local os_ver
  os_ver=$(sw_vers -productVersion 2>/dev/null | cut -d. -f1 || echo "0")
  if [ "$os_ver" -lt 13 ]; then
    error "macOS 13+ required for Claude Code. You have $(sw_vers -productVersion)."
    exit 1
  fi
  info "macOS $(sw_vers -productVersion) — OK"

  # git installed
  if ! command -v git &>/dev/null; then
    error "git not found. Install Xcode Command Line Tools: xcode-select --install"
    error "After installation completes, re-run this script."
    exit 1
  fi
  info "git $(git --version | cut -d' ' -f3) — OK"

  # bash version check (3.2+ is macOS default, should always pass)
  local bash_major
  bash_major="${BASH_VERSINFO[0]:-0}"
  if [ "$bash_major" -lt 3 ]; then
    error "bash 3.2+ required. Found: $BASH_VERSION"
    exit 1
  fi
  info "bash $BASH_VERSION — OK"

  # Soft-Check for Claude Code Binary (warning only, not a fatal error)
  if ! command -v claude &>/dev/null; then
    warn "Claude Code Binary nicht gefunden."
    warn "bootstrap.sh installiert die Config-Files, aber Claude Code selbst"
    warn "muss separat ueber den Pre-Call mit Affom installiert werden:"
    warn "  curl -fsSL https://claude.ai/install.sh | bash"
    warn "Files sind nach diesem Bootstrap bereit — Claude Code kommt spaeter."
    echo ""
  else
    info "claude $(claude --version 2>/dev/null | head -1 | cut -d' ' -f3 || echo '(version unknown)') — OK"
  fi
}

# =============================================================================
# Helper: copy with timestamped backup (for ~/.claude/ files)
# =============================================================================
copy_with_backup() {
  local src="$1"
  local dst="$2"

  if [ "$DRY_RUN" -eq 1 ]; then
    if [ -f "$dst" ]; then
      if cmp -s "$src" "$dst"; then
        drylog "WUERDE UEBERSPRINGEN (identisch): $(basename "$src")"
      else
        drylog "WUERDE BACKUP + KOPIEREN: $dst -> $dst.bak.$TS"
      fi
    else
      drylog "WUERDE NEU ANLEGEN: $dst"
    fi
    COUNT_DRY=$((COUNT_DRY + 1))
    return
  fi

  mkdir -p "$(dirname "$dst")"
  if [ -f "$dst" ]; then
    if cmp -s "$src" "$dst"; then
      info "Unveraendert (uebersprungen): $(basename "$src")"
      COUNT_UNCHANGED=$((COUNT_UNCHANGED + 1))
    else
      mv "$dst" "${dst}.bak.${TS}"
      cp "$src" "$dst"
      warn "Backup angelegt: $(basename "$dst").bak.$TS — neu: $(basename "$src")"
      COUNT_BACKED=$((COUNT_BACKED + 1))
    fi
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    info "Neu angelegt: $dst"
    COUNT_NEW=$((COUNT_NEW + 1))
  fi
}

# =============================================================================
# Helper: copy only if absent (for vault files — NEVER overwrite)
# =============================================================================
copy_if_absent() {
  local src="$1"
  local dst="$2"

  if [ "$DRY_RUN" -eq 1 ]; then
    if [ -f "$dst" ]; then
      drylog "WUERDE BEHALTEN (existiert): $dst"
    else
      drylog "WUERDE ANLEGEN (neu): $dst"
    fi
    COUNT_DRY=$((COUNT_DRY + 1))
    return
  fi

  mkdir -p "$(dirname "$dst")"
  if [ -f "$dst" ]; then
    info "Behalten (existiert): $(basename "$dst")"
    COUNT_SKIPPED=$((COUNT_SKIPPED + 1))
  else
    cp "$src" "$dst"
    info "Neu angelegt: $dst"
    COUNT_NEW=$((COUNT_NEW + 1))
  fi
}

# =============================================================================
# Install ~/.claude/ configuration files
# =============================================================================
install_claude_files() {
  echo ""
  echo "Installiere ~/.claude/ Konfiguration..."
  echo ""

  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$CLAUDE_DIR/rules"
    mkdir -p "$CLAUDE_DIR/commands"
    mkdir -p "$CLAUDE_DIR/hooks"
  fi

  # CLAUDE.md
  copy_with_backup "$REPO_DIR/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

  # Rules
  for rule_file in "$REPO_DIR/claude/rules/"*.md; do
    [ -f "$rule_file" ] || continue
    copy_with_backup "$rule_file" "$CLAUDE_DIR/rules/$(basename "$rule_file")"
  done

  # Commands
  for cmd_file in "$REPO_DIR/claude/commands/"*.md; do
    [ -f "$cmd_file" ] || continue
    copy_with_backup "$cmd_file" "$CLAUDE_DIR/commands/$(basename "$cmd_file")"
  done

  # Hooks
  for hook_file in "$REPO_DIR/claude/hooks/"*; do
    [ -f "$hook_file" ] || continue
    copy_with_backup "$hook_file" "$CLAUDE_DIR/hooks/$(basename "$hook_file")"
    if [ "$DRY_RUN" -eq 0 ]; then
      chmod +x "$CLAUDE_DIR/hooks/$(basename "$hook_file")" 2>/dev/null || true
    else
      drylog "WUERDE chmod +x: $CLAUDE_DIR/hooks/$(basename "$hook_file")"
    fi
  done

  # settings.json.template — IMMER aktuell halten (mit copy_with_backup)
  copy_with_backup "$REPO_DIR/claude/settings.json.template" "$CLAUDE_DIR/settings.json.template"

  # settings.json — NIEMALS ueberschreiben wenn vorhanden
  if [ "$DRY_RUN" -eq 1 ]; then
    if [ -f "$CLAUDE_DIR/settings.json" ]; then
      drylog "WUERDE BEHALTEN (existiert): $CLAUDE_DIR/settings.json"
    else
      drylog "WUERDE ANLEGEN aus Template: $CLAUDE_DIR/settings.json"
    fi
  else
    if [ -f "$CLAUDE_DIR/settings.json" ]; then
      warn ""
      warn "settings.json existiert bereits — wurde NICHT ueberschrieben (deine Konfig bleibt)."
      warn "Wenn du die Workshop-Hooks aktivieren willst, vergleiche:"
      warn "  diff ~/.claude/settings.json ~/.claude/settings.json.template"
      warn "und uebernimm den hooks-Block manuell ODER backup deine settings.json"
      warn "und kopiere die Vorlage: cp ~/.claude/settings.json.template ~/.claude/settings.json"
      warn ""
    else
      cp "$REPO_DIR/claude/settings.json.template" "$CLAUDE_DIR/settings.json"
      info "Neu angelegt: $CLAUDE_DIR/settings.json (aus Template)"
      COUNT_NEW=$((COUNT_NEW + 1))
    fi
  fi
}

# =============================================================================
# Install Obsidian Vault Skeleton
# =============================================================================
install_vault_skeleton() {
  echo ""
  echo "Installiere Vault-Skeleton unter $VAULT_DIR..."
  echo ""

  # Vault-Detection: friendly message if vault already exists
  if [ -d "$VAULT_DIR" ] && [ "$(ls -A "$VAULT_DIR" 2>/dev/null | head -1)" ]; then
    if [ "$DRY_RUN" -eq 0 ]; then
      info "Vault gefunden unter $VAULT_DIR — PARA-Struktur wird ergaenzt,"
      info "bestehende Inhalte werden NICHT angefasst."
    else
      drylog "Vault gefunden unter $VAULT_DIR — PARA-Struktur wuerde ergaenzt (bestehende Inhalte NICHT angefasst)"
    fi
    echo ""
  fi

  # Create PARA directories (00_Meta restrukturiert 2026-04-29:
  #   clusters/ = semantisches Cluster-Konzept, system/ = Maschinen-State)
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$VAULT_DIR/00_Meta/Templates"
    mkdir -p "$VAULT_DIR/00_Meta/clusters"
    mkdir -p "$VAULT_DIR/00_Meta/system/lint-reports"
    mkdir -p "$VAULT_DIR/00_Meta/system/backups"
    mkdir -p "$VAULT_DIR/01_Inbox"
    mkdir -p "$VAULT_DIR/02_Projects"
    mkdir -p "$VAULT_DIR/03_Areas"
    mkdir -p "$VAULT_DIR/04_Resources"
    mkdir -p "$VAULT_DIR/05_Contacts/People"
    mkdir -p "$VAULT_DIR/05_Contacts/Organizations"
    mkdir -p "$VAULT_DIR/06_Archive"
  else
    drylog "WUERDE mkdir -p: $VAULT_DIR/{00_Meta/{Templates,clusters,system/{lint-reports,backups}},01_Inbox,02_Projects,03_Areas,04_Resources,05_Contacts/{People,Organizations},06_Archive}"
  fi

  # Templates (copy_if_absent — niemals ueberschreiben)
  for tmpl_file in "$REPO_DIR/vault-skeleton/00_Meta/Templates/"*.md; do
    [ -f "$tmpl_file" ] || continue
    copy_if_absent "$tmpl_file" "$VAULT_DIR/00_Meta/Templates/$(basename "$tmpl_file")"
  done

  # Vault meta files (copy_if_absent) — neue Pfade nach Restrukturierung
  copy_if_absent "$REPO_DIR/vault-skeleton/00_Meta/system/vault-index.md" \
                 "$VAULT_DIR/00_Meta/system/vault-index.md"
  copy_if_absent "$REPO_DIR/vault-skeleton/00_Meta/system/vault-log.md" \
                 "$VAULT_DIR/00_Meta/system/vault-log.md"
  copy_if_absent "$REPO_DIR/vault-skeleton/00_Meta/clusters/vault-clusters.md.template" \
                 "$VAULT_DIR/00_Meta/clusters/vault-clusters.md.template"
  copy_if_absent "$REPO_DIR/vault-skeleton/00_Meta/vault-structure.md" \
                 "$VAULT_DIR/00_Meta/vault-structure.md"
}

# =============================================================================
# Report summary
# =============================================================================
report() {
  echo ""
  echo "=============================================="
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [DRY-RUN] Zusammenfassung — $COUNT_DRY Aktionen simuliert"
    echo "  (Keine Aenderungen auf Disk gemacht)"
  else
    echo "  Bootstrap abgeschlossen!"
    echo ""
    echo "  Neue Files angelegt:   $COUNT_NEW"
    echo "  Backups erstellt:      $COUNT_BACKED"
    echo "  Unveraendert skip:     $COUNT_UNCHANGED"
    echo "  Vault kept-existing:   $COUNT_SKIPPED"
    echo ""
    if [ "$COUNT_BACKED" -gt 0 ]; then
      echo "  Backup-Files findest du via:"
      echo "  ls ~/.claude/*.bak.* ~/.claude/**/*.bak.* 2>/dev/null"
    fi
  fi
  echo "=============================================="
  echo ""
  if [ "$DRY_RUN" -eq 0 ]; then
    echo "Naechste Schritte:"
    echo "  1. Claude Code starten: claude"
    echo "  2. Im Projekt /resume ausfuehren — Hook-Output zeigt Vault-Context"
    echo "  3. MCP-Connectors: claude.ai/settings/connectors"
    echo "     Details: docs/connector-setup.md"
    echo ""
  fi
}

# =============================================================================
# Main
# =============================================================================
install_gsd() {
  echo ""
  echo "Installiere GSD (Get Shit Done) Framework..."
  echo ""

  if ! command -v npx &>/dev/null; then
    warn "npx (Node.js) nicht gefunden — GSD wird uebersprungen."
    warn "Spaeter nachinstallieren: brew install node && npx -y get-shit-done-cc --global"
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    drylog "WUERDE GSD via npx installieren: npx -y get-shit-done-cc --global"
    COUNT_DRY=$((COUNT_DRY + 1))
    return 0
  fi

  if npx -y get-shit-done-cc --global 2>&1; then
    info "GSD-Framework installiert (Commands: /gsd:* in Claude Code verfuegbar)"
    COUNT_NEW=$((COUNT_NEW + 1))
  else
    warn "GSD-Install ueber npx ist gescheitert — manueller Retry: npx -y get-shit-done-cc --global"
  fi
}

main() {
  parse_args "$@"

  echo ""
  echo "================================================"
  echo "  AI Mastermind — AI Operating System Bootstrap"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo ""
    echo "  [DRY-RUN MODE — keine Aenderungen werden gemacht]"
    echo "  (Zeigt was passieren WUERDE — sicher fuer Walkthrough)"
  fi
  echo "================================================"
  echo ""
  echo "Tipp: Falls noch nicht gemacht — fuehre zuerst 'bash preflight.sh' aus,"
  echo "      um Voraussetzungen zu pruefen (read-only)."
  echo ""

  prereq_check
  install_claude_files
  install_vault_skeleton
  install_gsd
  report
}

main "$@"
