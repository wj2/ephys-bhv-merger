
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
    parser.add_argument('--target_name', default='rez2\.mat', type=str,
                        help='target file')
    parser.add_argument('--dry_run', action='store_true', default=False,
                        help='perform a dry run without any actual '
                        'file movements')
    return parser

if __name__ == '__main__':
    parser = create_parser()
    args = parser.parse_args()
    use_dir = args.dir
    dir_folders = os.listdir(use_dir)
    match_pattern = args.file_date
    matches = filter(lambda x: re.match(match_pattern, x), dir_folders)

    for m in matches:
        currpath = os.path.join(use_dir, m)
        f_files = os.listdir(currpath)
        targ_file = list(filter(lambda x: re.match(args.target_name, x),
                                f_files))
        if len(targ_file) > 0:
            print('moving {} to {}'.format(m, args.dest))
            if not args.dry_run:
                shutil.move(currpath, args.dest)
