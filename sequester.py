
import argparse
import os
import re
import shutil

def create_parser():
    parser = argparse.ArgumentParser(description='place files in folders '
                                     'according to their filename')
    parser.add_argument('dir', type=str, help='folder with constituent files')
    parser.add_argument('dest', type=str, help='destination for each subfolder')
    f_default = ('.*(?P<month>[0-9]{2})(?P<day>[0-9]{2})(?P<year>[0-9]{4})'
                 '(?P<extra>.*)')
    parser.add_argument('--file_date', type=str, help='pattern to use for the '
                        'file date string',
                        default=f_default)
    parser.add_argument('--extension', default='\.pl2', type=str,
                        help='extension for files to split on')
    folder_default = '{month}{day}{year}{extra}'
    parser.add_argument('--folder_string', type=str, help='pattern to use for '
                        'each folder name', default=folder_default)
    parser.add_argument('--dry_run', action='store_true', default=False,
                        help='perform a dry run without any actual '
                        'file movements')
    return parser

if __name__ == '__main__':
    parser = create_parser()
    args = parser.parse_args()
    use_dir = args.dir
    ephys_files = os.listdir(use_dir)
    ephys_dict = {}
    match_pattern = args.file_date + args.extension
    for fi, ec in enumerate(ephys_files):
        m = re.match(match_pattern, ec)
        if m:
            mdye = m.group('month', 'day', 'year', 'extra')
            if mdye in ephys_dict.keys():
                mdye[-1] = mdye[-1] + '{}'.format(fi)
            ephys_dict[mdye] = ec

    for (month, day, year, extra), fn in ephys_dict.items():
        dirname = args.folder_string.format(month=month, day=day, year=year,
                                            extra=extra)
        makepath = os.path.join(args.dest, dirname)
        filepath = os.path.join(use_dir, fn)
        print('creating {} in {}'.format(dirname, args.dest))
        print('moving {} to {}'.format(fn, dirname))
        if not args.dry_run:
            folder_name = os.makedirs(makepath)
            shutil.move(filepath, makepath)
