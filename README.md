# AI Operating System Workshop — Starter

Dieses Repository enthält das AI Operating System Setup für Teilnehmer des **AI Operating System Workshops** von Affom Birhane.

Nach dem Setup hast du ein vollständiges, persönliches AI-OS: Claude Code mit vorbereiteten globalen Instructions, Skills (auto-invokable Workflows), Slash-Commands, Hooks, und einem Obsidian Second Brain.

---

## Voraussetzungen (werden vom Preflight-Check automatisch geprüft)

Du brauchst:

- **macOS 13 (Ventura) oder neuer** — 14+ empfohlen
- **zsh als aktive Shell** (macOS-Default seit Catalina)
- **git** (Xcode Command Line Tools)
- **Claude Code** — Anthropic Installer
- **Homebrew** + **Node.js** — für GSD-Framework
- **Obsidian** — Second Brain (kostenlos, [obsidian.md](https://obsidian.md))

> **Du musst das nicht selber durchgehen.** `bash preflight.sh` checkt alles und gibt dir die exakten Install-Commands für alles was fehlt — in der richtigen Reihenfolge.

---

## Onboarding

### Schritt 0: Terminal.app öffnen + zsh sicherstellen

Öffne **Terminal.app** (nicht Cursor-Terminal — das kommt später). Spotlight (`Cmd+Space`) → "Terminal".

Falls dein Prompt mit `(base)` startet oder du irgendwo `bash-3.2$` siehst, bist du auf bash. Auf zsh wechseln:

```bash
chsh -s /bin/zsh
```

**Terminal komplett zumachen + neu öffnen** (nicht nur Tab — komplett). Das ist wichtig, damit alle PATH-Anpassungen später in der richtigen Shell-Config landen.

### Schritt 1: Repository klonen

```bash
git clone https://github.com/ai-os7/ai-os-starter.git ~/ai-os-starter
cd ~/ai-os-starter
```

> **WICHTIG:** Immer via `git clone` klonen, niemals ZIP-Download. macOS Gatekeeper kann ZIPs sonst blockieren (Quarantine-Attribut). Falls doch ZIP: `xattr -dr com.apple.quarantine ./ai-os-starter`

### Schritt 2: Preflight-Check — was fehlt noch?

```bash
bash preflight.sh
```

Read-only Check. Ändert nichts. Output zeigt grüne Häkchen für alles was schon da ist und rote Kreuze + exakte Install-Commands für alles was fehlt.

**Typischer Workflow:** Falls etwas fehlt, die ausgegebenen Install-Commands von oben nach unten ausführen (z.B. erst Homebrew, dann Node, dann Claude Code). Nach jedem Install nochmal `bash preflight.sh` — bis alle Checks grün sind.

**Häufige Reibungspunkte:**

- **Claude-Code-PATH:** Der Anthropic-Installer schreibt PATH-Hinweise nach `~/.bashrc`, auch wenn du zsh nutzt. Preflight gibt dir den korrekten Fix für deine Shell aus.
- **Homebrew auf Apple Silicon vs Intel:** Unterschiedliche `brew shellenv`-Pfade. Preflight kennt beide Varianten.
- **macOS 13:** Homebrew warnt, läuft aber. Update auf 14+ wenn möglich.

### Schritt 3: Dry-Run (Bootstrap-Vorschau)

```bash
bash bootstrap.sh --dry-run
```

Zeigt was passieren würde, ohne etwas zu schreiben. Output mit `[DRY-RUN MODE]`-Header.

### Schritt 4: Bootstrap ausführen

```bash
bash bootstrap.sh
```

Das Skript:
- Prüft Voraussetzungen
- Installiert `~/.claude/` Config-Files (CLAUDE.md, rules/, commands/, hooks/)
- Erstellt `~/Documents/Second-Brain/` PARA-Struktur + Templates
- Installiert das GSD-Framework via `npx -y get-shit-done-cc --global` (falls Node verfügbar)
- Gibt Summary mit Counts aus

Dauer: 30-60 Sekunden (länger wenn GSD über Netzwerk nachgeladen wird).

### Schritt 5: Verifizieren

```bash
ls ~/.claude/CLAUDE.md
ls ~/.claude/rules/
ls ~/.claude/commands/
ls ~/.claude/hooks/
ls ~/Documents/Second-Brain/00_Meta/Templates/
claude --version
```

### Schritt 6: Obsidian öffnen

1. Obsidian starten
2. "Open folder as vault" klicken
3. `~/Documents/Second-Brain/` auswählen
4. Vault ist jetzt mit PARA-Struktur und Templates bereit

### Schritt 7: Claude Code starten + testen

```bash
cd ~
claude
```

In der Claude-REPL:
- `/help` → Slash-Commands sichtbar
- `/brain:health-check` → Vault-Sanity-Check
- `/gsd:help` → GSD-Reference (falls Node installiert)

Falls du Cursor nutzen willst: erst jetzt Cursor öffnen — bei aktivem Cursor-Plugin **Cursor neu starten**, damit die frische `~/.claude/`-Config geladen wird.

### Schritt 8: Nächste Schritte

- **MCP-Connectors einrichten:** Gmail, Calendar, Drive, Fathom → [docs/connector-setup.md](docs/connector-setup.md)
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
├── preflight.sh              # Read-only Voraussetzungs-Check (Schritt 2)
├── bootstrap.sh              # Idempotenter Installer (Schritt 4)
├── README.md                 # Dieses Dokument
├── .gitignore                # Schützt .claude.json, .bak-Files, Logs
├── claude/                   # Mappt zu ~/.claude/
│   ├── CLAUDE.md             # Globale Claude Code Instructions
│   ├── settings.json.template # Stripped Settings (Template)
│   ├── rules/                # 4 Rule-Files
│   ├── commands/brain/       # 4 Slash-Commands (Vault-Tooling, Doppelpunkt-Namespace /brain:*)
│   ├── skills/               # 4 Skills (skill-creator, wrap-up, resume, new-project) — April-2026-Standard, auto-invokable
│   ├── hooks/                # 7 Hook-Scripts
│   └── participants/         # Per-TN Bundles — NICHT auto-installiert (manuelles cp beim Pre-Call)
│
│  GSD-Commands (/gsd:*) werden separat im Bootstrap via
│  npx -y get-shit-done-cc --global installiert — nicht im Repo.
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
