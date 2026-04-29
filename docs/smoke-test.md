# Smoke-Test: AI Operating System Bootstrap Verifikation

Dieser Test verifiziert, dass `bootstrap.sh` auf einer frischen macOS-Umgebung korrekt funktioniert.

---

## Voraussetzung (CRITICAL — ZUERST LESEN)

**Claude Code muss auf dem Test-Account bereits via Pre-Call-Skript installiert sein.**

Verify mit `claude --version` BEVOR du `bootstrap.sh` laufen lässt.

```bash
claude --version
# Erwarteter Output: "Claude Code 2.x.xxx" oder ähnlich
```

`bootstrap.sh` installiert NUR die `~/.claude/` Config-Files, NICHT Claude Code selbst.

Falls Claude Code fehlt: `curl -fsSL https://claude.ai/install.sh | bash` im Test-Account ausführen, dann Login via Browser-OAuth zu claude.ai. Danach: `exec zsh` um PATH neu zu laden, dann `claude --version` prüfen.

---

## Test-Setup

**Variante A (sauber, empfohlen):** Neuer macOS-User-Account anlegen, dort einloggen, Claude Code installieren.

**Variante B (schnell, simuliert):**
```bash
export TEST_HOME=/tmp/test-tn-$(date +%s)
mkdir -p $TEST_HOME
# Hinweis: claude --version greift auf System-Binary zu — ist OK für Funktionstest
```

---

## Schritt 1: Repo klonen

```bash
cd ~/Desktop  # oder $TEST_HOME
git clone https://github.com/ai-os7/ai-os-starter.git
cd ai-os-starter
```

Erwarteter Output: `Cloning into 'ai-os-starter'...` ohne Fehler.

---

## Schritt 2: Dry-Run (Pflicht vor erstem echtem Run)

```bash
bash bootstrap.sh --dry-run
```

Erwarteter Output:
- Header: `[DRY-RUN MODE — keine Aenderungen werden gemacht]`
- Liste aller geplanten Aktionen ([DRY]-Labels)
- Exit 0 (kein Fehler)

**Verifikation:** Keine Files auf Disk geändert:
```bash
ls ~/.claude/ 2>/dev/null | grep -v ".bak." || echo "(leer oder nicht existent — OK fuer frische Umgebung)"
```

---

## Schritt 3: Bootstrap ausführen

```bash
bash bootstrap.sh
```

Erwarteter Output:
- prereq_check: macOS-Version OK, git OK, bash OK
- Bei Claude Code fehlt: freundliche Warnung [!!], KEIN Abbruch
- X Files installiert ([OK]-Labels)
- Vault-Skeleton angelegt
- Summary-Block mit Counts (Neue Files / Backups / Unveraendert / Vault kept)

---

## Schritt 4: Asserts

```bash
[ -f ~/.claude/CLAUDE.md ] && echo "CLAUDE.md OK" || echo "FAIL: CLAUDE.md fehlt"
[ -f ~/.claude/settings.json ] && echo "settings.json OK" || echo "FAIL: settings.json fehlt"
[ -d ~/.claude/rules ] && [ "$(ls ~/.claude/rules | wc -l | tr -d ' ')" = "4" ] && echo "rules OK (4 Files)" || echo "FAIL: rules nicht korrekt"
[ -d ~/.claude/commands ] && [ "$(ls ~/.claude/commands | wc -l | tr -d ' ')" -ge "7" ] && echo "commands OK (7+ Files)" || echo "FAIL: commands nicht korrekt"
[ -d ~/Documents/Second-Brain/00_Meta/Templates ] && echo "Vault-Templates OK" || echo "FAIL: Vault-Templates fehlen"
[ -f ~/Documents/Second-Brain/00_Meta/system/vault-index.md ] && echo "vault-index OK" || echo "FAIL: vault-index fehlt"
claude --version && echo "Claude Code OK" || echo "WARNUNG: claude binary nicht gefunden (Pre-Call noetig)"
```

---

## Schritt 5: Idempotenz-Test

```bash
bash bootstrap.sh
```

Erwarteter Output: Summary zeigt:
- Neue Files angelegt: **0**
- Backups erstellt: **0**
- Alle bestehenden Files als "Unveraendert (uebersprungen)" oder "Behalten (existiert)"

---

## Schritt 6: Backup-Test (künstliche Änderung)

```bash
echo "# test-change" >> ~/.claude/CLAUDE.md
bash bootstrap.sh
```

Erwarteter Output:
- 1 Backup `.bak.<timestamp>` angelegt für CLAUDE.md
- CLAUDE.md zurück auf Repo-Stand
- Summary zeigt: Backups erstellt: **1**

Verify:
```bash
ls ~/.claude/CLAUDE.md.bak.* && echo "Backup vorhanden — OK"
```

---

## Schritt 7: Safety-Test — Existing Vault

```bash
echo "Wichtige Notiz" > ~/Documents/Second-Brain/01_Inbox/test-note.md
bash bootstrap.sh
cat ~/Documents/Second-Brain/01_Inbox/test-note.md
```

Erwarteter Output: `Wichtige Notiz` — File unverändert nach Bootstrap.

---

## Schritt 8: Safety-Test — Andere Projekte

```bash
mkdir -p ~/Desktop/test-other-project
echo "# Mein anderes Projekt" > ~/Desktop/test-other-project/CLAUDE.md
bash bootstrap.sh
cat ~/Desktop/test-other-project/CLAUDE.md
```

Erwarteter Output: `# Mein anderes Projekt` — andere Projekt-CLAUDE.md vollständig unberührt.

---

## Schritt 9: Funktional (Claude Code)

```bash
mkdir -p /tmp/test-mastermind && cd /tmp/test-mastermind
claude
```

Innerhalb von Claude Code:
```
/resume
```

Erwarteter Output: Session-Context-Loading ohne Fehler. Hook-Output zeigt Vault-Context (falls session-init.sh korrekt installiert und ausführbar).

---

## Bei Failures

1. Lies zuerst: `docs/troubleshooting.md`
2. `claude: command not found` → Pre-Call-Schritt nicht erfüllt. `curl -fsSL https://claude.ai/install.sh | bash` ausführen.
3. Permission denied auf bootstrap.sh → `chmod +x bootstrap.sh` (eigentlich via `git clone` schon gesetzt)
4. Strukturelle Issues (Skript-Fehler, falsche Backup-Logik) → Bitte Fehler und vollständigen Terminal-Output an Affom melden.
