function calc_connectivity_ts(ts_dir,  atlas_name, cond_name, ...
                              subj_id, conn_type,  output_dir)
% Function to calculate connectivity between regions of interest using
% already extracted HRF weighted time series for specified condition(s)
%% Inputs:
% ts_dir:       fullpath to where time series are saved (see get_ts_conn.m)
% atlas_name:   name(s) of the atlas file or one of: (see Notes)
%                   * 'all'
%                   * 'merge'
% cond_name:    name(s) of the condition to calculate connectivity for
% subj_id:      cell type with rows being subject ID(s) (or 'all')
% conn_type:    connectivity type; should be one of:
%                   * 'corr'     (correlation coefficient)
%                   * 'fisher'   (Fisher transformed r values)
%                   * 'partcorr' (partial correlation coefficient)
% 
%% Output:
% A sub-folder for each atlas is made under 'connectivity_<conn_type>' in
% output_dir where connectivity between time series is calculated and 
% written out as a .mat file.
% 
% Files are named as <conn_type>_<atlas_name>_<cond_name>_<subjID>.mat and
% contain the connectivity matrix, the names of the ROIs, and the xyz 
% coordinates of the centroid of each of the ROIs
%
%% Notes:
% Condition specific time series should already have been extracted;
% relies on the output format from get_ts_conn.m file
% 
% Uses weighted_ts variable for connectivity calculation
% 
% atlas_name can be given as 'merge' in which case ROIs across all atlases
% are pooled together and a single large connectivity matrix is created
% 
% Multiple atlas_name can be passed at once as a cell type with rows
% corresponding to atlas names
% 
% Assumes that condition names do not contain underscores!
%
%% Defaults:
% atlas_name:   'all'
% cond_name:    'all'
% subj_id:      'all'
% conn_type;    'fisher'
% output_dir:   one level above ts_dir (i.e. the folder in which ts_dir is)
% 
%% Author(s):
% Parekh, Pravesh
% January 19, 2019
% MBIAL

%% Parse input
% Check ts_dir
if ~exist('ts_dir', 'var') || isempty(ts_dir)
    error('ts_dir needs to be specified');
else
    if ~exist(ts_dir, 'dir')
        error(['Cannot find: ', ts_dir]);
    end
end

% Check atlas_name
if ~exist('atlas_name', 'var') || isempty(atlas_name)
    atlas_name = 'all';
end

% Check cond_name
if ~exist('cond_name', 'var') || isempty(cond_name)
    cond_name = 'all';
else
    if ischar(cond_name)
        cond_name = {cond_name};
    end
end

% Check subj_id
if ~exist('subj_id', 'var') || isempty(subj_id)
    subj_id = 'all';
else
    if ischar(subj_id)
        subj_id = {subj_id};
    end
end

% Check conn_type
if ~exist('conn_type', 'var') || isempty(conn_type)
    conn_type = 'fisher';
else
    if ~ismember(conn_type, {'corr', 'fisher', 'partcorr'})
        error(['Unknown conn_type given: ', conn_type]);
    end
end

% Check output_dir
if ~exist('output_dir', 'var') || isempty(output_dir)
    cd(ts_dir);
    cd('..');
    output_dir = pwd;
end

%% Get atlases
% Get list of atlases
cd(ts_dir);
list_atlases = dir;
list_atlases = struct2cell(list_atlases);
list_atlases(2:end,:) = [];
list_atlases(ismember(list_atlases, {'.', '..'})) = [];
list_atlases = list_atlases';

% Check if specified atlases exist
if strcmpi(atlas_name, 'all')
    atlas_name = list_atlases;
    merge = 0;
else
    if strcmpi(atlas_name, 'merge')
        atlas_name = list_atlases;
        merge = 1;
    else
        if sum(ismember(atlas_name, list_atlases)) ~= size(atlas_name,1)
            error('Time series for one or more atlases does not exist');
        else
            merge = 0;
        end
    end
end

% Convert to cell
if ischar(atlas_name)
    atlas_name = {atlas_name};
end
num_atlases = size(atlas_name, 1);

%% Get all files for each atlas
cd(ts_dir);
file_list  = cell(1,num_atlases);
parse_list = cell(1,num_atlases);

for atlas = 1:num_atlases
    cd(fullfile(ts_dir, atlas_name{atlas}));
    tmp_list  = dir('*.mat');
    tmp_list  = struct2cell(tmp_list);
    tmp_list(2:end,:)   = [];
    file_list{:,atlas}  = tmp_list';
    parse_list{:,atlas} = cellfun(@(x) strsplit(x, '_'),                  ...
                          regexprep(file_list{:,atlas},                   ...
                          {'TS_', [atlas_name{atlas}, '_'], '.mat'}, ''), ...
                          'UniformOutput', false);
end

%% Compile condition list and subject list
cond_list     = cell(1,num_atlases);
subj_list     = cell(1,num_atlases);
tmp_cond_list = cell(1,num_atlases);
tmp_subj_list = cell(1,num_atlases);

for atlas = 1:num_atlases
    for files = 1:length(parse_list{1,atlas})
        tmp_cond_list{files,atlas} = parse_list{1,atlas}{files,1}{1};
        tmp_subj_list{files,atlas} = parse_list{1,atlas}{files,1}{2};
    end
    cond_list{:,atlas} = unique(tmp_cond_list(:,atlas));
    subj_list{:,atlas} = unique(tmp_subj_list(:,atlas));
end

