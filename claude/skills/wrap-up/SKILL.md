---
name: wrap-up
description: Beendet die Session und sichert das Wissen im Second Brain (Inbox-Files, STATE.md-Update, Vault-Log). Triggert wenn jemand sagt "lass uns Schluss machen", "Session beenden", "wir sind fertig", "session wrap up", "speicher das alles", oder explizit "/wrap-up" tippt.
when_to_use: |
  Trigger-Phrasen: "lass uns Schluss machen", "Session beenden", "wir sind fertig", "wrap up", "session ist durch", "sicher das ab", "speichere die Session", "/wrap-up". Nicht triggern wenn der User nur "fertig" als Antwort auf eine andere Frage sagt — Kontext beachten.
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, Bash(grep:*), Bash(ls:*)
---

# Session beenden und Wissen sichern

Du bist ein Session-Archivar. Sichere das Wissen dieser Session im Second Brain.

## Schritte

1. **Session zusammenfassen**
   Was wurde besprochen/erledigt? Entscheidungen? Offene Fragen? Naechste Schritte?

2. **Wissens-Extraktion — ALLE Quellen der Session durchgehen**
   Pruefe systematisch JEDE Informationsquelle dieser Session auf langfristigen Mehrwert:
   - Konversation: Entscheidungen, Erkenntnisse, Aha-Momente
   - Erstellte/geaenderte Dateien: Research-Ergebnisse, Analysen, Berechnungen
   - Projekt-Dateien: Konfigurationen, Referenzdokumente, Kataloge
   - Externe Quellen: API-Responses, Web-Recherchen, Dokumentationen
   Fuer jede Quelle fragen: "Gibt es hier etwas, das ueber diese Session hinaus wertvoll ist?"
   Lieber eine Erkenntnis zu viel in die Inbox als eine wichtige Information verlieren.
   Die Inbox ist ein Sicherheitsnetz — /brain:sort-inbox entscheidet spaeter was bleibt.

3. **Vorschlaege dem User praesentieren**
   Konkrete Liste mit Typ-Zuordnung:
   - Decisions: Getroffene Entscheidungen mit Kontext und Begruendung
   - Learnings: Gotchas, Best Practices, ueberraschende Erkenntnisse
   - Session Log: Zusammenfassung fuer Kontext-Wiederherstellung
   - Persons: Neue oder aktualisierte Personen-Kontexte
   - Concepts: Zeitlose Erkenntnisse, Frameworks
   - Meetings: Meeting Notes mit Teilnehmern und Ergebnissen
   Der User waehlt aus oder sagt "alles".
   Nach Auswahl DIREKT schreiben — nicht nochmal nachfragen.

3.5 **Projekt-Tag setzen**
    - Lies den Projekt-Tag aus der CLAUDE.md (`## Vault-Integration` → `Projekt-Tag: project/[slug]`)
    - Setze diesen Tag im Frontmatter JEDER Vault-Datei die aus dieser Session entsteht
    - Bei projektuebergreifenden Learnings/Decisions: zusaetzlich `scope/cross-project` setzen
    - Wenn kein Projekt-Tag vorhanden: keinen project/-Tag erzwingen

