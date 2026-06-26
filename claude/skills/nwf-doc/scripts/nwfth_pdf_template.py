"""
NWFTH PDF Template Helper
Creates PDF documents with NWFTH branding (logo header, footer attribution)
"""

from reportlab.lib.pagesizes import letter, A4
from reportlab.lib.units import inch
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.colors import HexColor, black, white
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, PageBreak
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.pdfgen import canvas
from datetime import datetime
import os

LOGO_PATH = os.path.join(os.path.dirname(__file__), '..', 'NWFLogo.jpg')

# NWFTH Brand Colors
NWFTH_BROWN = HexColor('#3A2920')
NWFTH_LIGHT_BROWN = HexColor('#8B6A53')
NWFTH_GOLD = HexColor('#E0AA2F')


def create_nwfth_header_footer(canvas, doc):
    """Draw NWFTH header and footer on each page"""
    canvas.saveState()

    # Logo in top-right corner
    try:
        canvas.drawImage(LOGO_PATH, doc.pagesize[0] - 1.8*inch, doc.pagesize[1] - 0.9*inch,
                        width=1.5*inch, height=0.75*inch, preserveAspectRatio=True)
    except:
        pass  # Logo not found, skip

    # Footer attribution
    canvas.setFont("Helvetica", 9)
    canvas.setFillColor(HexColor('#666666'))
    canvas.drawCentredString(doc.pagesize[0]/2, 0.5*inch, "Newly Weds Foods (Thailand)")

    # Page number
    page_num = canvas.getPageNumber()
    canvas.drawRightString(doc.pagesize[0] - 0.75*inch, 0.5*inch, f"Page {page_num}")

    canvas.restoreState()


def create_nwfth_pdf(filename, title=None, content=None, pagesize=letter):
    """
    Create a basic NWFTH branded PDF document

    Args:
        filename: Output filename
        title: Document title
        content: List of flowables (Paragraphs, Spacers, Tables, etc.)
        pagesize: Page size (default: letter)
    """
    doc = SimpleDocTemplate(
        filename,
        pagesize=pagesize,
        rightMargin=72,
        leftMargin=72,
        topMargin=108,  # Extra space for logo
        bottomMargin=72
    )

    styles = getSampleStyleSheet()

    # Custom styles
    title_style = ParagraphStyle(
        'NWFTHTitle',
        parent=styles['Heading1'],
        fontSize=24,
        textColor=NWFTH_BROWN,
        spaceAfter=30,
        alignment=TA_LEFT
    )

    heading2_style = ParagraphStyle(
        'NWFTHHeading2',
        parent=styles['Heading2'],
        fontSize=16,
        textColor=NWFTH_LIGHT_BROWN,
        spaceAfter=12,
        spaceBefore=12
    )

    normal_style = ParagraphStyle(
        'NWFTHNormal',
        parent=styles['Normal'],
        fontSize=11,
        leading=14
    )

    story = []

    if title:
        story.append(Paragraph(title, title_style))
        story.append(Spacer(1, 0.2*inch))

    if content:
        story.extend(content)

    doc.build(story, onFirstPage=create_nwfth_header_footer, onLaterPages=create_nwfth_header_footer)
    return filename


