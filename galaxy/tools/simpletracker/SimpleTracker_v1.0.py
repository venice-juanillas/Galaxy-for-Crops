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

import sys
import os
import pandas as pd
import uuid
import xlrd, xlwt
import traceback
from xlutils.copy import copy

from optparse import OptionParser

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

def generate_intertek_file(df, plate_df,intertek_template_file,outfile):
    rb = xlrd.open_workbook(intertek_template_file, formatting_info=True)
    wb = copy(rb)
    ws1 = wb.get_sheet(3)
    ws1_col_start = 1
    ws1_row_start = 12
    df = df.reset_index(drop=True)
    plate_df = plate_df.reset_index(drop=True)
    
    for index, row in plate_df.iterrows():
        ws1.write(ws1_row_start+index, ws1_col_start, row['plate_name'])
        ws1.write(ws1_row_start+index, ws1_col_start+1, row['plate_barcode'])
    
    ws2 = wb.get_sheet(4)
    ws2_col_start = 1
    ws2_row_start = 15
    
    for index, row in df.iterrows():
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
    df.insert(0,'plate_well_position',value=plate_well_position)
    df.insert(0,'plate_name',value=plate_name_readable)
    df.insert(0,'plate_barcode',value=plate_name_barcode)
    df.insert(0,'plate_uuid',value=plate_name)
    return df

def generate_envelope_barcodes(df):
    return df
    
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

def generate_samples(infile, outfile, separator, exp_id, direction, check_positions, intertek_template_file):
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
    
    generate_intertek_file(new_df,plate_df, intertek_template_file,outfile)
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
        parser.add_option("-i", "--in", dest="infile", help="set input path [default: %default]", metavar="FILE")
        parser.add_option("-o", "--out", dest="outfile", help="set output path [default: %default]", metavar="FILE")
        parser.add_option("-e", "--exp-name", dest="exp_name", help="set experiment name for plate prefix [default: %default]")
        parser.add_option("-d", "--direction", dest="direction", help="set plate layout direction if vertical or horizontal [default: %default]")
        parser.add_option("-t", "--intertek-template", dest="intertek_template_file", help="set Intertek template Excel file [default: %default]", metavar="FILE")
        parser.add_option("-c", "--check-position", dest="check_positions", help="set position of checks in plate, comma separated with no spaces [default: %default]")
        parser.add_option("-v", "--verbose", dest="verbose", action="count", help="set verbosity level [default: %default]")

        # set defaults
        parser.set_defaults(outfile="files/out", infile="files/in.txt", exp_name="new_exp-", direction="horizontal", intertek_template_file="files/intertek.xls", check_positions="H11,H12")

        # process options
        (opts, args) = parser.parse_args(argv)

        if opts.verbose > 0:
            print("verbosity level = %d" % opts.verbose)
#        if opts.infile:
#            print("infile = %s" % opts.infile)
#         else:
#             sys.stderr.write("No input file detected!\n")
#             sys.exit()
#        if opts.outfile:
#            print("outfile = %s" % opts.outfile)

        # MAIN BODY #
        if opts.infile.endswith('.csv'):
            separator = ','
        else:
            separator = '\t'
        generate_samples(
            infile=opts.infile,
            outfile=opts.outfile,
            separator=separator,
            exp_id=opts.exp_name,
            direction=opts.direction,
            check_positions=opts.check_positions,
            intertek_template_file=opts.intertek_template_file
            )
        
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