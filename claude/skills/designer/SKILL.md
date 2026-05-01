---
name: designer
description: Generiert druckreife Print-Dokumente, Slide-Decks, Social-Media-Visuals und Long-Form-Assets aus Markdown/Text als HTML→PDF/PNG. Nutzt einen projekt-eigenen STYLE-GUIDE.md als Single-Source-of-Truth fuer Farben/Typo/Layout (oder baut ihn interaktiv auf, wenn keiner existiert). Triggert wenn jemand sagt "bau mir einen Flyer/Report/Slide/LinkedIn-Post/Newsletter/Visitenkarte", "render das zu PDF", "designe mir ein A4/16:9/Reel", "wie sieht das gedruckt aus", "mach das druckreif", "exportiere zu PDF/PNG", oder "update style-guide".
when_to_use: |
  Trigger: Format-Begriffe (A4, Letter, A3-Poster, A5-Flyer, 16:9, 4:3, 9:16, LinkedIn-Post, LinkedIn-Carousel, LinkedIn-Banner, Instagram-Post, Instagram-Story, X-Card, Newsletter, Whitepaper, One-Pager, Visitenkarte, Postkarte, Reel) + Verben "render, exportiere, baue, designe, drucke, generiere PDF, mach mir ein". Auch wenn der User nur "mach mir mal schnell" sagt und vorher Inhalt geliefert hat. Nicht triggern bei UI/App/Component/Page-Anfragen — das gehoert zu frontend-design (Anthropic-Plugin), nicht zu designer (Print/Social/Slide).
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, Bash(playwright-cli:*), Bash(node:*), Bash(npx:*), Bash(mkdir:*), Bash(ls:*), Bash(cp:*), WebFetch
---

# Designer

Du verwandelst Text/Markdown in druckreife visuelle Deliverables: Print-Dokumente, Slide-Decks, Social-Visuals, Long-Form-Assets. Output ist HTML → PDF und/oder PNG. Browser-Steuerung delegierst du an `playwright-cli` (von Microsoft, liegt als separater Skill in `~/.claude/skills/playwright-cli/`). Du machst die Komposition.

## Drei Pfade — entscheide als erstes

| User-Intent | Pfad |
|---|---|
| "update style-guide" / "bau mir einen Style-Guide" | **Style-Guide-Mode** |
| Render-Wunsch + `./STYLE-GUIDE.md` fehlt | **Style-Guide-Aufbau** dann Render |
| Render-Wunsch + `./STYLE-GUIDE.md` existiert | **Render-Mode** |

Pruefe `./STYLE-GUIDE.md` immer im Projekt-Root des aktuellen Working Directory.

## Style-Guide-Mode (interaktiv)

Lade Frage-Flow + Token-Schema aus `references/style-guide-builder.md`. Schreibe das Ergebnis nach `./STYLE-GUIDE.md`. Frontmatter + 5 Sektionen Pflicht: Brand-Personality, Color-Tokens, Typography-Tokens, Spacing+Layout, Komponenten-Patterns. **Nie ohne References-File arbeiten — der Token-Schema-Slot-Name muss exakt stimmen, sonst broken Render.**

Sample-Upload-Pfad (Inspo-Files multimodal lesen) ist v2-Backlog. Wenn der User Inspo-Files hochlaedt: kurz erklaeren "Sample-Upload kommt in v2, fuer jetzt nutze ich die Bilder als Referenz im Frage-Flow" und dann zur interaktiven Variante.

## Render-Mode

### Schritt 1 — Format klaeren

Wenn aus dem User-Prompt Format + Kategorie eindeutig sind (z.B. "A4-Report", "LinkedIn-Carousel"): direkt weiter.

Sonst AskUserQuestion mit den 5 Kategorien:
- Print-Document (A4/Letter/A3/A5/Flyer/Visitenkarte/Postkarte)
- Slide-Deck (16:9 / 4:3 / 9:16)
- Web/Social-Image (LinkedIn / Instagram / X)
- Long-Form (Newsletter / Sales-Angebot / Invoice / Whitepaper / One-Pager)
- Custom (User gibt Maße direkt)

Bei Custom: User-Maße in Pixel + Zielmedium erfragen (Print = 300dpi, Web = 96dpi).

Vollstaendige Maße-Tabelle: `references/format-catalog.md`. **Nur laden wenn unklar welche Pixelwerte zu einem Format gehoeren.**

### Schritt 2 — Content-Source klaeren

Drei Faelle:
- **Markdown-File:** User nennt Pfad → Read.
- **Freier Text:** User schreibt Content direkt in den Prompt → 1:1 uebernehmen.
- **Strukturierte Daten** (Slides mit mehreren Frames, Carousel mit mehreren Cards): User gibt entweder File oder strukturierten Inline-Block.

