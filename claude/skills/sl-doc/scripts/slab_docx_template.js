/**
 * Solution Lab DOCX Template Helper
 * Creates Word documents with Solution Lab branding (logo header, footer attribution)
 */

const { Document, Packer, Paragraph, TextRun, ImageRun, Header, Footer,
        AlignmentType, PageNumber, HeadingLevel, Table, TableRow, TableCell,
        BorderStyle, WidthType, ShadingType, LevelFormat } = require('docx');
const fs = require('fs');
const path = require('path');

const LOGO_PATH = path.join(__dirname, '..', 'solution-lab-logo.png');
const SLAB_HEADER_TEXT = 'Solution Lab - Innovation & Technology';

// Solution Lab Brand Colors
const SLAB_PRIMARY = 'D4652C';
const SLAB_SECONDARY = '333333';
const SLAB_ACCENT = 'E88B5A';

// Default Solution Lab styles
const SLAB_STYLES = {
  default: { document: { run: { font: "Arial", size: 24 } } },
  paragraphStyles: [
    {
      id: "Heading1",
      name: "Heading 1",
      basedOn: "Normal",
      next: "Normal",
      quickFormat: true,
      run: { size: 32, bold: true, font: "Arial", color: "D4652C" },
      paragraph: { spacing: { before: 240, after: 240 }, outlineLevel: 0 }
    },
    {
      id: "Heading2",
      name: "Heading 2",
      basedOn: "Normal",
      next: "Normal",
      quickFormat: true,
      run: { size: 28, bold: true, font: "Arial", color: "333333" },
      paragraph: { spacing: { before: 180, after: 180 }, outlineLevel: 1 }
    },
    {
      id: "Heading3",
      name: "Heading 3",
      basedOn: "Normal",
      next: "Normal",
      quickFormat: true,
      run: { size: 24, bold: true, font: "Arial", color: "E88B5A" },
      paragraph: { spacing: { before: 120, after: 120 }, outlineLevel: 2 }
    }
  ]
};

// Default page settings (US Letter)
const PAGE_SETTINGS = {
  size: { width: 12240, height: 15840 },
  margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 }
};

/**
 * Create Solution Lab branded header with logo and canonical brand line
 */
function createSlabHeader() {
  const logoData = fs.readFileSync(LOGO_PATH);
  return new Header({
    children: [
      new Paragraph({
        alignment: AlignmentType.LEFT,
        spacing: { after: 120 },
        children: [
          new ImageRun({
            type: "png",
            data: logoData,
            transformation: { width: 120, height: 60 }
          }),
          new TextRun({
            text: `  ${SLAB_HEADER_TEXT}`,
            size: 24,
            bold: true,
            color: SLAB_SECONDARY
          })
        ]
      })
    ]
  });
}

/**
 * Create Solution Lab branded footer with attribution
 */
function createSlabFooter() {
  return new Footer({
    children: [
      new Paragraph({
        alignment: AlignmentType.CENTER,
        children: [
          new TextRun({ text: SLAB_HEADER_TEXT, size: 20, color: "666666" }),
          new TextRun({ text: " | Page ", size: 20, color: "666666" }),
          new TextRun({ children: [PageNumber.CURRENT], size: 20, color: "666666" }),
          new TextRun({ text: " of ", size: 20, color: "666666" }),
          new TextRun({ children: [PageNumber.TOTAL_PAGES], size: 20, color: "666666" })
        ]
      })
    ]
  });
}

/**
 * Create a basic Solution Lab branded document
 * @param {string} filename - Output filename
 * @param {Object} options - Document options
 * @param {string} options.title - Document title
 * @param {Array} options.content - Array of content paragraphs
 */
async function createSlabDocument(filename, options = {}) {
  const { title, content = [] } = options;

  const children = [];

  if (title) {
    children.push(
      new Paragraph({
        heading: HeadingLevel.HEADING_1,
        children: [new TextRun(title)]
      })
    );
  }

  content.forEach(item => {
    if (typeof item === 'string') {
      children.push(new Paragraph({ children: [new TextRun(item)] }));
    } else if (item.heading) {
      children.push(
        new Paragraph({
          heading: HeadingLevel[item.heading] || HeadingLevel.HEADING_2,
          children: [new TextRun(item.text)]
        })
      );
    } else if (item.bullet) {
      children.push(
        new Paragraph({
          bullet: { level: item.level || 0 },
          children: [new TextRun(item.text)]
        })
      );
    }
  });

  const doc = new Document({
    styles: SLAB_STYLES,
    sections: [{
      properties: { page: PAGE_SETTINGS },
      headers: { default: createSlabHeader() },
      footers: { default: createSlabFooter() },
      children
    }]
  });

  const buffer = await Packer.toBuffer(doc);
  fs.writeFileSync(filename, buffer);
  return filename;
}

