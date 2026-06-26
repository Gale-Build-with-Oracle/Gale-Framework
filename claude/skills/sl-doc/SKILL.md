---
name: sl-doc
description: 'Solution Lab document creation with company branding.'
---

# Solution Lab Document Creation Skill

## Overview

This skill creates professional documents with consistent Solution Lab company branding. All documents automatically include:
- Solution Lab logo (solution-lab-logo.png) in the header
- "Solution Lab - Innovation & Technology" header branding
- Professional formatting with orange/copper and charcoal color scheme
- Cover page contractor name format: `Solution Lab - [Name]`

## When to Use

Use this skill when the user requests:
- Test summary reports
- UAT (User Acceptance Testing) documents
- Database transaction reports
- Project presentations
- Any DOCX, PDF, XLSX, or PPTX file creation for Solution Lab

## Document Types Supported

| Format | Library | Best For |
|--------|---------|----------|
| DOCX | docx-js | Reports, letters, memos, test summaries |
| PDF | reportlab (Python) | Formal documents, signed reports |
| XLSX | openpyxl (Python) | Data tables, test cases, financials |
| PPTX | pptxgenjs | Presentations, project updates |

## Solution Lab Branding Requirements

### Logo
- **File**: `$HOME/.claude/skills/sl-doc/solution-lab-logo.png`
- **DOCX/PDF Header**: Logo (left, 140x70px DOCX / 42mm x 21mm PDF) + `Solution Lab - Innovation & Technology` (right or beside logo) — **inline on same row**
- **PPTX**: Logo top-left on slide master (1.7" x 0.85")
- **Size**: Logo should be prominent and readable — 42mm wide in PDF, 140px in DOCX, 1.7in in PPTX

### Header Pattern — Logo + Brand Text (MANDATORY)
The header MUST combine the logo and exact brand text on one line to save space:
```
[Logo 140x70]  Solution Lab - Innovation & Technology
```
- Logo size: 140x70px in DOCX, 42mm x 21mm in PDF, 1.7" x 0.85" in PPTX
- Header text must be exactly `Solution Lab - Innovation & Technology`
- Header text: 12pt bold, color: charcoal or dark gray

### Footer — NO FOOTER ON CONTENT PAGES
- **DO NOT add footers on every page** — they waste vertical space
- **Attribution goes on the LAST PAGE only** (or cover page): `Solution Lab - Innovation & Technology`
- **Page numbers**: Optional, place in header right-side if needed, or omit entirely
- For PPTX: footer text on slide master is OK since it's outside content area (bottom strip)

### PPTX Safe Layout Boundaries (MANDATORY)

16:9 slide = 10" × 5.63". All content MUST stay within these safe zones:

```
┌──────────────────────────────────────────────────┐
│ [Logo 1.7×0.85]  Title (20pt bold orange/copper) │ ← Header zone: y 0.1–0.65
│──────────────────────────────────────────────────│
│                                                  │
│  CONTENT SAFE ZONE                               │ ← y 0.7 to 4.8
│  x: 0.5 to 9.5 (w = 9.0)                        │    max content height = 4.1"
│  y: 0.7 to 4.8                                   │
│                                                  │
│──────────────────────────────────────────────────│
│ ══════════ orange accent line ═══════════════════ │ ← y 5.05 (orange accent, 0.02" thick)
└──────────────────────────────────────────────────┘
```

**Hard rules:**
- **Header zone**: y 0.1–0.65 — logo (x:0.3) + title (x:1.5)
- **Content zone**: y 0.7–4.8 — ALL tables, text, boxes, bullets must fit here
- **Bottom limit**: Nothing below y 4.8 (orange accent line at y 5.05)
- **Left/right padding**: x 0.5 minimum, max width 9.0"
- **accentBox()**: max y = 4.3 (box height 0.5 = bottom edge at 4.8)
- **Tables**: calculate rows × row_height — if > 4.1", reduce font size or split slide
- **Side-by-side boxes**: each max width 4.2", gap 0.6" between (x:0.5 + x:5.3)
- **NEVER let content overflow** — always calculate: last_item_y + item_height ≤ 4.8

