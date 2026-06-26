# NWFTH XLSX Examples

This document provides common patterns and examples for creating Excel spreadsheets with NWFTH branding.

## Quick Start

```python
from scripts.nwfth_xlsx_template import (
    create_nwfth_workbook,
    create_nwfth_uat_template,
    create_nwfth_test_summary
)

# Basic workbook
wb, ws = create_nwfth_workbook("My Sheet")
ws['A5'] = "Hello World"
wb.save('output.xlsx')

# UAT Template
create_nwfth_uat_template('uat.xlsx', 'BME System', [
    {'id': 'TC001', 'scenario': 'Login', 'steps': '...', 'expected': '...'}
])

# Test Summary
create_nwfth_test_summary('summary.xlsx', {
    'project_name': 'BME System',
    'test_cases': [
        {'id': 'TC001', 'name': 'Login Test', 'status': 'Passed'},
        {'id': 'TC002', 'name': 'Logout Test', 'status': 'Failed'}
    ]
})
```

## Common Patterns

### Basic Workbook Structure

```python
from openpyxl import Workbook
from openpyxl.drawing.image import Image as XLImage
from openpyxl.styles import Font, Alignment, PatternFill, Border, Side

# Create workbook with NWFTH branding
wb, ws = create_nwfth_workbook("Sheet Name")

# Logo is automatically added at A1
# Footer is automatically set

# Your content starts around row 5 (below logo)
ws['A5'] = "Title"
ws['A5'].font = Font(bold=True, size=16, color='1F4E79')

wb.save('output.xlsx')
```

### Adding Data Tables

```python
from scripts.nwfth_xlsx_template import apply_header_style, create_thin_border

# Headers
headers = ['Column 1', 'Column 2', 'Column 3']
header_row = 10

for col, header in enumerate(headers, 1):
    cell = ws.cell(row=header_row, column=col, value=header)
    apply_header_style(cell)
    cell.border = create_thin_border()

# Data rows
data = [
    ['Value 1', 'Value 2', 'Value 3'],
    ['Value 4', 'Value 5', 'Value 6']
]

for i, row_data in enumerate(data, 1):
    row = header_row + i
    for col, value in enumerate(row_data, 1):
        cell = ws.cell(row=row, column=col, value=value)
        cell.border = create_thin_border()
```

### Styling Cells

```python
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side

# Font styling
cell.font = Font(
    bold=True,
    italic=False,
    size=11,
    color='1F4E79',  # NWFTH Blue
    name='Arial'
)

# Background fill
cell.fill = PatternFill(
    start_color='1F4E79',
    end_color='1F4E79',
    fill_type='solid'
)

# Alignment
cell.alignment = Alignment(
    horizontal='center',  # left, center, right
    vertical='center',    # top, center, bottom
    wrap_text=True
)

# Borders
thin_border = Border(
    left=Side(style='thin', color='CCCCCC'),
    right=Side(style='thin', color='CCCCCC'),
    top=Side(style='thin', color='CCCCCC'),
    bottom=Side(style='thin', color='CCCCCC')
)
cell.border = thin_border
```

### Column Widths and Row Heights

```python
from openpyxl.utils import get_column_letter

# Set column widths
ws.column_dimensions['A'].width = 20
ws.column_dimensions['B'].width = 30

# Auto-adjust based on content
for col in range(1, 10):
    ws.column_dimensions[get_column_letter(col)].width = 20

# Set row height
ws.row_dimensions[10].height = 25
```

### Formulas

```python
# Simple formula
ws['D10'] = '=SUM(A10:C10)'

# Formula with references
ws['E10'] = '=A10*B10'

# Cross-sheet reference
ws['F10'] = '=Sheet2!A1'

# Complex formula
ws['G10'] = '=IF(A10>0, "Positive", "Negative")'
```

### Conditional Formatting (Status Colors)

```python
# Apply color based on status
def apply_status_color(cell, status):
    if status == 'Passed':
        cell.font = Font(color='00AA00', bold=True)
    elif status == 'Failed':
        cell.font = Font(color='AA0000', bold=True)
    elif status == 'In Progress':
        cell.font = Font(color='FF9900', bold=True)
    else:
        cell.font = Font(color='666666')

# Usage
status_cell = ws.cell(row=10, column=3, value='Passed')
apply_status_color(status_cell, 'Passed')
```

## Document Templates

### UAT Test Case Template

```python
from scripts.nwfth_xlsx_template import create_nwfth_uat_template

test_cases = [
    {
        'id': 'TC001',
        'scenario': 'User Login',
        'steps': '1. Enter username\n2. Enter password\n3. Click Login',
        'expected': 'User logged in successfully',
        'actual': '',
        'status': '',
        'tester': '',
        'notes': ''
    },
    {
        'id': 'TC002',
        'scenario': 'Data Export',
        'steps': '1. Select data range\n2. Click Export\n3. Choose format',
        'expected': 'File downloaded successfully',
        'actual': '',
        'status': '',
        'tester': '',
        'notes': ''
    }
]

create_nwfth_uat_template('uat-test-cases.xlsx', 'BME System', test_cases)
```

### Database Transaction Log

