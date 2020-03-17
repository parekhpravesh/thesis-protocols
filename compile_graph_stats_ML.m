function compile_graph_stats_ML(graph_dir, stats_dir, conn_type, list_subjs, out_dir)
% Function to compile graph theory based statistics for machine learning
%% Inputs:
% graph_dir:    full path to a directory containing threshold folders which
%               in turn contain adjacency matrices (the graph directory)
% stats_dir:    full path to a directory containing graph_stats_* folders
% conn_type:    which type of connectivity stats to use; should be one of:
%                   * 'corr'
%                   * 'fisher'
%                   * 'partcorr'
% list_subjs:   cell type containing list of subjects to compile
%               information for; otherwise 'all'
% out_dir:      full path to where results should be written
%
%% Output:
% An Excel workbook containing multiple sheets are written in out_dir
%
%% Notes:
% Assumes that the same graph theory threshold exists in adj_dir and
% stats_dir
% 
%% Default(s):
% conn_type:    'fisher'
% 
%% Author(s):
% Parekh, Pravesh
% February 01, 2020
% MBIAL

%% Check inputs
% Check adjacency directory
if ~exist('graph_dir', 'var') || isempty(graph_dir) || ~exist(graph_dir, 'dir')
    error('Please provide path to graph directory');
end

% Check stats directory
if ~exist('stats_dir', 'var') || isempty(stats_dir) || ~exist(stats_dir, 'dir')
    error('Please provide path to stats directory containing graph_stats_* folders');
end

% Check conn_type
if ~exist('conn_type', 'var') || isempty(conn_type)
    conn_type = 'fisher';
else
    if ~ismember(conn_type, {'corr'; 'fisher'; 'partcorr'})
        error(['Unknown connectivity type specified: ', conn_type]);
    end
end

% Check list_subjs
if ~exist('list_subjs', 'var') || isempty(list_subjs)
    to_build = true;
else
    if ~iscell(list_subjs)
        if ischar(list_subjs)
            if ~strcmpi(list_subjs, 'all')
                error(['Unknown value of list_subjs specified:', list_subjs]);
            else
                to_build = true;
            end
        else
            error('List of subjects should be a cell type variable');
        end
    else
        to_build = false;
    end
end

% Check output directory
if ~exist('out_dir', 'var') || isempty(out_dir)
    error('Please provide output directory');
else
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
end

%% List of thresholds
cd(stats_dir);
to_search = ['graph_stats_*', conn_type, '*'];
list_thresh = dir(to_search);
if isempty(list_thresh)
    error(['No ', to_search, ' folders found']);
else
    num_thresh = length(list_thresh);
end

