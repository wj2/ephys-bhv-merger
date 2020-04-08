function data = opendatafile_sdmst_plt(nex_file, bhvfile, readLFP, readWaveforms, save_file, ...
    imglog, nex_offset, eventsFile)
%May select either a bhv or a nex file, this program will load that file
%along with the corresponding nex or bhv file (file names must be
%identical).  Must call this function before calling nexgetspike.
%
%Created by     WA, June, 2008
%Modified by AS, July, 2009
% Modified by NYM, 2013s
% Modified by KM, January 7, 2015

verify = 1;
only_waveform_means = 1; % save just the waveform means, not all the waveforms
only_good = 1;

knownfiles = {'nex'};
BHV = [];
NEURO = [];

if ~exist('nex_file','var') || isempty(nex_file)
     [fname pname] = uigetfile('*.nex', 'Choose Plexon data file...');
    if ~fname,
        return
    end
    odflastdir = pname;
    NEURO.File = [pname fname];

    [fname pname] = uigetfile('*.bhv', 'Choose Monkeylogic data file...');
    if ~fname,
        return
    end
    bhvfile = [pname filesep fname];
else
      
    NEURO.File = nex_file;
  
end

[pname fname ext] = fileparts(NEURO.File);
filetype = ext;

MLPrefs.Directories.ExperimentDirectory = [pname filesep];
setpref('MonkeyLogic', 'Directories', MLPrefs.Directories);

VarNames.BehavioralCodes = 'Strobed';
VarNames.Neurons = 'SPK[0-9]{2}[a-z]{1}$';
VarNames.LFP = 'AD';
VarNames.EyeX = 'EyeX';
VarNames.EyeY = 'EyeY';
VarNames.JoyX = 'JoyX';
VarNames.JoyY = 'JoyY';
VarNames.Waveforms = 'SPK[0-9]{2}[a-z]{1}_wf$';

start_trial_code = 9;
end_trial_code = 18;

NEURO.Neuron = [];
NEURO.CodeTimes = [];
NEURO.CodeNumbers = [];
NEURO.LFP = [];

if contains(filetype, 'nex'),
    NEURO.File
    [fh vh d] = nex_read(NEURO.File, readLFP);
    vn = cat(1, {vh.Name});
    numvars = length(vn);

    %Determine index to each variable expected in VarNames, given above
    fn = fieldnames(VarNames);
    n = length(fn);
    for i = 1:n,
        v = fn{i};
        flist = strfind(vn, VarNames.(v));
        flist = regexp(vn, VarNames.(v));
        if strcmp(v, 'Neurons')
            VarNames.(v);
            vn;
            flist;
        end
        k = zeros(1, numvars);
        for ii = 1:numvars,
            if ~isempty(flist{ii}) && flist{ii} == 1,
                k(ii) = ii;
            end
        end
        k = k(logical(k));
        if ~isempty(k),
            VarIndex.(v) = k;
        else
            VarIndex.(v) = 0;
        end
    end

    %Extract LFPs
    display_warning = false;
    if readLFP & VarIndex.LFP,
  
        for i = 1:length(VarIndex.LFP),
            k = VarIndex.LFP(i);
            
            recordedLFP = single(d{k});
            startTime = round(vh(VarIndex.LFP(i)).FragmentTimeStamps*1000); % timestamp of first LFP data point
            frag_index = vh(VarIndex.LFP(i)).FragmentIndex;
            if i == 1
                frag_index_proper = frag_index;
            end
            if sum(frag_index)==0
                display_warning = true;
                frag_index = frag_index_proper;
            end
            
            if length(startTime)==1
            % Pad LFP with zeros if started recording LFP after spikes, or
            % throw out values if started recording LFP before.
            if startTime(1) > 1
                finalLFP = cat(1,zeros((startTime(1)-1),1),recordedLFP);
            elseif startTime(1) < 1
                finalLFP = recordedLFP((-startTime(1)+2):length(recordedLFP));
            else
                finalLFP = recordedLFP;
            end
            
            elseif length(startTime)==2
                
                s1 = startTime(1);
                s2 = startTime(2) - startTime(1) - frag_index(2);