% Check if cond_name exist in cond_list
for atlas = 1:num_atlases
    if ~strcmpi(cond_name, 'all')
        if sum(ismember(cond_list{:,atlas}, cond_name)) ~= length(cond_name)
            error('Cannot find one or more conditions');
        else
            cond_list{:,atlas} = cond_name;
        end
    end
end

% Check if subj_id exist in subj_list
for atlas = 1:num_atlases
    if ~strcmpi(subj_id, 'all')
        if ~ismember(subj_list{:,atlas}, subj_id)
            error('Cannot find one or more subjects');
        else
            subj_list{:,atlas} = subj_id;
        end
    end
end

%% Prepare output directory
if ~exist(fullfile(output_dir, ['connectivity_', conn_type]), 'dir')
    mkdir(fullfile(output_dir, ['connectivity_', conn_type]));
end

if ~merge
    for atlas = 1:num_atlases
        if ~exist(fullfile(output_dir, ['connectivity_', conn_type], ...
                           atlas_name{atlas}), 'dir')
            mkdir(fullfile(output_dir, ['connectivity_', conn_type], ...
                           atlas_name{atlas}));
        end
    end
else
    if ~exist(fullfile(output_dir, ['connectivity_', conn_type], ...
                       'merged_atlases'), 'dir')
       mkdir(fullfile(output_dir, ['connectivity_', conn_type], ...
                       'merged_atlases'));
    end
end

%% Calculate connectivity
% Handle special case of merging atlases
if merge
    % Get all subjects which exist across atlases
    if size(subj_list,2) > 1
        subj_list_all = intersect(subj_list{:});
    else
        subj_list_all = subj_list;
    end
    
    % Get all conditions which exist across atlases
    if size(cond_list,2) > 1
        cond_list_all = intersect(cond_list{:});
    else
        cond_list_all = cond_list;
    end
    
    for sub = 1:length(subj_list_all)
            for cond = 1:length(cond_list_all)
                
                % Empty initialize
                ts_all        = [];
                roi_names_all = [];
                xyz_all       = [];
                
                for atlas = 1:num_atlases
                    % Load variable
                    load(fullfile(ts_dir, atlas_name{atlas},                 ...
                        ['TS_', atlas_name{atlas}, '_', cond_list_all{cond}, ...
                        '_', subj_list_all{sub}, '.mat']), 'weighted_ts',    ...
                        'xyz', 'roi_names');
                    
                    % Concatenate time series etc
                    ts_all        = [ts_all weighted_ts];
                    roi_names_all = [roi_names_all roi_names];
                    xyz_all       = [xyz_all xyz];
                end
                
                % Consistent naming while saving
                roi_names         = roi_names_all;
                xyz               = xyz_all;
                
                % Save some extra information
                notes.atlas     = atlas_name;
                notes.conn_tpye = conn_type;
                notes.ts_type   = 'HRF weighted TS';
                
                % Initialize
                conn_mat = zeros(length(roi_names));
                p_vals   = zeros(length(roi_names));
                
                % Calculate connectivity
                switch(conn_type)
                    case 'corr'
                        [conn_mat, p_vals] = corr(ts_all);
                    case 'fisher'
                        [conn_mat, p_vals] = corr(ts_all);
                        conn_mat           = atanh(conn_mat);
                    case 'partcorr'
                        [conn_mat, p_vals] = partialcorr(ts_all);
                end
                
                % Save variables
                save_name = fullfile(output_dir, ['connectivity_', conn_type], ...
                                    'merged_atlases', [conn_type,              ...
                                    '_merged_atlases_',                        ...
                                    cond_list_all{cond}, '_',                  ...
                                    subj_list_all{sub}, '.mat']);
               save(save_name, 'conn_mat', 'p_vals', 'roi_names', 'xyz', 'notes');
            end
    end
else
    % All other cases where atlases do not need to be merged
    for atlas = 1:num_atlases
        for sub = 1:length(subj_list{1,atlas})
            for cond = 1:length(cond_list{1,atlas})
                
                % Load variable
                load(fullfile(ts_dir, atlas_name{atlas},               ...
                    ['TS_', atlas_name{atlas}, '_',                    ...
                    cond_list{1,atlas}{cond},  '_',                    ...
                    subj_list{1,atlas}{sub}, '.mat']),                 ...
                    'weighted_ts', 'xyz', 'roi_names');
                
                % Initialize
                conn_mat = zeros(length(roi_names));
                p_vals   = zeros(length(roi_names));
                
                % Save some extra information
                notes.atlas     = atlas_name{atlas};
                notes.conn_tpye = conn_type;
                notes.ts_type   = 'HRF weighted TS';
                
                % Calculate connectivity
                switch(conn_type)
                    case 'corr'
                        [conn_mat, p_vals] = corr(weighted_ts);
                    case 'fisher'
                        [conn_mat, p_vals] = corr(weighted_ts);
                        conn_mat           = atanh(conn_mat);
                    case 'partcorr'
                        [conn_mat, p_vals] = partialcorr(weighted_ts);
                end
                
                % Save variable
                save_name = fullfile(output_dir, ['connectivity_', conn_type],    ...
                                     atlas_name{atlas}, [conn_type, '_',          ...
                                     atlas_name{atlas}, '_',                      ...
                                     cond_list{1,atlas}{cond}, '_',               ...
                                     subj_list{1,atlas}{sub}, '.mat']);
                save(save_name, 'conn_mat', 'p_vals', 'roi_names', 'xyz', 'notes');
            end
        end
    end
end