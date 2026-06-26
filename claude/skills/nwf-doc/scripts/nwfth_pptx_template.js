/**
 * NWFTH PPTX Template Helper
 * Creates PowerPoint presentations with NWFTH branding (logo header, footer attribution)
 */

const pptxgen = require("pptxgenjs");
const fs = require('fs');
const path = require('path');

const LOGO_PATH = path.join(__dirname, '..', 'NWFLogo.jpg');

// NWFTH Brand Colors (hex without # for pptxgenjs)
const NWFTH_BROWN = '3A2920';
const NWFTH_LIGHT_BROWN = '8B6A53';
const NWFTH_GOLD = 'E0AA2F';
const NWFTH_DARK = '363636';
const NWFTH_GRAY = '666666';

/**
 * Create a new NWFTH branded presentation
 * @param {Object} options - Presentation options
 * @param {string} options.title - Presentation title
 * @param {string} options.author - Author name
 * @returns {pptxgen} PptxGenJS presentation object
 */
function createNWFTHPresentation(options = {}) {
    const { title = 'NWFTH Presentation', author = 'ICT - NWFTH' } = options;

    const pptx = new pptxgen();
    pptx.layout = 'LAYOUT_16x9';
    pptx.author = author;
    pptx.title = title;
    pptx.company = 'NWFTH';

    // Define master slide with NWFTH branding
    pptx.defineSlideMaster({
        title: 'NWFTH_MASTER',
        background: { color: 'FFFFFF' },
        objects: [
            {
                image: {
                    path: LOGO_PATH,
                    x: 0.3,
                    y: 0.2,
                    w: 1.2,
                    h: 0.6
                }
            },
            {
                text: {
                    text: 'Newly Weds Foods (Thailand)',
                    options: {
                        x: 0.5,
                        y: 5.2,
                        w: 9,
                        h: 0.3,
                        align: 'center',
                        fontSize: 10,
                        color: NWFTH_GRAY,
                        fontFace: 'Arial'
                    }
                }
            }
        ]
    });

    // Define title slide master
    pptx.defineSlideMaster({
        title: 'NWFTH_TITLE',
        background: { color: NWFTH_BROWN },
        objects: [
            {
                image: {
                    path: LOGO_PATH,
                    x: 8.0,
                    y: 0.3,
                    w: 1.5,
                    h: 0.75
                }
            },
            {
                text: {
                    text: 'Newly Weds Foods (Thailand)',
                    options: {
                        x: 0.5,
                        y: 5.2,
                        w: 9,
                        h: 0.3,
                        align: 'center',
                        fontSize: 10,
                        color: 'FFFFFF',
                        fontFace: 'Arial'
                    }
                }
            }
        ]
    });

    return pptx;
}

/**
 * Add a title slide to the presentation
 * @param {pptxgen} pptx - Presentation object
 * @param {Object} data - Slide data
 * @param {string} data.title - Slide title
 * @param {string} data.subtitle - Slide subtitle
 * @returns {Object} The created slide
 */
function addNWFTHTitleSlide(pptx, data = {}) {
    const { title = 'Title', subtitle = '' } = data;

    const slide = pptx.addSlide({ masterName: 'NWFTH_TITLE' });

    slide.addText(title, {
        x: 0.5,
        y: 2,
        w: 9,
        h: 1.5,
        fontSize: 44,
        bold: true,
        color: 'FFFFFF',
        align: 'center',
        fontFace: 'Arial'
    });

    if (subtitle) {
        slide.addText(subtitle, {
            x: 0.5,
            y: 3.5,
            w: 9,
            h: 0.8,
            fontSize: 24,
            color: 'CCCCCC',
            align: 'center',
            fontFace: 'Arial'
        });
    }

    return slide;
}

/**
 * Add a content slide to the presentation
 * @param {pptxgen} pptx - Presentation object
 * @param {Object} data - Slide data
 * @param {string} data.title - Slide title
 * @param {Array} data.bullets - Array of bullet points
 * @param {string} data.content - Raw text content
 * @returns {Object} The created slide
 */