def create_nwfth_test_report(filename, data=None):
    """
    Create a test summary report PDF

    Args:
        filename: Output filename
        data: Dictionary with keys:
            - project_name: str
            - test_date: str
            - prepared_by: str
            - test_cases: list of dicts with id, name, status, notes
            - summary: dict with additional summary info
    """
    if data is None:
        data = {}

    project_name = data.get('project_name', 'N/A')
    test_date = data.get('test_date', datetime.now().strftime('%Y-%m-%d'))
    prepared_by = data.get('prepared_by', 'ICT - NWFTH')
    test_cases = data.get('test_cases', [])

    styles = getSampleStyleSheet()

    # Custom styles
    title_style = ParagraphStyle(
        'NWFTHTitle',
        parent=styles['Heading1'],
        fontSize=24,
        textColor=NWFTH_BROWN,
        spaceAfter=20
    )

    heading2_style = ParagraphStyle(
        'NWFTHHeading2',
        parent=styles['Heading2'],
        fontSize=16,
        textColor=NWFTH_LIGHT_BROWN,
        spaceAfter=10,
        spaceBefore=15
    )

    normal_style = ParagraphStyle(
        'NWFTHNormal',
        parent=styles['Normal'],
        fontSize=11
    )

    bold_style = ParagraphStyle(
        'NWFTHBold',
        parent=styles['Normal'],
        fontSize=11,
        fontName='Helvetica-Bold'
    )

    story = []

    # Title
    story.append(Paragraph("Test Summary Report", title_style))
    story.append(Spacer(1, 0.2*inch))

    # Project Information
    story.append(Paragraph("Project Information", heading2_style))
    story.append(Paragraph(f"<b>Project Name:</b> {project_name}", normal_style))
    story.append(Paragraph(f"<b>Test Date:</b> {test_date}", normal_style))
    story.append(Paragraph(f"<b>Prepared By:</b> {prepared_by}", normal_style))
    story.append(Spacer(1, 0.2*inch))

    # Summary
    passed = sum(1 for tc in test_cases if tc.get('status') == 'Passed')
    failed = sum(1 for tc in test_cases if tc.get('status') == 'Failed')
    total = len(test_cases)

    story.append(Paragraph("Summary", heading2_style))
    story.append(Paragraph(f"<b>Total Test Cases:</b> {total}", normal_style))
    story.append(Paragraph(f"<b>Passed:</b> {passed}", normal_style))
    story.append(Paragraph(f"<b>Failed:</b> {failed}", normal_style))
    story.append(Spacer(1, 0.2*inch))

    # Test Results Table
    if test_cases:
        story.append(Paragraph("Test Results", heading2_style))

        table_data = [['Test ID', 'Test Name', 'Status', 'Notes']]
        for tc in test_cases:
            status = tc.get('status', '')
            status_color = ''
            if status == 'Passed':
                status_color = '<font color="#00AA00">Passed</font>'
            elif status == 'Failed':
                status_color = '<font color="#AA0000">Failed</font>'
            else:
                status_color = status

            table_data.append([
                tc.get('id', ''),
                tc.get('name', ''),
                Paragraph(status_color, normal_style),
                tc.get('notes', '')
            ])

        table = Table(table_data, colWidths=[1.2*inch, 2.5*inch, 1*inch, 1.8*inch])
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), NWFTH_BROWN),
            ('TEXTCOLOR', (0, 0), (-1, 0), white),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 11),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), white),
            ('GRID', (0, 0), (-1, -1), 1, HexColor('#CCCCCC')),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('LEFTPADDING', (0, 0), (-1, -1), 6),
            ('RIGHTPADDING', (0, 0), (-1, -1), 6),
        ]))

        story.append(table)

    create_nwfth_pdf(filename, content=story)
    return filename


def create_nwfth_db_report(filename, transactions=None, title="Database Transaction Report"):
    """
    Create a database transaction report PDF

    Args:
        filename: Output filename
        transactions: List of transaction dicts with id, table, action, status, timestamp
        title: Report title
    """
    if transactions is None:
        transactions = []

    styles = getSampleStyleSheet()

    title_style = ParagraphStyle(
        'NWFTHTitle',
        parent=styles['Heading1'],
        fontSize=24,
        textColor=NWFTH_BROWN,
        spaceAfter=20
    )

    heading2_style = ParagraphStyle(
        'NWFTHHeading2',
        parent=styles['Heading2'],
        fontSize=16,
        textColor=NWFTH_LIGHT_BROWN,
        spaceAfter=10,
        spaceBefore=15
    )

    normal_style = ParagraphStyle(
        'NWFTHNormal',
        parent=styles['Normal'],
        fontSize=10
    )

    story = []

    story.append(Paragraph(title, title_style))
    story.append(Spacer(1, 0.2*inch))

    story.append(Paragraph(f"<b>Generated:</b> {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", normal_style))
    story.append(Spacer(1, 0.2*inch))

    if transactions:
        story.append(Paragraph("Transaction Log", heading2_style))

        table_data = [['Transaction ID', 'Table', 'Action', 'Status', 'Timestamp']]
        for tx in transactions:
            status = tx.get('status', '')
            if status == 'Success':
                status = '<font color="#00AA00">Success</font>'
            elif status == 'Failed':
                status = '<font color="#AA0000">Failed</font>'

            table_data.append([
                tx.get('id', ''),
                tx.get('table', ''),
                tx.get('action', ''),
                Paragraph(status, normal_style),
                tx.get('timestamp', '')
            ])

        table = Table(table_data, colWidths=[1.5*inch, 1.5*inch, 1*inch, 1*inch, 1.5*inch])
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), NWFTH_BROWN),
            ('TEXTCOLOR', (0, 0), (-1, 0), white),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 10),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 10),
            ('BACKGROUND', (0, 1), (-1, -1), white),
            ('GRID', (0, 0), (-1, -1), 1, HexColor('#CCCCCC')),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('LEFTPADDING', (0, 0), (-1, -1), 6),
            ('RIGHTPADDING', (0, 0), (-1, -1), 6),
        ]))

        story.append(table)

    create_nwfth_pdf(filename, content=story)
    return filename


