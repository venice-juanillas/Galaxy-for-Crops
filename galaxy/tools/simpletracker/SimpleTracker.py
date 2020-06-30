    #!/usr/bin/env python
# encoding: utf-8
'''
SimpleTracker.SimpleTracker -- Generate sample ID, barcodes, and plate layout for a genotyping experiment from an entry list

SimpleTracker.SimpleTracker is a tool that parses a file for <germplasm_name> and <number_of_plants> to generate sample IDs,
barcodes, and plate layout. It will take all other columns included in the input file. 

It defines classes_and_methods

@author:     John Carlos Ignacio

@copyright:  2018 John Carlos Ignacio. All rights reserved.

@license:    license

@contact:    j.ignacio@irri.org
@deffield    updated: Updated
'''

import csv
import zipfile
import sys
import os
import pandas as pd
import uuid
import xlrd, xlwt
import traceback
from xlutils.copy import copy

from optparse import OptionParser
from zipfile import ZIP_DEFLATED

__all__ = []
__version__ = 0.1
__date__ = '2018-04-12'
__updated__ = '2018-04-12'

DEBUG = 1
TESTRUN = 0
PROFILE = 0
plate_well_positions_vertical = [
        'A01','B01','C01','D01','E01','F01','G01','H01',
        'A02','B02','C02','D02','E02','F02','G02','H02',
        'A03','B03','C03','D03','E03','F03','G03','H03',
        'A04','B04','C04','D04','E04','F04','G04','H04',
        'A05','B05','C05','D05','E05','F05','G05','H05',
        'A06','B06','C06','D06','E06','F06','G06','H06',
        'A07','B07','C07','D07','E07','F07','G07','H07',
        'A08','B08','C08','D08','E08','F08','G08','H08',
        'A09','B09','C09','D09','E09','F09','G09','H09',
        'A10','B10','C10','D10','E10','F10','G10','H10',
        'A11','B11','C11','D11','E11','F11','G11','H11',
        'A12','B12','C12','D12','E12','F12','G12','H12'
    ]

plate_well_positions_horizontal = [
        'A01','A02','A03','A04','A05','A06','A07','A08','A09','A10','A11','A12',
        'B01','B02','B03','B04','B05','B06','B07','B08','B09','B10','B11','B12',
        'C01','C02','C03','C04','C05','C06','C07','C08','C09','C10','C11','C12',
        'D01','D02','D03','D04','D05','D06','D07','D08','D09','D10','D11','D12',
        'E01','E02','E03','E04','E05','E06','E07','E08','E09','E10','E11','E12',
        'F01','F02','F03','F04','F05','F06','F07','F08','F09','F10','F11','F12',
        'G01','G02','G03','G04','G05','G06','G07','G08','G09','G10','G11','G12',
        'H01','H02','H03','H04','H05','H06','H07','H08','H09','H10','H11','H12'
    ]

infinium_plate_well_format = [
        'A01','E02','G01','C03','B01','F02','H01','D03','C01','G02','A02','E03',
        'D01','H02','B02','F03','E01','A03','C02','G03','F01','B03','D02','H03',
        'A04','E05','G04','C06','B04','F05','H04','D06','C04','G05','A05','E06',
        'D04','H05','B05','F06','E04','A06','C05','G06','F04','B06','D05','H06',
        'A07','E08','G07','C09','B07','F08','H07','D09','C07','G08','A08','E09',
        'D07','H08','B08','F09','E07','A09','C08','G09','F07','B09','D08','H09',
        'A10','E11','G10','C12','B10','F11','H10','D12','C10','G11','A11','E12',
        'D10','H11','B11','F12','E10','A12','C11','G12','F10','B12','D11','H12'
    ]

sentrix_wells = [
        'R01C01', 'R01C02', 'R02C01', 'R02C02', 'R03C01', 'R03C02', 'R04C01', 'R04C02',
        'R05C01', 'R05C02', 'R06C01', 'R06C02', 'R07C01', 'R07C02', 'R08C01', 'R08C02',
        'R09C01', 'R09C02', 'R10C01', 'R10C02', 'R11C01', 'R11C02', 'R12C01', 'R12C02'
    ]

