function calc_graph_properties(graph_dir,   atlas_name, cond_name, ...
                               thresh_type, graph_type, norm_wei, out_dir)
% Function to calculate various graph theory properties for a set of graphs
%% Inputs:
% graph_dir:    fullpath to directory having graphs
% atlas_name:   name(s) of atlases to calculate properties for (or 'all')
% cond_name:    name(s) of condition to calculate properties for (or 'all')
% thresh_type:  threshold type; should be one of:
%                   * 'absolute'
%                   * 'proportional'
% graph_type:   indicate if graph is binary or weighted:
%               	* 'wei'
%                   * 'bin'
% norm_wei:     yes/no indicating if weighted graph needs to be normalized
%               to have values between 0-1 (necessary for some computation)
% out_dir:      output directory where results will be saved
% 
%% Output:
% Graphs properties are saved in the output directory as follows:
% <out_dir>/
%   <atlas_name>/
%       <cond_name>/
%           graph_stats_<conn_type>_<thresh_type>_<wei/bin>_<thresh_weight>/
%               graph_stats_<subj_ID>_<conn_type>_<atlas_name>_<thresh_type>_<wei/bin>_<thresh_weight>.mat
% 
% Graph properties are saved as structure variable 'graph_stats' while 
% 'roi_names', and 'xyz' are retained from adjacency matrix file. 
% A variable named 'notes' is also saved containing details of processing 
% (variable 'notes' from previous operations is preserved)
% 
%% Notes:
% Relies on output format from get_ts_conn.m, calc_connectivity_ts.m and
% threshold_graphs.m
% 
% Requires the Brain Connectivity Toolbox (BCT)
% 
% atlas names are the folders inside graph_dir
% 
% condition names are the folders inside each atlas folder
% 
% Assumes that weight_conversion function of BCT using autofix has already
% been called on the adjacency matrix
% 
% Processes all subjects
%
% Assumes all graphs are undirected
%
%% Defaults:
% atlas_name:   'all'
% cond_name:    'all'
% thresh_type:  'proportional'
% graph_type:   'wei'
% norm_wei:     'yes'
% output_dir:   one level above graph_dir
% 
%% Author(s):
% Parekh, Pravesh
% February 01, 2019
% MBIAL

%% Check inputs and assign defaults
% Check graph_dir
if ~exist('graph_dir', 'var') || isempty(graph_dir)
    error('graph_dir should be provided');
else
    if ~exist(graph_dir, 'dir')
        error(['Cannot find: ', graph_dir]);
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

% Check thresh_type
if ~exist('thresh_type', 'var') || isempty(thresh_type)
    thresh_type = 'proportional';
else
    if ~ismember(thresh_type, {'absolute', 'proportional'})
        error(['Unknown thresh_type specified: ', thresh_type]);
    end
end

% Check graph_type
if ~exist('graph_type', 'var') || isempty(graph_type)
    graph_type = 'wei';
else
    if ~ismember(graph_type, {'wei', 'bin'})
        error(['Unknown graph_type specified: ', graph_type]);
    end
end

% Check norm_wei
if ~exist('norm_wei', 'dir') || isempty(norm_wei)
    norm_wei = 'yes';
else
    norm_wei = lower(norm_wei);
    if ~ismember(norm_wei, {'yes', 'no'})
        error(['Unknwon norm_wei value specified: ', norm_wei]);
    end
end

% Check out_dir
if ~exist('out_dir', 'var') || isempty(out_dir)
        cd(graph_dir);
        cd('..');
        out_dir = fullfile(pwd, 'graph_stats');
else
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
end

%% Check atlas names
cd(graph_dir);
list_atlases = dir;
list_atlases = struct2cell(list_atlases);
list_atlases(2:end,:) = [];
list_atlases(ismember(list_atlases, {'.', '..'})) = [];
list_atlases = list_atlases';

% Check if specified atlases exist
if strcmpi(atlas_name, 'all')
    atlas_name = list_atlases;
else
    if sum(ismember(atlas_name, list_atlases)) ~= size(atlas_name,1)
        error('Could not find one or more of specified atlases');
    end
end

% Convert to cell
if ischar(atlas_name)
    atlas_name = {atlas_name};
end

num_atlases = size(atlas_name, 1);

%% Get all conditions for each atlas
cond_list = cell(1,num_atlases);
for atlas = 1:num_atlases
    cd(fullfile(graph_dir, atlas_name{atlas}));
    tmp_list = dir;
    tmp_list = struct2cell(tmp_list);
    tmp_list(2:end,:) = [];
    tmp_list(ismember(tmp_list, {'.', '..'})) = [];
    cond_list{:,atlas} = tmp_list';
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

%% Get all thresholds per condition
weight_list = cell(1,num_atlases);

for atlas = 1:num_atlases
    for cond = 1:length(cond_list{1,atlas})
        cd(fullfile(graph_dir, atlas_name{atlas}, cond_list{1,atlas}{cond}));
        tmp_list = dir([thresh_type, '_', graph_type, '*']);
        tmp_list = struct2cell(tmp_list);
        tmp_list(2:end,:) = [];
        tmp_list = tmp_list';
        weight_list{atlas}{:,cond} = tmp_list;
    end
end

%% Calculate graph properties
for atlas = 1:num_atlases
    for cond = 1:length(cond_list{1,atlas})
        for weight = 1:length(weight_list{atlas}{cond})
            
            % Move to atlas specific, condition specific, weight specific
            % directory
            work_dir = fullfile(graph_dir, atlas_name{atlas}, ...
                        cond_list{1,atlas}{cond},             ...
                        weight_list{atlas}{cond}{weight});
            cd(work_dir);
            
            % Get all files
            tmp_list  = dir(['graphs_*_', thresh_type, '_', graph_type, '*.mat']);
            tmp_list  = struct2cell(tmp_list);
            tmp_list(2:end,:) = [];
            tmp_list          = tmp_list';
            num_files         = length(tmp_list);
            
            for file = 1:num_files
                % Load variables
                load(fullfile(work_dir, tmp_list{file}), 'adj', 'xyz', ...
                    'roi_names', 'notes');
                         
                % Get some details from file name
                temp = strsplit(regexprep(tmp_list{file}, {'graphs_',          ...
                                [atlas_name{atlas}, '_'],  [thresh_type, '_'], ...
                                [graph_type, '_'], '.mat'}, ''), '_');
                            
                subj_name   = temp{1};
                subj_conn   = temp{2};
                subj_weight = temp{3};
                
                % Compute values
                if strcmpi(graph_type, 'bin')
                    graph_stats = graph_stats_bin(adj, xyz);
                else
                    graph_stats = graph_stats_wei(adj, norm_wei);
                    notes.normalize_for_stats = norm_wei;
                end
                
                % Save directory
                save_dir  = fullfile(out_dir, atlas_name{atlas},        ...
                                     cond_list{1,atlas}{cond},          ...
                                     ['graph_stats_', subj_conn, '_',   ...
                                     thresh_type, '_', graph_type, '_', ...
                                     num2str(subj_weight, '%0.2f')]);
                if ~exist(save_dir, 'dir')
                    mkdir(save_dir);
                end
                
                % Save name
                save_name = ['graph_stats_', subj_name, '_', subj_conn, '_', ...
                             atlas_name{atlas}, '_', thresh_type, '_',       ...
                             graph_type, '_', subj_weight, '.mat'];
                         
                % Save variable
                save(fullfile(save_dir, save_name), 'graph_stats', 'xyz', ...
                                                    'roi_names', 'notes')
            end
        end
    end
end