%                 disp(['Second offset = ' num2str(s2)])
                finalLFP = [zeros(s1-1,1); recordedLFP(1:frag_index(2)-1); zeros(s2,1); recordedLFP(frag_index(2):end)];
                
            elseif length(startTime)==3  % CHECK THIS
                
                s1 = startTime(1);
                s2 = startTime(2) - startTime(1) - frag_index(2);
                s3 = startTime(3) - startTime(1) - frag_index(3);
%                 disp(['Second offset = ' num2str(s2)])
                finalLFP = [zeros(s1-1,1); recordedLFP(1:frag_index(2)-1); zeros(s2,1); recordedLFP(frag_index(2):frag_index(3)-1); zeros(s3,1); recordedLFP(frag_index(3):end)];
                
            else
                error('Fragment Index is greater than 2')
            end
            
            NEURO.LFP.(vh(VarIndex.LFP(i)).Name) = finalLFP;
            %NEURO.LFP.(vh(VarIndex.LFP(i)).Name) = d{k};
            %NEURO.LFP(i,:) = d{k}';
            %d{k} = '';
        end
    end
    
    if display_warning
        disp('Warning: Frag Index is not present for all channels')
    end
    
    if readWaveforms & VarIndex.Waveforms
        NEURO.Waveforms = [];
        waveform_length = 56; % number of samples in a waveform
        %check if waveform size is correct
        if length(d{VarIndex.Waveforms(1)})/(waveform_length+1) ~= round(length(d{VarIndex.Waveforms(1)})/(waveform_length+1))
             waveform_length = 48;
             if length(d{VarIndex.Waveforms(1)})/(waveform_length+1) ~= round(length(d{VarIndex.Waveforms(1)})/(waveform_length+1))
                  waveform_length = 54;
             end
        end
            
            for i = 1:length(VarIndex.Waveforms),
            k = VarIndex.Waveforms(i);
            
            num_events = length(d{k})/(waveform_length+1);
            waveforms = double(reshape(d{k}(num_events+1:end), waveform_length, (length(d{k})-num_events)/waveform_length));
            
            if only_waveform_means & num_events > 1