4. **Ausgewaehlte Punkte in den Vault schreiben**
   - Ziel: `~/Documents/Second-Brain/01_Inbox/`
   - Dateiname: `YYYY-MM-DD-[beschreibung].md`
   - Korrektes Frontmatter setzen (title, created_date, type, status: draft, tags, aliases)
   - Tags aus der definierten Taxonomie verwenden (#type/, #status/, #project/)
   - **VERLINKUNG PFLICHT:** Personen nur via `[[Wikilinks]]` referenzieren (keine human/-Tags). Backlinks ersetzen tag-basiertes Filtern fuer Personen.
     Wikilinks → Graph-Verbindung, Backlinks, klickbar. Gilt fuer Personen, Projekte, referenzierte Notizen.

5. **STATE.md aktualisieren**
   - Done-Sektion mit erledigten Punkten
   - Next Steps aktualisieren
   - Session Continuity Sektion updaten (Datum, wo gestoppt, naechster Schritt)

5.1 **TODO-Cleanup in STATE.md** (verhindert endlose TODO-Liste)
    Vor dem Session-Continuity-Update:

    1. Parse `.planning/STATE.md` (oder `STATE.md` Root-Fallback)
    2. Suche in `### Pending Todos` und allen Themen-Subheadings (`####`) nach:
       - `- [x] ...` (erledigte Checkbox)
       - `~~...~~` (durchgestrichener Text)
    3. Entferne diese Zeilen komplett (nicht in Archiv verschieben, direkt raus)
    4. Wenn ein `####` Themen-Cluster danach leer ist: Heading-Zeile selbst auch entfernen
    5. Im Output erwaehnen: "STATE.md-Cleanup: N erledigte Items entfernt aus M Themen-Clustern"

    Token-Budget: Cleanup ist idempotent und billig. Max 1 Read + 1 Edit auf STATE.md.
    Skip-Bedingung: Wenn keine STATE.md existiert, Schritt ueberspringen.

5.3 **Vault-Log Eintrag**
    Append eine Zeile an `~/Documents/Second-Brain/00_Meta/system/vault-log.md`:
    ```
    ## [YYYY-MM-DD] wrap-up | <projekt-slug>: N inbox-files written, <one-line-summary>
    ```
    Format: max 120 Zeichen. Beispiel: `## [2026-04-08] compress | ai-mastermind: 4 inbox files, vault-index/log infrastructure built`. Diese Zeile gibt dem naechsten /resume die Cross-Session-Timeline.

5.5 **Projekt-Lifecycle Check**
    Hat sich die Natur des Projekts veraendert?
    - Projekt ohne Enddatum → Vorschlag: "Soll ich [Projekt] nach 03_Areas/ verschieben?"
    - Area mit neuem konkreten Ziel → Vorschlag: "Soll ich [Area] nach 02_Projects/ verschieben?"
    - Projekt abgeschlossen → Vorschlag: "Soll ich [Projekt] nach 06_Archive/ verschieben?"
    NUR vorschlagen, NIEMALS eigenstaendig verschieben. User muss explizit bestaetigen.

6. **Bestaetigung ausgeben**
   ```
   === SESSION KOMPRIMIERT ===
   Vault: [Anzahl] Dateien in 01_Inbox/ geschrieben
   STATE.md: Aktualisiert
   Naechste Session: /resume zum Wiedereinstieg
   ```

## Regeln

- Frontmatter ist PFLICHT (tags als Array, keine verschachtelten YAML-Strukturen)
- Typ-Zuordnung: `type: decision`, `type: learning`, `type: concept`, `type: resource`, `type: session-log`, `type: meeting`, `type: person`, `type: organization`, `type: project`, `type: meta`
- **HARTE REGEL: Dateien landen AUSNAHMSLOS in `01_Inbox/`**
  NIEMALS direkt in Zielordner schreiben (nicht 04_Resources/, nicht 05_Contacts/, etc.)
  Auch wenn der Zielordner offensichtlich ist — das Einsortieren ist ALLEIN Job von /brain:sort-inbox.
  Keine Abkuerzungen. Keine Ausnahmen. Kein "ich weiss wo es hingehoert".
- Kurz und praegnant formulieren — kein Copy-Paste der ganzen Konversation
- Tags im Frontmatter IMMER OHNE `#` (z.B. `project/tax`, NICHT `#project/tax`). Das `#` ist NUR fuer Inline-Markdown.
- Projekt-Tag ist PFLICHT bei jeder Datei die aus einem Projekt-Kontext entsteht
- Bei projektuebergreifenden Erkenntnissen: zusaetzlich `scope/cross-project` Tag setzen
- Wikilinks NUR auf existierende Seiten setzen (Dateiname oder Alias). Pipe-Syntax wenn noetig: [[dateiname|Anzeige-Text]]
