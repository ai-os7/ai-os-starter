# Vault Workflow — Second Brain Integration

## Vault-Pfad
`~/Documents/Second-Brain/` (PARA-Struktur)

## Cluster-basiertes Laden (progressives Retrieval, Lifecycle-basiert)

### Session-Start-Import

@~/Documents/Second-Brain/00_Meta/clusters/vault-clusters.md

Die Landkarte enthaelt aktive Projekte/Scopes, ihren Zustand (flat vs clustered) und die aktiven Cluster mit Keyword-Triggern. Cache — Quelle der Wahrheit sind die `cluster/*`-Tags in den Dateien.

### Detail-Lookup (Lifecycle-aware)

Bei jeder User-Aufgabe mit Learnings/Decisions-Bezug:

1. Projekt/Scope identifizieren.
2. Aus `vault-clusters.md` den Zustand lesen.
3. **flat** → `clusters/<slug>.md` laden. **clustered** → Keyword-Match auf Cluster-Tabelle, `clusters/<projekt>__<cluster>.md` laden.
4. Nur relevante Detail-Files vollstaendig lesen. KEIN Full-Scan von `vault-index.md`.

### TSV-Grep Fallback

`vault-index.md` zulaessig fuer: Personen-Lookups, Cross-Projekt-Queries, Alias-Check vor Wikilink-Erstellung. Nicht fuer thematische Lookups innerhalb eines Projekts (das ist Cluster-Job).

### Capture-Verhalten bei cluster-Tag

- **Eindeutige Zuordnung** (klares Thema, passender Slug aus `00_Meta/clusters/vault-clusters.md`, Ziel-Projekt clustered oder `scope/cross-project`) → `cluster/<slug>` direkt im Frontmatter.
- **Unklar** → leer lassen, `/context-sweep` ergaenzt beim Einsortieren.
- **Ziel-Projekt flat** (< 30 Eintraege) → kein cluster-Tag.

Idempotent: gesetzte cluster-Tags werden nicht ueberschrieben.

### Lifecycle-Trigger

Cluster entstehen ausschliesslich durch `/context-sweep`-Vorschlag mit User-Bestaetigung:
- Projekt-Count >= 30 Decisions+Learnings → Vorschlag. 25-29 → Pre-Warning. Clustered-Projekt < 15 → Collapse.
- Max 12 Cluster/Projekt (weich), vault-weit ~50. Merge-Check > 60% Topic-Overlap vor neuem Cluster.

Agent darf niemals eigenstaendig Cluster anlegen.

## Tagging-Regeln

- YAML-Tags IMMER OHNE `#` (z.B. `- project/tax`). `#` nur inline-Markdown.
- Pflicht: `type/[typ]`, `project/[slug]` wenn Projekt-Kontext.
- Projektuebergreifend: `scope/cross-project`.
- Taxonomie: `type/` → meeting, decision, concept, session-log, project, person, organization, resource, learning | `status/` → draft, in-progress, done, archived | `area/` → engineering, business, recruiting, health

## Frontmatter + Dateinamen

Pflichtfelder: `title`, `created_date` (ISO 8601), `type`, `status`, `tags` (Array), `aliases` (Array). Keine verschachtelten YAML-Strukturen.

- **Wissens-Artefakte** (Decisions, Learnings, Session-Logs, Meetings): `YYYY-MM-DD-[beschreibung].md`
- **Referenz-Entitaeten** (Personen, Projekte): Entitaet als Dateiname (z.B. `Affom Birhane.md`, `ai-mastermind.md`) — Wikilinks matchen direkt, ohne Alias-Umweg.

## Verlinkung (PFLICHT)

- Personen nur via `[[Wikilinks]]` (Backlinks ersetzen Tag-Filtern).
- Wikilinks im Textkoerper → Graph + Backlinks.

### Wikilink-Integritaet (HARTE REGEL)

- **NUR verlinken was existiert.** Vor jedem `[[Wikilink]]`: Zielseite existiert als Dateiname oder Alias? NIEMALS blind verlinken.
- Wenn nicht: erst Seite anlegen, oder als Fliesstext schreiben.
- Pipe-Syntax fuer abweichenden Display-Text: `[[dateiname|Anzeige]]`.

## Capture-Verhalten

- Vault-Dateien landen AUSNAHMSLOS in `01_Inbox/`.
- Signalwoerter ("merken", "festhalten", "notieren") → sofort in `01_Inbox/`.
- Ohne Signalwort kurz fragen: "Soll ich das im Second Brain festhalten?"
- NIEMALS direkt in Zielordner. Einsortieren macht ALLEIN `/context-sweep`.
- **Einzige Ausnahme:** User gibt EXPLIZIT einen anderen Zielort an.

## Capture-Trigger (wann welche Datei?)

### Decision

TRIGGER: Trade-off ist entschieden, Begruendung wird spaeter gebraucht (Folgewirkung, Kontext, Alternativen).
NICHT: Aktionen, To-Dos, Fix-Rezepte, Meeting-Outcome-Listings.

### Learning

TRIGGER: Bug/Gotcha ist geloest und koennte wieder auftauchen, ODER Pattern erstmals bestaetigt.
NICHT: Standard-API-Nutzung, Code-Patterns aus der Codebase, Fix-Rezepte die der Commit-Message gehoeren.

