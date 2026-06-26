# NWFTH PPTX Examples

This document provides common patterns and examples for creating PowerPoint presentations with NWFTH branding.

## Quick Start

```javascript
const {
    createNWFTHPresentation,
    addNWFTHTitleSlide,
    addNWFTHContentSlide,
    createNWFTHProjectPresentation
} = require('../scripts/nwfth_pptx_template.js');

// Simple presentation
const pptx = createNWFTHPresentation({ title: 'My Presentation' });
addNWFTHTitleSlide(pptx, { title: 'Hello World', subtitle: 'NWFTH' });
addNWFTHContentSlide(pptx, {
    title: 'Overview',
    bullets: ['Point 1', 'Point 2', 'Point 3']
});
await pptx.writeFile({ fileName: 'presentation.pptx' });

// Project presentation
await createNWFTHProjectPresentation('project.pptx', {
    title: 'Project Update',
    subtitle: 'Q1 2026',
    slides: [
        { title: 'Overview', bullets: ['Item 1', 'Item 2'] },
        { title: 'Progress', bullets: ['Milestone 1', 'Milestone 2'] }
    ]
});
```

## Common Patterns

### Basic Presentation Structure

```javascript
const pptxgen = require("pptxgenjs");
const { createNWFTHPresentation, addNWFTHContentSlide } = require('../scripts/nwfth_pptx_template.js');

// Create presentation with NWFTH branding
const pptx = createNWFTHPresentation({
    title: 'Presentation Title',
    author: 'Wind - ICT NWFTH'
});

// Add slides
addNWFTHTitleSlide(pptx, {
    title: 'Main Title',
    subtitle: 'Subtitle'
});

addNWFTHContentSlide(pptx, {
    title: 'Content Slide',
    bullets: ['Bullet 1', 'Bullet 2', 'Bullet 3']
});

// Save
await pptx.writeFile({ fileName: 'output.pptx' });
```

### Adding Text

```javascript
// Simple text
slide.addText("Hello World", {
    x: 0.5, y: 1, w: 9, h: 1,
    fontSize: 24,
    color: '363636',
    fontFace: 'Arial'
});

// Rich text
slide.addText([
    { text: "Bold ", options: { bold: true } },
    { text: "and ", options: {} },
    { text: "italic", options: { italic: true } }
], {
    x: 0.5, y: 2, w: 9, h: 1,
    fontSize: 18
});

// Multi-line with breaks
slide.addText([
    { text: "Line 1", options: { breakLine: true } },
    { text: "Line 2", options: { breakLine: true } },
    { text: "Line 3" }
], {
    x: 0.5, y: 3, w: 9, h: 2
});
```

### Adding Bullets

```javascript
// Correct way - use bullet option
slide.addText([
    { text: "First item", options: { bullet: true, breakLine: true } },
    { text: "Second item", options: { bullet: true, breakLine: true } },
    { text: "Third item", options: { bullet: true } }
], {
    x: 0.5, y: 1.8, w: 9, h: 3
});

// Nested bullets (indent levels)
slide.addText([
    { text: "Parent item", options: { bullet: true, breakLine: true } },
    { text: "Child item", options: { bullet: true, indentLevel: 1, breakLine: true } },
    { text: "Another child", options: { bullet: true, indentLevel: 1 } }
], {
    x: 0.5, y: 1.8, w: 9, h: 3
});

// Numbered list
slide.addText([
    { text: "First", options: { bullet: { type: "number" }, breakLine: true } },
    { text: "Second", options: { bullet: { type: "number" }, breakLine: true } },
    { text: "Third", options: { bullet: { type: "number" } } }
], {
    x: 0.5, y: 1.8, w: 9, h: 3
});
```

### Adding Tables

```javascript
// Simple table
slide.addTable([
    ["Header 1", "Header 2", "Header 3"],
    ["Row 1 Col 1", "Row 1 Col 2", "Row 1 Col 3"],
    ["Row 2 Col 1", "Row 2 Col 2", "Row 2 Col 3"]
], {
    x: 0.5, y: 1.8, w: 9, h: 3,
    border: { pt: 1, color: "999999" },
    fill: { color: "F1F1F1" },
    fontFace: "Arial",
    fontSize: 12
});

// Styled table with merged cells
const tableData = [
    [
        { text: "Header 1", options: { fill: "1F4E79", color: "FFFFFF", bold: true } },
        { text: "Header 2", options: { fill: "1F4E79", color: "FFFFFF", bold: true } }
    ],
    [
        { text: "Merged cell", options: { colspan: 2 } }
    ],
    ["Cell 1", "Cell 2"]
];

slide.addTable(tableData, {
    x: 0.5, y: 1.8, w: 9, h: 2,
    colW: [4.5, 4.5]
});
```

### Adding Images

