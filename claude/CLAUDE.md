# CLAUDE.md (Global)

Globale Anweisungen fuer Claude Code — gilt fuer alle Projekte.

## Session Start

1. Projekt-CLAUDE.md lesen wenn vorhanden (PFLICHT)
2. STATE.md lesen wenn vorhanden (PFLICHT). Suchreihenfolge:
   a. `.planning/STATE.md` (GSD-Konvention)
   b. `STATE.md` im Projekt-Root (pre-GSD oder Non-GSD Projekte)
   Wenn beide existieren: aeltere ignorieren, User auf Dublette hinweisen.
3. SessionStart Hook liefert automatisch: Decisions, letzter Session Log, Learning Index

## Second Brain (Obsidian Vault)

**Vault-Pfad:** `~/Documents/Second-Brain/`
**Details:** `~/.claude/rules/vault-workflow.md`

### Kontext-Routing: Was lebt wo?

| Information | Projekt-Verzeichnis | Second Brain (Vault) |
|---|---|---|
| CLAUDE.md, STATE.md, ROADMAP | Projekt | - |
| Deliverables (Code, HTML, PDFs) | Projekt | - |
| Projekt-Uebersicht (Business) | - | Vault (02_Projects/ oder 03_Areas/) |
| Meeting Notes, Decisions | - | Vault |
| Learnings, Referenzen | - | Vault |
| Personen-Kontext | - | Vault |

**Faustregel:** Wenn das Projekt geloescht wird — was willst du behalten? → Second Brain.

### Projekt-Lifecycle

Projekte (02_Projects/) haben ein Enddatum. Areas (03_Areas/) sind laufend.
Bei Statuswechsel (z.B. Firma gegruendet) → proaktiv Verschiebung vorschlagen.
NUR vorschlagen, NIEMALS eigenstaendig verschieben. Details → vault-workflow.md

### Gueltige Typen

decision, learning, session-log, person, concept, meeting, project, organization

**Templates:** `00_Meta/Templates/`, neue Vault-Dateien IMMER via Template.
**Decision Validity:** `validity: active|superseded|archived`, nur active in Kontext laden.
**Vault-Index:** `00_Meta/system/vault-index.md` (TSV, grep-basiert) und `00_Meta/system/vault-log.md` (append-only Timeline) werden von `/context-sweep`, `/vault-reindex`, `/vault-lint` gepflegt. Details in `vault-workflow.md`.

## Session Ende

Bei "Schluss", "Fertig", "Session beenden" → `/compress` ausfuehren (aktualisiert STATE.md automatisch).
Nach grosser Aufgabe (ohne /compress): Proaktiv anbieten: "Soll ich STATE.md aktualisieren?"

## Schreibstil (global)

- Keine Gedankenstriche (—, –). Stattdessen Komma, Punkt, Doppelpunkt, Klammern.
- Echte Umlaute (ä, ö, ü, ß), kein ae/oe/ue/ss. Ausnahme: Code, Dateinamen, URLs.

## Security (KRITISCH)

**NIEMALS:** API-Keys in Code, Secrets in Git, Tokens in Logs.
**Vor jedem Commit:** `git diff --cached | grep -iE "(api.?key|secret|password|token|bearer)"`

**Agent-Sicherheit (LLM-Permission-Boundaries):** `~/.claude/rules/security-basics.md` (kategorische Imperative gegen IPI, OAuth-Cross-Context, MCP-Transcript-Injection, Vault-Exfiltration).
**Code-Quality-Security:** `~/.claude/rules/security-quality.md` (OWASP, Input Validation, Quality Gates).

## Verifikation mit Playwright

Bei Erstellung/Aenderung von UI-Elementen, HTML-Dokumenten oder visuellen Deliverables:
1. Playwright oeffnet im Browser
2. Screenshot erstellen und visuell pruefen
3. Bei Problemen: iterativ verbessern (Fix → Screenshot → Verify Loop)
4. Screenshots danach sofort loeschen

## Context Management

- Hauptsession = Koordinator, Sub-Agents = Arbeiter
- MCP-Abfragen mit grossen Responses → via Sub-Agent delegieren (Context-Schutz)
- Unabhaengige Aufgaben → parallel (mehrere Tool-Calls in einer Nachricht)
- Agent-Typen: `Explore` (Codebase), `general-purpose` (Multi-Step), `Plan` (Architektur), Feature-Dev-Familie
- Agent-Teams experimentell via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, wenn Multi-Hypothesen noetig

## Self-Learning

Problem geloest oder neues Pattern entdeckt → Learning im Vault dokumentieren:
In `01_Inbox/` als neue Learning-Datei anlegen. /context-sweep sortiert spaeter ein.
Frontmatter mit `type: learning` setzen, damit es automatisch im Learning Index erscheint.

## Regeln (Details)

- CLAUDE.md kurz halten: Global max ~150 Zeilen, Projekt max ~100 Zeilen. Details in Rules auslagern.

| Thema | Datei |
|-------|-------|
| Full-Stack Patterns | `~/.claude/rules/fullstack-patterns.md` |
| Security Basics (Agent-Permissions) | `~/.claude/rules/security-basics.md` |
| Security & Quality (Code) | `~/.claude/rules/security-quality.md` |
| Vault Workflow | `~/.claude/rules/vault-workflow.md` |

**Archiv (on-demand, nicht auto-geladen):** `~/.claude/rules-archive/` — `n8n-patterns.md` (Workflow-Quality-Checklists, falls wieder n8n-Projekt). Bewusst ausserhalb `rules/` damit die Harness es nicht auto-loaded.