**Font size guidelines for fitting:**
| Element | Size | When to reduce |
|---------|------|---------------|
| Header title | 20pt | Never reduce |
| H1/body heading | 16pt | Never below 14pt |
| H2/sub-heading | 13pt | Never below 12pt |
| Body text | 12pt | 11pt minimum for dense slides |
| Table header | 11pt | Reduce to 10pt only if >7 rows |
| Table body | 11pt | Reduce to 10pt only if >8 rows |
| Bullet text | 11.5pt | Reduce to 11pt only if >6 items |
| Accent box text | 12pt | Reduce to 11pt if long text |
| Subtitle | 12pt | Never reduce below 11pt |

**Before generating each slide, mentally verify:**
1. First content element starts at y ≥ 0.7
2. Last content element bottom edge ≤ 4.8
3. No text overlaps another element
4. Side-by-side elements have equal heights
5. Table fits: (header + rows) × row_height + start_y ≤ 4.8

### Color Scheme (Theme)
- **Primary**: `#D4652C` — Orange/copper for headings, table headers
- **Secondary**: `#333333` — Dark charcoal for sub-headings and structure
- **Accent**: `#E88B5A` — Lighter orange for highlights, info boxes, accents
- **Text**: `#333333` — Dark gray for readability (not pure black)
- **Background**: White or `#F8F4F0` for alternating table rows
- **Font**: `Tahoma` — native Thai glyph support, consistent sizing Thai+English

## Layout Quality Rules (MANDATORY)

Every document generated with this skill MUST pass these checks before delivery:

1. **No content overflow** — text, tables, and bullets must NEVER spill past page boundaries or outside table column borders. If content is too long, reduce font size or split across pages with explicit PageBreak.
2. **No orphan lines** — a section heading must have at least 3 lines of content with it on the same page. If a heading would appear at the bottom of a page with no room for content, move it to the next page.
3. **Fill pages properly** — avoid pages with only 1-3 lines of content and massive whitespace. Merge short sections onto the same page.
4. **Table column sizing** — always calculate column widths so text fits. Test long Thai words (e.g. 'สารเติมเต็ม', 'Supabase (PostgreSQL)') against column width. Use word wrap, never overflow.
5. **Verify before delivery** — after generating any PDF, read it back page-by-page and check for overflow, orphans, and empty pages. Fix before reporting done.
6. **Thai font** — use Garuda TTF (/usr/share/fonts/truetype/tlwg/Garuda.ttf) for Thai+Latin support. Noto Sans Thai lacks Latin glyphs.

## Mermaid Diagram Rendering (MANDATORY for IEEE/ISO docs)

When source markdown contains ```` ```mermaid ```` code blocks (per CMMI L3 doc mandate: SRS §2.1 + §3.2; SDD §4.1, §4.2, §4.4, §4.7, §4.10; UAT §8), render each block to PNG via `mmdc` **before** DOCX/XLSX generation, then embed PNGs inline. Without this step, the diagrams land as literal monospace code blocks in the output — not customer-deliverable.

### Installation

```bash
npm install -g @mermaid-js/mermaid-cli   # provides `mmdc`
```

### MANDATORY puppeteer config (Ubuntu 23.10+ AppArmor fix)

Ubuntu 23.10+ restricts unprivileged user namespaces, blocking Chromium's default sandbox. Without `-p puppeteer-config.json`, `mmdc` **silently fails** and the pipeline falls back to code-block rendering with no warning — hard to diagnose post-publish.

```bash
# 1. Write puppeteer config to workdir (once per run)
cat > /tmp/luna-workdir/puppeteer-config.json <<'EOF'
{"args":["--no-sandbox","--disable-setuid-sandbox"]}
EOF

# 2. Render each .mmd block extracted from the .md source
mmdc -i diagram.mmd \
     -o diagram.png \
     -b white \
     -w 1200 -H 700 \
     -p /tmp/luna-workdir/puppeteer-config.json
```

Flags: `-b white` (match page), `-w 1200 -H 700` (readable at 100% zoom), `-p` (**always required on Ubuntu 23.10+**).

### Verification (before marking publish complete)

Open the generated DOCX/XLSX — diagrams must appear as **images**, not monospace code blocks. If any render is missing, re-run with the `-p` flag explicit; do not ship the doc until every Mermaid block became an image.

### XLSX note

For UAT `§8 Approach`, render the flowchart PNG and embed into a dedicated `Approach Diagram` sheet (see `slab_xlsx_template.py` for the image-in-sheet pattern).

## DOCX Creation

### Installation
```bash
npm install -g docx
```

### Basic Template with Solution Lab Branding
```javascript
const { Document, Packer, Paragraph, TextRun, ImageRun, Header,
        AlignmentType, Table, TableRow, TableCell, WidthType } = require('docx');
