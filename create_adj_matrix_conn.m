function create_adj_matrix_conn(conn_proj_dir, roi_idx, threshold_type, ...
                                threshold, wt_conversion)
% Function to create adjacency matrices from a conn project
%% Inputs:
% conn_proj_dir:    full path to a conn project folder
% roi_idx:          index of ROIs for which to create adjacency matrix
% threshold_type:   method choice for applying thresholding to the 
%                   correlation matrix; can be one of the following:
%                       * absolute
%                       * proportional
%                       * none
% threshold:        number or range for the threshold to apply
% wt_conversion:    conversion of weights; can be one of the following:
%                       * binarize
%                       * normalize
%                       * lengths
%                       * none
% 
%% Outputs:
% A folder named adjacency_matrices is created in the same location as the
% project directory with the following directory structure:
%   <project_directory>/
%       adjacency_matrices/
%           abs_<threshold>/
%           prop_<threshold>/
%           fully_connected/
% 
% mat file(s) for each subject having correlation coefficients for all 
% (or selected) source ROIs are created in the appropriate sub-folder
% and named as (threshold is not mentioned if none is applied):
%   adj_<subject_ID>_task-<task_name>_<condition_number>-<condition_name>_<threshold_type>-<threshold>_bin.mat
%   adj_<subject_ID>_task-<task_name>_<condition_number>-<condition_name>_<threshold_type>-<threshold>_norm.mat
%   adj_<subject_ID>_task-<task_name>_<condition_number>-<condition_name>_<threshold_type>-<threshold>_len.mat
%   adj_<subject_ID>_task-<task_name>_<condition_number>-<condition_name>_<threshold_type>-<threshold>_wei.mat
% 
% Additionally, details of thresholding, weight conversion, ROI names, 
% and subject names are saved in a desc variable
%
%% Notes:
% See threshold_absolute and threshold_proportional from the Brain
% Connectivity toolbox for details of thresholding
% 
% See weight_conversion from the Brain Connectivity Toolbox for details on
% conversion of weights
% 
% weight_conversion 'autofix' is always applied at the end irrespective of 
% the other choices specified
% 
% Assumes that analyses have already been run
% 
% Designed to work with Conn 18.a output
% 
% Requires Brain Connectivity Toolbox
% 
%% Defaults:
% roi_idx:          'all'
% threshold_type:   'proportional'
% threshold:        0.01:0.01:1 (proportional) or 0.2 (absolute)
% wt_conversion:    'binarize'
% 
%% Author(s):
% Parekh, Pravesh
% July 11, 2018
% MBIAL

%% Validate input
% Check conn_proj_dir
if ~exist('conn_proj_dir', 'var') || isempty(conn_proj_dir)
    error('Conn project directory should be provided');
else
    if ~exist(conn_proj_dir, 'dir')
        error(['Conn project directory not found: ', conn_proj_dir]);
    else
        if ~exist([conn_proj_dir, '.mat'], 'file')
            error('Conn project directory found; variable not found');
        end
    end
end

% Check roi_idx
if ~exist('roi_idx', 'var') || isempty(roi_idx)
    select_rois = 0;
    roi_idx     = 'all';
else
    select_rois = 1;
end

% Check threshold_type
if ~exist('threshold_type', 'var') || isempty(threshold_type)
    threshold_type = 'proportional';
else
    if ~ismember(threshold_type, {'absolute', 'proportional', 'none'})
        error(['Unknown threshold_type specified: ', threshold_type]);
    end
end

% Check threshold
if ~exist('threshold', 'var') || isempty(threshold)
    if strcmpi(threshold_type, 'proportional')
        threshold = 0.01:0.01:1;
    else
        if strcmpi(threshold_type, 'absolute')
            threshold = 0.2;
        else
            threshold = 1;
        end
    end
else
    if ~isnumeric(threshold)
        error('Threshold should be a single number or a range');
    end
end

% Check weight_conversion
if ~exist('wt_conversion', 'var') || isempty(wt_conversion)
    wt_conversion = 'binarize';
else
    if ~ismember(wt_conversion, {'binarize', 'normalize', 'lengths', 'none'})
        error(['Unknown wt_conversion specified: ', wt_conversion]);
    end
end

%% Get task_name and figure out which conditions to pick
[~,task_name]   = fileparts(regexprep(conn_proj_dir, 'conn_', ''));

switch(lower(task_name))
    case 'rest'
        conditions  = {'001'};
        cond_names  = {'rest'};
        num_cond    = 1;
        
    case 'vft_classic'
        conditions  = {'002', '003'};
        cond_names  = {'WR', 'WG'};
        num_cond    = 2;
        
    case 'vft_modern'
        conditions  = {'002', '003'};
        cond_names  = {'WR', 'WG'};
        num_cond    = 2;
        
    case 'pm'
        conditions  = {'002', '003', '004', '005'};
        cond_names  = {'BL', 'OT', 'WM', 'PM'};
        num_cond    = 4;
        
    case 'hamt_hs'
        conditions  = {'002', '003'};
        cond_names  = {'FA', 'VA'};
        num_cond    = 2;
        
    case 'hamt_sz'
        conditions  = {'002','003','004'};
        cond_names  = {'FA', 'VA', 'HA'};
        num_cond    = 3;
end

%% Figure out subject details and locate connectivity matrices
cd(fullfile(conn_proj_dir, 'results', 'firstlevel', 'SBC_01'));
list_files = dir('resultsROI_Subject*.mat');
num_subjs  = length(list_files);