%% Loop over each threshold
for thresh = 1:num_thresh
    
    % Make list of subjects available for this threshold
    cd(fullfile(stats_dir, list_thresh(thresh).name));
    subj_list = dir('*.mat');
    subj_list = struct2cell(subj_list);
    subj_list(2:end,:) = [];
    subj_list = subj_list';
    
    % Make sure all subjects are present if list of subjects is provided
    if ~to_build
        subj_list = cell(length(list_subjs),1);
        cd(fullfile(stats_dir, list_thresh(thresh).name));
        for subjs = 1:length(list_subjs)
            tmp = dir(['*', list_subjs{subjs}, '*.mat']);
            if isempty(tmp) || length(tmp)>1
                error(['Trouble finding ', list_subjs{subjs}, ' in ', list_thresh(thresh).name]);
            else
                subj_list{subjs} = tmp(1).name;
            end
        end
    end
    num_subjs = length(subj_list);

    % Load one subject to get information
    load(subj_list{1}, 'roi_names', 'notes');
    num_rois      = length(roi_names);
    atlas_name    = notes.atlas;
    cond_name     = notes.cond_name;
    thresh_type   = notes.thresh_type;
    thresh_weight = notes.thresh_weight;
    
    if notes.binarize
        ct = 'bin';
    else
        ct = 'wei';
    end
    
    % Header information
    local_header  = ['SubjectID', 'Class', strrep(roi_names, [atlas_name, '.'], '')];
    global_header = {'SubjectID', 'Class', 'AvgDegree', 'AvgClusCoeff', 'Transitivity', ...
                     'GlobEfficiency', 'AvgCommStr', 'MaxModularity', 'Assortativity',  ...
                     'Charpathlen', 'EfficiencyExcInf', 'AvgEccentricity',              ...
                     'Radius', 'Diameter', 'AvgBetweenCentr', 'AvgModZScore',           ...
                     'AvgPartCoeff', 'AvgEigenCent', 'AvgSubgraphCent',                 ...
                     'AvgCoreness', 'AvgVulnerability'};

    % Initialize
    all_degrees  = cell(num_subjs, num_rois+2);
    all_cluscoef = cell(num_subjs, num_rois+2);
    all_effloc   = cell(num_subjs, num_rois+2);
    all_commstr  = cell(num_subjs, num_rois+2);
    all_ecctcity = cell(num_subjs, num_rois+2);
    all_betcentr = cell(num_subjs, num_rois+2);
    all_moddegZ  = cell(num_subjs, num_rois+2);
    all_partcoef = cell(num_subjs, num_rois+2);
    all_eigcent  = cell(num_subjs, num_rois+2);
    all_subcent  = cell(num_subjs, num_rois+2);
    all_coreness = cell(num_subjs, num_rois+2);
    all_sizecore = cell(num_subjs, num_rois+2);
    all_vulnerb  = cell(num_subjs, num_rois+2);
    avg_metrics  = table('Size', [num_subjs, length(global_header)],    ...
                         'VariableTypes', [{'cell'}; repmat({'double'}, ...
                         length(global_header)-1, 1)], 'VariableNames', global_header);

    % Loop over each subject
    for subjs = 1:num_subjs
        
        % Get subject name
        tmp = strsplit(subj_list{subjs}, '_');
        
        % Load connectivity matrix for this subject and calculate
        % vulneribility for all the nodes
        load(fullfile(graph_dir, [thresh_type, '_', ct, '_', num2str(thresh_weight, '%.2f')],     ...
                               ['graphs_', tmp{3}, '_', conn_type, '_', atlas_name, '_',        ...
                               thresh_type, '_', ct, '_', num2str(thresh_weight, '%.2f'), '.mat']), 'adj');
        vindex = vulnerability_analysis(adj, logical(notes.binarize));
        
        % Load graph theory stats
        load(fullfile(stats_dir, list_thresh(thresh).name, subj_list{subjs}), 'graph_stats');
        
        % Assign subject ID everywhere
        [all_degrees{subjs,1},  all_cluscoef{subjs,1}, all_effloc{subjs,1},   ...
         all_commstr{subjs,1},  all_ecctcity{subjs,1}, all_betcentr{subjs,1}, ...
         all_moddegZ{subjs,1},  all_partcoef{subjs,1}, all_eigcent{subjs,1},  ...
         all_subcent{subjs,1},  all_coreness{subjs,1}, all_sizecore{subjs,1}, ...
         all_vulnerb{subjs,1},  avg_metrics.SubjectID{subjs}] = deal(tmp{3});
     
        % Assign class ID everywhere
        if strcmpi(tmp{3}(5:6), 'HS')
            classID = 0;
        else
            classID = 1;
        end
        [all_degrees{subjs,2},  all_cluscoef{subjs,2}, all_effloc{subjs,2},   ...
         all_commstr{subjs,2},  all_ecctcity{subjs,2}, all_betcentr{subjs,2}, ...
         all_moddegZ{subjs,2},  all_partcoef{subjs,2}, all_eigcent{subjs,2},  ...
         all_subcent{subjs,2},  all_coreness{subjs,2}, all_sizecore{subjs,2}, ...
         all_vulnerb{subjs,2},  avg_metrics.Class(subjs)] = deal(classID);
     
        % Replace NaN in eccentricity with zeros
        ecc = graph_stats.charpath.eccentricity;
        ecc(isnan(ecc)) = 0;
                
        % Node level metrics
        all_degrees(subjs,  3:end) = num2cell(graph_stats.degree);
        all_cluscoef(subjs, 3:end) = num2cell(graph_stats.clustering_coeff);
        all_effloc(subjs,   3:end) = num2cell(graph_stats.efficiency_local);
        all_commstr(subjs,  3:end) = num2cell(graph_stats.modularity.community_str);
        all_ecctcity(subjs, 3:end) = num2cell(ecc);
        all_betcentr(subjs, 3:end) = num2cell(graph_stats.betweenness_centrality);
        all_moddegZ(subjs,  3:end) = num2cell(graph_stats.module_degree_z_score);
        all_partcoef(subjs, 3:end) = num2cell(graph_stats.participation_coefficient);
        all_eigcent(subjs,  3:end) = num2cell(graph_stats.eigenvector_centrality);
        all_subcent(subjs,  3:end) = num2cell(graph_stats.subgraph_centrality);
        all_coreness(subjs, 3:end) = num2cell(graph_stats.kcoreness_centrality.coreness);
        all_sizecore(subjs, 3:end) = num2cell(graph_stats.kcoreness_centrality.size_k_core);
        all_vulnerb(subjs,  3:end) = num2cell(vindex);
        
        % Average metrics over all nodes
        avg_metrics.AvgDegree(subjs)        = mean(graph_stats.degree);
        avg_metrics.AvgClusCoeff(subjs)     = mean(graph_stats.clustering_coeff);
        avg_metrics.Transitivity(subjs)     = graph_stats.transitivity;
        avg_metrics.GlobEfficiency(subjs)   = graph_stats.efficiency_global;
        avg_metrics.AvgCommStr(subjs)       = mean(graph_stats.modularity.community_str);
        avg_metrics.MaxModularity(subjs) 	= graph_stats.modularity.max_modularity;
        avg_metrics.Assortativity(subjs)    = graph_stats.assortativity;
        avg_metrics.Charpathlen(subjs)      = graph_stats.charpath.charpathlen;
        avg_metrics.EfficiencyExcInf(subjs) = graph_stats.charpath.efficiency;
        avg_metrics.AvgEccentricity(subjs)  = mean(ecc);
        avg_metrics.Radius(subjs)           = graph_stats.charpath.radius;
        avg_metrics.Diameter(subjs)         = graph_stats.charpath.diameter;
        avg_metrics.AvgBetweenCentr(subjs)  = mean(graph_stats.betweenness_centrality);
        avg_metrics.AvgModZScore(subjs)     = mean(graph_stats.module_degree_z_score);
        avg_metrics.AvgPartCoeff(subjs)     = mean(graph_stats.participation_coefficient);
        avg_metrics.AvgEigenCent(subjs)     = mean(graph_stats.eigenvector_centrality);
        avg_metrics.AvgSubgraphCent(subjs)  = mean(graph_stats.subgraph_centrality);
        avg_metrics.AvgCoreness(subjs)      = mean(graph_stats.kcoreness_centrality.coreness);
        avg_metrics.AvgVulnerability(subjs) = mean(vindex);
    end
    
    % Convert to tables
    all_degrees     = cell2table(all_degrees,   'VariableNames', local_header);
    all_cluscoef    = cell2table(all_cluscoef,  'VariableNames', local_header);
    all_effloc      = cell2table(all_effloc,    'VariableNames', local_header);
    all_commstr     = cell2table(all_commstr,   'VariableNames', local_header);
    all_ecctcity    = cell2table(all_ecctcity,  'VariableNames', local_header);
    all_betcentr    = cell2table(all_betcentr,  'VariableNames', local_header);
    all_moddegZ     = cell2table(all_moddegZ,   'VariableNames', local_header);
    all_partcoef    = cell2table(all_partcoef,  'VariableNames', local_header);
    all_eigcent     = cell2table(all_eigcent,   'VariableNames', local_header);
    all_subcent     = cell2table(all_subcent,   'VariableNames', local_header);
    all_coreness    = cell2table(all_coreness,  'VariableNames', local_header);
    all_sizecore    = cell2table(all_sizecore,  'VariableNames', local_header);
    all_vulnerb     = cell2table(all_vulnerb,   'VariableNames', local_header);
    
    % Write out results for this threshold
    out_name = fullfile(out_dir, ['Features_', cond_name, '_', atlas_name, '_', conn_type, '_', thresh_type, '_', ct, '_', num2str(thresh_weight, '%.2f'), '.xlsx']);
    writetable(avg_metrics,     out_name, 'Sheet', 'NetworkMeasures');
    writetable(all_degrees,     out_name, 'Sheet', 'Degrees');
    writetable(all_cluscoef,    out_name, 'Sheet', 'ClusteringCoeff');
    writetable(all_effloc,      out_name, 'Sheet', 'LocalEfficiency');
    writetable(all_commstr,     out_name, 'Sheet', 'CommunityStructure');
    writetable(all_ecctcity,    out_name, 'Sheet', 'Eccentricity');
    writetable(all_betcentr,    out_name, 'Sheet', 'BetweennessCent');
    writetable(all_moddegZ,     out_name, 'Sheet', 'BetModZScore');
    writetable(all_partcoef,    out_name, 'Sheet', 'ParticipationCoeff');
    writetable(all_eigcent,     out_name, 'Sheet', 'EigenvecCent');
    writetable(all_subcent,     out_name, 'Sheet', 'SubgraphCent');
    writetable(all_coreness ,   out_name, 'Sheet', 'KCoreness');
    writetable(all_sizecore,    out_name, 'Sheet', 'KCorenessSize');
    writetable(all_vulnerb,     out_name, 'Sheet', 'Vulnerability');
end