function addNWFTHContentSlide(pptx, data = {}) {
    const { title = 'Slide Title', bullets = [], content = '' } = data;

    const slide = pptx.addSlide({ masterName: 'NWFTH_MASTER' });

    // Title
    slide.addText(title, {
        x: 0.5,
        y: 1.0,
        w: 9,
        h: 0.6,
        fontSize: 32,
        bold: true,
        color: NWFTH_BROWN,
        fontFace: 'Arial'
    });

    // Content
    if (bullets.length > 0) {
        const bulletItems = bullets.map((bullet, index) => ({
            text: bullet,
            options: {
                bullet: true,
                breakLine: index < bullets.length - 1,
                fontSize: 18,
                color: NWFTH_DARK,
                fontFace: 'Arial'
            }
        }));

        slide.addText(bulletItems, {
            x: 0.5,
            y: 1.8,
            w: 9,
            h: 3.2
        });
    } else if (content) {
        slide.addText(content, {
            x: 0.5,
            y: 1.8,
            w: 9,
            h: 3.2,
            fontSize: 18,
            color: NWFTH_DARK,
            fontFace: 'Arial'
        });
    }

    return slide;
}

/**
 * Add a two-column slide to the presentation
 * @param {pptxgen} pptx - Presentation object
 * @param {Object} data - Slide data
 * @param {string} data.title - Slide title
 * @param {Array} data.leftBullets - Left column bullets
 * @param {Array} data.rightBullets - Right column bullets
 * @param {string} data.leftTitle - Left column title
 * @param {string} data.rightTitle - Right column title
 * @returns {Object} The created slide
 */
function addNWFTHTwoColumnSlide(pptx, data = {}) {
    const {
        title = 'Slide Title',
        leftBullets = [],
        rightBullets = [],
        leftTitle = '',
        rightTitle = ''
    } = data;

    const slide = pptx.addSlide({ masterName: 'NWFTH_MASTER' });

    // Title
    slide.addText(title, {
        x: 0.5,
        y: 1.0,
        w: 9,
        h: 0.6,
        fontSize: 32,
        bold: true,
        color: NWFTH_BROWN,
        fontFace: 'Arial'
    });

    // Left column title
    if (leftTitle) {
        slide.addText(leftTitle, {
            x: 0.5,
            y: 1.7,
            w: 4.2,
            h: 0.4,
            fontSize: 18,
            bold: true,
            color: NWFTH_LIGHT_BROWN,
            fontFace: 'Arial'
        });
    }

    // Left column bullets
    if (leftBullets.length > 0) {
        const leftItems = leftBullets.map((bullet, index) => ({
            text: bullet,
            options: {
                bullet: true,
                breakLine: index < leftBullets.length - 1,
                fontSize: 14,
                color: NWFTH_DARK,
                fontFace: 'Arial'
            }
        }));

        slide.addText(leftItems, {
            x: 0.5,
            y: leftTitle ? 2.1 : 1.7,
            w: 4.2,
            h: 3.0
        });
    }

    // Right column title
    if (rightTitle) {
        slide.addText(rightTitle, {
            x: 5.3,
            y: 1.7,
            w: 4.2,
            h: 0.4,
            fontSize: 18,
            bold: true,
            color: NWFTH_LIGHT_BROWN,
            fontFace: 'Arial'
        });
    }

    // Right column bullets
    if (rightBullets.length > 0) {
        const rightItems = rightBullets.map((bullet, index) => ({
            text: bullet,
            options: {
                bullet: true,
                breakLine: index < rightBullets.length - 1,
                fontSize: 14,
                color: NWFTH_DARK,
                fontFace: 'Arial'
            }
        }));

        slide.addText(rightItems, {
            x: 5.3,
            y: rightTitle ? 2.1 : 1.7,
            w: 4.2,
            h: 3.0
        });
    }

    return slide;
}

/**
 * Add a table slide to the presentation
 * @param {pptxgen} pptx - Presentation object
 * @param {Object} data - Slide data
 * @param {string} data.title - Slide title
 * @param {Array} data.headers - Table headers
 * @param {Array} data.rows - Table rows (array of arrays)
 * @returns {Object} The created slide
 */
