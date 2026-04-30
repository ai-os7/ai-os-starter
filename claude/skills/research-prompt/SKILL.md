---
name: research-prompt
description: Generiert einen optimierten Gemini Deep Research Prompt aus Projekt-Kontext (CLAUDE.md, Rules, STATE.md, Memory) und kopiert ihn in die Zwischenablage. Triggert wenn jemand sagt "bau mir einen Prompt fuer Gemini", "generier Research-Prompt", "Gemini Deep Research Auftrag", "ich will bei Gemini X recherchieren", "research-prompt".
when_to_use: |
  Trigger-Phrasen: "bau mir einen Prompt fuer Gemini", "generier Research-Prompt", "Gemini Deep Research", "ich will bei Gemini recherchieren", "formulier mir einen Research-Auftrag", "/research-prompt". Argument: Thema oder Fragestellung.
allowed-tools: Read, Write, Glob, Grep, Bash(pbcopy:*), Bash(mkdir:*), Bash(ls:*), Bash(date:*)
---

# Gemini Deep Research Prompt generieren

Generiere einen optimierten Prompt fuer Gemini Deep Research und kopiere ihn in die Zwischenablage.

## Argument

Pflicht: Thema oder Fragestellung (z.B. "Docker build optimization for Next.js with NEXT_PUBLIC env vars").

## Ablauf

1. **Projekt-Kontext laden:**
   - CLAUDE.md (Tech Stack, Architektur, Gotchas, Konventionen)
   - .claude/rules/ (alle Rule-Dateien die zum Thema passen)
   - .planning/STATE.md (aktueller Projektstand, offene Blocker)
   - .planning/research/gemini_deep_research/ (bereits vorhandene Research, um Duplikate zu vermeiden)
   - memory/ Gotchas die zum Thema relevant sind

2. **Prompt Engineer spawnen:**
   - Spawne einen `prompt-engineer` Sub-Agent
   - Uebergib:
     - Das Thema des Users
     - Extrahierten Projekt-Kontext (Tech Stack, Constraints, bekannte Gotchas)
     - Anweisung: "Erstelle einen Gemini Deep Research Prompt in English"
   - Der Prompt soll enthalten:
     - Expert Persona fuer Gemini
     - Strukturierte Teilbereiche mit Sub-Topics
     - Comparison Tables + Implementation Sketches als gewuenschtes Output-Format
     - Scope Constraints (2025-2026 Quellen, Team-Groesse, Budget, EU-Datensouveraenitaet wo relevant)
     - Projekt-spezifische Details die Gemini kennen muss (bestehendes Setup, bekannte Probleme)

3. **Prompt in Zwischenablage kopieren:**
   - Kopiere den fertigen Prompt via `pbcopy`
   - Melde: "Prompt in Zwischenablage ({N} Woerter). In Gemini Deep Research einfuegen."

4. **Prompt als Referenz speichern:**
   - Erstelle `.planning/research/gemini_deep_research/` falls nicht vorhanden
   - Speichere den Prompt in `.planning/research/gemini_deep_research/prompt-YYYY-MM-DD-{slug}.md`
   - Damit spaeter nachvollziehbar ist, welcher Prompt zu welchem Research-Ergebnis fuehrte

## Hinweise

- Prompt MUSS in English sein (Gemini Deep Research arbeitet besser auf Englisch)
- Projekt-spezifische Details einbauen, NICHT generisch lassen
- Bekannte Gotchas aus memory/ einbeziehen wenn thematisch relevant
- Bestehende Research referenzieren damit Gemini nicht dieselben Themen wiederholt
- Funktioniert in jedem Projekt
