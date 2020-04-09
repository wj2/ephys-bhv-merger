function [] = merge_files(folder, use_cache)

files = dir(folder);
files(ismember({files.name}, {'.', '..'})) = [];
dirFlags = [files.isdir];
merge_folders = files(dirFlags);

cacheLocation = fullfile(folder, '.merging_cache.mat');
maxTries = 5;
devThr = 10;
readLFP = 0;
readWaveforms = 0; 

if isfile(cacheLocation) && use_cache
    cache = load(cacheLocation);
else
    cache = [];
end

for folderInd = 1:length(merge_folders)
    subfolder = merge_folders(folderInd).name;
    subfName = strcat('f', subfolder);
    if use_cache && isfield(cache, subfName)
        bhvFile = cache.(subfName).bhvFile;
        ephysFile = cache.(subfName).ephysFile;
        imglogFile = cache.(subfName).imglogFile;
        eventsFile = cache.(subfName).eventsFile;
        saveFile = cache.(subfName).saveFile;
        nexOffset = cache.(subfName).nex_offset;
    else
        [bhvFile, ephysFile, imglogFile, eventsFile, ...
         saveFile] = getFiles(folder, subfolder);
        nexOffset = 0;
        cache.(subfName) = [];
        cache.(subfName).bhvFile = bhvFile;
        cache.(subfName).ephysFile = ephysFile;
        cache.(subfName).imglogFile = imglogFile;
        cache.(subfName).eventsFile = eventsFile;
        cache.(subfName).saveFile = saveFile;       
    end
    dev = devThr + 1;
    tryCount = 0;
    while dev > devThr && tryCount <= maxTries
        tryCount = tryCount + 1;
        [~, diffs] = opendatafile_bhv_ephys(ephysFile, bhvFile, readLFP,...
                                            readWaveforms, saveFile, imglogFile,...
                                            nexOffset, eventsFile);
        dev = max(abs(diffs));
        if dev > devThr
            nexOffset = nexOffset + 1;
            fprintf('deviance above threshold %d > %d \n', dev, devThr);
            if tryCount <= maxTries
                fprintf('trying again with offset %d \n', nexOffset);
            end
        end
    end
    if dev > devThr
        fprintf('correct offset was not found \n');
    end
    cache.(subfName).nexOffset = nexOffset; 
end
save(cacheLocation, '-struct', 'cache');
end

function [bhvFile, ephysFile, imglogFile, eventsFile, ...
          save_file] = getFiles(folder, subfolder)
bhvExtension = '.*\.bhv2?';
bhvNarrower = '.*TASK.*';
ephysNex = '.*\.nex';
ephysMat = 'rez2\.mat';
eventsExtension = '.*\events\.mat';

fileNames = {dir(strcat(folder, subfolder)).name};
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
    bhvchoice = bhvchoice{1};
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
        ephyschoice = ephyschoice{1};
        ephysEvents = fileNames(ephysEventsMask);
        ephysEvents = ephysEvents{1};
    end
else
    ephyschoice = fileNames(ephysMask);
    ephyschoice = ephyschoice{1};
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
save_file = fullfile(path, strcat(name, '-', subfolder, '_merged.mat'));
end

function choice = choose_option(options)
optText = cell(length(options), 1);
for i = 1:length(options)
    optText{i} = strcat(choiceStr, num2str(i), ' ', options(i));
end
optionStr = join(optText, ' | ');
s = strcat(optionStr, '\n');
fprintf(s);
inp = input('option number: ');
choice = options(str2int(inp));
end

