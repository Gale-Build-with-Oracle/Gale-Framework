# NWFTH DOCX Examples

This document provides common patterns and examples for creating DOCX files with NWFTH branding.

## Quick Start

```javascript
const { createNWFTHDocument, createNWFTHTestReport } = require('../scripts/nwfth_docx_template.js');

// Simple document
await createNWFTHDocument('report.docx', {
    title: 'My Report',
    content: [
        'This is a paragraph.',
        { heading: 'HEADING_2', text: 'Section Title' },
        { bullet: true, text: 'Bullet point 1' },
        { bullet: true, text: 'Bullet point 2' }
    ]
});

// Test report
await createNWFTHTestReport('test-report.docx', {
    projectName: 'BME System',
    testCases: [
        { id: 'TC001', name: 'Login Test', status: 'Passed' },
        { id: 'TC002', name: 'Logout Test', status: 'Failed', notes: 'Bug #123' }
    ]
});
```

## Common Patterns

### Basic Document Structure

```javascript
const { Document, Packer, Paragraph, TextRun, Header, Footer,
        AlignmentType, PageNumber, HeadingLevel } = require('docx');
const fs = require('fs');
const { createNWFTHHeader, createNWTFooter, NWFTH_STYLES, PAGE_SETTINGS } = require('../scripts/nwfth_docx_template.js');

const doc = new Document({
    styles: NWFTH_STYLES,
    sections: [{
        properties: { page: PAGE_SETTINGS },
        headers: { default: createNWFTHHeader() },
        footers: { default: createNWTFooter() },
        children: [
            // Your content here
        ]
    }]
});
```

### Adding Tables

```javascript
const { Table, TableRow, TableCell, BorderStyle, WidthType, ShadingType } = require('docx');

const border = { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC" };
const borders = { top: border, bottom: border, left: border, right: border };

const table = new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [2340, 2340, 2340, 2340],
    rows: [
        new TableRow({
            children: [
                new TableCell({
                    borders,
                    shading: { fill: "1F4E79", type: ShadingType.CLEAR },
                    width: { size: 2340, type: WidthType.DXA },
                    children: [new Paragraph({
                        children: [new TextRun({ text: "Header", bold: true, color: "FFFFFF" })]
                    })]
                }),
                // More cells...
            ]
        })
    ]
});
```

### Adding Images

```javascript
const { ImageRun } = require('docx');

new Paragraph({
    children: [
        new ImageRun({
            type: "png",
            data: fs.readFileSync("image.png"),
            transformation: { width: 200, height: 150 }
        })
    ]
})
```

### Lists (Bullets and Numbering)

```javascript
const { LevelFormat } = require('docx');

const doc = new Document({
    numbering: {
        config: [
            {
                reference: "bullets",
                levels: [{
                    level: 0,
                    format: LevelFormat.BULLET,
                    text: "•",
                    alignment: AlignmentType.LEFT,
                    style: { paragraph: { indent: { left: 720, hanging: 360 } } }
                }]
            }
        ]
    },
    sections: [{
        children: [
            new Paragraph({
                numbering: { reference: "bullets", level: 0 },
                children: [new TextRun("Bullet item")]
            })
        ]
    }]
});
```

### Page Breaks

```javascript
const { PageBreak } = require('docx');

new Paragraph({ children: [new PageBreak()] })
// Or
new Paragraph({ pageBreakBefore: true, children: [new TextRun("New page content")] })
```

## Document Templates

### Meeting Minutes

```javascript
const { createNWFTHMeetingMinutes } = require('../scripts/nwfth_docx_template.js');

await createNWFTHMeetingMinutes('meeting.docx', {
    title: 'Project Kickoff Meeting',
    date: '2026-02-10',
    attendees: ['Wind - ICT NWFTH', 'Project Manager', 'Developer Team'],
    agenda: ['Project overview', 'Timeline review', 'Next steps'],
    decisions: ['Use React for frontend', 'Weekly standup on Mondays'],
    actionItems: [
        { assignee: 'Wind', task: 'Setup repository', dueDate: '2026-02-15' }
    ]
});
```

### Project Status Report

```javascript
const sections = [
    { heading: 'HEADING_2', text: 'Executive Summary' },
    'Project is on track for delivery.',
    { heading: 'HEADING_2', text: 'Key Milestones' },
    { bullet: true, text: 'Phase 1: Complete' },
    { bullet: true, text: 'Phase 2: In Progress' },
    { bullet: true, text: 'Phase 3: Scheduled' },
    { heading: 'HEADING_2', text: 'Risks and Issues' },
    { bullet: true, text: 'None identified at this time' }
];

await createNWFTHDocument('status-report.docx', {
    title: 'Project Status Report',
    content: sections
});
```

## Styling Reference

### Text Formatting

```javascript
new TextRun({
    text: "Bold text",
    bold: true,
    size: 24,  // Half-points (24 = 12pt)
    color: "1F4E79",
    font: "Arial"
})
```

### Paragraph Alignment

```javascript
new Paragraph({
    alignment: AlignmentType.CENTER,  // LEFT, RIGHT, CENTER, JUSTIFIED
    children: [new TextRun("Centered text")]
})
```

### Spacing

```javascript
new Paragraph({
    spacing: { before: 240, after: 240, line: 360 },
    children: [new TextRun("Text with spacing")]
})
// Units are in twentieths of a point (240 = 12pt)
```

## Brand Colors

| Color | Hex | Usage |
|-------|-----|-------|
| NWFTH Blue | #1F4E79 | Primary headings |
| NWFTH Light Blue | #2E75B6 | Secondary headings |
| NWFTH Accent | #5B9BD5 | Accent elements |
| Success | #00AA00 | Passed status |
| Error | #AA0000 | Failed status |
