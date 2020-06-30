
#Description: This script exports excel data sheets to csv files
#For more info: wkigoni@gmail.com
#Usage: ./excel-txt_extractor.py excel_workbook.xlsx

import csv, xlrd
from os import sys

excel_file = sys.argv[1]

def get_all_sheets(excel_file):
    sheets = []
    workbook = xlrd.open_workbook(excel_file)
    all_worksheets = workbook.sheet_names()
    for worksheet_name in all_worksheets:
        sheets.append(worksheet_name)
    return sheets

def csv_from_excel(excel_file, sheets):
    workbook = xlrd.open_workbook(excel_file)
    i = 2
    for worksheet_name in sheets:
        worksheet = workbook.sheet_by_name(worksheet_name)
        your_csv_file = open(sys.argv[i], 'w')
        print(i)
        print(sys.argv[i])
        i+=1
        wr = csv.writer(your_csv_file,delimiter='\t', quoting=csv.QUOTE_NONE)

        for row in range(worksheet.nrows):
            lrow = []
            for cell in worksheet.row_values(row):
                lrow.append(cell)
            wr.writerow(lrow)
        your_csv_file.close()


sheets = []
sheets = get_all_sheets(sys.argv[1])
csv_from_excel(sys.argv[1], sheets)
