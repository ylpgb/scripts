#/usr/local/opt/python/libexec/bin/python
import csv
import argparse

arg_parser = argparse.ArgumentParser( description = 'Extract cvs column' )
arg_parser.add_argument( 'cvs_file' )
arg_parser.add_argument(
        '-i',
        type = int,
        nargs = 1,
        default = [2],
        help = 'column to extract'
)
args = arg_parser.parse_args()

file = args.cvs_file
column = args.i[0]

print(file,column)
reader = csv.reader(open(file, "r"))
for row in reader:
    print(row[column])