const fs = require('fs');

const LOGO_PATH = '$HOME/.claude/skills/sl-doc/solution-lab-logo.png';
const FONT = "Tahoma"; // Native Thai + English support

const SLAB_HEADER_TEXT = "Solution Lab - Innovation & Technology";

// Header with Logo + brand text inline (saves vertical space)
function createHeader(logo) {
  return new Header({
    children: [
      new Table({
        width: { size: 100, type: WidthType.PERCENTAGE },
        borders: { top: {}, bottom: {}, left: {}, right: {}, insideH: {}, insideV: {} },
        rows: [new TableRow({ children: [
          new TableCell({ width: { size: 20, type: WidthType.PERCENTAGE }, children: [
            new Paragraph({ children: [
              new ImageRun({ type: "png", data: logo, transformation: { width: 140, height: 70 } })
            ]})
          ]}),
          new TableCell({ width: { size: 80, type: WidthType.PERCENTAGE }, children: [
            new Paragraph({ alignment: AlignmentType.LEFT, children: [
              new TextRun({ text: SLAB_HEADER_TEXT, font: FONT, size: 24, bold: true, color: "333333" })
            ]})
          ]}),
        ]})]
      })
    ]
  });
}

const logo = fs.readFileSync(LOGO_PATH);

const doc = new Document({
  styles: {
    default: { document: { run: { font: FONT, size: 24 } } }, // 12pt body
    paragraphStyles: [
      {
        id: "Heading1",
        name: "Heading 1",
        basedOn: "Normal",
        next: "Normal",
        run: { font: FONT, size: 32, bold: true, color: "D4652C" }, // 16pt H1
      },
      {
        id: "Heading2",
        name: "Heading 2",
        basedOn: "Normal",
        next: "Normal",
        run: { font: FONT, size: 26, bold: true, color: "333333" }, // 13pt H2
      },
    ],
  },
  sections: [{
    properties: {
      page: { margin: { top: 1000, right: 1440, bottom: 1000, left: 1440 } } // Reduced margins
    },
    headers: { default: createHeader(logo) },
    // NO footer — saves ~0.5 inch per page
    // Attribution goes on the last page only
    children: [
      // ... document content ...
      // Last page: add attribution
      new Paragraph({
        alignment: AlignmentType.CENTER,
        children: [new TextRun({
          text: SLAB_HEADER_TEXT,
          font: FONT, size: 22, color: "333333"
        })]
      }),
    ]
  }]
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync("output.docx", buffer);
});
```

### Key Design Rules
1. **Header = Logo + `Solution Lab - Innovation & Technology`** — one row, saves vertical space vs separate logo + title
2. **NO footer on content pages** — attribution on last page only
3. **Font: Tahoma** — consistent Thai + English sizing (no garbled characters)
4. **Reduced margins** — `top: 1000, bottom: 1000` (vs default 1440) for more content space
5. **For multi-section DOCX**: Use separate `sections` array entries, each with its own header title

### DOCX Safe Layout Rules
- **Page width** (Letter): 8.5" — usable width with 1" margins = 6.5"
- **Table width**: Always `100%` of usable width — never let tables overflow
- **Body font**: Default 12pt (`size: 24`); keep body text in the 11-12pt range
- **Table font**: 11pt for headers and body cells; avoid dropping below 10pt
- **Bullets**: 11.5pt target; 11pt minimum only for dense content
- **Font consistency**: Every TextRun MUST specify `font: "Tahoma"` — never rely on defaults
- **Table cell padding**: Always include `before: 40, after: 40` spacing
- **Images in tables**: Keep within cell width, never wider than column
- **Long text**: Use word wrap (default) — never assume text fits in one line

## PDF Creation

### Installation
```bash
pip install reportlab
```

### Basic Template with Solution Lab Branding
```python
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from reportlab.lib.units import inch, mm