```python
from scripts.nwfth_xlsx_template import create_nwfth_db_report

transactions = [
    {
        'id': 'TX001',
        'table': 'Orders',
        'action': 'INSERT',
        'status': 'Success',
        'timestamp': '2026-02-10 10:00:00',
        'details': 'New order created'
    },
    {
        'id': 'TX002',
        'table': 'Customers',
        'action': 'UPDATE',
        'status': 'Success',
        'timestamp': '2026-02-10 10:05:00',
        'details': 'Address updated'
    }
]

create_nwfth_db_report('transaction-log.xlsx', transactions, 'Order Processing Log')
```

### Generic Data Table

```python
from scripts.nwfth_xlsx_template import create_nwfth_data_table

create_nwfth_data_table(
    'data-export.xlsx',
    sheet_name='Export Data',
    headers=['ID', 'Name', 'Value', 'Status', 'Date'],
    rows=[
        ['1', 'Item A', '100', 'Active', '2026-02-01'],
        ['2', 'Item B', '200', 'Inactive', '2026-02-02'],
        ['3', 'Item C', '150', 'Active', '2026-02-03']
    ],
    title='Q1 Data Export'
)
```

### Project Tracker

```python
wb, ws = create_nwfth_workbook("Project Tracker")

# Title
ws['A5'] = "Project Task Tracker"
ws['A5'].font = Font(bold=True, size=18, color='1F4E79')
ws.merge_cells('A5:F5')

# Metadata
ws['A7'] = "Project:"
ws['B7'] = "BME System Implementation"
ws['A8'] = "Last Updated:"
ws['B8'] = datetime.now().strftime('%Y-%m-%d')

for row in [7, 8]:
    ws[f'A{row}'].font = Font(bold=True, size=10)

# Task table
headers = ['Task ID', 'Task Name', 'Assignee', 'Status', 'Due Date', 'Progress']
header_row = 10

for col, header in enumerate(headers, 1):
    cell = ws.cell(row=header_row, column=col, value=header)
    apply_header_style(cell)

# Sample tasks
tasks = [
    ['T001', 'Setup Environment', 'Wind', 'Complete', '2026-02-01', '100%'],
    ['T002', 'Database Design', 'Wind', 'In Progress', '2026-02-15', '75%'],
    ['T003', 'API Development', 'Team', 'Pending', '2026-02-28', '0%']
]

for i, task in enumerate(tasks, 1):
    row = header_row + i
    for col, value in enumerate(task, 1):
        cell = ws.cell(row=row, column=col, value=value)
        cell.border = create_thin_border()

        # Color status column
        if col == 4:  # Status column
            if value == 'Complete':
                cell.font = Font(color='00AA00', bold=True)
            elif value == 'In Progress':
                cell.font = Font(color='FF9900', bold=True)
            elif value == 'Pending':
                cell.font = Font(color='666666')

# Column widths
ws.column_dimensions['A'].width = 12
ws.column_dimensions['B'].width = 25
ws.column_dimensions['C'].width = 15
ws.column_dimensions['D'].width = 15
ws.column_dimensions['E'].width = 15
ws.column_dimensions['F'].width = 12

wb.save('project-tracker.xlsx')
```

## Styling Reference

### Brand Colors

```python
# NWFTH Brand Colors
NWFTH_BLUE = '1F4E79'
NWFTH_LIGHT_BLUE = '2E75B6'
NWFTH_ACCENT = '5B9BD5'

# Status Colors
SUCCESS_GREEN = '00AA00'
ERROR_RED = 'AA0000'
WARNING_ORANGE = 'FF9900'
INFO_GRAY = '666666'
```

### Number Formatting

```python
# Currency
ws['A1'].number_format = '$#,##0.00'

# Percentage
ws['B1'].number_format = '0%'

# Date
ws['C1'].number_format = 'YYYY-MM-DD'

# Custom
ws['D1'].number_format = '#,##0'
```

### Cell Protection

```python
# Lock header cells
for col in range(1, 10):
    ws.cell(row=10, column=col).protection = Protection(locked=True)

# Enable protection (requires password to unprotect)
ws.protection.sheet = True
ws.protection.password = 'password'
```

## Helper Functions

### Auto-Adjust Column Widths

```python
from openpyxl.utils import get_column_letter

def auto_adjust_columns(ws):
    for column in ws.columns:
        max_length = 0
        column_letter = get_column_letter(column[0].column)

        for cell in column:
            try:
                if cell.value:
                    max_length = max(max_length, len(str(cell.value)))
            except:
                pass

        adjusted_width = min(max_length + 2, 50)
        ws.column_dimensions[column_letter].width = adjusted_width
```

### Add Data Validation

```python
from openpyxl.worksheet.datavalidation import DataValidation

# Dropdown list
dv = DataValidation(
    type="list",
    formula1='"Passed,Failed,In Progress,Blocked"',
    allow_blank=True
)
dv.error = 'Please select from the list'
dv.errorTitle = 'Invalid Entry'

# Add to worksheet
ws.add_data_validation(dv)
dv.add(f'D11:D100')  # Apply to range
```

### Freeze Panes

```python
# Freeze top row
ws.freeze_panes = 'A11'

# Freeze first column
ws.freeze_panes = 'B1'

# Freeze both
ws.freeze_panes = 'B11'
```