miseq_control_ids = ['NB1','NB1b','NB2','NB2b','NB3','NB3b','NB4','NB4b']
miseq_control_names = ['Nipponbare1','Nipponbare1b','Nipponbare2','Nipponbare2b','Nipponbare3','Nipponbare3b','Nipponbare4','Nipponbare4b']

def generate_intertek_file(df, plate_df,intertek_template_file,outfile,well_positions,check_positions,direction):
    rb = xlrd.open_workbook(intertek_template_file, formatting_info=True)
    wb = copy(rb)
    ws1 = wb.get_sheet(3)
    ws1_col_start = 1
    ws1_row_start = 12
    df = df.reset_index(drop=True)
    plate_df = plate_df.reset_index(drop=True)
    
    column_names = df.columns.values
    tmp_df = pd.DataFrame(columns=column_names)
    pos_df = pd.DataFrame(well_positions,columns=['plate_well_position'])
    
    
    for index, row in plate_df.iterrows():
        ws1.write(ws1_row_start+index, ws1_col_start, row['plate_name'])
        ws1.write(ws1_row_start+index, ws1_col_start+1, row['plate_barcode'])
        
        current_plate = df.loc[df['plate_name'] == row['plate_name']]
        current_plate_df = pos_df.reset_index().merge(current_plate, on='plate_well_position',how='left').set_index('index')
        current_plate_df['plate_name'].fillna(row['plate_name'],inplace=True)
        current_plate_df['plate_barcode'].fillna(row['plate_barcode'],inplace=True)
        tmp_df = tmp_df.append(current_plate_df)
        tmp_df = tmp_df.reset_index(drop=True)
        
    tmp_df.fillna('',inplace=True)
    
    ws2 = wb.get_sheet(4)
    ws2_col_start = 1
    ws2_row_start = 15
        
    for index, row in tmp_df.iterrows():
        ws2.write(ws2_row_start+index, ws2_col_start, row['sample_name'])
        ws2.write(ws2_row_start+index, ws2_col_start+1, row['plate_name'])
        ws2.write(ws2_row_start+index, ws2_col_start+2, row['plate_well_position'])
        ws2.write(ws2_row_start+index, ws2_col_start+3, row['sample_barcode'])
        ws2.write(ws2_row_start+index, ws2_col_start+4, row['plate_barcode'])
    
    ws3 = wb.get_sheet(5)
    ws3_col_start = 1
    ws3_row_start = 10
    
    for i in range(0, (len(df.index)-1) // 94 + 1):
        ws3.write(ws3_row_start+11*i,ws3_col_start,plate_df.iloc[i]['plate_name'])
        ws3 = format_to_plate(df.loc[i*94:i*94+93],ws3,ws3_row_start+1+11*i,ws3_col_start)
    
    wb.save(outfile+"_intertek.xls")

def format_to_plate(df,ws,row,col):
    row_dict = {'A':0,'B':1,'C':2,'D':3,'E':4,'F':5,'G':6,'H':7}
    for index,rows in df.iterrows():
        y = row_dict.get(rows['plate_well_position'][:1])+1
        x = int(rows['plate_well_position'][1:])-1
        ws.write(row+y,col+x,rows['sample_name'])
    return ws

def custom_insert(df, header, column):
    if header in df.columns:
        df = df.drop(columns=header)
    df.insert(0, header, value=column)
    
def generate_plate_layout(df, exp_id, well_positions):
    plate_name = []
    plate_name_barcode = []
    plate_name_readable = []
    plate_well_position = []
    samples_per_plate = len(well_positions)
    plate_index = 1
    plate_unique_id = uuid.uuid4()
    for i in range(0,len(df.index)):
        plate_index = i % samples_per_plate
        if plate_index == 0:
            plate_unique_id = uuid.uuid4()
        plate_name.append(plate_unique_id)
        plate_name_barcode.append(str(plate_unique_id.int))
        plate_name_readable.append(str(exp_id)+str(i // samples_per_plate + 1).zfill(2))
        plate_well_position.append(well_positions[plate_index])
    custom_insert(df,'plate_well_position',plate_well_position)
    custom_insert(df,'plate_name',plate_name_readable)
    df['plate_barcode'] = plate_name_barcode
    custom_insert(df,'plate_uuid',plate_name)
    return df

def generate_envelope_barcodes(df):
    return df

def reorder_samples(df, check_positions, all_well_positions,platform):
    plates = df.plate_name.drop_duplicates()
    if platform == 'miseq':
        plate_well_position = [ x for x in all_well_positions if x not in check_positions ]
    else:
        plate_well_position = all_well_positions
    number_samples = df.shape[0]
    number_samples_per_plate = len(plate_well_position)
    number_plates = (number_samples-1) // number_samples_per_plate +1
    new_df_rows = number_plates*number_samples_per_plate
    plate_names = []
    
    for plate in plates:
        plate_names = plate_names+[plate]*number_samples_per_plate
            
    new_df = pd.DataFrame(data={
        'sequence':range(new_df_rows),
        'plate_uuid':['']*new_df_rows,
        'plate_well_position':plate_well_position*number_plates,
        'uuid':['']*new_df_rows,
        'sample_barcode':['']*new_df_rows,
        'sample_name':['']*new_df_rows,
        'plate_name':plate_names,
        'plate_barcode':['']*new_df_rows,
        }, columns=df.columns, dtype=object)
    
    plate_index = 0
    for plate in plates:
        current_df = df[df['plate_name']==plate]
        for index,rows in current_df.iterrows():
            reorder_index = plate_well_position.index(rows['plate_well_position'])
            new_df.loc[(plate_index*number_samples_per_plate)+reorder_index] = rows
        plate_index = plate_index + 1
    return new_df

def generate_miseq_file(df,miseq_template_file,outfile,exp_id,check_positions,direction):
    import datetime as dt
    exp_name = exp_id
    date_row = 2
    assay_row = 5
    data_row_start = 22
    ofile = open(outfile, 'wb')
    writer = csv.writer(ofile)
    if direction == 'vertical':
        df = reorder_samples(df,check_positions,plate_well_positions_horizontal,platform='miseq')
    number_samples = df.shape[0]
    number_checks = ((number_samples-1) // 94 +1)*2
    with open(miseq_template_file, 'rb') as miseq_csv:
        reader = csv.reader(miseq_csv)
        for row in range(data_row_start):
            if row == date_row:
                new_row = reader.next()
                new_row[1] = str(dt.date.today())
                writer.writerow(new_row)
            elif row == assay_row:
                new_row = reader.next()
                new_row[1] = exp_name
                writer.writerow(new_row)
            else:
                writer.writerow(reader.next())
        row_index = 0
        sample_index = 0
        control_index = 0
        last_plate = ''
        for row in reader:
            if sample_index < number_samples:
                row_data = df.iloc[sample_index]
            if row_index % 96 < 94 and sample_index < number_samples:
                row[0] = str(row_data['sample_barcode'])
                row[1] = str(row_data['sample_name'])
                row[2] = str(row_data['plate_name'])
                last_plate = str(row_data['plate_name'])
                sample_index = sample_index + 1
            elif control_index < number_checks:
                row[0] = miseq_control_ids[control_index]
                row[1] = miseq_control_names[control_index]
                row[2] = last_plate
                control_index = control_index + 1
            writer.writerow(row)
            row_index = row_index + 1
    
    ofile.close()

def generate_miseq_file_for_all_samples(df,group_size,miseq_template_file,outfile,exp_id,check_positions,direction):
    number_samples = df.shape[0]
    splits = (number_samples-1) // group_size + 1
    
    miseq_zip = zipfile.ZipFile(outfile+'.miseq.zip','w',ZIP_DEFLATED)

    for group in range(splits):
        df_group = df.iloc[group*group_size:(group+1)*group_size]
        filename = outfile+'.miseq.'+str(group+1)+'.csv'
        generate_miseq_file(df_group,miseq_template_file,filename,exp_id,check_positions,direction)
        miseq_zip.write(filename, os.path.basename(filename))
        os.remove(filename)
        
    miseq_zip.close()
    
def zipAll(outfile, proj_info_file):
    all_zip = zipfile.ZipFile(outfile+'.zip','w',ZIP_DEFLATED)
    all_zip.write(outfile+'_intertek.xls', os.path.basename(outfile+'_intertek.xls'))
    all_zip.write(outfile+'.miseq.zip', os.path.basename(outfile+'.miseq.zip'))
    all_zip.write(outfile+'.infinium.csv', os.path.basename(outfile+'.infinium.csv'))
    all_zip.write(outfile+'.sample_file.txt', os.path.basename(outfile+'.sample_file.txt'))
    all_zip.write(outfile+'.plate_barcodes.txt', os.path.basename(outfile+'.plate_barcodes.txt'))
    all_zip.write(outfile+'.verify_db.txt', os.path.basename(outfile+'.verify_db.txt'))
    if proj_info_file != None:
        all_zip.write(outfile+'.project_info.txt', os.path.basename(outfile+'.project_info.txt'))
    all_zip.close()

def generate_infinium_file(df,infinium_template_file,sentrix_barcodes,outfile,exp_id,plate_well_position,check_positions,direction):
    number_samples = df.shape[0]
    number_samples_per_plate = len(plate_well_position)
    number_plates = (number_samples-1) // number_samples_per_plate + 1
    number_samples_last_plate = number_samples % number_samples_per_plate
    number_barcodes = number_plates*4
    #===========================================================================
    # if number_samples_last_plate == 0:
    #     number_barcodes = number_plates*4
    # elif number_samples_last_plate <= 23:
    #     number_barcodes = (number_plates-1)*4+1
    # elif number_samples_last_plate <= 47:
    #     number_barcodes = (number_plates-1)*4+2
    # elif number_samples_last_plate <= 70:
    #     number_barcodes = (number_plates-1)*4+3
    # else:
    #     number_barcodes = number_plates*4
    #===========================================================================
    
    barcodes = []
    
    if sentrix_barcodes != None:
        with open(sentrix_barcodes) as f:
            barcodes = f.read().splitlines()
            
    barcode_diff = number_barcodes - len(barcodes)
    if barcode_diff > 0:
        for i in range(barcode_diff):
            barcodes.append('')       
            
    data_row_start = 11
    ofile = open(outfile+'.infinium.csv', 'wb')
    writer = csv.writer(ofile)
                  
    with open(infinium_template_file, 'rb') as infinium_csv:
        reader = csv.reader(infinium_csv)
        for row_idx in range(data_row_start):
            row = reader.next()
            writer.writerow(row)
            
    sample_index = 0
    barcode_index = 0
    plate_index = 0
    
    for plate in range(number_plates):
        df_group = df.iloc[plate*number_samples_per_plate:(plate+1)*number_samples_per_plate]
        df_group = reorder_samples(df_group,check_positions,infinium_plate_well_format,platform='infinium')
        for idx,row_data in df_group.iterrows():
            row = ['']*6
            barcode_idx = (plate*96+idx) // 24
            row[0] = barcodes[barcode_idx]
            row[1] = sentrix_wells[idx % 24]
            if idx < 85:
                row[2] = str(row_data['sample_barcode'])
                row[3] = str(row_data['sample_name'])
            elif idx == 85:
                row[2] = 'NB'+str(plate+1)
                row[3] = 'Nipponbare'+str(plate+1)
            elif idx < 95:
                row[2] = str(row_data['sample_barcode'])
                row[3] = str(row_data['sample_name'])
            elif idx == 95:
                row[2] = 'NB'+str(plate+1)+'b'
                row[3] = 'Nipponbare'+str(plate+1)+'b'
            else:
                row[2] = ''
                row[3] = ''
            row[4] = str(row_data['plate_name'])
            row[5] = str(row_data['plate_well_position'])
            writer.writerow(row)
        
    ofile.close()
    
def generate_verify_database(df):
    combined_barcodes = []
    current_step = []
    sample_name = []
    sample_seq = []
    plate_name = []
    well_position = []
    #next_step = []
    last_plate = None
    sample_index = 0
    
    for i in df.sample_barcode:
        current_plate = df.iloc[sample_index]['plate_barcode']
        if last_plate != current_plate:
            combined_barcodes.append(current_plate)
            current_step.append('Scan NEW PLATE')
            plate_name.append(df.iloc[sample_index]['plate_name'])
            sample_name.append('')
            sample_seq.append('')
            well_position.append('')
            last_plate = current_plate
        combined_barcodes.append(i)
        current_step.append('Scan next plant')
        plate_name.append(df.iloc[sample_index]['plate_name'])
        sample_name.append(df.iloc[sample_index]['sample_name'])
        sample_seq.append(df.iloc[sample_index]['sequence'])
        well_position.append(df.iloc[sample_index]['plate_well_position'])
        sample_index = sample_index + 1
    next_step = current_step[1:]
    next_step.append('END')
    new_df = pd.DataFrame(
        {
            'barcodes' : combined_barcodes,
            'next_step' : next_step,
            'plate_name' : plate_name,
            'seq' : sample_seq,
            'sample_name' : sample_name,
            'well_position' : well_position
                        
        })
    
    return new_df

def read_samples(infile, outfile, separator, exp_id, direction, check_positions, intertek_template_file, miseq_template_file, infinium_template_file, sentrix_barcodes, uuid_header):
    ## required headers: sample_name, uuid 
    df = pd.read_csv(infile, sep=separator, header=0)
    new_df = pd.DataFrame(data=None, columns=df.columns)
    dnarun_name = []
    unique_id = []
    dnarun_name_barcode = []
    sequence = []
    plant_index = 0
    entry_index = 0
    
    for idx,row in df.iterrows():
        unique_id = uuid.UUID(row[uuid_header])
        dnarun_name.append(unique_id)
        dnarun_name_barcode.append(str(unique_id.int))
        sequence.append(plant_index+1)
        new_df = new_df.append(df.iloc[[entry_index]])
        plant_index = plant_index + 1
        #plant_number = plant_number + 1
        entry_index = entry_index + 1
    
    check_positions = check_positions.split(',')
    
    if direction == 'horizontal':
        plate_well_position = plate_well_positions_horizontal
    else:
        plate_well_position = plate_well_positions_vertical
    well_positions = [ x for x in plate_well_position if x not in check_positions ]
    new_df = generate_plate_layout(new_df, exp_id, well_positions)
    new_df['sample_barcode'] = dnarun_name_barcode
    custom_insert(new_df,'uuid',dnarun_name)
    custom_insert(new_df,'sequence',sequence)
    
    plate_df = new_df[['plate_uuid','plate_barcode','plate_name']][~new_df.plate_barcode.duplicated(keep='first')]
    
    extension = '.txt'
    if separator == ',':
        extension = '.csv'
    plate_df.to_csv(outfile+'.plate_barcodes'+extension,sep=separator,index=0)
    new_df.drop(['plate_uuid','plate_barcode'],axis=1).to_csv(outfile+'.sample_file'+extension,sep=separator,index=0)
    
    generate_intertek_file(new_df,plate_df,intertek_template_file,outfile,plate_well_position,check_positions,direction)
    generate_miseq_file_for_all_samples(new_df,376,miseq_template_file,outfile,exp_id,check_positions,direction)
    generate_infinium_file(new_df,infinium_template_file,sentrix_barcodes,outfile,exp_id,well_positions,check_positions,direction)
    verify_df = generate_verify_database(new_df)
    verify_df.to_csv(outfile+'.verify_db.txt',sep='\t',index=0)
    
def generate_samples(infile, outfile, separator, exp_id, direction, check_positions, intertek_template_file):
    ## required headers: germplasm_name, number_of_plants
    df = pd.read_csv(infile, sep=separator, header=0)
    new_df = pd.DataFrame(data=None, columns=df.columns)
    dnarun_name = []
    dnarun_name_barcode = []
    dnasample_sample_name = []
    sequence = []
    plant_index = 0
    entry_index = 0
    
    for i in df.number_of_plants:
        plant_number = 1
        while (plant_number <= i):
            unique_id = uuid.uuid4()
            dnarun_name.append(unique_id)
            dnarun_name_barcode.append(str(unique_id.int))
            dnasample_sample_name.append(str(df.germplasm_name[entry_index])+'-'+str(plant_number))
            sequence.append(plant_index+1)
            new_df = new_df.append(df.iloc[[entry_index]])
            plant_index = plant_index + 1
            plant_number = plant_number + 1
        entry_index = entry_index + 1
    
    check_positions = check_positions.split(',')
    
    if direction == 'horizontal':
        plate_well_position = plate_well_positions_horizontal
    else:
        plate_well_position = plate_well_positions_vertical
    well_positions = [ x for x in plate_well_position if x not in check_positions ]
    new_df = generate_plate_layout(new_df, exp_id, well_positions)
    new_df.insert(0,'sample_name',value=dnasample_sample_name)
    new_df.insert(0,'sample_barcode',value=dnarun_name_barcode)
    new_df.insert(0,'uuid',value=dnarun_name)
    new_df.insert(0,'sequence',value=sequence)
    
    plate_df = new_df[['plate_uuid','plate_barcode','plate_name']][~new_df.plate_barcode.duplicated(keep='first')]
    
    extension = '.txt'
    if separator == ',':
        extension = '.csv'
    plate_df.to_csv(outfile+'.plate_barcodes'+extension,sep=separator,index=0)
    new_df.drop(['plate_uuid','plate_barcode'],axis=1).to_csv(outfile+'.sample_file'+extension,sep=separator,index=0)
    
    generate_intertek_file(new_df,plate_df, intertek_template_file,outfile,plate_well_position,check_positions,direction)
    verify_df = generate_verify_database(new_df)
    verify_df.to_csv(outfile+'.verify_db.txt',sep='\t',index=0)

def main(argv=None):
    '''Command line options.'''

    program_name = os.path.basename(sys.argv[0])
    program_version = "v0.1"
    program_build_date = "%s" % __updated__

    program_version_string = '%%prog %s (%s)' % (program_version, program_build_date)
    #program_usage = '''usage: spam two eggs''' # optional - will be autogenerated by optparse
    program_longdesc = '''''' # optional - give further explanation about what the program does
    program_license = "Copyright 2018 John Carlos Ignacio                                            \
                Licensed under the Apache License 2.0\nhttp://www.apache.org/licenses/LICENSE-2.0"

    if argv is None:
        argv = sys.argv[1:]
    try:
        # setup option parser
        parser = OptionParser(version=program_version_string, epilog=program_longdesc, description=program_license)
        parser.add_option("-m", "--mode", dest="mode", help="Choose mode: 'generate' or 'parse' sample file [default: %default]")
        parser.add_option("-i", "--in", dest="infile", help="set input path [default: %default]", metavar="FILE")
        parser.add_option("-o", "--out", dest="outfile", help="set output path [default: %default]", metavar="FILE")
        parser.add_option("-e", "--exp-name", dest="exp_name", help="set experiment name for plate prefix [default: %default]")
        parser.add_option("-j", "--project-info", dest="proj_info_file", help="set project information output file path [default: %default]", metavar="FILE")
        parser.add_option("-d", "--direction", dest="direction", help="set plate layout direction if vertical or horizontal [default: %default]")
        parser.add_option("-t", "--intertek-template", dest="intertek_template_file", help="set Intertek template Excel file [default: %default]", metavar="FILE")
        parser.add_option("-r", "--miseq-template", dest="miseq_template_file", help="set Miseq template csv file [default: %default]", metavar="FILE")
        parser.add_option("-f", "--infinium-template", dest="infinium_template_file", help="set Infinium template Excel file [default: %default]", metavar="FILE")
        parser.add_option("-c", "--check-position", dest="check_positions", help="set position of checks in plate, comma separated with no spaces [default: %default]")
        parser.add_option("-u", "--uuid-header", dest="uuid_header", help="If parse mode, header for sample UUID column in input file [default: %default]")
        parser.add_option("-p", "--platform", dest="platform", help="Indicate if writing output for files for intertek, miseq, infinium, or all [default: %default]")
        parser.add_option("-s", "--sentrix-barcodes", dest="sentrix_barcodes", help="If platform is infinium, indicate input file containing setrix barcodes, one sentrix barcode per line [default: %default]", metavar="FILE")
        parser.add_option("-v", "--verbose", dest="verbose", action="count", help="set verbosity level [default: %default]")

        # set defaults
        parser.set_defaults(mode="generate",
                            outfile="files/out",
                            infile="files/in.txt",
                            exp_name="new_exp-", 
                            direction="horizontal", 
                            intertek_template_file="files/intertek.xls",
                            miseq_template_file="files/miseq.csv",
                            infinium_template_file="files/infinium.csv",
                            check_positions="H11,H12",
                            platform="intertek",
                            proj_info_file=None,
                            sentrix_barcodes=None,
                            uuid_header="uuid")

        # process options
        (opts, args) = parser.parse_args(argv)

        if opts.verbose > 0:
            print("verbosity level = %d" % opts.verbose)
        if opts.infile:
            print("infile = %s" % opts.infile)
#         else:
#             sys.stderr.write("No input file detected!\n")
#             sys.exit()
        if opts.outfile:
            print("outfile = %s" % opts.outfile)

        # MAIN BODY #
        if opts.infile.endswith('.csv'):
            separator = ','
        else:
            separator = '\t'
        if opts.mode == 'generate':
            generate_samples(
                infile=opts.infile,
                outfile=opts.outfile,
                separator=separator,
                exp_id=opts.exp_name,
                direction=opts.direction,
                check_positions=opts.check_positions,
                intertek_template_file=opts.intertek_template_file,
                #miseq_template_file=opts.miseq_template_file
            )
        elif opts.mode == 'parse':
            read_samples(
                infile=opts.infile,
                outfile=opts.outfile,
                separator=separator,
                exp_id=opts.exp_name,
                direction=opts.direction,
                check_positions=opts.check_positions,
                intertek_template_file=opts.intertek_template_file,
                miseq_template_file=opts.miseq_template_file,
                infinium_template_file=opts.infinium_template_file,
                sentrix_barcodes=opts.sentrix_barcodes,
                uuid_header=opts.uuid_header
            )
        
            zipAll(opts.outfile,proj_info_file=opts.proj_info_file)
        
    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        traceback.print_exc()


if __name__ == "__main__":
#     if DEBUG:
#         sys.argv.append("-h")
    if TESTRUN:
        import doctest
        doctest.testmod()
    if PROFILE:
        import cProfile
        import pstats
        profile_filename = 'SimpleTracker.SimpleTracker_profile.txt'
        cProfile.run('main()', profile_filename)
        statsfile = open("profile_stats.txt", "wb")
        p = pstats.Stats(profile_filename, stream=statsfile)
        stats = p.strip_dirs().sort_stats('cumulative')
        stats.print_stats()
        statsfile.close()
        sys.exit(0)
    sys.exit(main())