/**
 * Create a test summary report
 * @param {string} filename - Output filename
 * @param {Object} data - Report data
 */
async function createSlabTestReport(filename, data = {}) {
  const {
    projectName = "N/A",
    testDate = new Date().toISOString().split('T')[0],
    preparedBy = "Solution Lab",
    testCases = [],
    summary = {}
  } = data;

  const border = { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC" };
  const borders = { top: border, bottom: border, left: border, right: border };

  // Create table rows
  const tableRows = [
    new TableRow({
      children: [
        new TableCell({
          borders,
          shading: { fill: "D4652C", type: ShadingType.CLEAR },
          width: { size: 2000, type: WidthType.DXA },
          children: [new Paragraph({ children: [new TextRun({ text: "Test ID", bold: true, color: "FFFFFF" })] })]
        }),
        new TableCell({
          borders,
          shading: { fill: "D4652C", type: ShadingType.CLEAR },
          width: { size: 4000, type: WidthType.DXA },
          children: [new Paragraph({ children: [new TextRun({ text: "Test Name", bold: true, color: "FFFFFF" })] })]
        }),
        new TableCell({
          borders,
          shading: { fill: "D4652C", type: ShadingType.CLEAR },
          width: { size: 2000, type: WidthType.DXA },
          children: [new Paragraph({ children: [new TextRun({ text: "Status", bold: true, color: "FFFFFF" })] })]
        }),
        new TableCell({
          borders,
          shading: { fill: "D4652C", type: ShadingType.CLEAR },
          width: { size: 2000, type: WidthType.DXA },
          children: [new Paragraph({ children: [new TextRun({ text: "Notes", bold: true, color: "FFFFFF" })] })]
        })
      ]
    })
  ];

  testCases.forEach(tc => {
    const statusColor = tc.status === 'Passed' ? '00AA00' : tc.status === 'Failed' ? 'AA0000' : '666666';
    tableRows.push(
      new TableRow({
        children: [
          new TableCell({
            borders,
            width: { size: 2000, type: WidthType.DXA },
            children: [new Paragraph({ children: [new TextRun(tc.id || "")] })]
          }),
          new TableCell({
            borders,
            width: { size: 4000, type: WidthType.DXA },
            children: [new Paragraph({ children: [new TextRun(tc.name || "")] })]
          }),
          new TableCell({
            borders,
            width: { size: 2000, type: WidthType.DXA },
            children: [new Paragraph({ children: [new TextRun({ text: tc.status || "", color: statusColor, bold: true })] })]
          }),
          new TableCell({
            borders,
            width: { size: 2000, type: WidthType.DXA },
            children: [new Paragraph({ children: [new TextRun(tc.notes || "")] })]
          })
        ]
      })
    );
  });

  const passed = testCases.filter(tc => tc.status === 'Passed').length;
  const failed = testCases.filter(tc => tc.status === 'Failed').length;
  const total = testCases.length;

  const doc = new Document({
    styles: SLAB_STYLES,
    sections: [{
      properties: { page: PAGE_SETTINGS },
      headers: { default: createSlabHeader() },
      footers: { default: createSlabFooter() },
      children: [
        new Paragraph({
          heading: HeadingLevel.HEADING_1,
          children: [new TextRun("Test Summary Report")]
        }),
        new Paragraph({
          heading: HeadingLevel.HEADING_2,
          children: [new TextRun("Project Information")]
        }),
        new Paragraph({
          children: [
            new TextRun({ text: "Project Name: ", bold: true }),
            new TextRun(projectName)
          ]
        }),
        new Paragraph({
          children: [
            new TextRun({ text: "Test Date: ", bold: true }),
            new TextRun(testDate)
          ]
        }),
        new Paragraph({
          children: [
            new TextRun({ text: "Prepared By: ", bold: true }),
            new TextRun(preparedBy)
          ]
        }),
        new Paragraph({ text: "" }),
        new Paragraph({
          heading: HeadingLevel.HEADING_2,
          children: [new TextRun("Summary")]
        }),
        new Paragraph({
          children: [
            new TextRun({ text: "Total Test Cases: ", bold: true }),
            new TextRun(String(total))
          ]
        }),
        new Paragraph({
          children: [
            new TextRun({ text: "Passed: ", bold: true }),
            new TextRun({ text: String(passed), color: "00AA00" })
          ]
        }),
        new Paragraph({
          children: [
            new TextRun({ text: "Failed: ", bold: true }),
            new TextRun({ text: String(failed), color: failed > 0 ? "AA0000" : "00AA00" })
          ]
        }),
        new Paragraph({ text: "" }),
        new Paragraph({
          heading: HeadingLevel.HEADING_2,
          children: [new TextRun("Test Results")]
        }),
        new Table({
          width: { size: 10000, type: WidthType.DXA },
          columnWidths: [2000, 4000, 2000, 2000],
          rows: tableRows
        })
      ]
    }]
  });

  const buffer = await Packer.toBuffer(doc);
  fs.writeFileSync(filename, buffer);
  return filename;
}

/**
 * Create a meeting minutes document
 * @param {string} filename - Output filename
 * @param {Object} data - Meeting data
 */
async function createSlabMeetingMinutes(filename, data = {}) {
  const {
    title = "Meeting Minutes",
    date = new Date().toISOString().split('T')[0],
    attendees = [],
    agenda = [],
    decisions = [],
    actionItems = []
  } = data;

  const children = [
    new Paragraph({
      heading: HeadingLevel.HEADING_1,
      children: [new TextRun(title)]
    }),
    new Paragraph({
      children: [
        new TextRun({ text: "Date: ", bold: true }),
        new TextRun(date)
      ]
    }),
    new Paragraph({ text: "" }),
    new Paragraph({
      heading: HeadingLevel.HEADING_2,
      children: [new TextRun("Attendees")]
    })
  ];

  attendees.forEach(attendee => {
    children.push(new Paragraph({
      bullet: { level: 0 },
      children: [new TextRun(attendee)]
    }));
  });

  children.push(
    new Paragraph({ text: "" }),
    new Paragraph({
      heading: HeadingLevel.HEADING_2,
      children: [new TextRun("Agenda")]
    })
  );

  agenda.forEach((item, index) => {
    children.push(new Paragraph({
      bullet: { level: 0 },
      children: [new TextRun(`${index + 1}. ${item}`)]
    }));
  });

  if (decisions.length > 0) {
    children.push(
      new Paragraph({ text: "" }),
      new Paragraph({
        heading: HeadingLevel.HEADING_2,
        children: [new TextRun("Decisions")]
      })
    );
    decisions.forEach(decision => {
      children.push(new Paragraph({
        bullet: { level: 0 },
        children: [new TextRun(decision)]
      }));
    });
  }

  if (actionItems.length > 0) {
    children.push(
      new Paragraph({ text: "" }),
      new Paragraph({
        heading: HeadingLevel.HEADING_2,
        children: [new TextRun("Action Items")]
      })
    );
    actionItems.forEach(item => {
      children.push(new Paragraph({
        bullet: { level: 0 },
        children: [new TextRun(`${item.assignee}: ${item.task} (${item.dueDate || 'TBD'})`)]
      }));
    });
  }

  const doc = new Document({
    styles: SLAB_STYLES,
    sections: [{
      properties: { page: PAGE_SETTINGS },
      headers: { default: createSlabHeader() },
      footers: { default: createSlabFooter() },
      children
    }]
  });

  const buffer = await Packer.toBuffer(doc);
  fs.writeFileSync(filename, buffer);
  return filename;
}

module.exports = {
  createSlabDocument,
  createSlabTestReport,
  createSlabMeetingMinutes,
  createSlabHeader,
  createSlabFooter,
  SLAB_STYLES,
  PAGE_SETTINGS,
  LOGO_PATH,
  SLAB_PRIMARY,
  SLAB_SECONDARY,
  SLAB_ACCENT
};

// CLI usage
if (require.main === module) {
  const args = process.argv.slice(2);
  const command = args[0];

  if (command === 'test-report') {
    createSlabTestReport('test-report.docx', {
      projectName: 'Sample Project',
      testCases: [
        { id: 'TC001', name: 'Login Test', status: 'Passed' },
        { id: 'TC002', name: 'Logout Test', status: 'Passed' },
        { id: 'TC003', name: 'Data Export', status: 'Failed', notes: 'Timeout issue' }
      ]
    }).then(() => console.log('Created test-report.docx'));
  } else if (command === 'meeting') {
    createSlabMeetingMinutes('meeting-minutes.docx', {
      title: 'Project Kickoff Meeting',
      attendees: ['Solution Lab', 'Project Manager', 'Developer Team'],
      agenda: ['Project overview', 'Timeline review', 'Next steps'],
      decisions: ['Use React for frontend', 'Weekly standup on Mondays'],
      actionItems: [
        { assignee: 'Solution Lab', task: 'Setup repository', dueDate: '2026-03-20' }
      ]
    }).then(() => console.log('Created meeting-minutes.docx'));
  } else {
    console.log('Usage: node slab_docx_template.js [test-report|meeting]');
  }
}
