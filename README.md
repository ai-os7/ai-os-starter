# AI Operating System Workshop — Starter

Dieses Repository enthält das AI Operating System Setup für Teilnehmer des **AI Operating System Workshops** von Affom Birhane.

Nach dem Setup hast du ein vollständiges, persönliches AI-OS: Claude Code mit vorbereiteten globalen Instructions, Slash-Commands, Hooks, und einem Obsidian Second Brain.

---

## Voraussetzungen

Bevor du anfängst, stelle sicher:

1. **macOS 13 (Ventura) oder neuer** — `sw_vers -productVersion`
2. **git installiert** — kommt mit Xcode Command Line Tools (`xcode-select --install`)
3. **Claude Code installiert** — wird im Pre-Call mit Affom eingerichtet:
   ```
   curl -fsSL https://claude.ai/install.sh | bash
   ```
4. **Obsidian installiert** — Download: [obsidian.md](https://obsidian.md) (kostenlos)

> **HINWEIS:** Claude Code und Obsidian werden NICHT von `bootstrap.sh` installiert. Das passiert im Pre-Call mit Affom. `bootstrap.sh` installiert nur die Config-Files.

---

## 6-Schritte-Onboarding

### Schritt 1: Repository klonen

```bash
git clone https://github.com/ai-os7/ai-os-starter.git ~/Desktop/projects/ai-os-starter
cd ~/Desktop/projects/ai-os-starter
```

> **WICHTIG:** Immer via `git clone` klonen, niemals ZIP-Download. Sonst kann macOS Gatekeeper das Skript blockieren (Quarantine-Attribut). Falls du trotzdem ein ZIP heruntergeladen hast: `xattr -dr com.apple.quarantine ./ai-os-starter`

### Schritt 2: Dry-Run zuerst (empfohlen)

Bevor du bootstrap.sh ausführst, sieh dir an, was es tun würde — ohne dass etwas auf deiner Festplatte verändert wird:

```bash
bash bootstrap.sh --dry-run
```

Erwarteter Output: Header `[DRY-RUN MODE — keine Aenderungen werden gemacht]`, gefolgt von einer Liste aller geplanten Aktionen. Exit 0 (kein Fehler). Nützlich für den Pre-Call-Walkthrough.

### Schritt 3: Bootstrap ausführen

```bash
bash bootstrap.sh
```

Das Skript:
- Prüft Voraussetzungen (macOS-Version, git)
- Gibt eine freundliche Warnung aus wenn Claude Code fehlt (kein Abbruch)
- Installiert `~/.claude/` Config-Files (CLAUDE.md, rules/, commands/, hooks/)
- Erstellt `~/Documents/Second-Brain/` PARA-Struktur + Templates
- Gibt einen Summary mit Counts aus

Dauer: ca. 10-30 Sekunden.

### Schritt 4: Verifizieren

```bash
# Config-Files prüfen
ls ~/.claude/CLAUDE.md
ls ~/.claude/rules/
ls ~/.claude/commands/
ls ~/.claude/hooks/

# Vault-Skeleton prüfen
ls ~/Documents/Second-Brain/00_Meta/Templates/

# Claude Code Version
claude --version
```

### Schritt 5: Obsidian öffnen

1. Obsidian starten
2. "Open folder as vault" klicken
3. `~/Documents/Second-Brain/` auswählen
4. Vault ist jetzt mit PARA-Struktur und Templates bereit

### Schritt 6: Nächste Schritte

- **MCP-Connectors einrichten:** Gmail, Calendar, Drive, Fathom → [docs/connector-setup.md](docs/connector-setup.md)
- **Claude Code testen:** Neues Projekt anlegen, `claude` starten, `/resume` ausführen
- **Workshop-Materialien:** Kommen vom Trainer im Pre-Call

---

## Was macht bootstrap.sh?

`bootstrap.sh` ist ein **idempotenter File-Installer** — es kopiert Config-Files an die richtigen Stellen.

**Konkret:**
- Kopiert `claude/CLAUDE.md` → `~/.claude/CLAUDE.md` (mit Backup falls vorhanden)
- Kopiert `claude/rules/*.md` → `~/.claude/rules/` (mit Backup)
- Kopiert `claude/commands/*.md` → `~/.claude/commands/` (mit Backup)
- Kopiert `claude/hooks/*` → `~/.claude/hooks/` + setzt `chmod +x`
- Erstellt `~/Documents/Second-Brain/` Ordnerstruktur (PARA: 00_Meta, 01_Inbox, 02_Projects, 03_Areas, 04_Resources, 05_Contacts, 06_Archive)
- Legt Templates und vault-index/log an (nur wenn noch nicht vorhanden)

**Idempotent:** Zweiter Durchlauf nach erfolgreichem ersten → 0 Änderungen (alles bereits vorhanden).

---

## Was macht es NICHT?

- Installiert **NICHT** Claude Code (das passiert im Pre-Call via `curl -fsSL https://claude.ai/install.sh | bash`)
- Setzt **NICHT** MCP-Connectors auf (Browser-OAuth via [claude.ai/settings/connectors](https://claude.ai/settings/connectors))
- Geht **NICHT** in andere Projekt-Ordner (z.B. `~/projects/...`) — projekt-spezifische `CLAUDE.md`-Files in deinen anderen Repos bleiben unangetastet
- Ändert **NICHT** zsh-Config, PATH, Shell-Aliases
- **WARNUNG: Niemals `~/.claude.json` ins Repo committen** — diese Datei enthält OAuth-Tokens und persönliche Auth-Daten. Sie liegt bewusst außerhalb von `~/.claude/` und wird von `.gitignore` abgedeckt.

---

## Was passiert mit meinen vorhandenen Files?

- **`~/.claude/CLAUDE.md` existiert:** wird mit Backup `.bak.<timestamp>` gesichert, dann mit Repo-Version überschrieben. Dein Custom-Inhalt steckt in der `.bak`-Datei und kann zurückgespielt werden.
- **`~/.claude/settings.json` existiert:** bleibt **vollständig unberührt**. Du erhältst nur einen Diff-Hinweis. Workshop-Hooks musst du manuell aus `settings.json.template` übernehmen.
- **Bestehender Obsidian-Vault** unter `~/Documents/Second-Brain/`: wird **nur ergänzt** mit PARA-Struktur. Bestehende Notizen, Dateien, Ordner bleiben unangetastet.
- **Custom Slash-Commands** unter `~/.claude/commands/` mit eigenen Namen (z.B. `my-cmd.md`): bleiben unberührt. Nur Files mit gleichen Namen wie Repo-Files werden mit Backup überschrieben.

Backup-Files findest du via:
```bash
ls ~/.claude/*.bak.* ~/.claude/**/*.bak.* 2>/dev/null
```

---

## Troubleshooting

Siehe [docs/troubleshooting.md](docs/troubleshooting.md) für:
- Quarantine-Attribut Probleme (ZIP statt git clone)
- `claude: command not found`
- Backup-Files wiederherstellen
- Vault unter anderem Pfad
- Hooks nicht aktiv

---

## Repo-Struktur

```
ai-os-starter/
├── bootstrap.sh              # Idempotenter Installer (dieses Skript)
├── README.md                 # Dieses Dokument
├── .gitignore                # Schützt .claude.json, .bak-Files, Logs
├── claude/                   # Mappt zu ~/.claude/
│   ├── CLAUDE.md             # Globale Claude Code Instructions
│   ├── settings.json.template # Stripped Settings (Template)
│   ├── rules/                # 4 Rule-Files
│   ├── commands/             # 7 Slash-Commands
│   └── hooks/                # 7 Hook-Scripts
├── vault-skeleton/           # Mappt zu ~/Documents/Second-Brain/
│   ├── 00_Meta/
│   │   ├── Templates/        # 8 Obsidian-Templates
│   │   ├── vault-index.md    # Leer (Header only, /brain:sort-inbox befüllt)
│   │   ├── vault-log.md      # Append-only Chronik
│   │   └── vault-clusters.md.template
│   ├── 01_Inbox/
│   ├── 02_Projects/
│   ├── 03_Areas/
│   ├── 04_Resources/         # Flach
│   ├── 05_Contacts/{People,Organizations}/
│   └── 06_Archive/
└── docs/
    ├── connector-setup.md    # MCP-Connector-Setup (Gmail/Calendar/Fathom)
    ├── smoke-test.md         # Verifikations-Prozedur
    └── troubleshooting.md    # Bekannte Probleme + Lösungen
```

---

## Lizenz

Für Teilnehmer des AI Operating System Workshops. Nicht für Weiterverteilung ohne Erlaubnis.