function addNWFTHTableSlide(pptx, data = {}) {
    const { title = 'Slide Title', headers = [], rows = [] } = data;

    const slide = pptx.addSlide({ masterName: 'NWFTH_MASTER' });

    // Title
    slide.addText(title, {
        x: 0.5,
        y: 1.0,
        w: 9,
        h: 0.6,
        fontSize: 32,
        bold: true,
        color: NWFTH_BROWN,
        fontFace: 'Arial'
    });

    // Prepare table data
    const tableData = [headers, ...rows];

    // Add table
    slide.addTable(tableData, {
        x: 0.5,
        y: 1.8,
        w: 9,
        h: 3.0,
        border: { pt: 1, color: 'CCCCCC' },
        colW: headers.map(() => 9 / headers.length),
        fill: { color: 'F5F5F5' },
        fontFace: 'Arial',
        fontSize: 12
    });

    // Style header row
    // Note: pptxgenjs applies header styling via the first row automatically

    return slide;
}

/**
 * Create a project update presentation
 * @param {string} filename - Output filename
 * @param {Object} data - Presentation data
 * @param {string} data.title - Presentation title
 * @param {Array} data.slides - Array of slide objects
 */
async function createNWFTHProjectPresentation(filename, data = {}) {
    const { title = 'Project Update', subtitle = '', slides = [] } = data;

    const pptx = createNWFTHPresentation({ title });

    // Title slide
    addNWFTHTitleSlide(pptx, { title, subtitle });

    // Content slides
    slides.forEach(slideData => {
        const { type = 'content', ...rest } = slideData;

        switch (type) {
            case 'content':
                addNWFTHContentSlide(pptx, rest);
                break;
            case 'two-column':
                addNWFTHTwoColumnSlide(pptx, rest);
                break;
            case 'table':
                addNWFTHTableSlide(pptx, rest);
                break;
            default:
                addNWFTHContentSlide(pptx, rest);
        }
    });

    await pptx.writeFile({ fileName: filename });
    return filename;
}

/**
 * Create a test summary presentation
 * @param {string} filename - Output filename
 * @param {Object} data - Presentation data
 */
async function createNWFTHTestPresentation(filename, data = {}) {
    const {
        projectName = 'Project',
        testDate = new Date().toISOString().split('T')[0],
        testCases = [],
        summary = {}
    } = data;

    const pptx = createNWFTHPresentation({ title: `${projectName} - Test Summary` });

    // Title slide
    addNWFTHTitleSlide(pptx, {
        title: 'Test Summary Report',
        subtitle: projectName
    });

    // Summary slide
    const passed = testCases.filter(tc => tc.status === 'Passed').length;
    const failed = testCases.filter(tc => tc.status === 'Failed').length;
    const total = testCases.length;

    addNWFTHContentSlide(pptx, {
        title: 'Summary',
        bullets: [
            `Project: ${projectName}`,
            `Test Date: ${testDate}`,
            `Total Test Cases: ${total}`,
            `Passed: ${passed}`,
            `Failed: ${failed}`,
            `Pass Rate: ${total > 0 ? Math.round((passed / total) * 100) : 0}%`
        ]
    });

    // Test results table slide
    if (testCases.length > 0) {
        const headers = ['Test ID', 'Test Name', 'Status', 'Notes'];
        const rows = testCases.map(tc => [
            tc.id || '',
            tc.name || '',
            tc.status || '',
            tc.notes || ''
        ]);

        addNWFTHTableSlide(pptx, {
            title: 'Test Results',
            headers,
            rows
        });
    }

    // Conclusion slide
    addNWFTHContentSlide(pptx, {
        title: 'Conclusion',
        bullets: [
            failed === 0
                ? 'All tests passed successfully'
                : `${failed} test(s) require attention`,
            'See detailed report for more information',
            'Contact ICT - NWFTH for questions'
        ]
    });

    await pptx.writeFile({ fileName: filename });
    return filename;
}

