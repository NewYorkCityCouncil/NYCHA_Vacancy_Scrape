# Claude AI was able to read/convert it perfectly. The following code is unused.
import pdfplumber
import pandas as pd
import re
from datetime import datetime

PDF_PATH = "../data/input/raw/PACT_Dataset.pdf"
OUTPUT_PATH = "../data/input/modified/PACT_Dataset.csv"

all_rows = []
headers = None

with pdfplumber.open(PDF_PATH) as pdf:
    for i, page in enumerate(pdf.pages):
        print(f"Processing page {i+1}/{len(pdf.pages)}...")
        tables = page.extract_tables()

        for table in tables:
            if not table:
                continue

            # First table on first page should have headers
            if headers is None:
                headers = [col.strip().replace('\n', ' ') if col else f"col_{j}" 
                           for j, col in enumerate(table[0])]
                data_rows = table[1:]
            else:
                # Check if this chunk is a continuation (no header row)
                # If first row matches headers, skip it
                first_row = [c.strip().replace('\n', ' ') if c else '' for c in table[0]]
                data_rows = table[1:] if first_row == headers else table

            for row in data_rows:
                cleaned = [cell.strip().replace('\n', ' ') if cell else '' for cell in row]
                all_rows.append(cleaned)

df = pd.DataFrame(all_rows, columns=headers)

# Drop fully empty rows
df = df.dropna(how='all')
df = df[df.apply(lambda r: r.str.strip().ne('').any(), axis=1)]

df.to_csv(OUTPUT_PATH, index=False)
print(f"\nDone! {len(df)} rows saved to {OUTPUT_PATH}")
print(df.head())