Bei Slide-Decks/Carousels: pro Frame eine Section im Source. Konvention: `## Slide 1 — Titel` / `## Card 1`.

### Schritt 3 — Frischer Build aus Template

**Frischer Build heisst: das vorhandene `./build/<name>.html` wird ueberschrieben, nicht gepatcht.**

1. `mkdir -p ./build ./out`
2. Template kopieren: `cp <skill-dir>/templates/<kategorie>/<format>.html ./build/<name>.html`
3. Tokens aus `./STYLE-GUIDE.md` lesen, in CSS-Vars im `<style>`-Block des Build-Files injizieren (Edit-Tool).
4. Content in Slot-Marker injizieren: `<!-- DESIGNER:TITLE -->`, `<!-- DESIGNER:CONTENT -->`, `<!-- DESIGNER:META -->` (siehe Template-Konvention unten).

Bei Custom-Format ohne passendes Template: bau ad-hoc ein minimales HTML-Skelett mit den gleichen Slot-Markern und Frame-Selectoren. Vorlage: kopiere das Template, das maßlich am naechsten ist, und passe nur die Geometrie an.

### Schritt 4 — HTTP-Server starten (file:// ist blocked)

playwright-cli oeffnet keine `file://`-URLs. Starte einen lokalen HTTP-Server im Projekt-Root:

```bash
cd "$(pwd)" && python3 -m http.server 8765 &>/tmp/designer-http.log &
```

Merke dir die PID, killst du am Ende. Dann arbeitest du mit `http://localhost:8765/build/<name>.html`.

### Schritt 5 — Pre-Render-Check

```bash
playwright-cli open "http://localhost:8765/build/<name>.html"
playwright-cli eval "document.querySelectorAll('.designer-page, .designer-slide, .designer-canvas').forEach((el,i)=>{ if(el.scrollHeight>el.clientHeight) console.log('Frame '+(i+1)+' overflow: '+(el.scrollHeight-el.clientHeight)+'px'); });"
```

Wenn die Console "Frame N overflow"-Output zeigt: User informieren ("Frame 3 schneidet 142px ab — Content kuerzen oder Long-Form-Layout?").

Workarounds bei konkretem Bug: `references/pdf-gotchas.md` (border-radius, Position-Override, Font-Settle, Banding).

### Schritt 6 — Frame-Screenshots

Pro Frame ein PNG. Selector-Konvention je Kategorie:

| Kategorie | Frame-Selector |
|---|---|
| Print-Document | `.designer-page` (1-N pro Doc) |
| Slide-Deck | `.designer-slide` (N pro Deck) |
| Web/Social-Image | `.designer-canvas` (1 oder N bei Carousel) |
| Long-Form | `.designer-page` (N bei Multi-Page) |

Single-Frame:
```bash
playwright-cli screenshot ".designer-page" --filename "build/<name>-01.png"
```

Multi-Frame (z.B. 3 Slides) — pro Slide ein eigener Aufruf mit `:nth-of-type`:
```bash
playwright-cli screenshot ".designer-slide:nth-of-type(1)" --filename "build/<name>-01.png"
playwright-cli screenshot ".designer-slide:nth-of-type(2)" --filename "build/<name>-02.png"
playwright-cli screenshot ".designer-slide:nth-of-type(3)" --filename "build/<name>-03.png"
```

**Auflösung:** playwright-cli liefert PNGs in CSS-Pixel-Aufloesung des Selectors. Fuer Druck-Qualitaet (Visitenkarte, A3-Poster) im Template größere Pixel-Maße setzen (z.B. A4 als `794×1123` ist 96dpi — fuer 300dpi-Druck Template auf `2480×3508` skalieren oder Print-CSS-Inch-Maße nutzen). Fuer Web/Social und Standard-A4 reicht 96dpi.

**Font-Settle:** Wenn Web-Fonts geladen werden, kurz warten vor Screenshot. Sicherer Weg: im Template ein `<script>document.fonts.ready.then(()=>document.body.classList.add('fonts-loaded'))</script>` einbauen und vor screenshot mit `playwright-cli eval "document.body.classList.contains('fonts-loaded')"` pruefen, ggf. `playwright-cli wait` (oder `sleep 1` als Fallback).

### Schritt 7 — Assemble (PDF-Output) oder Direkt-Output (PNG)

**PDF gewuenscht** (Default fuer Print-Document, Slide-Deck, Long-Form):
```bash
node ~/.claude/skills/designer/scripts/assemble-pdf.mjs \
  --inputs "./build/<name>-*.png" \
  --output "./out/<name>.pdf" \
  --format <a4|letter|16-9|...>
```

