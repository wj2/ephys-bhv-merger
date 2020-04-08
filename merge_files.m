function [] = merge_files(folder, use_cache)

files = dir(folder);
files(ismember({files.name}, {'.', '..'})) = [];
dirFlags = [files.isdir];
merge_folders = files(dirFlags);

if ~isempty(use_cache)
    cache = load(use_cache);
else
    cache = [];
end

for folderInd = 1:length(merge_folders)
    subfolder = merge_folders(folderInd);
    if use_cache && contains(subfolder, cache)
        bhvFile = cache.subfolder.bhvFile;
    else
        [bhvFile, ephysFile, imglogFile, eventsFile, save_file] = getFiles(folder, subfolder);
        nex_offset = 0;
    end
    opendatafile_sdmst_plt(ephysFile, bhvFile, readLFP, readWaveforms,...
        save_file, imglogFile, nex_offset, eventsFile);
end
end

function [bhvFile, ephysFile, imglogFile, eventsFile, save_file] = getFiles(folder, subfolder)
bhvExtension = '.*\.bhv2?';
bhvNarrower = '.*TASK.*';
ephysNex = '.*\.nex';
ephysMat = 'rez2\.mat';
eventsExtension = '.*\events\.mat';

fileNames = dir(strcat(folder, subfolder)).names;
bhvMask = ~cellfun(@isempty, regexpi(fileNames, bhvExtension));
narrowerMask = ~cellfun(@isempty, regexpi(fileNames, bhvNarrower));
ephysMask = ~cellfun(@isempty, regexpi(fileNames, ephysNex));
conj = bhvMask & narrowerMask;
if sum(conj) ~= 1
    fprintf('appropriate bhv not specified \n');
    fprintf('select correct bhv: \n');
    if sum(conj) == 0
        bhvchoice = choose_option(fileNames(bhvMask));
    else
        bhvchoice = choose_option(fileNames(conj));
    end
else
    bhvchoice = fileNames(conj);
    bhvchoice = bhvchoice(1);
end
if sum(ephysMask) > 1
    fprintf('too many nex files in %s \n', subfolder);
    return;
elseif sum(ephysMask) == 0
    ephysKSMask = ~cellfun(@isempty, regexpi(fileNames, ephysMat));
    ephysEventsMask = ~cellfun(@isempty, regexpi(fileNames, ...
        eventsExtension));
    ephysKSMask = ephysKSMask & ~ephysEventsMask;
    if sum(ephysKSMask) ~= 1 && sum(ephysEventsMask) ~= 1
        fprintf('too many or too few kilosort files in %s \n', ...
            subfolder);
        return;
    else
        ephyschoice = fileNames(ephysKSMask);
        ephyschoice = ephyschoice(1);
        ephysEvents = fileNames(ephysEventsMask);
        ephysEvents = ephysEvents(1);
    end
else
    ephyschoice = fileNames(ephysMask);
    ephyschoice = ephyschoice(1);
    ephysEvents = [];
end
[path, name, ~] = fileparts(bhvchoice);
imglogCand = strcat(path, name, '_imglog.txt');
if isfile(imglogCand)
    imglog = imglogCand;
else
    imglog = [];
end
bhvFile = fullfile(folder, subfolder, bhvchoice);
ephysFile = fullfile(folder, subfolder, ephyschoice);
imglogFile = fullfile(folder, subfolder, imglog);
eventsFile = fullfile(folder, subfolder, ephysEvents);
[path, name, ~] = fileparts(ephysFile);
save_file = fullfile(path, strcat(name, + '_merged.mat'));
end

function choice = choose_option(options)
optText = cell(length(options), 1);
for i = 1:length(options)
    optText{i} = strcat(choiceStr, num2str(i), ' ', options(i));
end
optionStr = join(optText, ' | ');
fprintf(strcat(optionStr, '\n'));
inp = input('option number: ');
choice = options(str2int(inp));
end