def create_nwfth_meeting_minutes(filename, data=None):
    """
    Create meeting minutes PDF

    Args:
        filename: Output filename
        data: Dictionary with keys:
            - title: str
            - date: str
            - attendees: list of str
            - agenda: list of str
            - decisions: list of str
            - action_items: list of dicts with assignee, task, due_date
    """
    if data is None:
        data = {}

    title = data.get('title', 'Meeting Minutes')
    date = data.get('date', datetime.now().strftime('%Y-%m-%d'))
    attendees = data.get('attendees', [])
    agenda = data.get('agenda', [])
    decisions = data.get('decisions', [])
    action_items = data.get('action_items', [])

    styles = getSampleStyleSheet()

    title_style = ParagraphStyle(
        'NWFTHTitle',
        parent=styles['Heading1'],
        fontSize=24,
        textColor=NWFTH_BROWN,
        spaceAfter=20
    )

    heading2_style = ParagraphStyle(
        'NWFTHHeading2',
        parent=styles['Heading2'],
        fontSize=16,
        textColor=NWFTH_LIGHT_BROWN,
        spaceAfter=10,
        spaceBefore=15
    )

    normal_style = ParagraphStyle(
        'NWFTHNormal',
        parent=styles['Normal'],
        fontSize=11
    )

    story = []

    story.append(Paragraph(title, title_style))
    story.append(Paragraph(f"<b>Date:</b> {date}", normal_style))
    story.append(Spacer(1, 0.2*inch))

    # Attendees
    story.append(Paragraph("Attendees", heading2_style))
    for attendee in attendees:
        story.append(Paragraph(f"• {attendee}", normal_style))
    story.append(Spacer(1, 0.1*inch))

    # Agenda
    if agenda:
        story.append(Paragraph("Agenda", heading2_style))
        for i, item in enumerate(agenda, 1):
            story.append(Paragraph(f"{i}. {item}", normal_style))
        story.append(Spacer(1, 0.1*inch))

    # Decisions
    if decisions:
        story.append(Paragraph("Decisions", heading2_style))
        for decision in decisions:
            story.append(Paragraph(f"• {decision}", normal_style))
        story.append(Spacer(1, 0.1*inch))

    # Action Items
    if action_items:
        story.append(Paragraph("Action Items", heading2_style))
        for item in action_items:
            assignee = item.get('assignee', 'TBD')
            task = item.get('task', '')
            due = item.get('due_date', 'TBD')
            story.append(Paragraph(f"• <b>{assignee}:</b> {task} (Due: {due})", normal_style))

    create_nwfth_pdf(filename, content=story)
    return filename


if __name__ == '__main__':
    import sys

    if len(sys.argv) < 2:
        print("Usage: python nwfth_pdf_template.py [test-report|db-report|meeting]")
        sys.exit(1)

    command = sys.argv[1]

    if command == 'test-report':
        create_nwfth_test_report('test-report.pdf', {
            'project_name': 'Sample Project',
            'test_cases': [
                {'id': 'TC001', 'name': 'Login Test', 'status': 'Passed'},
                {'id': 'TC002', 'name': 'Logout Test', 'status': 'Passed'},
                {'id': 'TC003', 'name': 'Data Export', 'status': 'Failed', 'notes': 'Timeout issue'}
            ]
        })
        print("Created test-report.pdf")

    elif command == 'db-report':
        create_nwfth_db_report('db-report.pdf', [
            {'id': 'TX001', 'table': 'Orders', 'action': 'INSERT', 'status': 'Success', 'timestamp': '2026-02-10 10:00:00'},
            {'id': 'TX002', 'table': 'Customers', 'action': 'UPDATE', 'status': 'Success', 'timestamp': '2026-02-10 10:05:00'}
        ])
        print("Created db-report.pdf")

    elif command == 'meeting':
        create_nwfth_meeting_minutes('meeting-minutes.pdf', {
            'title': 'Project Kickoff Meeting',
            'attendees': ['ICT - NWFTH', 'Project Manager', 'Developer Team'],
            'agenda': ['Project overview', 'Timeline review', 'Next steps'],
            'decisions': ['Use React for frontend', 'Weekly standup on Mondays'],
            'action_items': [
                {'assignee': 'ICT', 'task': 'Setup repository', 'due_date': '2026-02-15'}
            ]
        })
        print("Created meeting-minutes.pdf")

    else:
        print(f"Unknown command: {command}")
        print("Usage: python nwfth_pdf_template.py [test-report|db-report|meeting]")
