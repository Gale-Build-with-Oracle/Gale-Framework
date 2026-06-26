---
name: nwf-doc
description: 'NWFTH document creation with company branding.'
---

# NWFTH Document Creation Skill

## Overview

This skill creates professional documents with consistent NWFTH company branding. All documents automatically include:
- NWFTH logo (NWFLogo.jpg) in the header
- "Newly Weds Foods (Thailand)" footer attribution
- Professional formatting and styling

## When to Use

Use this skill when the user requests:
- Test summary reports
- UAT (User Acceptance Testing) documents
- Database transaction reports
- Project presentations
- Any DOCX, PDF, XLSX, or PPTX file creation

## Document Types Supported

| Format | Library | Best For |
|--------|---------|----------|
| DOCX | docx-js | Reports, letters, memos, test summaries |
| PDF | reportlab (Python) | Formal documents, signed reports |
| XLSX | openpyxl (Python) | Data tables, test cases, financials |
| PPTX | pptxgenjs | Presentations, project updates |

## NWFTH Branding Requirements

### Logo
- **File**: `$HOME/.claude/skills/nwf-doc/NWFLogo.jpg`
- **Placement**: Top-right corner of header (DOCX, PDF) or top-left (PPTX)
- **Size**: Approximately 1-1.5 inches wide, maintaining aspect ratio

### Footer Attribution
- **Text**: "Newly Weds Foods (Thailand)"
- **Placement**: Centered in footer
- **Font**: Professional, consistent with document (Arial or similar)
- **Size**: 10-12pt

### Color Scheme
- **Primary**: NWF brand brown/amber/gold tones
- **Secondary**: Light brown for secondary headings
- **Accent**: Gold for highlights and accents
- **Text**: Black or dark gray for readability
- **Background**: White or light colors

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

For UAT `§8 Approach`, render the flowchart PNG and embed into a dedicated `Approach Diagram` sheet.

## DOCX Creation

### Installation
```bash
npm install -g docx
```

### Basic Template with NWFTH Branding
```javascript
const { Document, Packer, Paragraph, TextRun, ImageRun, Header, Footer,
        AlignmentType, PageNumber, HeadingLevel } = require('docx');
const fs = require('fs');

const LOGO_PATH = '$HOME/.claude/skills/nwf-doc/NWFLogo.jpg';

const doc = new Document({
  styles: {
    default: { document: { run: { font: "Arial", size: 24 } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 32, bold: true, font: "Arial" },
        paragraph: { spacing: { before: 240, after: 240 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 28, bold: true, font: "Arial" },
        paragraph: { spacing: { before: 180, after: 180 }, outlineLevel: 1 } },
    ]
  },
  sections: [{
    properties: {
      page: {
        size: { width: 12240, height: 15840 }, // US Letter
        margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 }
      }
    },
    headers: {
      default: new Header({
        children: [
          new Paragraph({
            alignment: AlignmentType.RIGHT,
            children: [
              new ImageRun({
                type: "jpg",
                data: fs.readFileSync(LOGO_PATH),
                transformation: { width: 120, height: 60 }
              })
            ]
          })
        ]
      })
    },
    footers: {
      default: new Footer({
        children: [
          new Paragraph({
            alignment: AlignmentType.CENTER,
            children: [
              new TextRun({ text: "Newly Weds Foods (Thailand)", size: 20 }),
              new TextRun({ text: " | Page ", size: 20 }),
              new TextRun({ children: [PageNumber.CURRENT], size: 20 }),
              new TextRun({ text: " of ", size: 20 }),
              new TextRun({ children: [PageNumber.TOTAL_PAGES], size: 20 })
            ]
          })
        ]
      })
    },
    children: [
      new Paragraph({
        heading: HeadingLevel.HEADING_1,
        children: [new TextRun("Document Title")]
      }),
      new Paragraph({
        children: [new TextRun("Document content here...")]
      })
    ]
  }]
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync("output.docx", buffer);
});
```

## PDF Creation

### Installation
```bash
pip install reportlab
```

### Basic Template with NWFTH Branding
```python
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from reportlab.lib.units import inch

LOGO_PATH = '$HOME/.claude/skills/nwf-doc/NWFLogo.jpg'

def create_nwfth_pdf(filename, title, content_func):
    c = canvas.Canvas(filename, pagesize=letter)
    width, height = letter

    def draw_header_footer():
        # Logo in top-right
        c.drawImage(LOGO_PATH, width - 1.8*inch, height - 0.9*inch,
                    width=1.5*inch, height=0.75*inch, preserveAspectRatio=True)

        # Footer attribution
        c.setFont("Helvetica", 10)
        c.drawCentredString(width/2, 0.5*inch, "Newly Weds Foods (Thailand)")

    # First page
    draw_header_footer()
    c.setFont("Helvetica-Bold", 18)
    c.drawString(1*inch, height - 1.5*inch, title)

    # Add content
    content_func(c, width, height)

    c.save()

# Usage
 create_nwfth_pdf("report.pdf", "Test Report", lambda c, w, h: c.drawString(1*inch, h-2*inch, "Content"))
```