/**
 * Create a meeting presentation
 * @param {string} filename - Output filename
 * @param {Object} data - Presentation data
 */
async function createNWFTHMeetingPresentation(filename, data = {}) {
    const {
        title = 'Meeting',
        date = new Date().toISOString().split('T')[0],
        attendees = [],
        agenda = [],
        decisions = [],
        actionItems = []
    } = data;

    const pptx = createNWFTHPresentation({ title: `${title} - ${date}` });

    // Title slide
    addNWFTHTitleSlide(pptx, { title, subtitle: date });

    // Attendees slide
    if (attendees.length > 0) {
        addNWFTHContentSlide(pptx, {
            title: 'Attendees',
            bullets: attendees
        });
    }

    // Agenda slide
    if (agenda.length > 0) {
        addNWFTHContentSlide(pptx, {
            title: 'Agenda',
            bullets: agenda
        });
    }

    // Decisions slide
    if (decisions.length > 0) {
        addNWFTHContentSlide(pptx, {
            title: 'Decisions',
            bullets: decisions
        });
    }

    // Action items slide
    if (actionItems.length > 0) {
        const actionBullets = actionItems.map(item =>
            `${item.assignee}: ${item.task} (Due: ${item.dueDate || 'TBD'})`
        );

        addNWFTHContentSlide(pptx, {
            title: 'Action Items',
            bullets: actionBullets
        });
    }

    await pptx.writeFile({ fileName: filename });
    return filename;
}

module.exports = {
    createNWFTHPresentation,
    addNWFTHTitleSlide,
    addNWFTHContentSlide,
    addNWFTHTwoColumnSlide,
    addNWFTHTableSlide,
    createNWFTHProjectPresentation,
    createNWFTHTestPresentation,
    createNWFTHMeetingPresentation,
    LOGO_PATH,
    NWFTH_BROWN,
    NWFTH_LIGHT_BROWN,
    NWFTH_GOLD
};

// CLI usage
if (require.main === module) {
    const args = process.argv.slice(2);
    const command = args[0];

    if (command === 'project') {
        createNWFTHProjectPresentation('project-update.pptx', {
            title: 'Project Update',
            subtitle: 'Q1 2026',
            slides: [
                {
                    title: 'Overview',
                    bullets: ['Project started Jan 2026', 'Team of 5 developers', 'On track for delivery']
                },
                {
                    title: 'Progress',
                    bullets: ['Phase 1 complete', 'Phase 2 in progress', 'Testing scheduled']
                },
                {
                    type: 'two-column',
                    title: 'Comparison',
                    leftTitle: 'Current',
                    leftBullets: ['Legacy system', 'Manual processes', 'Limited reporting'],
                    rightTitle: 'Target',
                    rightBullets: ['Modern platform', 'Automated workflows', 'Real-time dashboards']
                }
            ]
        }).then(() => console.log('Created project-update.pptx'));
    } else if (command === 'test') {
        createNWFTHTestPresentation('test-summary.pptx', {
            projectName: 'BME System',
            testCases: [
                { id: 'TC001', name: 'Login Test', status: 'Passed' },
                { id: 'TC002', name: 'Logout Test', status: 'Passed' },
                { id: 'TC003', name: 'Data Export', status: 'Failed', notes: 'Timeout issue' }
            ]
        }).then(() => console.log('Created test-summary.pptx'));
    } else if (command === 'meeting') {
        createNWFTHMeetingPresentation('meeting.pptx', {
            title: 'Project Kickoff',
            attendees: ['ICT - NWFTH', 'Project Manager', 'Developer Team'],
            agenda: ['Project overview', 'Timeline review', 'Next steps'],
            decisions: ['Use React for frontend', 'Weekly standup on Mondays'],
            actionItems: [
                { assignee: 'ICT', task: 'Setup repository', dueDate: '2026-02-15' }
            ]
        }).then(() => console.log('Created meeting.pptx'));
    } else {
        console.log('Usage: node nwfth_pptx_template.js [project|test|meeting]');
    }
}
