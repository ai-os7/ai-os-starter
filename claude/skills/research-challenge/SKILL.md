---
name: research-challenge
description: Reviewt einen Gemini Deep Research Plan kritisch gegen Projekt-Kontext (CLAUDE.md, Rules, Memory, bestehende Research, STATE.md), generiert projekt-spezifische Korrekturen und kopiert sie in die Zwischenablage. Triggert wenn jemand sagt "review research plan", "kritischer Review Gemini Plan", "Gemini Plan checken", "stell den Research-Plan auf den Pruefstand", "research-challenge".
when_to_use: |
  Trigger-Phrasen: "review research plan", "kritischer Review Gemini Plan", "Gemini Plan checken", "stell den Plan auf den Pruefstand", "research-challenge", "Gemini Research kritisch reviewen", "/research-challenge". Argument optional: der Plan als Text. Wenn nicht uebergeben, erwartet der Skill den Plan im naechsten User-Prompt.
allowed-tools: Read, Write, Glob, Grep, Bash(pbcopy:*), Bash(ls:*)
---

# Gemini Research Plan kritisch reviewen

Reviewe einen Research Plan von Gemini Deep Research, generiere projektspezifische Korrekturen und kopiere sie in die Zwischenablage.

## Argument

Optional: Der Research Plan als Text. Wenn nicht als Argument uebergeben, erwartet der Skill dass der User den Plan im naechsten Prompt einfuegt.

## Ablauf

1. **Research Plan einlesen:**
   - Lies den vom User eingefuegten Research Plan (die nummerierten Schritte die Gemini vorschlaegt)

2. **Projekt-Kontext laden:**
   - CLAUDE.md (Tech Stack, Architektur, bestehende Gotchas)
   - .claude/rules/ (Backend, Frontend, Compliance, Domain — alle relevanten)
   - memory/ Gotchas und Learnings die zum Thema passen
   - .planning/research/gemini_deep_research/ (bereits vorhandene Research-Ergebnisse)
   - .planning/STATE.md (aktueller Stand, bekannte Probleme, offene Blocker)

3. **Kritisch vergleichen — pruefe jeden Research-Schritt:**
   - Kennt Gemini unser bestehendes Setup? (Wir haben oft schon CI, Docker, Tests etc.)
   - Ist der Schritt zu generisch? (z.B. "generic PostgreSQL" statt unseres spezifischen Supabase-Setups)
   - Fehlen projekt-spezifische Herausforderungen? (bekannte Gotchas, Compliance-Constraints)
   - Fehlen ganze Themen die fuer unser Projekt relevant waeren?
   - Ist etwas dabei was wir NICHT brauchen?

4. **Korrekturen strukturieren:**
   - Format: Markdown mit klaren Abschnitten
   - "### Revise Step (N): [Grund]" — fuer Schritte die angepasst werden muessen
   - "### Add New Step: [Thema]" — fuer fehlende Bereiche
   - Jede Korrektur erklaert WAS Gemini nicht weiss und WAS stattdessen recherchiert werden soll
   - Projekt-spezifische Details einbauen (Dateinamen, Konfigurationen, bekannte Bugs)

5. **In Zwischenablage kopieren:**
   - Kopiere die kompletten Korrekturen via `pbcopy`
   - Melde: "Korrekturen in Zwischenablage ({N} Punkte). In Gemini unter 'Edit Research Plan' einfuegen."

## Output-Format

```markdown
## Corrections & Additions to the Research Plan

[Einleitungssatz: was gut ist, was fehlt]

### Revise Step (N): [Titel]

[Was Gemini nicht weiss ueber unser Setup]
[Was stattdessen recherchiert werden soll]
[Spezifische Details: Dateinamen, Konfigurationen, bekannte Bugs]

### Add New Step: [Titel]

[Warum dieses Thema fehlt]
[Was genau recherchiert werden soll]
[Projekt-Kontext der relevant ist]
```

## Hinweise

- Korrekturen in English verfassen (Gemini arbeitet auf Englisch)
- Nicht alles kritisieren — bestaetigen was gut ist, nur anpassen was fehlt
- Projekt-spezifische Details sind der Hauptmehrwert (das kann der User nicht selbst so schnell)
- Funktioniert in jedem Projekt