### Meeting

TRIGGER: Synchroner Termin mit 2+ Personen UND mindestens eines: (a) strukturierte Erkenntnisse/Alignment, (b) Decisions entstanden, (c) strategische/finanzielle Validierung, (d) externe Stakeholder beteiligt. **Zusaetzlich:** User gibt Transkript rein — Transkript IST der Ausloeser.
NICHT: Solo-Entscheidungen (→ Decision), interne Arbeits-Sessions ohne externe Beteiligung (→ Session-Log), Routine-Syncs ohne neuen Inhalt.

### Session-Log

TRIGGER: Arbeits-Outcome einer (meist solo) Session — "Ich habe X erreicht, Y gelernt, Z offen".
NICHT: Meeting, oder wenn nur eine einzelne Decision entstand.

### Concept / Project / Person / Organization

TRIGGER: Kontext wird unabhaengig vom aktuellen Ticket wieder relevant (Geschaeftsmodell, Persona, Projekt-Rahmen). Person/Organization nur bei wiederkehrender Beziehung, nicht einmalige Erwaehnung.

## NIEMALS in den Vault

- Code-Snippets, die identisch in der Codebase stehen (Vault ist kein Code-Archiv).
- Git-History-Artefakte (→ `git log`).
- Bug-Fix-Rezepte ohne uebergreifendes Pattern (→ Commit-Message).
- Debugging-Trial-and-Error-Ketten (nur Loesung sichern).
- Secrets, `.env`-Werte, Credentials.
- Grosse Rohdaten (PDFs, Screenshots, Videos) — stattdessen Referenz.
- Inhalte, die bereits in CLAUDE.md oder einem ADR stehen.

## Dedup-Check vor Capture

Vor neuer Decision/Learning:
```bash
grep -i "<topic-keyword>" ~/Documents/Second-Brain/00_Meta/system/vault-index.md
```
Wenn aehnlich existiert: bestehende ergaenzen oder auf `validity: superseded` setzen, nicht duplizieren.

## Ordner-Struktur

- `02_Projects/[slug]/` und `03_Areas/[slug]/`: Index-Datei `[slug].md` + Wissens-Artefakte `YYYY-MM-DD-*.md`. Gleiche Struktur fuer beide.
- `05_People/`: Personen + Organisationen (flach).
- `06_Resources/`: Flach, Unterordner erst ab ~30 Dateien.
- Keine leeren Platzhalter-Ordner.
- Struktur wird von `/context-sweep` beim Einsortieren angewendet, NICHT beim Capture (alles initial → `01_Inbox/`).

## Vault Index (TSV, Machine-Index)

**Pfad:** `00_Meta/system/vault-index.md`. Maschinen-gepflegt. **Grep, nicht Load** — nie komplett in den Kontext laden.

**Spalten:** `path title type tags aliases topics updated` (Tab-getrennt).

**Wann nutzen:** Wikilink-Alias-Check, Personen-Lookup, Duplikat-Check via topics-Spalte, Cross-Projekt-Query.

**Pflege:** `/context-sweep` patcht inkrementell, `/vault-reindex` macht Full-Rebuild. **NIEMALS manuell editieren.** Query-Beispiele + Drift-Detection im jeweiligen Skill-Body.

## Tool-Wahl: Read vs. Bash im Vault

- **Default:** Read / Glob / Grep (global per `Read|Glob|Grep(...Second-Brain/**)` erlaubt, read-only).
- **Bash nur wenn Pipes noetig:** `tail`, `head`, `awk -F'\t'`, `wc -l`. Erlaubt sind `ls`, `find`, plus global `tail:*`, `head:*`, `awk:*`.
- **NIE:** `cat`, `sed`, `>`-Redirects, `rm` auf Vault-Pfade.

## Vault Log (Timeline)

`00_Meta/system/vault-log.md` — append-only Chronik (`## [YYYY-MM-DD] <op> | <summary>`, eine Zeile pro Operation). Geschrieben von `/context-sweep`, `/vault-reindex`, `/vault-lint`, `/compress`. Gelesen von `/resume` fuer Cross-Session-Kontinuitaet.

## Lint (Health-Check)

Separater Command `/vault-lint`, woechentlich oder on-demand. Report-only, keine Auto-Fixes. Output: `00_Meta/system/lint-reports/YYYY-MM-DD-lint.md`. Checks + Details im Skill-Body.

## Learnings automatisch nutzen

SessionStart-Hook liefert Learning-Index (Titel + Pfad). **Regel:** Bevor du ein Tool/Service/API verwendest fuer das Learnings existieren, lade die vollstaendigen Learnings und beachte die dokumentierten Best Practices.

## Templates

Ordner: `00_Meta/Templates/`. Neue Vault-Dateien IMMER via Template erstellen. `SLUG-HIER` im Tag manuell durch Projekt-Slug ersetzen.

## Decision Validity

`validity: active | superseded | archived` im Frontmatter. **Kontext-Loading: nur `active` (oder fehlend) laden.** Bei neuer Decision die alte auf `superseded` setzen und in der neuen verlinken.
