function graph_stats = graph_stats_wei(adj, normalize)
% Computes different graph properties for weighted undirected graphs
%% Inputs:
% adj:          binarized adjacency matrix
% normalize:    yes/no indicating if adj has to be normalized before 
%               computing measures like clustering coefficient or has 
%               already been normalized (such as when passing correlation 
%               coefficient based adjacency matrix) 
%% Output:
% A structure containing different graph theory properties
% 
%% Note:
% Requires the Brain Connectivity Toolbox (BCT)
% 
%% Default:
% normalize:    yes
% 
%% Author(s):
% Parekh, Pravesh
% February 01, 2019
% MBIAL

%% Check inputs
if ~exist('adj', 'var') || isempty(adj)
    error('Adjacency matrix needs to be provided');
end

if ~exist('normalize', 'var') || isempty(normalize)
    normalize = 1;
else
    if strcmpi(normalize, 'yes')
        normalize = 1;
    else
        if strcmpi(normalize, 'no')
            normalize = 0;
        else
            error(['Unknown value for normalize: ', normalize]);
        end
    end
end

%% Degree
graph_stats.degree = degrees_und(adj);

%% Strength
graph_stats.strength = strengths_und(adj);

%% Matching index
graph_stats.matching_idx = matching_ind_und(adj);

%% Density
[graph_stats.density.density, graph_stats.density.num_vertices, ...
                              graph_stats.density.num_edges] = density_und(adj);

%% Normalized adjacency matrix
if normalize
    graph_stats.normalized_adj = weight_conversion(adj, 'normalize');
else
    graph_stats.normalized_adj = adj;
end
graph_stats.normalization = normalize;

%% Clustering coefficient
graph_stats.clustering_coeff = clustering_coef_wu(graph_stats.normalized_adj);

%% Transitivity
graph_stats.transitivity = transitivity_wu(graph_stats.normalized_adj);

%% Efficiency
graph_stats.efficiency.global = efficiency_wei(adj,0);
graph_stats.efficiency.local  = efficiency_wei(adj,2);
graph_stats.efficiency.local_normalized = efficiency_wei(graph_stats.normalized_adj, 2);
graph_stats.efficiency.settings.local_variant = 2;
graph_stats.efficiency.settings.normalized = 'normalized weights';

%% Modularity
[graph_stats.modularity.community_str, graph_stats.modularity.max_modularity] = ...
                                       modularity_und(adj,1);
graph_stats.modularity.settings.function = 'modularity_und';
graph_stats.modularity.settings.gamma    = 1;

%% Assortativity
graph_stats.assortativity = assortativity_wei(adj,0);

%% Rich club detection
graph_stats.rich_club.coefficient = rich_club_wu(adj);

%% S-core
% Run from 0 to max strength; stop when returned score_size hits zero
strengths = 0:0.1:max(graph_stats.strength);
for str = 1:length(strengths)
    [graph_stats.score(str).score, graph_stats.score(str).score_size] = ...
                                   score_wu(adj, strengths(str));
    graph_stats.score(str).settings_s = strengths(str);
    if graph_stats.score(str).score_size == 0
        break;
    end
end

%% Length matrix
graph_stats.length_matrix = weight_conversion(adj, 'lengths');

%% Distance matrix
[graph_stats.distance.matrix, graph_stats.distance.num_edges] = ...
                              distance_wei(graph_stats.length_matrix);
graph_stats.distance.settings_input     = 'length matrix';
graph_stats.distance.settings.algorithm = 'Dijkstra';

%% Characteristic path length
[graph_stats.charpath.charpathlen, graph_stats.charpath.efficiency,   ...
                                   graph_stats.charpath.eccentricity, ...
                                   graph_stats.charpath.radius,       ...
                                   graph_stats.charpath.diameter] =   ...
                                   charpath(graph_stats.distance.matrix, 0, 0);
graph_stats.charpath.settings.diagonal_distance = 0;
graph_stats.charpath.settings.infinite_distance = 0;

%% Routing efficiency
[graph_stats.routing.global_efficiency, graph_stats.routing.routing_eff,       ...
                                        graph_stats.routing.local_efficieny] = ...
                                        rout_efficiency(graph_stats.length_matrix);
graph_stats.routing.settings.input      = 'length matrix';
graph_stats.routing.settings.transform  = 'none';

%% Betweenness centrality
graph_stats.betweenness_centrality.value = betweenness_wei(graph_stats.length_matrix);
graph_stats.betweenness_centrality.input = 'length matrix';

%% Edge betweenness centrality
[graph_stats.edge_betweenness_centrality.matrix, ...
 graph_stats.edge_betweenness_centrality.vector] = edge_betweenness_wei(adj);
graph_stats.edge_betweenness_centrality.input = 'length matrix';

%% Module degree Z score
graph_stats.module_degree_z_score = module_degree_zscore(adj, ...
                                    graph_stats.modularity.community_str, 0);
                                
%% Participation coefficient
graph_stats.participation_coefficient = participation_coef(adj, ...
                                        graph_stats.modularity.community_str, 0);
                                    
%% Eigenvector centrality
graph_stats.eigenvector_centrality = eigenvector_centrality_und(adj);

%% Pagerank centrality
graph_stats.pagerank_centrality.pagerank_centrality = pagerank_centrality(adj, 0.85);
graph_stats.pagerank_centrality.settings_dampingfac = 0.85;