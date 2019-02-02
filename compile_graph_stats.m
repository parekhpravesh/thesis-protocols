function compile_graph_stats(graph_stats_dir, atlas_name,   cond_name, ...
                             thresh_type,     graph_type,   classwise, ...
                             class0_id,       out_dir)
% Function to compile already computed graph statistics across subjects
%% Inputs:
% graph_stats_dir:  fullpath to directory having graph_stats results
% atlas_name:       name(s) of atlas(es) for which to compile results
% cond_name:        name(s) of condition(s) for which to compile results
% thresh_type:      threshold type; should be one of:
%                       * 'absolute'
%                       * 'proportional'
% graph_type:       indicate if graph is binary or weighted:
%                       * 'wei'
%                       * 'bin'
% classwise:        yes/no indicating if class variable should be added
% class0_id:        list of subjects belonging to class 0 OR a wildcard
%                   that can be used to identify class 0 subjects 
%                   (for example, 'HS' denotes that all subjects which 
%                   have HS in their names belong to class 0); only needed
%                   when classwise is yes
% out_dir:          fullpath to where the compiled results are written
% 
%% Output:
% csv and mat files are written in the output directory for each atlas, 
% each condition, each graph present in the graph_stats_dir (or as 
% specified by the user); files are named:
% graph_stats_all_<conn_type>_<atlas_name>_<cond_name>_<thresh_type>_<wei/bin>_<thresh_weight>
% 
%% Notes:
% Relies on output format of calc_graph_properties.m
% 
% atlas names are the folders inside graph_stats_dir
% 
% condition names are the folders inside each atlas folder
% 
% weights are folders present inside each condition name folder
% 
% Regional measures are averaged and written as a single mean value after
% omitting all NaN
% 
% At the moment, only selected common stats across graph_type are compiled
% 
% Assumes uniform conn_type for all subjects
% 
% Assumes that if class0_id is character type, then it is a wildcard
% search; otherwise the user has provided a cell type with rows being
% subject IDs
% 
%% Defaults:
% atlas_name:       'all'
% cond_name:        'all'
% thresh_type:      'proportional'
% graph_type:       'wei'
% classwise:        'no'
% out_dir:          one level above graph_stats_dir ('graph_stats_all')
% 
%% Author(s):
% Parekh, Pravesh
% February 02, 2019
% MBIAL

%% Check inputs and assign defaults
% Check graph_dir
if ~exist('graph_stats_dir', 'var') || isempty(graph_stats_dir)
    error('graph_dir should be provided');
else
    if ~exist(graph_stats_dir, 'dir')
        error(['Cannot find: ', graph_stats_dir]);
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

% Check classwise and class0_id
if ~exist('classwise', 'var') || isempty(classwise)
    classwise = false;
else
    if strcmpi(classwise, 'yes')
        classwise = true;
        
        % Check class0_id
        if ~exist('class0_id', 'var') || isempty(class0_id)
            error('Need to specify class0_id when classiwise = yes');
        else
            if ischar(class0_id)
                wildcard = 1;
            else
                wildcard = 0;
            end
        end
        
    else
        if strcmpi(classwise, 'no')
            classwise = false;
        else
            error(['Unknown value for classwise spcecified: ', classwise]);
        end
    end
end

% Check out_dir
if ~exist('out_dir', 'var') || isempty(out_dir)
        cd(graph_stats_dir);
        cd('..');
        out_dir = fullfile(pwd, 'graph_stats_all');
else
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
end

%% Get atlas names
cd(graph_stats_dir);
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
    cd(fullfile(graph_stats_dir, atlas_name{atlas}));
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
        cd(fullfile(graph_stats_dir, atlas_name{atlas}, cond_list{1,atlas}{cond}));
        tmp_list = dir;
        tmp_list = struct2cell(tmp_list);
        tmp_list(2:end,:) = [];
        tmp_list(ismember(tmp_list, {'.', '..'})) = [];
        tmp_list = tmp_list';
        weight_list{atlas}{:,cond} = tmp_list;
    end
end

%% Initialize header
if classwise
    header = {'subject_ID', 'conn_type', 'thresh_type', 'thresh_weight',        ...
            'num_nodes', 'num_edges', 'average_degree', 'density',              ...
            'average_cluscoeff', 'transitivity', 'global_efficiency',           ...
            'maximum_modularity', 'assortativity', 'charpathlen',               ...
            'average_eccentricity', 'radius', 'diameter',                       ...
            'average_betweenness_centrality',                                   ...
            'average_edge_betweenness_centrality',                              ...
            'average_eigenvector_centrality', 'average_pagerank_centrality'     ...
            'class'};
else
    header = {'subject_ID', 'conn_type', 'thresh_type', 'thresh_weight',        ...
            'num_nodes', 'num_edges', 'average_degree', 'density',              ...
            'average_cluscoeff', 'transitivity', 'global_efficiency',           ...
            'maximum_modularity', 'assortativity', 'charpathlen',               ...
            'average_eccentricity', 'radius', 'diameter',                       ...
            'average_betweenness_centrality',                                   ...
            'average_edge_betweenness_centrality',                              ...
            'average_eigenvector_centrality', 'average_pagerank_centrality'};
