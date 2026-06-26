# NWFTH PDF Examples

This document provides common patterns and examples for creating PDF files with NWFTH branding.

## Quick Start

```python
from scripts.nwfth_pdf_template import create_nwfth_pdf, create_nwfth_test_report

# Simple document
from reportlab.platypus import Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet

styles = getSampleStyleSheet()
content = [
    Paragraph("Hello World", styles['Heading1']),
    Spacer(1, 12),
    Paragraph("This is a paragraph.", styles['Normal'])
]

create_nwfth_pdf('report.pdf', title='My Report', content=content)

# Test report
create_nwfth_test_report('test-report.pdf', {
    'project_name': 'BME System',
    'test_cases': [
        {'id': 'TC001', 'name': 'Login Test', 'status': 'Passed'},
        {'id': 'TC002', 'name': 'Logout Test', 'status': 'Failed', 'notes': 'Bug #123'}
    ]
})
```

## Common Patterns

### Basic Document Structure

```python
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet

# Create document
doc = SimpleDocTemplate(
    'output.pdf',
    pagesize=letter,
    rightMargin=72,
    leftMargin=72,
    topMargin=108,  # Extra space for logo
    bottomMargin=72
)

# Build content
styles = getSampleStyleSheet()
story = [
    Paragraph("Title", styles['Title']),
    Spacer(1, 12),
    Paragraph("Content here...", styles['Normal'])
]

# Build with NWFTH header/footer
doc.build(story, onFirstPage=create_nwfth_header_footer, onLaterPages=create_nwfth_header_footer)
```

### Adding Tables

```python
from reportlab.platypus import Table, TableStyle
from reportlab.lib.colors import HexColor, white

# Table data
data = [
    ['Header 1', 'Header 2', 'Header 3'],
    ['Row 1 Col 1', 'Row 1 Col 2', 'Row 1 Col 3'],
    ['Row 2 Col 1', 'Row 2 Col 2', 'Row 2 Col 3']
]

table = Table(data, colWidths=[2*inch, 2*inch, 2*inch])
table.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HexColor('#1F4E79')),  # NWFTH Blue header
    ('TEXTCOLOR', (0, 0), (-1, 0), white),
    ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
    ('FONTSIZE', (0, 0), (-1, 0), 11),
    ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
    ('BACKGROUND', (0, 1), (-1, -1), white),
    ('GRID', (0, 0), (-1, -1), 1, HexColor('#CCCCCC')),
    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
]))

story.append(table)
```

### Custom Styles

```python
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.lib.colors import HexColor

# Custom title style
title_style = ParagraphStyle(
    'NWFTHTitle',
    parent=styles['Heading1'],
    fontSize=24,
    textColor=HexColor('#1F4E79'),
    spaceAfter=30,
    alignment=TA_LEFT
)

# Custom heading style
heading2_style = ParagraphStyle(
    'NWFTHHeading2',
    parent=styles['Heading2'],
    fontSize=16,
    textColor=HexColor('#2E75B6'),
    spaceAfter=12,
    spaceBefore=12
)
```

### Multi-Page Documents

```python
from reportlab.platypus import PageBreak

story = [
    Paragraph("Page 1 Content", styles['Heading1']),
    Paragraph("..."),
    PageBreak(),
    Paragraph("Page 2 Content", styles['Heading1']),
    Paragraph("...")
]
```

## Document Templates

### Meeting Minutes

```python
from scripts.nwfth_pdf_template import create_nwfth_meeting_minutes

create_nwfth_meeting_minutes('meeting.pdf', {
    'title': 'Project Kickoff Meeting',
    'date': '2026-02-10',
    'attendees': ['Wind - ICT NWFTH', 'Project Manager', 'Developer Team'],
    'agenda': ['Project overview', 'Timeline review', 'Next steps'],
    'decisions': ['Use React for frontend', 'Weekly standup on Mondays'],
    'action_items': [
        {'assignee': 'Wind', 'task': 'Setup repository', 'due_date': '2026-02-15'}
    ]
})
```

