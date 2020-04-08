Several scripts and matlab functions for organizing and merging
Plexon electrophysiology files that have been sorted either by hand
or with Kilosort2 with MonkeyLogic behavioral files.

#### Dependencies ####
1. Plexon Matlab SDK
2. MonkeyLogic
3. Python 3.6.x
4. Matlab

#### Usage ####
The two python scripts are meant to be used from the command line and are setup
to organize the collections of electrophysiology and behavioral files for both
automatic sorting with Kilosort2 and merging into a single mat file.

**sequester.py** -- meant to be run on a folder containing the electrophysiology
files. It will put each file in its own folder according to its date and any
extra information. See
```
python sequester.py --help
```
for usage information.

**match_files.py** -- meant to be run on a folder containing subfolders for each
electrophysiological recording as well as an additional folder with all
behavioral data. It will match each behavioral file to the electrophysiological
sessions that could correspond to it, and ask for user input on any ambiguities.
See
```
python match_files.py --help
```
for usage information.

**merge_files.m** -- meant to be run on a folder containing subfolders
constructed with the two scripts above. It will merge the behavioral and
electrophysiological files into a single file and create the appropriate trial
structure. This requires MonkeyLogic to be on the Matlab path, to allow the
reading of bhv files, and the Plexon SDK to be on the Matlab path if using
hand-sorted nex files.