```javascript
// From file
slide.addImage({
    path: "image.png",
    x: 1, y: 1, w: 5, h: 3
});

// From URL
slide.addImage({
    path: "https://example.com/image.jpg",
    x: 1, y: 1, w: 5, h: 3
});

// With sizing options
slide.addImage({
    path: "image.png",
    x: 1, y: 1,
    sizing: { type: 'contain', w: 5, h: 3 }
});

// Centered image
const imgWidth = 4;
const imgHeight = 3;
const centerX = (10 - imgWidth) / 2;
slide.addImage({
    path: "image.png",
    x: centerX, y: 1.5,
    w: imgWidth, h: imgHeight
});
```

### Adding Shapes

```javascript
// Rectangle
slide.addShape(pptx.shapes.RECTANGLE, {
    x: 0.5, y: 0.8, w: 1.5, h: 3.0,
    fill: { color: "F1F1F1" },
    line: { color: "1F4E79", width: 2 }
});

// Rounded rectangle
slide.addShape(pptx.shapes.ROUNDED_RECTANGLE, {
    x: 1, y: 1, w: 3, h: 2,
    fill: { color: "FFFFFF" },
    rectRadius: 0.1
});

// Line
slide.addShape(pptx.shapes.LINE, {
    x: 1, y: 3, w: 5, h: 0,
    line: { color: "FF0000", width: 3, dashType: "dash" }
});

// With shadow
slide.addShape(pptx.shapes.RECTANGLE, {
    x: 1, y: 1, w: 3, h: 2,
    fill: { color: "FFFFFF" },
    shadow: {
        type: "outer",
        color: "000000",
        blur: 6,
        offset: 2,
        angle: 135,
        opacity: 0.15
    }
});
```

### Adding Charts

```javascript
// Bar chart
slide.addChart(pptx.charts.BAR, [{
    name: "Sales",
    labels: ["Q1", "Q2", "Q3", "Q4"],
    values: [4500, 5500, 6200, 7100]
}], {
    x: 0.5, y: 1.5, w: 6, h: 3.5,
    barDir: 'col',
    showTitle: true,
    title: 'Quarterly Sales',
    chartColors: ["1F4E79", "2E75B6", "5B9BD5", "9DC3E6"]
});

// Line chart
slide.addChart(pptx.charts.LINE, [{
    name: "Revenue",
    labels: ["Jan", "Feb", "Mar", "Apr", "May", "Jun"],
    values: [100, 120, 115, 140, 160, 180]
}], {
    x: 0.5, y: 1.5, w: 6, h: 3.5,
    lineSize: 3,
    lineSmooth: true,
    showTitle: true,
    title: 'Revenue Trend'
});

// Pie chart
slide.addChart(pptx.charts.PIE, [{
    name: "Market Share",
    labels: ["Product A", "Product B", "Product C"],
    values: [35, 45, 20]
}], {
    x: 0.5, y: 1.5, w: 5, h: 4,
    showPercent: true,
    showTitle: true,
    title: 'Market Share'
});
```

## Document Templates

### Test Summary Presentation

```javascript
const { createNWFTHTestPresentation } = require('../scripts/nwfth_pptx_template.js');

await createNWFTHTestPresentation('test-summary.pptx', {
    projectName: 'BME System',
    testDate: '2026-02-10',
    testCases: [
        { id: 'TC001', name: 'Login Test', status: 'Passed' },
        { id: 'TC002', name: 'Logout Test', status: 'Passed' },
        { id: 'TC003', name: 'Data Export', status: 'Failed', notes: 'Timeout issue' },
        { id: 'TC004', name: 'User Profile', status: 'Passed' }
    ]
});
```

### Meeting Presentation

```javascript
const { createNWFTHMeetingPresentation } = require('../scripts/nwfth_pptx_template.js');

await createNWFTHMeetingPresentation('meeting.pptx', {
    title: 'Project Kickoff',
    date: '2026-02-10',
    attendees: [
        'Wind - ICT NWFTH',
        'Project Manager',
        'Lead Developer',
        'QA Team'
    ],
    agenda: [
        'Project overview and goals',
        'Timeline and milestones',
        'Team roles and responsibilities',
        'Next steps and action items'
    ],
    decisions: [
        'Use React for frontend development',
        'Weekly standup meetings on Mondays',
        'Code reviews required for all PRs'
    ],
    actionItems: [
        { assignee: 'Wind', task: 'Setup development environment', dueDate: '2026-02-12' },
        { assignee: 'Lead Dev', task: 'Create initial project structure', dueDate: '2026-02-15' },
        { assignee: 'QA Team', task: 'Prepare test plan', dueDate: '2026-02-20' }
    ]
});
```

### Two-Column Comparison Slide

```javascript
const { addNWFTHTwoColumnSlide } = require('../scripts/nwfth_pptx_template.js');

addNWFTHTwoColumnSlide(pptx, {
    title: 'Before vs After',
    leftTitle: 'Current State',
    leftBullets: [
        'Manual data entry',
        'Paper-based records',
        'Limited reporting',
        'Slow processing'
    ],
    rightTitle: 'Target State',
    rightBullets: [
        'Automated workflows',
        'Digital records',
        'Real-time dashboards',
        'Fast processing'
    ]
});
```

