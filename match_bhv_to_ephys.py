
import argparse
import os
import re
import shutil

def create_parser():
    parser = argparse.ArgumentParser(description='assign behavioral files to'
                                     'same folder as matching ephys data')
    parser.add_argument('ephys_dir', type=str, help='folder with one subfolder '
                        'per ephys session')
    parser.add_argument('bhv_dir', type=str, help='folder with all behavioral '
                        'files')
    ep_default = '(?P<month>[0-9]{2})(?P<day>[0-9]{2})(?P<year>[0-9]{4})'
    parser.add_argument('--ephys_date', type=str, help='pattern to use for the '
                        'ephys subdirectory date string',
                        default=ep_default)
    bhv_default = '.*{month}-{day}-{year}.*'
    parser.add_argument('--bhv_date', type=str, help='pattern to use for the '
                        'ephys subdirectory date string',
                        default=bhv_default)
    parser.add_argument('--bhv_extensions', nargs='+', type=str,
                        default=('bhv','_imglog.txt'))
    parser.add_argument('--dry_run', action='store_true', default=False,
                        help='perform a dry run without any actual '
                        'file movements')
    return parser

def choose_destination(f, ec_folders):
    print('should {} go to'.format(f))
    options = range(1, len(ec_folders) + 1)
    option_match = list(zip(options, ec_folders))
    option_strs = ('{}. {}'.format(*op) for op in option_match)
    option_str = ' || '.join(option_strs)
    print(option_str)
    choice = int(input('enter an integer: ')) - 1
    dest_folder = option_match[choice][1]
    return dest_folder

if __name__ == '__main__':
    parser = create_parser()
    args = parser.parse_args()
    ephys = args.ephys_dir
    bhvs = args.bhv_dir    
    ephys_candidates = os.listdir(ephys)
    ephys_dirs = {}
    for ec in ephys_candidates:
        m = re.match(args.ephys_date, ec)
        if m:
            mdy = m.group('month', 'day', 'year')
            if mdy in ephys_dirs.keys():
                ephys_dirs[mdy].append(ec)
            else:
                ephys_dirs[mdy] = [ec]
    bhv_files = os.listdir(bhvs)
    or_ext = '[' + '|'.join(args.bhv_extensions) + ']'
    expr = args.bhv_date + or_ext
    for (month, day, year), ec_folders in ephys_dirs.items():
        d_expr = expr.format(day=day, month=month, year=year)
        matches = filter(lambda x: re.match(d_expr, x), bhv_files)
        if len(ec_folders) > 1:
            print('there are multiple folders from '
                  '{month}-{day}-{year}'.format(month=month, day=day,
                                                year=year))
        for m in matches:
            if len(ec_folders) > 1:
                dest_folder = choose_destination(m, ec_folders)
            else:
                dest_folder = ec_folders[0]
            fp_bhv = os.path.join(args.bhv_dir, m)
            fp_ephys = os.path.join(args.ephys_dir, dest_folder)
            print('moving {} to {}'.format(m, dest_folder))
            if not args.dry_run:
                shutil.move(fp_bhv, fp_ephys)
