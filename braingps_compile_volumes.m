function braingps_compile_volumes(in_dir, out_dir, native_flag, append_flag)
% Function to read stats file from BrainGPS output and compile information
% across subjects for statistical analysis
%% Inputs:
% in_dir:       input directory containing various 'target' sub-folders
% out_dir:      location where results will be compiled
% native_flag:  1/0 indicating if native space ("corrected") results are
%               to be compiled instead of MNI space resulst
% append_flag:  1/0 indicating if results should be appended to existing
%               files (useful when running the script multiple times)
%
%% Outputs:
% csv files containing regional volumes (actually voxel count) across
% subjects are written at each level of granularity (levels) in out_dir
% 
%% Notes:
% Assumes that the in_dir is organized as follows:
% <in_dir>/
%   target1/
%   target2/
%   :
% <some_other_in_dir_for_another_run>/
%   target1/
%   target2/
%   :
% 
%% Defaults:
% out_dir:      in_dir/results
% native_flag:  0 (no)
% append_flag:  1 (yes)
% 
%% Author(s)
% Parekh, Pravesh
% July 19, 2018
% MBIAL

%% Validate inputs
% Check in_dir
if ~exist('in_dir', 'var') || isempty(in_dir)
    error('Input directory should be provided');
else
    if ~exist(in_dir, 'dir')
        error(['Input directory not found: ', in_dir]);
    end
end

% Check out_dir and create if necessary
if ~exist('out_dir', 'var') || isempty(out_dir)
    mkdir(fullfile(in_dir, 'results'));
else
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
end

% Check native_flag
if ~exist('native_flag', 'var') || isempty(native_flag)
    native_flag = 0;
else
    if native_flag ~= 0 || native_flag ~= 1
        error(['Unknown native_flag provided: ', native_flag]);
    end
end

% Check append_flag
if ~exist('append_flag', 'var') || isempty(append_flag)
    append_flag = 1;
else
    if append_flag ~= 0 || append_flag ~= 1
        error(['Unknown append_flag provided: ', append_flag]);
    end
end

%% Compile list of subjects
cd(in_dir);
tmp_subjs = dir('target*');
num_subjs  = length(tmp_subjs);
list_subjs = cell(num_subjs,1);

% Add full paths to list_subjs
for sub = 1:num_subjs
    list_subjs{sub} = fullfile(in_dir, tmp_subjs(sub).name);
end

%% Read one subject's stats file and initialize some variables
granularity_levels = 10;
cd(list_subjs{1});

% Locate the stats file
if native_flag
    stats_file = dir('*Labels_*_corrected_stats.txt');
    stats_file = stats_file(1).name;
else
    stats_file = dir('*Labels_*_MNI_stats.txt');
    stats_file = stats_file(1).name;
end
tmp_stats_data = readtable(fullfile(list_subjs{1}, stats_file));

% Find the locations for 'Type*'
sep_loc = strfind(tmp_stats_data.Var1, 'Type');
sep_loc = find(~cellfun('isempty', sep_loc));

% Starting and end locations of each granularity level
start_locs = zeros(length(sep_loc)+1,1);
end_locs   = zeros(length(sep_loc)+1,1);
for loc = 1:length(sep_loc)
    if loc == 1
        start_locs(loc) = 1;
        end_locs(loc)   = sep_loc(loc)-1;
    else
        if loc == length(sep_loc)
            start_locs(loc)   = sep_loc(loc-1)+1;
            end_locs(loc)     = sep_loc(loc)-1;
            start_locs(loc+1) = sep_loc(loc)+1;
            end_locs(loc+1)   = length(tmp_stats_data.Var1);
        else
            start_locs(loc) = sep_loc(loc-1)+1;
            end_locs(loc)   = sep_loc(loc)-1;
        end
    end
end

% Get sheet names
sheet_names = [{'Type1-L1 Statistics'}; tmp_stats_data.Var1(sep_loc)];

% Get ROI names for each granularity level
roi_names = cell(1,granularity_levels);
for gran = 1:granularity_levels
    roi_names{:,gran} = tmp_stats_data.Var2(start_locs(gran):end_locs(gran));
end

% Initialize variables; need to shrink later
results = zeros(num_subjs, max(cellfun(@length,roi_names)), granularity_levels);
subj_names = cell(num_subjs, 1);

%% Loop over subjects and compile results
for sub = 1:num_subjs
    
    % Load stats file
    cd(list_subjs{sub});
    if native_flag
        stats_file = dir('*Labels_*_corrected_stats.txt');
        stats_file = stats_file(1).name;
    else
        stats_file = dir('*Labels_*_MNI_stats.txt');
        stats_file = stats_file(1).name;
    end
    stats_data = readtable(fullfile(list_subjs{sub}, stats_file));
    
    % Get subject name
    [~, subj_names{sub,1}] = fileparts(stats_data.Var1{1});
    
    % Loop over each granularity level
    for gran = 1:granularity_levels
        tmp = stats_data.Var3(start_locs(gran):end_locs(gran));
        results(sub, 1:length(tmp), gran) = tmp;
    end
end

%% Write out results
cd(out_dir);

for gran = 1:granularity_levels
    fname = [sheet_names{gran}, '.csv'];
    
    if exist(fname, 'file') && append_flag
        % Use low level commands to append
        fid = fopen(fname, 'a');
        for sub = 1:num_subjs
            fprintf(fid, ['%s,', repmat('%6d,', 1, length(roi_names{gran}))], ...
                    subj_names{sub}, results(sub,1:length(roi_names{gran}),gran));
            fprintf(fid, '\n');
        end
        fclose(fid);
    else
        % Remove any special characters from the ROI names
        var_names = strrep(strrep(roi_names{gran}, '/', '_'), ' ', '_');
        
        % Make a table of the results at the granularity level
        results_gran_tmp = array2table(results(:,1:length(roi_names{gran}),gran), ...
                            'VariableNames', var_names);
        
        % Add subject name and move it to the first column
        results_gran_tmp.SubjectNames = subj_names;
        results_gran = [results_gran_tmp.SubjectNames, results_gran_tmp(:,1:end-1)];
        
        % Write file out
        writetable(results_gran, fname);
    end
end
fclose all;