%                 NEURO.Waveforms.(vh(VarIndex.Waveforms(i)).Name) = mean(waveforms');
                NEURO.Waveforms.(vh(VarIndex.Waveforms(i)).Name) = int16(waveforms');
            else
                NEURO.Waveforms.(vh(VarIndex.Waveforms(i)).Name) = d{k};
            end
            
        end
    end

    %Extract behavioral codes
    NEURO.CodeTimes = round(1000*d{VarIndex.BehavioralCodes});
    NEURO.CodeNumbers = vh(VarIndex.BehavioralCodes).MarkerValues{1};

    %Extract spiketimes
    lasttime = 0;
    if VarIndex.Neurons > 0
        for i = 1:length(VarIndex.Neurons),
            k = VarIndex.Neurons(i);
            NEURO.Neuron.(vh(k).Name) = round(1000*d{k});
            lasttime = max([lasttime max(NEURO.Neuron.(vh(k).Name))]);
        end
    end
elseif contains(filetype, 'mat')
    ndata = load(NEURO.File).rez;
    spiketimes = ndata.st3(:, 1);
    neuronids = ndata.st3(:, 2);
    good_neurons = logical(ndata.good);
    uniqueIDs = 1:size(good_neurons, 1);
    if only_good
        uniqueIDs = uniqueIDs(good_neurons);
    end
    freq = ndata.ops.fs;
    for i = 1:length(uniqueIDs)
        id = uniqueIDs(i);
        label = strcat('CLUSTER', num2str(id));
        spks = spiketimes(id == neuronids);
        NEURO.Neuron.(label) = round(1000*spks/freq);
    end
    events = load(eventsFile).Neuro;
    NEURO.CodeTimes = events.Ts;
    NEURO.CodeNumbers = events.Strobed;
else
    fprintf('filetype %s not recognized.', filetype);
end

if exist(bhvfile, 'file'),
    BHV = bhv_read(bhvfile);
    data.BHV = BHV;
else
    fprintf('BHV file not found.');
%     return;
end

ms_cond_nums = 181:188;
%Extract Trials:
if ~isempty(NEURO.CodeTimes),
    c9 = (NEURO.CodeNumbers == start_trial_code);
    c18 = (NEURO.CodeNumbers == end_trial_code);
    t9 = NEURO.CodeTimes(c9);
    t18 = NEURO.CodeTimes(c18);
    if t18(1) < t9(1),
        disp('Warning: An end-of-trial code precedes the first instance of a start-of-trial code');
        c = 0;
        while t18(1) < t9(1)
            c = c + 1;
            t18 = t18(2:end);
        end
        fprintf('%i end of trial codes removed', c);
    elseif t9(length(t9)) > t18(length(t18)),
        disp('Warning: A start-of-trial code follows the last end-of-trial code');
        t9 = t9(1:length(t18));
    end

    count = 0;
    r9 = t9;
    while ~isempty(r9),
        count = count + 1;
        starttrial = r9(1);
        NEURO.TrialTimes(count, 1) = starttrial;
        r18 = t18(t18 > starttrial);
        endtrial = r18(1);
        cds = NEURO.CodeNumbers(NEURO.CodeTimes >= starttrial ...
            & NEURO.CodeTimes <= endtrial);
        ms_trial(count, 1) = any(ismember(ms_cond_nums, cds));
        NEURO.TrialDurations(count, 1) = endtrial - starttrial;
        r9 = t9(t9 > endtrial);
    end
    NEURO.NumTrials = length(NEURO.TrialTimes);
else
    NEURO.TrialTimes = [];
    NEURO.TrialDurations = [];
    NEURO.NumTrials = 0;
end
NEURO.TrialTimes = NEURO.TrialTimes(~ms_trial);
NEURO.TrialDurations = NEURO.TrialDurations(~ms_trial);
NEURO.NumTrials = sum(~ms_trial);
if exist('nex_offset', 'var')
    no_ind = nex_offset + 1;
    NEURO.TrialTimes = NEURO.TrialTimes(no_ind:end);
    NEURO.TrialDurations = NEURO.TrialDurations(no_ind:end);
    NEURO.NumTrials = NEURO.NumTrials - nex_offset;
end
disp('ms trials');
disp(sum(ms_trial));
disp('non ms trials - nex');
disp(length(NEURO.TrialDurations));
disp('trials - bhv');
disp(length(BHV.ConditionNumber));
data.NEURO = NEURO;
set(0, 'userdata', data);

% numneurons = length(fieldnames(data.NEURO.Neuron));

if verify,
    %cross-check trial-durations:
    bhvnumtrials = length(BHV.ConditionNumber);
    if bhvnumtrials ~= NEURO.NumTrials,
        disp(sprintf('Trial Number Mismatch: %i trials found in NEX file and %i trials found in BHV file.', NEURO.NumTrials, bhvnumtrials))
    end
    numtrials = min([bhvnumtrials NEURO.NumTrials]);
    tduration = zeros(numtrials, 1);
    for t = 1:numtrials,
        ct = BHV.CodeTimes{t};
        cn = BHV.CodeNumbers{t};
        cstart = min(ct(cn == start_trial_code));
        cend = min(ct(cn == end_trial_code));
        tduration(t) = cend - cstart;
    end

    durdiff = NEURO.TrialDurations(1:numtrials) - tduration;
    figure
    hist(durdiff, 50);
    figure
    plot(1:numtrials, durdiff, '.')
end

if exist('imglog','var')
    data.imglog = imglog;
end

if save_file
    if ~ischar(save_file)
        [fname, pname] = uiputfile('*.mat', 'Save merged data file...');
    else
        [pname, fname, ~] = fileparts(save_file);
    end
    if ~fname,
        return
    end
    dirtemp = pwd;
    cd(pname);
    save(fname,'data');
    cd(dirtemp);
end

end