LOGO_PATH = '$HOME/.claude/skills/sl-doc/solution-lab-logo.png'
SLAB_HEADER_TEXT = "Solution Lab - Innovation & Technology"
BODY_FONT_SIZE = 12
TABLE_FONT_SIZE = 11
BULLET_FONT_SIZE = 11.5
H1_FONT_SIZE = 16
H2_FONT_SIZE = 13

def create_slab_pdf(filename, title, content_func):
    c = canvas.Canvas(filename, pagesize=letter)
    width, height = letter

    def draw_header_footer():
        c.drawImage(LOGO_PATH, width - 45*mm, height - 22*mm,
                    width=42*mm, height=21*mm, preserveAspectRatio=True)
        c.setFont("Helvetica-Bold", 12)
        c.drawString(1*inch, height - 0.5*inch, SLAB_HEADER_TEXT)
        c.drawCentredString(width/2, 0.5*inch, SLAB_HEADER_TEXT)

    draw_header_footer()
    c.setFont("Helvetica-Bold", H1_FONT_SIZE)
    c.drawString(1*inch, height - 1.5*inch, title)
    c.setFont("Helvetica", BODY_FONT_SIZE)
    content_func(c, width, height)
    c.save()
```

## XLSX Creation

### Installation
```bash
pip install openpyxl
```

### Basic Template with Solution Lab Branding
```python
from openpyxl import Workbook
from openpyxl.drawing.image import Image as XLImage
from openpyxl.styles import Font, Alignment, PatternFill, Border, Side

LOGO_PATH = '$HOME/.claude/skills/sl-doc/solution-lab-logo.png'
SLAB_HEADER_TEXT = "Solution Lab - Innovation & Technology"

def create_slab_xlsx(filename, sheet_name="Report"):
    wb = Workbook()
    ws = wb.active
    ws.title = sheet_name

    img = XLImage(LOGO_PATH)
    img.width = 150
    img.height = 75
    ws.add_image(img, 'A1')

    ws.oddHeader.center.text = SLAB_HEADER_TEXT
    ws.oddHeader.center.size = 11
    ws.oddFooter.center.text = SLAB_HEADER_TEXT
    ws.oddFooter.center.size = 11

    header_fill = PatternFill(start_color="D4652C", end_color="D4652C", fill_type="solid")
    header_font = Font(name="Tahoma", bold=True, color="FFFFFF", size=11)
    body_font = Font(name="Tahoma", color="333333", size=12)
    table_font = Font(name="Tahoma", color="333333", size=11)

    return wb, ws
```

## PPTX Creation

### Installation
```bash
npm install -g pptxgenjs
```

### Basic Template with Solution Lab Branding
```javascript
const pptxgen = require("pptxgenjs");

const LOGO_PATH = '$HOME/.claude/skills/sl-doc/solution-lab-logo.png';
const SLAB_HEADER_TEXT = 'Solution Lab - Innovation & Technology';
const FONT = "Tahoma"; // Native Thai support
const BODY_FONT_SIZE = 12;
const TABLE_FONT_SIZE = 11;
const BULLET_FONT_SIZE = 11.5;
const H1_FONT_SIZE = 16;
const H2_FONT_SIZE = 13;

