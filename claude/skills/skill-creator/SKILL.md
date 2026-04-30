---
name: skill-creator
description: Hilft dir, einen wiederkehrenden Workflow als Claude Code Skill anzulegen oder einen bestehenden Slash-Command zu einem Skill zu migrieren. Triggert wenn jemand sagt "ich mache X taeglich", "automatisier das", "mach daraus einen Skill", "ich kopier immer denselben Prompt", "Claude soll sich merken", "wiederkehrend", "bau mir einen Skill", "neues Skill anlegen", "migriere den Command zum Skill".
when_to_use: |
  Trigger-Phrasen (Deutsch): "automatisier das", "mach daraus einen Skill", "ich mache das taeglich", "Claude soll sich merken", "wiederkehrend", "bau mir einen Skill", "skill anlegen", "skill erstellen", "command zu skill migrieren", "skill-creator". Englisch ebenfalls erlaubt: "build me a skill", "automate this", "turn into a skill".
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, Bash(mkdir:*), Bash(ls:*), Bash(rm:*), Bash(cp:*)
---

# Skill Creator

Du baust aus einem wiederkehrenden Workflow einen sauberen, token-effizienten Claude Code Skill. Adaptiv: wenn der User schon viel Kontext geliefert hat, springst du direkt zur Verifikation. Wenn er nur "bau mir einen Skill" sagt, fuehrst du ihn durch einen kompakten Wizard.

## Modus-Erkennung (immer als erstes)

Schaue dir die letzte User-Nachricht plus Konversations-Kontext an und entscheide:

- **Cold Start** — User sagt nur eine Trigger-Phrase ohne Details ("Ich will einen Skill bauen", "automatisier das"). Du weisst nichts ueber den Workflow. → **Wizard-Modus** unten.
- **Warm Start** — User hat schon konkrete Details geliefert ("Bau einen Skill der Pitch-Decks aus ~/Inbound liest und in deal-pipeline schreibt"). → **Inferenz + Sammel-Verifikation** unten.
- **Autonomous** — User sagt explizit "skip wizard", "bau einfach", "vertrau mir, leg an", "no questions". → **Autonomous-Modus** unten.

Sage dem User in 1 Satz welchen Modus du gewaehlt hast und warum, bevor du startest.

## Wizard-Modus (Cold Start)

Nutze AskUserQuestion fuer strukturierte Fragen. **Eine Frage pro Aufruf**, jede mit 3-4 Multiple-Choice-Optionen plus "Bin mir nicht sicher". Wenn der User "Bin mir nicht sicher" waehlt, leite aus Kontext ab oder frage konkret nach im Free-Text.

### Frage 1 — Aufgabe

```
question: "Was machst du wiederkehrend? Welche Aufgabe willst du automatisieren?"
options:
  - "Daten aus Dateien rausziehen (PDFs, Mails, Webseiten)"
  - "Notizen oder Memos in mein Vault schreiben"
  - "Etwas pruefen oder bewerten (Pitch-Decks, Bewerbungen, Deals)"
  - "Bin mir nicht sicher — lass mich frei beschreiben"
```

Falls "frei beschreiben": stell eine offene Folge-Frage ohne AskUserQuestion ("Erzaehl mir in 1-2 Saetzen was du machst") und mappe selbst auf eine Kategorie.

### Frage 2 — Trigger

```
question: "Wann soll der Skill anspringen?"
options:
  - "Ich tippe einen Slash-Command (z.B. /screen-deal)"
  - "Ich sage in Worten was ich brauche, KI erkennt selbst"
  - "Beides — manchmal so, manchmal so"
  - "Bin mir nicht sicher"
```

Mapping:
- Slash-only → `disable-model-invocation: true` setzen
- KI erkennt → ausfuehrliche `description` + `when_to_use`
- Beides → Default (keine `disable-model-invocation`-Flag)
- Unsicher → Default

### Frage 3 — Input

```
question: "Was liest der Skill als Input?"
options:
  - "Eine Datei aus einem Ordner (z.B. neuestes PDF)"
  - "Inhalt einer URL oder Webseite"
  - "Text den ich tippe oder diktiere"
  - "Nichts — Skill hat alle Infos schon"
  - "Bin mir nicht sicher"
```

### Frage 4 — Output

```
question: "Was produziert der Skill?"
options:
  - "Eine neue Datei (z.B. Memo im Vault)"
  - "Eine bestehende Datei aktualisieren"
  - "Eine Antwort hier im Chat (kein File)"
  - "Bin mir nicht sicher"
```

### Frage 5 — Web-Research

```
question: "Soll der Skill im Web recherchieren?"
options:
  - "Ja — Web-Search mit Quellen (Perplexity oder Tavily)"
  - "Ja — nur eine bekannte URL aufrufen"
  - "Nein"
  - "Bin mir nicht sicher"
```

### Tools-Mapping (Skill macht das selbst)

User soll YAML nicht lernen. Mappe Antworten:

| Antwort | `allowed-tools` |
|---|---|
| Datei lesen | `Read, Glob` |
| Datei schreiben (neu) | `Write` |
| Datei aktualisieren | `Edit` |
| URL aufrufen | `WebFetch` |
| Web-Search mit Quellen | `mcp__perplexity-ask__*` falls verfuegbar, sonst `mcp__tavily*`, sonst `WebSearch` |
| Ordner anlegen | `Bash(mkdir:*)` |
| Datei loeschen | `Bash(rm:*)` |

## Warm-Start-Modus

User hat schon Details geliefert. Inferiere alles aus dem Kontext:

