/**
 * Solution Lab PPTX Template Helper
 * Creates PowerPoint presentations with Solution Lab branding (logo header, footer attribution)
 */

const pptxgen = require("pptxgenjs");
const fs = require('fs');
const path = require('path');

const LOGO_PATH = path.join(__dirname, '..', 'solution-lab-logo.png');
const SLAB_HEADER_TEXT = 'Solution Lab - Innovation & Technology';

// Solution Lab Brand Colors (hex without # for pptxgenjs)
const SLAB_PRIMARY = 'D4652C';
const SLAB_SECONDARY = '333333';
const SLAB_ACCENT = 'E88B5A';
const SLAB_DARK = '363636';
const SLAB_GRAY = '666666';

/**
 * Create a new Solution Lab branded presentation
 * @param {Object} options - Presentation options
 * @param {string} options.title - Presentation title
 * @param {string} options.author - Author name
 * @returns {pptxgen} PptxGenJS presentation object
 */
function createSlabPresentation(options = {}) {
    const { title = 'Solution Lab Presentation', author = 'Wind - Solution Lab' } = options;

    const pptx = new pptxgen();
    pptx.layout = 'LAYOUT_16x9';
    pptx.author = author;
    pptx.title = title;
    pptx.company = 'Solution Lab';

    // Define master slide with Solution Lab branding
    pptx.defineSlideMaster({
        title: 'SLAB_MASTER',
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
                    text: SLAB_HEADER_TEXT,
                    options: {
                        x: 1.65,
                        y: 0.33,
                        w: 5.8,
                        h: 0.25,
                        align: 'left',
                        fontSize: 9,
                        bold: true,
                        color: SLAB_SECONDARY,
                        fontFace: 'Arial'
                    }
                }
            },
            {
                text: {
                    text: SLAB_HEADER_TEXT,
                    options: {
                        x: 0.5,
                        y: 5.2,
                        w: 9,
                        h: 0.3,
                        align: 'center',
                        fontSize: 10,
                        color: SLAB_GRAY,
                        fontFace: 'Arial'
                    }
                }
            }
        ]
    });

    // Define title slide master
    pptx.defineSlideMaster({
        title: 'SLAB_TITLE',
        background: { color: SLAB_PRIMARY },
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
                    text: SLAB_HEADER_TEXT,
                    options: {
                        x: 0.5,
                        y: 0.55,
                        w: 6.8,
                        h: 0.25,
                        align: 'left',
                        fontSize: 10,
                        bold: true,
                        color: 'FFFFFF',
                        fontFace: 'Arial'
                    }
                }
            },
            {
                text: {
                    text: SLAB_HEADER_TEXT,
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
function addSlabTitleSlide(pptx, data = {}) {
    const { title = 'Title', subtitle = '' } = data;

    const slide = pptx.addSlide({ masterName: 'SLAB_TITLE' });

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
function addSlabContentSlide(pptx, data = {}) {
    const { title = 'Slide Title', bullets = [], content = '' } = data;

    const slide = pptx.addSlide({ masterName: 'SLAB_MASTER' });

    // Title
    slide.addText(title, {
        x: 0.5,
        y: 1.0,
        w: 9,
        h: 0.6,
        fontSize: 32,
        bold: true,
        color: SLAB_PRIMARY,
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
                color: SLAB_DARK,
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
            color: SLAB_DARK,
            fontFace: 'Arial'
        });
    }

    return slide;
}

/**
 * Add a two-column slide to the presentation
 * @param {pptxgen} pptx - Presentation object
 * @param {Object} data - Slide data
 * @returns {Object} The created slide
 */
function addSlabTwoColumnSlide(pptx, data = {}) {
    const {
        title = 'Slide Title',
        leftBullets = [],
        rightBullets = [],
        leftTitle = '',
        rightTitle = ''
    } = data;

    const slide = pptx.addSlide({ masterName: 'SLAB_MASTER' });

    // Title
    slide.addText(title, {
        x: 0.5,
        y: 1.0,
        w: 9,
        h: 0.6,
        fontSize: 32,
        bold: true,
        color: SLAB_PRIMARY,
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
            color: SLAB_SECONDARY,
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
                color: SLAB_DARK,
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
            color: SLAB_SECONDARY,
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
                color: SLAB_DARK,
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
 * @returns {Object} The created slide
 */
function addSlabTableSlide(pptx, data = {}) {
    const { title = 'Slide Title', headers = [], rows = [] } = data;

    const slide = pptx.addSlide({ masterName: 'SLAB_MASTER' });

    // Title
    slide.addText(title, {
        x: 0.5,
        y: 1.0,
        w: 9,
        h: 0.6,
        fontSize: 32,
        bold: true,
        color: SLAB_PRIMARY,
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

    return slide;
}

/**
 * Create a project update presentation
 * @param {string} filename - Output filename
 * @param {Object} data - Presentation data
 */
async function createSlabProjectPresentation(filename, data = {}) {
    const { title = 'Project Update', subtitle = '', slides = [] } = data;

    const pptx = createSlabPresentation({ title });

    // Title slide
    addSlabTitleSlide(pptx, { title, subtitle });

    // Content slides
    slides.forEach(slideData => {
        const { type = 'content', ...rest } = slideData;

        switch (type) {
            case 'content':
                addSlabContentSlide(pptx, rest);
                break;
            case 'two-column':
                addSlabTwoColumnSlide(pptx, rest);
                break;
            case 'table':
                addSlabTableSlide(pptx, rest);
                break;
            default:
                addSlabContentSlide(pptx, rest);
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
async function createSlabTestPresentation(filename, data = {}) {
    const {
        projectName = 'Project',
        testDate = new Date().toISOString().split('T')[0],
        testCases = [],
        summary = {}
    } = data;

    const pptx = createSlabPresentation({ title: `${projectName} - Test Summary` });

    // Title slide
    addSlabTitleSlide(pptx, {
        title: 'Test Summary Report',
        subtitle: projectName
    });

    // Summary slide
    const passed = testCases.filter(tc => tc.status === 'Passed').length;
    const failed = testCases.filter(tc => tc.status === 'Failed').length;
    const total = testCases.length;

    addSlabContentSlide(pptx, {
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

        addSlabTableSlide(pptx, {
            title: 'Test Results',
            headers,
            rows
        });
    }

    // Conclusion slide
    addSlabContentSlide(pptx, {
        title: 'Conclusion',
        bullets: [
            failed === 0
                ? 'All tests passed successfully'
                : `${failed} test(s) require attention`,
            'See detailed report for more information',
            'Contact Solution Lab for questions'
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
async function createSlabMeetingPresentation(filename, data = {}) {
    const {
        title = 'Meeting',
        date = new Date().toISOString().split('T')[0],
        attendees = [],
        agenda = [],
        decisions = [],
        actionItems = []
    } = data;

    const pptx = createSlabPresentation({ title: `${title} - ${date}` });

    // Title slide
    addSlabTitleSlide(pptx, { title, subtitle: date });

    // Attendees slide
    if (attendees.length > 0) {
        addSlabContentSlide(pptx, {
            title: 'Attendees',
            bullets: attendees
        });
    }

    // Agenda slide
    if (agenda.length > 0) {
        addSlabContentSlide(pptx, {
            title: 'Agenda',
            bullets: agenda
        });
    }

    // Decisions slide
    if (decisions.length > 0) {
        addSlabContentSlide(pptx, {
            title: 'Decisions',
            bullets: decisions
        });
    }

    // Action items slide
    if (actionItems.length > 0) {
        const actionBullets = actionItems.map(item =>
            `${item.assignee}: ${item.task} (Due: ${item.dueDate || 'TBD'})`
        );

        addSlabContentSlide(pptx, {
            title: 'Action Items',
            bullets: actionBullets
        });
    }

    await pptx.writeFile({ fileName: filename });
    return filename;
}

module.exports = {
    createSlabPresentation,
    addSlabTitleSlide,
    addSlabContentSlide,
    addSlabTwoColumnSlide,
    addSlabTableSlide,
    createSlabProjectPresentation,
    createSlabTestPresentation,
    createSlabMeetingPresentation,
    LOGO_PATH,
    SLAB_PRIMARY,
    SLAB_SECONDARY,
    SLAB_ACCENT
};

// CLI usage
if (require.main === module) {
    const args = process.argv.slice(2);
    const command = args[0];

    if (command === 'project') {
        createSlabProjectPresentation('project-update.pptx', {
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
        createSlabTestPresentation('test-summary.pptx', {
            projectName: 'Solution Lab System',
            testCases: [
                { id: 'TC001', name: 'Login Test', status: 'Passed' },
                { id: 'TC002', name: 'Logout Test', status: 'Passed' },
                { id: 'TC003', name: 'Data Export', status: 'Failed', notes: 'Timeout issue' }
            ]
        }).then(() => console.log('Created test-summary.pptx'));
    } else if (command === 'meeting') {
        createSlabMeetingPresentation('meeting.pptx', {
            title: 'Project Kickoff',
            attendees: ['Solution Lab', 'Project Manager', 'Developer Team'],
            agenda: ['Project overview', 'Timeline review', 'Next steps'],
            decisions: ['Use React for frontend', 'Weekly standup on Mondays'],
            actionItems: [
                { assignee: 'Solution Lab', task: 'Setup repository', dueDate: '2026-03-20' }
            ]
        }).then(() => console.log('Created meeting.pptx'));
    } else {
        console.log('Usage: node slab_pptx_template.js [project|test|meeting]');
    }
}
