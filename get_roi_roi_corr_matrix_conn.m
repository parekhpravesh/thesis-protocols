function get_roi_roi_corr_matrix_conn(conn_proj_dir, roi_idx)
% Function to derive ROI-to-ROI matrix from a conn project
%% Inputs:
% conn_proj_dir: full path to a conn project folder
% roi_idx:       index of ROIs for which to compile connectivity values
% 
%% Output:
% csv file(s) are created in the same location as the project directory
% named
% task-<task_name>_<condition_number>-<condition_name>_connectivity_matrix_ddmmmyyyy.csv
% having subject IDs and a list of pairwise correlation coefficients for
% all source ROIs; also saves condition specific mat file(s) having list of
% subjects, the names of all ROIs, and the correlation coefficient matrix
% for all the subjects; these file(s) are named the same as the csv file
%
% If roi_idx is input, csv file(s) are named
% task-<task_name>_<condition_number>-<condition_name>_connectivity_matrix_selectROIs_ddmmmyyyy.csv
% 
%% Notes:
% Assumes that analyses have already been run
% 
% Designed to work with Conn 18.a output
% 
%% Author(s):
% Parekh, Pravesh
% April 16, 2018
% MBIAL

%% Validate input
if ~exist('conn_proj_dir', 'var')
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

if ~exist('roi_idx', 'var')
    select_rois = 0;
    roi_idx     = 'all';
else
    select_rois = 1;
end

%% Get task_name and figure out which conditions to pick
[~,task_name]   = fileparts(regexprep(conn_proj_dir, 'conn_', ''));

switch(task_name)
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
load(load_name, 'names', 'names2');

% Check if all ROIs are needed, otherwise shrink names and names2
if select_rois
    names   = names(roi_idx);
    names2  = names2(roi_idx);
else
    roi_idx = 1:length(names);
end

num_sources = length(roi_idx);
corr_matrix = NaN(num_cond, num_subjs, num_sources*(num_sources-1)/2);
col_names   = cell(num_sources*(num_sources-1)/2,1);

% Create pairwise names of ROIs
spot = 1;
for source = 1:num_sources
    for dest = source+1:num_sources
        % In case the ROI name has any text in brackets, ignore the bracket
        % part to prevent column names from being too long
        source_name = deblank(names{source}(1:strfind(names{source}, '(')-1));
        dest_name   = deblank(names2{dest}(1:strfind(names2{dest}, '(')-1));
        if isempty(source_name)
            source_name = names{source};
        end
        if isempty(dest_name)
            dest_name = names2{dest};
        end
        
        % In case the ROI name has "atlas" or "networks", shrink it to "at"
        % and "net" to prevent column names from being too long
        source_name = strrep(source_name, 'atlas', 'at');
        dest_name   = strrep(dest_name,   'atlas', 'at');
        
        source_name = strrep(source_name, 'networks', 'net');
        dest_name   = strrep(dest_name,   'networks', 'net');
        
        % Add hyphen between source and destination ROI name
        col_names(spot) = {[source_name, ' - ', dest_name]};
        spot = spot + 1;
    end
end
col_names = [{'list_subjs'}; col_names];

%% Load, for each condition, resultsROI_* variable and get correlations
for cond = 1:num_cond
    for subj = 1:num_subjs
        
        % Create variable name to load
        load_name = fullfile(conn_proj_dir, 'results', 'firstlevel', 'SBC_01', ...
                            ['resultsROI_Subject', num2str(subj,'%03d'), '_', ...
                            'Condition', num2str(cond, '%03d'), '.mat']);
        load(load_name, 'Z');
        
        % Convert back to correlation coefficients
        Z = tanh(Z);
        
        % Shrink Z if needed
        if select_rois
            Z = Z(roi_idx, roi_idx);
        end
        
        % Extract correlation values
        spot = 1;
        for source = 1:num_sources
            for dest = source+1:num_sources
                corr_matrix(cond, subj, spot) = Z(source, dest);
                spot = spot + 1;
            end
        end
    end
end

%% Write out files
% Set output directory
cd(conn_proj_dir);
cd('..');
out_dir = pwd;

for cond = 1:num_cond
    % Create filename for saving
    if select_rois
        fname = fullfile(out_dir, ['task-', task_name, '_', conditions{cond}, ...
        '-', cond_names{cond}, '_connectivity_matrix_selectROIs_', ...
        datestr(now, 'ddmmmyyyy'), '.csv']);
    else
        fname = fullfile(out_dir, ['task-', task_name, '_', conditions{cond}, ...
            '-', cond_names{cond}, '_connectivity_matrix_', ...
            datestr(now, 'ddmmmyyyy'), '.csv']);
    end
    
    % Write column names
    fid = fopen(fname, 'w');
    for col = 1:length(col_names)
        fprintf(fid,'%s,',col_names{col});
    end
    
    % Go to next row and close file
    fprintf(fid, '\r\n');
    fclose(fid);
    
    % Get condition specfic correlation matrix
    corr_matrix_cond = squeeze(corr_matrix(cond, :, :));
    
    % Print subject name and subject specific correlation values
    fid = fopen(fname, 'a');
    for subj = 1:length(list_subjs)
        fprintf(fid, '%s,', list_subjs{subj});
        dlmwrite(fname, corr_matrix_cond(subj,:),'-append', 'delimiter', ',')
    end
    
    % Close the file
    fclose(fid);
    
    % Save the condition specific mat file
    if select_rois
        fname = fullfile(out_dir, ['task-', task_name, '_', conditions{cond}, ...
            '-', cond_names{cond}, '_connectivity_matrix_', ...
            datestr(now, 'ddmmmyyyy'), '.mat']);
    else
        fname = fullfile(out_dir, ['task-', task_name, '_', conditions{cond}, ...
            '-', cond_names{cond}, '_connectivity_matrix_selectROIs_', ...
            datestr(now, 'ddmmmyyyy'), '.mat']);
    end
    save(fname, 'list_subjs', 'names', 'names2', 'col_names', 'corr_matrix_cond');
end