end
            
%% Compile stats
    for atlas = 1:num_atlases
        for cond = 1:length(cond_list{1,atlas})
            for weight = 1:length(weight_list{atlas}{cond})
                
                % Move to atlas specific, condition specific, weight specific
                % directory
                work_dir = fullfile(graph_stats_dir, atlas_name{atlas}, ...
                            cond_list{1,atlas}{cond},                   ...
                            weight_list{atlas}{cond}{weight});
                cd(work_dir);
            
                % Get all files
                tmp_list  = dir(['graph_stats_*_', thresh_type, '_', graph_type, '*.mat']);
                tmp_list  = struct2cell(tmp_list);
                tmp_list(2:end,:) = [];
                tmp_list          = tmp_list';
                num_files         = length(tmp_list);
                
                % Initialize
                all_stats = cell(num_files, length(header));
                
                for file = 1:num_files

                    % Load variables
                    load(fullfile(work_dir, tmp_list{file}), 'graph_stats', 'xyz', ...
                        'roi_names');
                    
                    % Get some details from file name
                    temp = strsplit(regexprep(tmp_list{file}, {'graph_stats_',          ...
                                    [atlas_name{atlas}, '_'],  [thresh_type, '_'], ...
                                    [graph_type, '_'], '.mat'}, ''), '_');

                    subj_name   = temp{1};
                    subj_conn   = temp{2};
                    subj_weight = temp{3};
                    
                    % Subject ID
                    all_stats{file, 1} = subj_name;
                    
                    % Connectivity type
                    all_stats{file, 2} = subj_conn;
                    
                    % Threshold type
                    all_stats{file, 3} = thresh_type;
                    
                    % Threshold weight
                    all_stats{file, 4} = subj_weight;
                    
                    % Number of nodes
                    all_stats{file, 5} = graph_stats.density.num_vertices;
                    
                    % Number of edges
                    all_stats{file, 6} = graph_stats.density.num_edges;
                    
                    % Average degree
                    all_stats{file, 7} = mean(graph_stats.degree, 'omitnan');
                    
                    % Density
                    all_stats{file, 8} = graph_stats.density.density;
                    
                    % Average clustering coefficient
                    all_stats{file, 9} = mean(graph_stats.clustering_coeff, 'omitnan');
                    
                    % Transitivity
                    all_stats{file,10} = graph_stats.transitivity;
                    
                    % Global efficiency
                    all_stats{file,11} = graph_stats.efficiency.global;
                    
                    % Maximum modularity
                    all_stats{file,12} = graph_stats.modularity.max_modularity;
                    
                    % Assortativity
                    all_stats{file,13} = graph_stats.assortativity;
                    
                    % Charactersitic path length
                    all_stats{file,14} = graph_stats.charpath.charpathlen;
                    
                    % Average eccentricity
                    all_stats{file,15} = mean(graph_stats.charpath.eccentricity, 'omitnan');
                    
                    % Radius
                    all_stats{file,16} = graph_stats.charpath.radius;
                    
                    % Diameter
                    all_stats{file,17} = graph_stats.charpath.diameter;
                    
                    % Average betweenness centrality
                    all_stats{file,18} = mean(graph_stats.betweenness_centrality.value, 'omitnan');
                    
                    % Average edge-betweenness centrality
                    all_stats{file,19} = mean(graph_stats.edge_betweenness_centrality.vector, 'omitnan');
                    
                    % Average eigenvector centrality
                    all_stats{file,20} = mean(graph_stats.eigenvector_centrality, 'omitnan');
                    
                    % Average pagerank centrality
                    all_stats{file,21} = mean(graph_stats.pagerank_centrality.pagerank_centrality, 'omitnan');
                end
                
                % Assign class, if needed
                if classwise
                    if wildcard
                        classes = zeros(num_files,1);
                        classes(cellfun(@isempty, regexpi(all_stats(:,1), class0_id))) = 1;
                    else
                        classes = ones(num_files,1);
                        [~,loc] = intersect(all_stats(:,1), class0_id);
                        classes(loc) = 0;
                    end
                    all_stats(:,22) = num2cell(classes);
                end
                
                % Output directory
                save_dir = fullfile(out_dir, atlas_name{atlas}, ...
                                    cond_list{1,atlas}{cond});
                if ~exist(save_dir, 'dir')
                    mkdir(save_dir);
                end                

                % Output name
                out_name = ['graph_stats_all_', subj_conn, '_',               ...
                            atlas_name{atlas}, '_', cond_list{1,atlas}{cond}, ...
                            '_', thresh_type, '_', graph_type, '_', subj_weight];
                        
                % Save as mat file
                save(fullfile(save_dir, [out_name, '.mat']), 'all_stats', ...
                             'header', 'roi_names', 'xyz');
                       
                % Save as csv file
                temp = cell2table(all_stats, 'VariableNames', header);
                writetable(temp, fullfile(save_dir, [out_name, '.csv']));
            end
        end
    end
end