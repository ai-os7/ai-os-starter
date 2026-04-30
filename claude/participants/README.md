# Participants Track — NICHT Standard-Setup

Dieses Verzeichnis enthaelt **per-Teilnehmer** Skills, Notizen und Ressourcen. **Wird NICHT automatisch durch `bootstrap.sh` installiert.**

Zweck: Workshop-TN bekommen zusaetzlich zu den Standard-Skills (`claude/skills/`) individuell gebaute Skills, die auf ihren konkreten Branchenkontext zugeschnitten sind. Beispiel: Investment-Pre-Screening-Skill fuer einen Real-Estate-Investor.

## Struktur

```
participants/
├── README.md          # dieses File
├── <kuerzel>/         # ein Subordner pro TN, Initialen als Kuerzel
│   ├── README.md      # Was ist drin, wie installieren
│   └── skills/
│       └── <skill>/SKILL.md
```

## Aktive Kuerzel

| Kuerzel | Status |
|---|---|
| `lm` | Platzhalter, Skill kommt nach Pre-Call (Mo 5.5.) |

## Installation eines TN-Bundles

Wird vom Workshop-Host beim Pre-Call manuell ausgefuehrt:

```bash
cp -r ~/Desktop/projects/ai-os-starter/claude/participants/<kuerzel>/skills/* ~/.claude/skills/
```

Danach Claude Code restart, damit neue Skills auto-invokable sind.

## Fuer TN nicht selbst nutzen

Standard-Onboarding via `bash bootstrap.sh` reicht aus, um produktiv zu starten. `participants/` ist Workshop-Host-Material, nicht Self-Service.
