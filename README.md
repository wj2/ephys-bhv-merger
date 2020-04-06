usage: match_bhv_to_ephys.py [-h] [--ephys_date EPHYS_DATE]
                             [--bhv_date BHV_DATE]
                             [--bhv_extensions BHV_EXTENSIONS [BHV_EXTENSIONS ...]]
                             [--dry_run]
                             ephys_dir bhv_dir

assign behavioral files tosame folder as matching ephys data

positional arguments:
  ephys_dir             folder with one subfolder per ephys session
  bhv_dir               folder with all behavioral files

optional arguments:
  -h, --help            show this help message and exit
  --ephys_date EPHYS_DATE
                        pattern to use for the ephys subdirectory date string
  --bhv_date BHV_DATE   pattern to use for the ephys subdirectory date string
  --bhv_extensions BHV_EXTENSIONS [BHV_EXTENSIONS ...]
  --dry_run             perform a dry run without any actual file movements
