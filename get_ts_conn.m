function get_ts_conn(project_name, atlas_name, output_dir)
% Function to get condition specific denoised regional time series for a 
% given atlas from an existing Conn project
%% Inputs:
% project_name: fullpath to the conn project (.mat file)
% atlas_name:   name of the atlas file to get time series from
% output_dir:   fullpath to where results should be saved
% 
%% Output:
% A sub-folder named <atlas_name> is made in the folder 'time_series' in
% output_dir where condition specific time series is written out as .mat 
% files in condition specific sub-folders; contained within each of these 
% is the reduced time series for that condition, the HRF weights for the 
% time series, the weighted time series, the names of the ROIs, and the 
% xyz coordinates of the centroid of each of the ROIs
%
%% Defaults:
% atlas_name:   all multiple label ROIs specified in the project setup
% output_dir:   project path
% 
%% Notes:
% Assumes that analyses have already been run (see create_conn_batch_mat.m
% for batch mode analysis of already pre-processed data)
%
% Assumes that functional files are present in subject specific folders.
% 
% Subject IDs are based on the first occurrence of 'sub-' keyword 
% 
% Multiple atlas_name can be passed at once as a cell type with rows
% corresponding to atlas names
% 
% Designed to work with Conn 18.b output
%
%% References
% 1) https://www.nitrc.org/forum/message.php?msg_id=15735
% 2) https://www.nitrc.org/forum/message.php?msg_id=15500
% 3) https://www.nitrc.org/forum/message.php?msg_id=18633
% 
%% Author(s):
% Parekh, Pravesh
% January 18, 2019
% MBIAL

%% Parse input
% Check project_name
if ~exist('project_name', 'var') || isempty(project_name)
    error('project_name needs to be specified');
else
    if ~exist(project_name, 'file')
        error(['Cannot find: ', project_name]);
    else
        [project_path, project_name, ~] = fileparts(project_name);
    end
end

% Check atlas_name
if ~exist('atlas_name', 'var') || isempty(atlas_name)
    atlas_name = 'all';
else
    if ischar(atlas_name)
        atlas_name = {atlas_name};
    end
end

% Check output_dir
if ~exist('output_dir', 'var') || isempty(output_dir)
    output_dir = fullfile(project_path, 'time_series');
end

%% Get subject information
load(fullfile(project_path, [project_name, '.mat']), 'CONN_x');
num_subjs = CONN_x.Setup.nsubjects;

% Get subject IDs by parsing functional file names
list_subjs = cell(num_subjs,1);
for sub = 1:num_subjs
    loc             = strfind(CONN_x.Setup.functional{sub}{1}{1}, 'sub-');
    tmp             = strsplit(CONN_x.Setup.functional{sub}{1}{1}(loc(1):end), '/');
    list_subjs{sub} = tmp{1};
    % [~, list_subjs{sub}] = fileparts(fileparts(CONN_x.Setup.functional{sub}{1}{1}));
end

%% Load one file for initializing etc
load(fullfile(project_path, project_name, 'results', 'preprocessing', ...
             'ROI_Subject001_Condition001.mat'), 'names', 'xyz');
xyz_all = xyz;

%% Get ROI information
% Get all atlases specified in the project
list_atlases = CONN_x.Setup.rois.names(logical(CONN_x.Setup.rois.multiplelabels));

% Check if atlas_name is present in list_atlases
if ~strcmpi(atlas_name, 'all')
    if sum(ismember(atlas_name, list_atlases)) ~= size(atlas_name,1)
        error('Cannot find one or more atlases; check atlas_name');
    else
        list_atlases(~ismember(list_atlases, atlas_name)) = [];
    end
end
atlas_name  = list_atlases;
atlases_num = size(atlas_name,2);

% Find ROI indices for atlases
roi_idx_at = cell(atlases_num, 1);
for atlas = 1:atlases_num
    roi_idx_at{atlas} = find(~cellfun('isempty', ...
                            (regexp(names, atlas_name{atlas}))));
end

%% Get condition details
cond_names = CONN_x.Setup.conditions.allnames;
cond_nums  = length(cond_names);

%% Prepare output directory
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

for atlas = 1:atlases_num
    if ~exist(fullfile(output_dir, atlas_name{atlas}), 'dir')
        mkdir(fullfile(output_dir, atlas_name{atlas}));
    end
    for con = 1:cond_nums
        if ~exist(fullfile(output_dir, atlas_name{atlas}, cond_names{con}), 'dir')
            mkdir(fullfile(output_dir, atlas_name{atlas}, cond_names{con}));
        end
    end
end

%% Get time series
for sub = 1:num_subjs
    for con = 1:cond_nums
        % Load ROI_Subject*_Condition*.mat file
        load(fullfile(project_path, project_name, 'results', ...
                      'preprocessing', ['ROI_', 'Subject',   ...
                      num2str(sub, '%03d'), '_Condition',    ...
                      num2str(con, '%03d'), '.mat']),        ...
                      'conditionweights', 'data');
                  
        % Get reduced time series for all ROIs
        % https://www.nitrc.org/forum/message.php?msg_id=15735
        w            = max(0,conditionweights{1});
        idx          = find( w>0 );
        data_reduced = cellfun(@(x)x(idx,:), data, 'uni',0);
        w_reduced    = w(idx);
        
        % Work on each atlas
        for atlas = 1:atlases_num
            
            % Get atlas specific reduced time series and ROI names etc.
            weighted_ts     = zeros(length(w_reduced),length(roi_idx_at{atlas}));
            data_reduced_at = data_reduced(roi_idx_at{atlas});
            num_rois        = length(roi_idx_at{atlas});
            roi_names       = names(roi_idx_at{atlas});
            xyz             = xyz_all(roi_idx_at{atlas});
            
            % Get weighted time series for each ROI
            for roi = 1:num_rois
                weighted_ts(:,roi) = conn_wdemean(data_reduced_at{roi}, ...
                                                  w_reduced).*w_reduced;
            end
            
            % Save condition specific time series
            save_name = fullfile(output_dir, atlas_name{atlas}, ...
                                 cond_names{con}, ['TS_',       ...
                                 atlas_name{atlas}, '_',        ...
                                 cond_names{con}, '_',          ...
                                 list_subjs{sub}, '.mat']);
            save(save_name, 'weighted_ts', 'data_reduced_at', 'w_reduced', ...
                            'roi_names', 'xyz');
        end
    end
end