### Database Transaction Report

```python
from scripts.nwfth_pdf_template import create_nwfth_db_report

create_nwfth_db_report('db-report.pdf', [
    {
        'id': 'TX001',
        'table': 'Orders',
        'action': 'INSERT',
        'status': 'Success',
        'timestamp': '2026-02-10 10:00:00'
    },
    {
        'id': 'TX002',
        'table': 'Customers',
        'action': 'UPDATE',
        'status': 'Success',
        'timestamp': '2026-02-10 10:05:00'
    }
])
```

### Project Status Report

```python
from reportlab.platypus import ListFlowable, ListItem

story = [
    Paragraph("Project Status Report", title_style),
    Spacer(1, 0.2*inch),

    Paragraph("Executive Summary", heading2_style),
    Paragraph("Project is on track for delivery on schedule."),
    Spacer(1, 0.1*inch),

    Paragraph("Key Milestones", heading2_style),
    ListFlowable([
        ListItem(Paragraph("Phase 1: Complete")),
        ListItem(Paragraph("Phase 2: In Progress (75%)")),
        ListItem(Paragraph("Phase 3: Scheduled for March"))
    ], bulletType='bullet'),
    Spacer(1, 0.1*inch),

    Paragraph("Risks and Issues", heading2_style),
    Paragraph("No critical risks identified at this time.")
]

create_nwfth_pdf('status-report.pdf', content=story)
```

## Styling Reference

### Text Formatting in Paragraphs

```python
# Bold text
Paragraph("<b>Bold text</b>", styles['Normal'])

# Italic text
Paragraph("<i>Italic text</i>", styles['Normal'])

# Colored text
Paragraph("<font color='#00AA00'>Green text</font>", styles['Normal'])

# Combined
Paragraph("<b><font color='#1F4E79'>Bold blue text</font></b>", styles['Normal'])
```

### Page Layout

```python
from reportlab.lib.pagesizes import letter, A4, landscape

# Portrait US Letter (default)
doc = SimpleDocTemplate('output.pdf', pagesize=letter)

# A4
doc = SimpleDocTemplate('output.pdf', pagesize=A4)

# Landscape
from reportlab.lib.pagesizes import landscape
doc = SimpleDocTemplate('output.pdf', pagesize=landscape(letter))
```

### Margins

```python
doc = SimpleDocTemplate(
    'output.pdf',
    pagesize=letter,
    rightMargin=72,   # 1 inch
    leftMargin=72,    # 1 inch
    topMargin=108,    # 1.5 inches (extra for logo)
    bottomMargin=72   # 1 inch
)
```

## Brand Colors

```python
from reportlab.lib.colors import HexColor

NWFTH_BLUE = HexColor('#1F4E79')
NWFTH_LIGHT_BLUE = HexColor('#2E75B6')
NWFTH_ACCENT = HexColor('#5B9BD5')
SUCCESS_GREEN = HexColor('#00AA00')
ERROR_RED = HexColor('#AA0000')
```

## Helper Functions

### Adding a Header/Footer to Every Page

```python
def create_nwfth_header_footer(canvas, doc):
    """Draw NWFTH header and footer on each page"""
    canvas.saveState()

    # Logo in top-right corner
    try:
        canvas.drawImage(
            LOGO_PATH,
            doc.pagesize[0] - 1.8*inch,
            doc.pagesize[1] - 0.9*inch,
            width=1.5*inch,
            height=0.75*inch,
            preserveAspectRatio=True
        )
    except:
        pass

    # Footer attribution
    canvas.setFont("Helvetica", 9)
    canvas.setFillColor(HexColor('#666666'))
    canvas.drawCentredString(
        doc.pagesize[0]/2,
        0.5*inch,
        "Newly Weds Foods (Thailand)"
    )

    # Page number
    page_num = canvas.getPageNumber()
    canvas.drawRightString(
        doc.pagesize[0] - 0.75*inch,
        0.5*inch,
        f"Page {page_num}"
    )

    canvas.restoreState()
```