function createSlabPresentation() {
    const pptx = new pptxgen();
    pptx.layout = 'LAYOUT_16x9';
    pptx.author = 'Solution Lab';
    pptx.title = 'Solution Lab Presentation';

    // Slide master with logo (top-left) + canonical header text + thin orange accent line
    pptx.defineSlideMaster({
        title: 'SLAB_MASTER',
        background: { color: 'FFFFFF' },
        objects: [
            { image: { path: LOGO_PATH, x: 0.3, y: 0.15, w: 1.7, h: 0.85 } },
            { text: {
                text: SLAB_HEADER_TEXT,
                options: { x: 2.1, y: 0.35, w: 5.8, h: 0.25, align: 'left',
                           fontSize: 9, fontFace: FONT, color: '333333', bold: true }
            }},
            { rect: { x: 0, y: 5.05, w: 10, h: 0.02, fill: { color: 'E88B5A' } } },
            { text: {
                text: SLAB_HEADER_TEXT,
                options: { x: 0.5, y: 5.15, w: 9, h: 0.25, align: 'center',
                           fontSize: 8, fontFace: FONT, color: '333333' }
            }}
        ]
    });

    // Dark variant for cover/thank-you slides
    pptx.defineSlideMaster({
        title: 'SLAB_DARK',
        background: { color: '333333' },
        objects: [
            { image: { path: LOGO_PATH, x: 0.3, y: 0.15, w: 1.7, h: 0.85 } },
            { text: {
                text: SLAB_HEADER_TEXT,
                options: { x: 0.5, y: 5.15, w: 9, h: 0.25, align: 'center',
                           fontSize: 8, fontFace: FONT, color: 'E88B5A' }
            }}
        ]
    });

    return pptx;
}
```

### PPTX Design Rules
1. **Font: Tahoma** everywhere — consistent Thai + English
2. **Logo top-left** on slide master (~1.7" wide)
3. **Slide title NEXT TO logo in header** — NOT duplicated in content area
   - Use `headerTitle(slide, "สารบัญ")` to place title beside logo at y=0.1
   - Title font: 20pt, bold, primary orange/copper color
   - **DO NOT render title twice** (once in header, once in body) — this wastes space
   - Content starts at y=0.8-1.0 (not 1.4+) since title is in header
4. **Orange accent line** (`#E88B5A`) as thin separator at bottom — NO footer text
5. **`Solution Lab - Innovation & Technology` must appear in the slide header**; repeat it in the closing slide only when needed as attribution
6. **Dark slide master** for cover and closing slides (charcoal `#333333` background)
7. **Use `accentBox()` pattern** for callout/highlight boxes (orange/copper border + warm neutral fill)
8. **Content positioning**: Since title lives in header, content can start at y=0.8-1.0 instead of 1.4+

### PPTX Header Pattern
```javascript
// Slide master — logo + exact brand header text, NO footer text
pptx.defineSlideMaster({ title: "SL", background: { color: "FFFFFF" }, objects: [
  { image: { path: LOGO, x: 0.3, y: 0.15, w: 1.7, h: 0.85 } },
  { text: { text: "Solution Lab - Innovation & Technology",
    options: { x: 2.1, y: 0.35, w: 5.8, h: 0.25, fontFace: "Tahoma",
      fontSize: 9, bold: true, color: "333333" } } },
  { rect: { x: 0, y: 5.3, w: 10, h: 0.02, fill: { color: "E88B5A" } } },
]});

// Title function — renders title ONLY in header, not in body
function headerTitle(slide, text) {
  slide.addText(text, { x: 1.5, y: 0.1, w: 7, h: 0.55, fontSize: 20,
    fontFace: "Tahoma", color: "D4652C", bold: true, valign: "middle" });
}

function title(slide, text, sub) {
  headerTitle(slide, text);  // Title in header next to logo — no duplicate
  if (sub) slide.addText(sub, { x: 0.5, y: 0.8, w: 9, h: 0.3, fontSize: 12,
    fontFace: "Tahoma", color: "333333" });
}
```

## Quick Templates

### Test Summary Report (DOCX)
```javascript
const { createSlabTestReport } = require('./scripts/slab_docx_template.js');

createSlabTestReport("test-summary.docx", {
    projectName: "Project Name",
    testDate: "2026-03-12",
    testCases: [
        { id: "TC001", name: "Login Test", status: "Passed" },
        { id: "TC002", name: "Data Entry", status: "Passed" }
    ]
});
```

### UAT Document (XLSX)
```python
from scripts.slab_xlsx_template import create_slab_uat_template

create_slab_uat_template("uat-test.xlsx", project_name="Solution Lab System")
```

### Database Transaction Report (PDF)
```python
from scripts.slab_pdf_template import create_slab_db_report

create_slab_db_report("db-report.pdf", transactions=[
    {"id": "TX001", "table": "Orders", "action": "INSERT", "status": "Success"}
])
```

### Project Presentation (PPTX)
```javascript
const { createSlabProjectPresentation } = require('./scripts/slab_pptx_template.js');

createSlabProjectPresentation("project-update.pptx", {
    title: "Project Update",
    slides: [
        { title: "Overview", bullets: ["Point 1", "Point 2"] },
        { title: "Progress", bullets: ["Milestone 1", "Milestone 2"] }
    ]
});
```

## Helper Scripts Location

All helper scripts are available in:
```
$HOME/.claude/skills/sl-doc/scripts/
├── slab_docx_template.js
├── slab_pdf_template.py
├── slab_xlsx_template.py
└── slab_pptx_template.js
```