### Project Status Presentation

```javascript
const pptx = createNWFTHPresentation({ title: 'Project Status' });

// Title slide
addNWFTHTitleSlide(pptx, {
    title: 'Project Status Update',
    subtitle: 'BME System - February 2026'
});

// Executive Summary
addNWFTHContentSlide(pptx, {
    title: 'Executive Summary',
    bullets: [
        'Project is on track for March delivery',
        'Phase 1 and 2 completed successfully',
        'Budget utilization at 65%',
        'No critical risks identified'
    ]
});

// Timeline
addNWFTHTwoColumnSlide(pptx, {
    title: 'Project Timeline',
    leftTitle: 'Completed',
    leftBullets: [
        'Requirements gathering',
        'System design',
        'Database setup',
        'Core API development'
    ],
    rightTitle: 'Upcoming',
    rightBullets: [
        'Frontend development (In Progress)',
        'Integration testing',
        'User acceptance testing',
        'Production deployment'
    ]
});

// Metrics with chart
const metricsSlide = pptx.addSlide({ masterName: 'NWFTH_MASTER' });
metricsSlide.addText('Progress Metrics', {
    x: 0.5, y: 1.0, w: 9, h: 0.6,
    fontSize: 32, bold: true, color: NWFTH_BLUE
});

metricsSlide.addChart(pptx.charts.BAR, [{
    name: "Completion %",
    labels: ["Design", "Backend", "Frontend", "Testing"],
    values: [100, 85, 60, 30]
}], {
    x: 0.5, y: 1.8, w: 9, h: 3.5,
    barDir: 'col',
    showTitle: false,
    chartColors: ["1F4E79", "2E75B6", "5B9BD5", "9DC3E6"],
    showValue: true,
    dataLabelPosition: "outEnd"
});

await pptx.writeFile({ fileName: 'project-status.pptx' });
```

## Styling Reference

### Brand Colors

```javascript
// NWFTH Brand Colors (no # prefix)
const NWFTH_BLUE = '1F4E79';
const NWFTH_LIGHT_BLUE = '2E75B6';
const NWFTH_ACCENT = '5B9BD5';
const NWFTH_DARK = '363636';
const NWFTH_GRAY = '666666';

// Status Colors
const SUCCESS_GREEN = '00AA00';
const ERROR_RED = 'AA0000';
const WARNING_ORANGE = 'FF9900';
```

### Typography

```javascript
// Title
{
    fontSize: 44,
    bold: true,
    color: NWFTH_BLUE,
    fontFace: 'Arial'
}

// Heading
{
    fontSize: 32,
    bold: true,
    color: NWFTH_BLUE,
    fontFace: 'Arial'
}

// Body text
{
    fontSize: 18,
    color: NWFTH_DARK,
    fontFace: 'Arial'
}

// Caption
{
    fontSize: 14,
    color: NWFTH_GRAY,
    fontFace: 'Arial'
}
```

### Layout Dimensions

```javascript
// 16:9 Layout (default)
// Width: 10 inches
// Height: 5.625 inches

// Common positions
const TITLE_Y = 1.0;        // Title position
const CONTENT_Y = 1.8;      // Content start
const FOOTER_Y = 5.2;       // Footer position

// Margins
const LEFT_MARGIN = 0.5;
const RIGHT_MARGIN = 0.5;
const CONTENT_WIDTH = 9.0;  // 10 - 0.5 - 0.5
```

### Slide Backgrounds

```javascript
// Solid color
slide.background = { color: "F1F1F1" };

// With transparency
slide.background = { color: "FF3399", transparency: 50 };

// Image background
slide.background = { path: "background.jpg" };
```

## Common Pitfalls

### Color Format
```javascript
// CORRECT - no # prefix
color: "FF0000"

// WRONG - causes file corruption
color: "#FF0000"
```

### Shadow Offset
```javascript
// CORRECT - positive offset
shadow: { type: "outer", blur: 6, offset: 2, angle: 270, color: "000000", opacity: 0.15 }

// WRONG - negative offset causes corruption
shadow: { type: "outer", blur: 6, offset: -2, color: "000000", opacity: 0.15 }
```

### Bullet Points
```javascript
// CORRECT - use bullet option
{ text: "Item", options: { bullet: true } }

// WRONG - unicode bullets create double bullets
{ text: "• Item" }
```

### Reusing Objects
```javascript
// WRONG - mutates object
const shadow = { type: "outer", blur: 6, offset: 2, color: "000000", opacity: 0.15 };
slide.addShape(pptx.shapes.RECTANGLE, { shadow, ... });
slide.addShape(pptx.shapes.RECTANGLE, { shadow, ... }); // Already mutated!

// CORRECT - fresh object each time
const makeShadow = () => ({ type: "outer", blur: 6, offset: 2, color: "000000", opacity: 0.15 });
slide.addShape(pptx.shapes.RECTANGLE, { shadow: makeShadow(), ... });
slide.addShape(pptx.shapes.RECTANGLE, { shadow: makeShadow(), ... });
```