```
Skill-Name:       <vorschlag-slug>
Pfad:             ~/.claude/skills/<name>/SKILL.md
Trigger:          <auto-invoke / nur slash / beides>
Trigger-Phrasen:  "<phrase 1>", "<phrase 2>", "<phrase 3>"
Input:            <was der Skill liest>
Output:           <was der Skill schreibt>
Tools:            <liste>
Was er tut:       <1-Satz-Klartext>
```

Zeige diese Skizze, dann **eine** AskUserQuestion:

```
question: "Stimmt diese Skizze fuer deinen Skill?"
options:
  - "Ja, los — bau das so"
  - "Nein, lass mich korrigieren"
  - "Ich will lieber durch den Wizard gefuehrt werden"
```

Bei "korrigieren": offene Frage was geaendert werden soll.
Bei "Wizard": springe zu Wizard-Modus.

## Autonomous-Modus

Inferiere alles, zeige NUR finale Skizze + Pfad als einzige AskUserQuestion:

```
question: "Ich lege folgenden Skill an:\n  Name: <name>\n  Pfad: ~/.claude/skills/<name>/SKILL.md\n  Was er tut: <1-Satz>\nOK?"
options:
  - "Ja, anlegen"
  - "Nein, doch lieber Wizard"
```

## Vor Write — IMMER (alle drei Modi)

Letzte Confirmation-Gate vor `Write`. Zeige:

```
Skill-Name:       <name>
Pfad:             ~/.claude/skills/<name>/SKILL.md
Trigger-Phrasen:  <liste>
Tools:            <liste>
Body-Outline:     <Schritt 1, 2, 3 ...>
```

AskUserQuestion: "Anlegen?"
- "Ja, anlegen"
- "Nein, abbrechen"

## Skill schreiben

Wenn YAML-Felder unklar sind, lies `references/frontmatter-cheatsheet.md`. Wenn die Primitiv-Wahl unklar ist (Skill / Subagent), lies `references/decision-tree.md`.

Schritte:

1. `mkdir -p ~/.claude/skills/<name>`
2. `Write ~/.claude/skills/<name>/SKILL.md` mit folgender Struktur:

```markdown
---
name: <name>
description: <was-er-tut>. Triggert wenn <trigger-phrase-1>, <trigger-phrase-2>, oder wenn jemand "<woertliche phrase>" sagt.
when_to_use: |
  Trigger-Phrasen: "<phrase 1>", "<phrase 2>", ...
allowed-tools: <liste>
---

# <Skill-Name>

<1-2 Zeilen: was produziert der Skill>

## Workflow

1. **<Schritt-Name>**: <Was passiert>
2. **<Schritt-Name>**: ...

## <Optional: Output-Format>

<Beispiel kompakt>
```

**Body-Regeln:**
- < 200 Zeilen Total
- Schritte nummeriert + aktiv formuliert
- Lange Beispiele in `examples/<name>.md`, nicht inline
- Inline-Tabellen nur fuer Quick-Reference (max 10 Zeilen)

## Bericht nach Erstellung

Gib am Ende aus:

```
Skill angelegt: ~/.claude/skills/<name>/SKILL.md

Trigger-Phrasen die ihn auto-invoken:
  - "<phrase 1>"
  - "<phrase 2>"

Test jetzt:
  - Slash:    /<name>
  - Auto:     "<konkrete Test-Phrase>" (sollte den Skill auto-invoken)

Hinweis: Falls Auto-Invoke nicht triggert, Claude Code restart noetig — brand-neue Skill-Verzeichnisse brauchen Reload.
```

## Migrations-Modus (Spezialfall)

User sagt "migriere mir den `<name>`-Command zum Skill" oder "mach aus dem Command einen Skill".

Workflow:

1. `Read ~/.claude/commands/<name>.md`
2. Inferiere die Skizze (description erweitert mit Trigger-Phrasen, Body 1:1, Tools-Allowlist aus Body-Inhalt ableiten)
3. Zeige Skizze, AskUserQuestion: "Migration so durchfuehren?" (Ja / Korrigieren / Abbrechen)
4. Bei Ja: `mkdir -p ~/.claude/skills/<name>` + `Write SKILL.md`
5. AskUserQuestion: "Skill testen — funktioniert Slash-Aufruf?" mit Optionen "Ja, alten Command loeschen" / "Nein, Skill behalten + alten auch behalten" / "Skill loeschen, Migration zurueck"
6. Bei "alten loeschen": `rm ~/.claude/commands/<name>.md`
7. AskUserQuestion: "Auch in ai-os-starter spiegeln?" (Ja / Nein)
8. Bei Ja: `cp -r ~/.claude/skills/<name> ~/Desktop/projects/ai-os-starter/claude/skills/` + `rm ~/Desktop/projects/ai-os-starter/claude/commands/<name>.md`

## Anti-Patterns (vermeiden)

- Skill ohne Trigger-Phrasen → wird nie auto-invoked
- SKILL.md > 500 Zeilen → token-teuer + schwer wartbar
- Lange Beispiele inline statt in `examples/`
- Sprache mischen (User arbeitet in Deutsch → Trigger-Phrasen in Deutsch, nicht Englisch)
- Hardcoded Listen die woanders schon Single-Source-of-Truth sind
- Vergessen den User vor `Write` zu fragen
- Im Wizard-Modus mehr als 5 Fragen stellen — kuerzer ist besser

## Weiterfuehrend

- YAML-Frontmatter-Cheatsheet: [references/frontmatter-cheatsheet.md](references/frontmatter-cheatsheet.md)
- Wann Skill, wann Subagent: [references/decision-tree.md](references/decision-tree.md)
- Best-in-class Beispiel-Skill: [examples/good-skill-example.md](examples/good-skill-example.md)