## XLSX Creation

### Installation
```bash
pip install openpyxl
```

### Basic Template with NWFTH Branding
```python
from openpyxl import Workbook
from openpyxl.drawing.image import Image as XLImage
from openpyxl.styles import Font, Alignment, PatternFill, Border, Side

LOGO_PATH = '$HOME/.claude/skills/nwf-doc/NWFLogo.jpg'

def create_nwfth_xlsx(filename, sheet_name="Report"):
    wb = Workbook()
    ws = wb.active
    ws.title = sheet_name

    # Add logo
    img = XLImage(LOGO_PATH)
    img.width = 150
    img.height = 75
    ws.add_image(img, 'A1')

    # Set footer
    ws.oddFooter.center.text = "Newly Weds Foods (Thailand)"
    ws.oddFooter.center.size = 10

    # Styling
    header_fill = PatternFill(start_color="3A2920", end_color="3A2920", fill_type="solid")
    header_font = Font(bold=True, color="FFFFFF")
    thin_border = Border(
        left=Side(style='thin'),
        right=Side(style='thin'),
        top=Side(style='thin'),
        bottom=Side(style='thin')
    )

    return wb, ws

# Usage
wb, ws = create_nwfth_xlsx("report.xlsx", "Test Cases")
ws['A5'] = "Test Case ID"
ws['A5'].font = Font(bold=True)
wb.save("report.xlsx")
```

## PPTX Creation

### Installation
```bash
npm install -g pptxgenjs
```

### Basic Template with NWFTH Branding
```javascript
const pptxgen = require("pptxgenjs");
const fs = require('fs');

const LOGO_PATH = '$HOME/.claude/skills/nwf-doc/NWFLogo.jpg';

function createNWFTHPresentation() {
    const pptx = new pptxgen();
    pptx.layout = 'LAYOUT_16x9';
    pptx.author = 'Wind - ICT NWFTH';
    pptx.title = 'NWFTH Presentation';

    // Define master slide — logo only, NO footer (footer overlaps content)
    pptx.defineSlideMaster({
        title: 'NWFTH_MASTER',
        background: { color: 'FFFFFF' },
        objects: [
            { image: { path: LOGO_PATH, x: 0.3, y: 0.15, w: 1.0, h: 0.5 } }
        ]
    });

    // Helper: title to the RIGHT of logo (never on top)
    function addSlideTitle(slide, title) {
        slide.addText(title, {
            x: 1.5, y: 0.15, w: 8.2, h: 0.5,
            fontSize: 22, bold: true, align: 'left', valign: 'middle'
        });
    }

    // Title slide — "Newly Weds Foods (Thailand)" goes here only
    const titleSlide = pptx.addSlide({ masterName: 'NWFTH_MASTER' });
    titleSlide.addText("Presentation Title", {
        x: 0.5, y: 2, w: 9, h: 1,
        fontSize: 36, bold: true, align: 'center'
    });
    titleSlide.addText("Newly Weds Foods (Thailand)", {
        x: 0.5, y: 4.3, w: 9, h: 0.4,
        fontSize: 12, color: '666666', align: 'center'
    });

    // Content slides — use addSlideTitle, content starts at y=0.8
    const contentSlide = pptx.addSlide({ masterName: 'NWFTH_MASTER' });
    addSlideTitle(contentSlide, "Slide Title");
    contentSlide.addText("Slide Content", {
        x: 0.5, y: 0.8, w: 9, h: 4.0,
        fontSize: 18
    });

    pptx.writeFile({ fileName: "presentation.pptx" });
}

createNWFTHPresentation();
```

## PPTX Layout Rules (MANDATORY)

These rules prevent common rendering issues in generated presentations. Follow them for ALL PPTX output.

### 1. No Footer Bar in Master Slide
Do NOT add a colored bar or text block at the bottom of the master slide. It overlaps with content on dense slides. Instead, put "Newly Weds Foods (Thailand)" only on the title slide as part of the date/subtitle text.

### 2. Logo + Title Side-by-Side
Logo goes at `x:0.3, y:0.15, w:1.0, h:0.5`. Slide title starts at `x:1.5` (to the RIGHT of the logo), never on top of it. Use a shared `addSlideTitle(slide, text)` helper.