% Read conn project file and get actual subject IDs
cd(conn_proj_dir);
cd('..');
load([conn_proj_dir, '.mat'], 'CONN_x');

% Get subject IDs by parsing functional file names
list_subjs = cell(num_subjs,1);

for subj = 1:num_subjs
    list_subjs{subj} = CONN_x.Setup.functional{subj}{1}{1};
end

[list_subjs, ~] = cellfun(@fileparts, list_subjs, 'UniformOutput', false);
[~, list_subjs] = cellfun(@fileparts, list_subjs, 'UniformOutput', false);

% Load one variable and initialize
load_name = fullfile(conn_proj_dir, 'results', 'firstlevel', 'SBC_01', ...
                    'resultsROI_Subject001_Condition001.mat');
var    = load(load_name);
names  = var.names;
names2 = var.names2;

% Check if all ROIs are needed, otherwise shrink names and names2
if select_rois
    names   = names(roi_idx);
    names2  = names2(roi_idx);
else
    roi_idx = 1:length(names);
end

%% Prepare output folder
% Get output directory
cd(conn_proj_dir);
cd('..');
out_dir = pwd;

% Create adjacency_matrices folder
cd(out_dir);
if ~exist('adjacency_matrices', 'dir')
    mkdir('adjacency_matrices');
end

%% Description variable
desc.threshold_type    = threshold_type;
desc.weight_conversion = wt_conversion;
desc.names             = names;
desc.names2            = names2;
desc.roi_idx           = roi_idx;

%% Load, for each condition, resultsROI_* variable and get correlations
for cond = 1:num_cond
    for subj = 1:num_subjs
        
        % Create variable name to load
        load_name = fullfile(conn_proj_dir, 'results', 'firstlevel', 'SBC_01', ...
                            ['resultsROI_Subject', num2str(subj,'%03d'), '_',  ...
                            'Condition', num2str(cond, '%03d'), '.mat']);
        load(load_name, 'Z');
        
        % Convert back to correlation coefficients
        Z = tanh(Z);
        
        % Shrink Z
        Z = Z(roi_idx, roi_idx);
        
        % Perform thresholding operation, if needed
        for thresh = 1:length(threshold)
            switch(threshold_type)
                case 'absolute'
                    % Make output folder if needed
                    if ~exist(fullfile(out_dir, 'adjacency_matrices', ...
                              ['abs_', num2str(threshold(thresh),'%.02f')]), 'dir')
                        mkdir(fullfile(out_dir, 'adjacency_matrices', ...
                              ['abs_', num2str(threshold(thresh), '%.02f')]));
                    end
                    out_local = fullfile(out_dir, 'adjacency_matrices',        ...
                                ['abs_', num2str(threshold(thresh),'%.02f')],   ...
                                ['adj_', list_subjs{subj}, '_task-', task_name, ...
                                '_', conditions{cond}, '_', cond_names{cond},  ...
                                '_abs_', num2str(threshold(thresh), '%.02f')]);
                    
                    adj = threshold_absolute(Z, threshold(thresh));
                    
                case 'proportional'
                    % Make output folder if needed
                    if ~exist(fullfile(out_dir, 'adjacency_matrices', ...
                              ['prop_', num2str(threshold(thresh), '%.02f')]), 'dir')
                        mkdir(fullfile(out_dir, 'adjacency_matrices', ...
                              ['prop_', num2str(threshold(thresh), '%.02f')]));
                    end
                    out_local = fullfile(out_dir, 'adjacency_matrices', ...
                                ['prop_', num2str(threshold(thresh),'%.02f')],  ...
                                ['adj_', list_subjs{subj}, '_task-', task_name, ...
                                '_', conditions{cond}, '_', cond_names{cond},   ...
                                '_prop_', num2str(threshold(thresh), '%.02f')]);
                    
                    adj = threshold_proportional(Z, threshold(thresh));
                    
                case 'none'
                    % Make output folder if needed
                    if ~exist(fullfile(out_dir, 'adjacency_matrices', ...
                              'fully_connected'), 'dir')
                        mkdir(fullfile(out_dir, 'adjacency_matrices', ...
                              'fully_connected'));
                    end
                    out_local = fullfile(out_dir, 'adjacency_matrices', ...
                                'fully_connected', ['adj_', list_subjs{subj}, ...
                                '_task-', task_name, '_', conditions{cond},   ...
                                '_', cond_names{cond}]);
                    adj = Z;
            end
            
            % Apply weight conversion, if needed
            if ~strcmpi(wt_conversion, 'none')
                adj = weight_conversion(adj, wt_conversion);
            end
            adj = weight_conversion(adj, 'autofix');
            
            % Figure out filename for saving
            if strcmpi(wt_conversion, 'binarize')
                filename = [out_local, '_bin.mat'];
            else
                if strcmpi(wt_conversion, 'normalize')
                    filename = [out_local, '_norm.mat'];
                else
                    if strcmpi(wt_conversion, 'lengths')
                        filename = [out_local, '_len.mat'];
                    else
                        filename = [out_local, '_wei.mat'];
                    end
                end
            end
        
            % Save the matrix
            desc.subject_ID = list_subjs{subj};
            desc.threshold  = threshold(thresh);
            save(filename, 'adj', 'desc');
        end
    end
end