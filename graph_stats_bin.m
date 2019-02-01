function graph_stats = graph_stats_bin(adj, xyz)
% Computes different graph properties for binary undirected graphs
%% Inputs:
% adj:      binarized adjacency matrix
% xyz:      x,y,z coordinates for each node (used for Rentian scaling) as
%           nx3 matrix (where n is the number of nodes)
% 
%% Output:
% A structure containing different graph theory properties
% 
%% Note:
% Requires the Brain Connectivity Toolbox (BCT)
% 
%% Author(s):
% Parekh, Pravesh
% February 01, 2019
% MBIAL

%% Check inputs
if ~exist('adj', 'var') || isempty(adj)
    error('Adjacency matrix needs to be provided');
end

if ~exist('xyz', 'var') || isempty(xyz)
    error('xyz coordinates need to be provided');
end

%% Degree
graph_stats.degree = degrees_und(adj);

%% Matching index
graph_stats.matching_idx = matching_ind_und(adj);

%% Density
[graph_stats.density.density, graph_stats.density.num_vertices, ...
                              graph_stats.density.num_edges] = density_und(adj);
                          
%% Rentian scaling (3D)
[graph_stats.rentian3.nodes, graph_stats.rentian3.edges] = ...
                             rentian_scaling_3d(adj, xyz, 5000, 1e-6);
[graph_stats.rentian3.beta,  graph_stats.rentian3.stats] = ...
                             robustfit(log10(graph_stats.rentian3.nodes), ...
                                       log10(graph_stats.rentian3.edges));
graph_stats.rentian3.rentexponent    = graph_stats.rentian3.beta(2,1);
graph_stats.rentian3.rentexponent_SE = graph_stats.rentian3.stats.se(2,1);
graph_stats.rentian3.settings.n      = 5000;
graph_stats.rentian3.settings.tol    = 1e-6;

%% Clustering coefficient
graph_stats.clustering_coeff = clustering_coef_bu(adj);

%% Transitivity
graph_stats.transitivity = transitivity_bu(adj);

%% Efficiency
graph_stats.efficiency_local  = efficiency_bin(adj, 1);
graph_stats.efficiency_global = efficiency_bin(adj, 0);

%% Components
[graph_stats.components.components, graph_stats.components.component_size] = ...
                                    get_components(adj);

%% Modularity
[graph_stats.modularity.community_str, graph_stats.modularity.max_modularity] = ...
                                       modularity_und(adj,1);
graph_stats.modularity.settings.function = 'modularity_und';
graph_stats.modularity.settings.gamma    = 1;

%% Assortativity
graph_stats.assortativity = assortativity_bin(adj, 0);

%% Rich club detection
[graph_stats.rich_club.coefficient, graph_stats.rich_club.num_nodes,   ...
                                    graph_stats.rich_club.num_edges] = ...
                                    rich_club_bu(adj);
                                 
%% k-core
% Run till max degree; stop when returned kcore_size hits zero
uq_degrees = unique(graph_stats.degree);
for deg = 1:length(uq_degrees)
    [graph_stats.kcore(deg).kcore, graph_stats.kcore(deg).kcore_size,  ...
                                   graph_stats.kcore(deg).peelorder,   ...
                                   graph_stats.kcore(deg).peellevel] = ...
                                   kcore_bu(adj,uq_degrees(deg));
    graph_stats.kcore(deg).settings_k = uq_degrees(deg);
    if graph_stats.kcore(deg).kcore_size == 0
        break;
    end
end

%% Distance matrix
graph_stats.distance.matrix = distance_bin(adj);
graph_stats.distance.settings.algorithm = 'Dijkstra';

%% Charactersistic path length
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
                                        rout_efficiency(adj);
graph_stats.routing.settings.input      = 'adj';
graph_stats.routing.settings.transform  = 'none';

%% Betweenness centrality
graph_stats.betweenness_centrality = betweenness_bin(adj);

%% Edge betweenness centrality
[graph_stats.edge_betweenness_centrality.matrix, ...
 graph_stats.edge_betweenness_centrality.vector] = edge_betweenness_bin(adj);

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

%% Subgraph centrality
graph_stats.subgraph_centrality = subgraph_centrality(adj);

%% kcoreness centrality
[graph_stats.kcoreness_centrality.coreness, ...
 graph_stats.kcoreness_centrality.size_k_core] = kcoreness_centrality_bu(adj);