### 3. Content Safe Zone
- **Top**: y >= 0.8 (below logo + title row)
- **Bottom**: y + h <= 5.5 (16:9 slide is 5.63" tall)
- **Left/Right**: x >= 0.3, x + w <= 9.7

### 4. Database/Entity Diagrams

**Use TEXT connectors, NOT shape lines.** Shape lines cause z-order bugs (labels hidden behind boxes, lines crossing through entities). Instead, use text elements like `── 1:N ──▶`, `◀── 1:1 ──`, `N:1 ▲`, `1:N ▼` placed between entity boxes. This completely eliminates overlap problems.

**Grid layout (3-row pattern for most DB diagrams):**
```
Row 1 (y=0.8):   Reference tables (e.g., FMMast, FMItem)
Row 2 (y=2.05):  Main tables (e.g., PNMAST, PNITEM, INMAST)
Row 3 (y=4.1):   Audit/log tables
```
- Entities in the same row are connected with horizontal text connectors
- Rows are connected with vertical text connectors (▲ ▼)
- No entity overlaps another — clear gaps between all boxes

**Entity box sizing — match height to content:**
- **Always add `autoFit: true`** to the column text element. This shrinks text to fit inside the box if it overflows. Without this, text renders PAST the box border.
- Calculate height per entity: `header (0.32") + lines × 0.12" + padding (0.06")`
- Example: 11 lines → 0.32 + 1.32 + 0.06 = **1.7"** (not 2.2" which wastes space)
- Combine related columns on one line to reduce line count (e.g., `"FormulaId, Status nchar(1)"`)
- fontSize 7 for column text, 9 for entity header name
- Max entity height: ~2 inches. If more columns needed, group/abbreviate

**Entity drawEntity pattern:**
```javascript
function drawEntity(slide, name, cols, x, y, w, h, accent) {
  // Box outline
  slide.addShape(pptx.ShapeType.roundRect, {
    x, y, w, h, fill: { color: WHITE },
    line: { color: accent, width: 1.5 }, rectRadius: 0.08,
    shadow: { type: "outer", blur: 3, offset: 1, color: "cccccc" },
  });
  // Colored header bar
  slide.addShape(pptx.ShapeType.rect, {
    x: x + 0.04, y: y + 0.04, w: w - 0.08, h: 0.26,
    fill: { color: accent },
  });
  slide.addText(name, {
    x: x + 0.04, y: y + 0.04, w: w - 0.08, h: 0.26,
    fontSize: 9, bold: true, color: WHITE, fontFace: "Arial",
    align: "center", valign: "middle",
  });
  // Column list — autoFit prevents overflow past border
  slide.addText(cols, {
    x: x + 0.08, y: y + 0.32, w: w - 0.16, h: h - 0.38,
    fontSize: 7, color: "333333", fontFace: "Consolas",
    valign: "top", lineSpacingMultiple: 1.05, autoFit: true,
  });
}
```

**Text connector pattern:**
```javascript
function addConnector(slide, text, x, y, w) {
  slide.addText(text, {
    x, y, w: w || 0.55, h: 0.22,
    fontSize: 7, bold: true, color: BROWN, fontFace: "Arial",
    align: "center", valign: "middle",
  });
}
// Usage:
addConnector(s, "── 1:N ──▶", 4.9, 2.4, 0.85);  // horizontal
addConnector(s, "1:N ▼", 3.5, 3.8, 0.5);          // vertical down
addConnector(s, "◀── 1:1 ──", 1.85, 2.4, 0.85);  // horizontal left
addConnector(s, "N:1 ▲", 3.5, 1.72, 0.5);          // vertical up
```

### 5. Tables — Stay Within Bounds
- Calculate total table height before placing: `headerRow + (dataRows × rowH)`. Ensure `y + totalHeight <= 5.4`.
- If a table has >12 rows, reduce `rowH` to 0.22 or split across slides.
- For all text elements inside shapes/tables, add `autoFit: true` to prevent text overflowing past borders.

## Quick Templates

### Test Summary Report (DOCX)
```javascript
// Use the helper script
const { createNWFTHTestReport } = require('./scripts/nwfth_docx_template.js');

createNWFTHTestReport("test-summary.docx", {
    projectName: "Project Name",
    testDate: "2026-02-10",
    testCases: [
        { id: "TC001", name: "Login Test", status: "Passed" },
        { id: "TC002", name: "Data Entry", status: "Passed" }
    ]
});
```

### UAT Document (XLSX)
```python
# Use the helper script
from scripts.nwfth_xlsx_template import create_nwfth_uat_template

create_nwfth_uat_template("uat-test.xlsx", project_name="BME System")
```

### Database Transaction Report (PDF)
```python
# Use the helper script
from scripts.nwfth_pdf_template import create_nwfth_db_report

create_nwfth_db_report("db-report.pdf", transactions=[
    {"id": "TX001", "table": "Orders", "action": "INSERT", "status": "Success"}
])
```

### Project Presentation (PPTX)
```javascript
// Use the helper script
const { createNWFTHProjectPresentation } = require('./scripts/nwfth_pptx_template.js');

createNWFTHProjectPresentation("project-update.pptx", {
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
$HOME/.claude/skills/nwf-doc/scripts/
├── nwfth_docx_template.js
├── nwfth_pdf_template.py
├── nwfth_xlsx_template.py
└── nwfth_pptx_template.js
```

## Reference Documentation

See the `references/` directory for detailed examples:
- `docx-examples.md` - DOCX patterns and examples
- `pdf-examples.md` - PDF patterns and examples
- `xlsx-examples.md` - XLSX patterns and examples
- `pptx-examples.md` - PPTX patterns and examples
