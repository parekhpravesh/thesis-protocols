function subset_timeseries(ts_dir,  source_atlas_name, cond_name, ...
                           roi_idx, target_atlas_name)
% Function to take the output of get_ts_conn and subset time series from a
% set of regions, thereby creating a new atlas
%% Inputs:
% ts_dir:               fullpath to where time series are saved (see get_ts_conn.m)
% source_atlas_name:    name of atlas file from which time series is needed
% cond_name:            name(s) of condition(s) for which time series is needed
% roi_idx:              region number(s) for which time series is needed
% target_atlas_name:    name by which new atlas files will be saved
% 
%% Output:
% A sub-folder named <target_atlas_name> is made in the folder 'ts_dir'; 
% condition specific time series is written out as .mat files in condition 
% specific sub-folders; contained within each of these is the reduced time 
% series for that condition, the HRF weights for the time series, the 
% weighted time series, the names of the ROIs, and the xyz coordinates of 
% the centroid of each of the ROIs
%
%% Default:
% cond_name:            'all'
% 
%% Author(s):
% Parekh, Pravesh
% February 21, 2020
% MBIAL

%% Check inputs
% Check time series directory
if ~exist('ts_dir', 'var') || isempty(ts_dir)
    error('Please provide fullpath to time series directory');
else
    if ~exist(ts_dir, 'dir')
        error(['Cannot find: ', ts_dir]);
    end
end

% Check source_atlas_name
if ~exist('source_atlas_name', 'var') || isempty(source_atlas_name)
    error('Please provide source atlas name');
else
    if ~exist(fullfile(ts_dir, source_atlas_name), 'dir')
        error(['Unable to find ', source_atlas_name, ' folder in ', ts_dir]);
    end
end

% Check cond_name
if ~exist('cond_name', 'var') || isempty(cond_name)
    cond_name = 'all';
end

% Check roi_idx
if ~exist('roi_idx', 'var') || isempty(roi_idx)
    error('Please provide ROI index value(s)');
end

% Check target_atlas_name
if ~exist('target_atlas_name', 'var') || isempty(target_atlas_name)
    error('Please provide a name for the new atlas to be created');
end

%% Get condition list if necessary
if strcmpi(cond_name, 'all')
    cd(fullfile(ts_dir, source_atlas_name));
    tmp_list = dir;
    tmp_list = struct2cell(tmp_list);
    tmp_list(2:end,:) = [];
    tmp_list(ismember(tmp_list, {'.', '..'})) = [];
    cond_name = tmp_list;
end

%% Save modified atlas time series
for cond = 1:length(cond_name)
    % Make output directories if required
    if ~exist(fullfile(ts_dir, target_atlas_name, cond_name{cond}), 'dir')
        mkdir(fullfile(ts_dir, target_atlas_name, cond_name{cond}));
    end
    
    % Get list of subjects
    cd(fullfile(ts_dir, source_atlas_name, cond_name{cond}));
    list_subjs = dir('TS*.mat');
    
    % Go over each subject
    for subjs = 1:length(list_subjs)
        % Load TS variable
        load(fullfile(ts_dir, source_atlas_name, cond_name{cond}, list_subjs(subjs).name), 'roi_names', 'data_reduced_at', 'w_reduced', 'weighted_ts', 'xyz');
        
        % Subset variables
        roi_names       = roi_names(roi_idx);
        data_reduced_at = data_reduced_at(roi_idx);
        weighted_ts     = weighted_ts(:,roi_idx);
        xyz             = xyz(roi_idx);
        
        % Save as new atlas
        new_name = strrep(list_subjs(subjs).name, source_atlas_name, target_atlas_name);
        save(fullfile(ts_dir, target_atlas_name, cond_name{cond}, new_name), 'roi_names', 'data_reduced_at', 'w_reduced', 'weighted_ts', 'xyz');
        
        % Clear up variables to prevent mixing up
        clear roi_names data_reduced_at weighted_ts xyz w_reduced
    end
end