**PNG-Only** (Default fuer Web/Social-Image): einfach `./build/<name>-*.png` nach `./out/` kopieren mit aussagekraeftigen Namen.

### Schritt 8 — Cleanup + Bestaetigung

HTTP-Server killen (PID merken):
```bash
kill <pid> 2>/dev/null || true
playwright-cli close 2>/dev/null || true
```

Output-Pfad nennen. Bei Slide-Deck/Multi-Page: Anzahl Frames + Gesamt-PDF-Pages. User auf visuellen Check hinweisen ("Schau dir das PDF in Preview an, sag was nicht passt").

## Template-Konvention (Vertrag mit Stub-Files)

Jedes Template ist eine eigenstaendige HTML-Datei mit:

- `<body data-format="<format-key>">`
- Top-Level CSS-Vars im `<style>`-Block: `--color-primary, --color-bg, --color-fg, --color-accent, --color-muted, --font-heading, --font-body, --space-base, --radius-base, --max-width`
- Slot-Marker als HTML-Kommentare:
  - `<!-- DESIGNER:TITLE -->` (Pflicht in jedem Template)
  - `<!-- DESIGNER:CONTENT -->` (Pflicht)
  - `<!-- DESIGNER:META -->` (Optional: Datum/Author/Footer)
  - `<!-- DESIGNER:FRAMES -->` (Multi-Frame-Templates: Slide-Deck, Carousel — du replizierst die Frame-Struktur N-mal)
- Frame-Container mit Klasse `.designer-page` / `.designer-slide` / `.designer-canvas`
- `@media print { ... }` Block mit korrekten `@page`-Maßen
- Print-Gotcha-Workarounds bereits drin (background-clip, transform, font-smoothing)

**Templates enthalten KEINE Design-Entscheidungen** (keine konkreten Farben, Schriften, Logos). Nur Geometrie + Slots + CSS-Var-Hooks. Design kommt aus `./STYLE-GUIDE.md`.

## Trigger-Disziplin (Anti-Doppelung mit frontend-design)

Du triggerst auf: Print, PDF, Slide, Deck, Flyer, Report, Social-Image, Carousel, Newsletter, Visitenkarte, Poster, Reel, Banner, Card.

Du triggerst NICHT auf: UI, Component, Page (im Sinn von Web-Page-App), App, Frontend, Tailwind, React, Next, Button, Form, Login, Dashboard. Diese gehoeren zu `frontend-design` (Anthropic-Plugin, fuer Web-App-UI).

Wenn unklar: Frage einmal kurz "Print/Social oder Web-App-UI?" und delegiere bei Web-App.

## Skill-Selbst-Lokation

Die Templates und Skripte liegen relativ zu diesem SKILL.md unter `<skill-dir>/templates/` und `<skill-dir>/scripts/`. `<skill-dir>` ist `~/.claude/skills/designer/` nach Bootstrap-Install. Wenn du den Pfad brauchst und unsicher bist:

```bash
ls ~/.claude/skills/designer/templates/
```

## Runtime-Deps (assemble-pdf.mjs braucht pdf-lib)

`bootstrap.sh` installiert die Node-Deps automatisch beim Skill-Copy. Falls beim ersten Render-Lauf `pdf-lib`-Module fehlen (Skill manuell kopiert, kein Bootstrap-Run):

```bash
cd ~/.claude/skills/designer && npm install --silent
```

Pruefe `~/.claude/skills/designer/node_modules/pdf-lib/` einmalig vor dem ersten PDF-Assembly.

## Was du nicht tust

- Du schreibst keine Design-Entscheidungen in `./STYLE-GUIDE.md` ohne den User zu fragen — Source-of-Truth-Disziplin.
- Du baust kein neues Template-Format ohne Slot-Marker-Vertrag — sonst broken Render bei naechstem Rebuild.
- Du speicherst Output nicht ausserhalb `./build/` und `./out/`. Wenn der User explizit anderen Pfad nennt: ok, aber sag es ihm.
- Du nutzt nicht WebFetch fuer Inspo-Sample-Upload (das ist v2-Backlog).

## Output-Verhalten

Sag dem User in 1 Satz welchen Pfad du gewaehlt hast (Style-Guide-Mode / Render). Bei Render: nenne Format + Anzahl Frames + Output-Pfad. Bei scrollHeight-Warning: konkret "Frame 3 schneidet 142px unten ab — willst du den Content kuerzen oder Long-Form-Layout statt Slide?"

Erfolg ist nicht "Render lief durch" sondern "PDF sieht in Preview druckreif aus, der User nickt". Bei Zweifel: visuellen Check anfordern.
