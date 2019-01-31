function visulize_connectivity(conn_dir,   subj_id,   atlas_name,  ...
                               cond_name,  vis_type,  vis_mode,    ...
                               colour_map, output_dir)
% Function to visualize functional connectivity matrix
%% Inputs: 
% conn_dir:     fullpath to directory having connectivity matrices
% subj_id:      cell type with rows being subject ID(s) (or 'all')
% atlas_name:   name(s) of atlases to create visualization for (or 'all')
% cond_name:    name(s) of conditions to create visualization for (or 'all')
% vis_type:     decides ordering of ROIs; should be one of (see Notes):
%                   * 'hemisphere'
%                   * 'ranking'
%                   * 'modularity'
%                   * 'original'
%                   * 'all'
% vis_mode:     if multiple visualizations, mode can be one of (see Notes):
%                   * 'independent'
%                   * 'subplot'
% colour_map:   can be any MATLAB colour map or a custom colour map
% output_dir:   output directory where visualization will be saved
% 
%% Output:
% A folder named 'connectivity_visualization' is saved in output_dir; 
% visualizations are saved as images in atlas specific folders in the
% output_dir;
% 
%% Notes:
% For visualization type (vis_type):
% ----------------------------------
% hemisphere:   uses xyz variable to figure out ROIs belonging to left and 
%               right hemispheres (left is x<=0, right is x>0); orders all
%               left hemispheres first, followed by all right hemispheres
% ranking:      sums the weights in conn_mat for each node and then ranks
%               them in descending order; visulization is in this order
% modularity:   requires brain connectivty toolbox (BCT); calls
%               modularity_und with gamma=1 (classic modularity) and then
%               plots ROIs based on their community structure
% original:     preserves the ordering of ROIs in conn_type and plots them
% all:          saves visualization in all these ways
% 
% For visualization mode (vis_mode):
% ----------------------------------
% independent:  saves each visualization as separate file
% subplot:      all visualizations are plotted in the same image
% 
% Assumes connectivity variable structure the same as one derived from
% calc_connectivity_ts.m
% 
% Jet is not a great colour map but is kept as default because it is
% conventional to talk in terms of cooler and warmer colours
% 
% Does not explicitly check provided colour maps with built-in colour maps
% 
% Processes each subject condition by condition; same image with multiple
% conditions not yet supported!
% 
% Calls the weight_conversion function of BCT using autofix before
% displaying any matrix 
% 
% For ranking, in case of weighted graphs, negative weights may reduce
% overall node's rank
% 
% Figure paper size is set to A5 and images are saved as png at 300 dpi
%
%% Defaults:
% subj_id:      'all'
% atlas_name:   'all'
% cond_name:    'all'
% vis_type:     'all'
% vis_mode:     'subplot'
% colour_map:   'jet'
% output_dir:   one level above conn_dir
% 
%% References:
% https://en.wikipedia.org/wiki/Paper_size#A_series
% https://www.mathworks.com/matlabcentral/answers/159371-unnest-cell-array-with-nested-cells-to-a-cell-array
% https://in.mathworks.com/matlabcentral/answers/10543-how-to-remove-whitespace-around-subplot-figures
% 
%% Author(s):
% Parekh, Pravesh
% January 21, 2019
% MBIAL

%% Check inputs, assign defaults, and make some decisions
% Check conn_dir
if ~exist('conn_dir', 'var') || isempty(conn_dir)
    error('conn_dir should be provided');
else
    if ~exist(conn_dir, 'dir')
        error(['Cannot find: ', conn_dir]);
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

% Check vis_type
if ~exist('vis_type', 'var') || isempty(vis_type)
    vis_type = 'all';
end

% Assign some variables based on vis_type
if strcmpi(vis_type, 'all')
    hemisphere  = true;
    ranking     = true;
    modularity  = true;
    original    = true;
else
    % Ensure correct vis_type is passed
    if iscell(vis_type)
        if sum(ismember(vis_type, {'hemisphere', 'ranking',     ...
                                   'modularity', 'original'}))  ...
                                   ~= max(size(vis_type))
            error('One or more incorrect vis_type specified');
        end
    end
    if sum(strcmpi(vis_type, 'hemisphere'))
        hemisphere = true;
    else
        hemisphere = false;
    end
    
    if sum(strcmpi(vis_type, 'ranking'))
        ranking = true;
    else
        ranking = false;
    end
    
    if sum(strcmpi(vis_type, 'modularity'))
        modularity = true;
    else
        modularity = false;
    end
    
    if sum(strcmpi(vis_type, 'original'))
        original = true;
    else
        original = false;
    end
    
    if sum([hemisphere, ranking, modularity, original]) == 0
        error(['Unknown vis_type specified: ', vis_type]);
    end
end

% Check vis_mode
if ~exist('vis_mode', 'var') || isempty(vis_mode)
    vis_mode = 'subplot';
else
    if ~ismember(vis_mode, {'independent', 'subplot'})
        error(['Unknown vis_mode provided: ', vis_mode]);
    end
end

% Check colour_map
if ~exist('colour_map', 'var') || isempty(colour_map)
    colour_map = 'jet';
end

% Check output_dir
if ~exist('output_dir', 'var') || isempty(output_dir)
    cd(conn_dir);
    cd('..');
    output_dir = pwd;
end

%% Define global variable for visualization setings
global fig_settings 
fig_settings.img_type       = 'png';
fig_settings.colourmap      = colour_map;
fig_settings.Units          = 'centimeters';
fig_settings.PaperUnits     = 'centimeters';
fig_settings.resolution     = 300;
fig_settings.show_y_labels  = false;
fig_settings.show_x_labels  = false;

%% Make some decisions about number of figures
if strcmpi(vis_mode, 'independent')
    num_visulizations = 1;
else
    num_visulizations = sum([hemisphere, ranking, modularity, original]);
end

if num_visulizations == 1
    fig_settings.sub_1 = 1;
    fig_settings.sub_2 = 1;
else
    if num_visulizations == 2
        fig_settings.sub_1 = 1;
        fig_settings.sub_2 = 2;
    else
        fig_settings.sub_1 = 2;
        fig_settings.sub_2 = 2;
    end
end

%% Decide figure size
if num_visulizations == 2
    fig_settings.size_x  = 14.80;
    fig_settings.size_y  = 10.80;
else
    fig_settings.size_x  = 14.80;
    fig_settings.size_y  = 21.00;
end

%% Set font sizes
if num_visulizations == 1
    fig_settings.titlesize = 9;
    fig_settings.xsize     = 3;
    fig_settings.ysize     = 3;
else
    fig_settings.titlesize = 6;
    fig_settings.xsize     = 2;
    fig_settings.ysize     = 2;
end

%% Figure out visualization indices
if num_visulizations == 1
    idx_h = 1;
    idx_r = 1;
    idx_m = 1;
    idx_o = 1;
else
    if num_visulizations == 4
        idx_h = 1;
        idx_r = 2;
        idx_m = 3;
        idx_o = 4;
    else
        if num_visulizations == 2
            if hemisphere
                idx_h = 1;
                idx_o = 2;
                idx_r = 2;
                idx_m = 2;
            else
                if ranking
                    idx_r = 1;
                    idx_o = 2;
                    idx_m = 2;
                else
                    if modularity
                        idx_m = 1;
                        idx_o = 2;
                    end
                end
            end
        else
            if hemisphere
                idx_h = 1;
                idx_o = 3;
                if ranking
                    idx_r = 2;
                    idx_m = 3;
                else
                    idx_m = 2;
                end
            else
                if ranking
                    idx_r = 1;
                    idx_m = 2;
                    idx_o = 3;
                end
            end
        end
    end
end

%% Get list of atlases
cd(conn_dir);
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
    else
        list_atlases(~ismember(list_atlases, atlas_name)) = [];
    end
end

% Convert to cell
if ischar(atlas_name)
    atlas_name = {atlas_name};
end
num_atlases = size(atlas_name, 1);

%% Get all files for each atlas
cd(conn_dir);
file_list  = cell(1,num_atlases);
parse_list = cell(1,num_atlases);

for atlas = 1:num_atlases
    cd(fullfile(conn_dir, atlas_name{atlas}));
    tmp_list  = dir('conn_mat_*.mat');
    tmp_list  = struct2cell(tmp_list);
    tmp_list(2:end,:)   = [];
    file_list{:,atlas}  = tmp_list';
    parse_list{:,atlas} = cellfun(@(x) strsplit(x, '_'),          ...
                          regexprep(file_list{:,atlas},           ...
                          {'conn_mat_', [atlas_name{atlas}, '_'], ...
                          '.mat'}, ''), 'UniformOutput', false);
end

%% Compile condition list, subject list, and connectivity list
cond_list     = cell(1,num_atlases);
subj_list     = cell(1,num_atlases);
conn_list     = cell(1,num_atlases);
tmp_cond_list = cell(1,num_atlases);
tmp_subj_list = cell(1,num_atlases);
tmp_conn_list = cell(1,num_atlases);

for atlas = 1:num_atlases
    for files = 1:length(parse_list{1,atlas})
        tmp_conn_list{files,atlas} = parse_list{1,atlas}{files,1}{1};
        tmp_cond_list{files,atlas} = parse_list{1,atlas}{files,1}{2};
        tmp_subj_list{files,atlas} = parse_list{1,atlas}{files,1}{3};
    end
    conn_list{:,atlas} = unique(tmp_conn_list(:,atlas));
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

%% Prepare output folder
if ~exist(fullfile(output_dir, 'connectivity_visualization'), 'dir')
    mkdir(fullfile(output_dir, 'connectivity_visualization'));
end

for atlas = 1:num_atlases
    if ~exist(fullfile(output_dir, 'connectivity_visualization', ...
                       atlas_name{atlas}), 'dir')
        mkdir(fullfile(output_dir, 'connectivity_visualization', ...
                       atlas_name{atlas}));
    end
end
        
%% Create visualizations
for atlas = 1:num_atlases
    for sub = 1:length(subj_list{1,atlas})
        for cond = 1:length(cond_list{1,atlas})
            
            % Load variables
            load(fullfile(conn_dir, list_atlases{atlas},            ...
                         ['conn_mat_', conn_list{1,atlas}{1}, '_',  ...
                         list_atlases{atlas}, '_',                  ...
                         cond_list{1,atlas}{cond}, '_',             ...
                         subj_list{1,atlas}{sub}, '.mat']),         ...
                         'conn_mat', 'xyz', 'roi_names');
            num_rois = length(roi_names);
            
            if hemisphere
                % Work on hemispheres
                all_xyz   = vertcat(xyz{:});
                all_left  = all_xyz(:,1)<=0;
                all_right = ~all_left;
                num_left  = length(nonzeros(all_left));
                
                % Initialize rearranged matrix
                r_conn_mat = zeros(num_rois, num_rois);
                
                % Assign all left hemispheres together
                r_conn_mat(1:num_left,1:num_left) = conn_mat(all_left, all_left);
                
                % Assign all right hemispheres together
                r_conn_mat(num_left+1:num_rois,num_left+1:num_rois) = conn_mat(all_right, all_right);
                
                % Assign all (left, right) connections
                r_conn_mat(1:num_left,num_left+1:num_rois) = conn_mat(all_left, all_right);
                
                % Assign all (right, left) connections
                r_conn_mat(num_left+1:num_rois,1:num_left) = conn_mat(all_right, all_left);
                
                % call weight_conversion (autofix)
                r_conn_mat = weight_conversion(r_conn_mat, 'autofix');
                
                % Rearranged roi_names
                r_roi_names = [roi_names(all_left), roi_names(all_right)];
                
                % Add rearranged names to fig_settings
                if ~isfield(fig_settings, 'xlabels') || isempty(fig_settings.xlabels)
                    fig_settings.xlabels = r_roi_names;
                end
                
                if ~isfield(fig_settings, 'ylabels') || isempty(fig_settings.ylabels)
                    fig_settings.ylabels = r_roi_names;
                end
                
                % Output name
                if num_visulizations == 1
                    out_name = fullfile(output_dir, 'connectivity_visualization',   ...
                                        atlas_name{atlas},                          ...
                                        [subj_list{1,atlas}{sub}, '_',              ...
                                        atlas_name{atlas}, '_',                     ...
                                        conn_list{1,atlas}{1}, '_',                 ...
                                        cond_list{1,atlas}{cond},                   ...
                                        '.', fig_settings.img_type]);
                else
                    out_name = fullfile(output_dir, 'connectivity_visualization',   ...
                                        atlas_name{atlas},                          ...
                                        [subj_list{1,atlas}{sub}, '_',              ...
                                        atlas_name{atlas}, '_',                     ...
                                        conn_list{1,atlas}{1}, '_',                 ...
                                        cond_list{1,atlas}{cond}, '_hemispheres',   ...
                                        '.', fig_settings.img_type]);
                end
                
                % Figure title
                fig_settings.title = [subj_list{1,atlas}{sub}, ': ',    ...
                                      cond_list{1,atlas}{cond}, ' (',   ...
                                      atlas_name{atlas}, ') [H]'];
                
                % Display
                display_matrix(r_conn_mat, idx_h, out_name, num_visulizations);
            end
            
            if ranking
                % Work on ranking
                % call weight_conversion (autofix)
                r_conn_mat = weight_conversion(conn_mat, 'autofix');
                
                % Add weights across columns
                corr_weights = sum(r_conn_mat,2);
                
                % Sort in descending order
                [~, loc] = sort(corr_weights, 'descend');
                
                % Rearranged roi_names
                r_roi_names = roi_names(loc);
                
                % Add rearranged names to fig_settings
                if ~isfield(fig_settings, 'xlabels') || isempty(fig_settings.xlabels)
                    fig_settings.xlabels = r_roi_names;
                end
                
                if ~isfield(fig_settings, 'ylabels') || isempty(fig_settings.ylabels)
                    fig_settings.ylabels = r_roi_names;
                end
                
                % Output name
                if num_visulizations == 1
                    out_name = fullfile(output_dir, 'connectivity_visualization',   ...
                                        atlas_name{atlas},                          ...
                                        [subj_list{1,atlas}{sub}, '_',              ...
                                        atlas_name{atlas}, '_',                     ...
                                        conn_list{1,atlas}{1}, '_',                 ...
                                        cond_list{1,atlas}{cond},                   ...
                                        '.', fig_settings.img_type]);
                else
                    out_name = fullfile(output_dir, 'connectivity_visualization',   ...
                                        atlas_name{atlas},                          ...
                                        [subj_list{1,atlas}{sub}, '_',              ...
                                        atlas_name{atlas}, '_',                     ...
                                        conn_list{1,atlas}{1}, '_',                 ...
                                        cond_list{1,atlas}{cond}, '_weights',       ...
                                        '.', fig_settings.img_type]);
                end
                
                % Figure title
                fig_settings.title = [subj_list{1,atlas}{sub}, ': ',    ...
                                      cond_list{1,atlas}{cond}, ' (',   ...
                                      atlas_name{atlas}, ') [W]'];
                
                % Display
                display_matrix(r_conn_mat(loc,loc), idx_r, out_name, num_visulizations);
            end
            
            if modularity
                % Working on modularity
                % call weight conversion (autofix)
                r_conn_mat = weight_conversion(conn_mat, 'autofix');
                
                % Get classic modularity
                Ci = modularity_und(r_conn_mat);
                
                % Figure out number of modules et al
                modules     = unique(Ci);
                num_modules = length(modules);
                num_cols    = zeros(num_modules,1);
                rr_conn_mat = zeros(size(conn_mat));
                
                for uq = 1:num_modules
                    num_cols(uq,1) = length(nonzeros(Ci==modules(uq)));
                end

                % Rearrange matrix module wise
                begin_pos = 1;
                for uq = 1:num_modules
                    end_pos = begin_pos+num_cols(uq)-1;
                    rr_conn_mat(begin_pos:end_pos, begin_pos:end_pos) = r_conn_mat(Ci==modules(uq), Ci==modules(uq));
                    begin_pos = end_pos+1;
                end
                
                % Rearrange connectivity between modules
                start_col = 1;
                for uq = 1:num_modules
                    start_row = sum(num_cols(1:uq))+1;
                    rr_conn_mat(start_row:end, start_col:sum(num_cols(1:uq))) = r_conn_mat(~ismember(Ci, modules(1:uq)), Ci==modules(uq));
                    rr_conn_mat(start_col:sum(num_cols(1:uq)), start_row:end) = r_conn_mat(Ci==modules(uq), ~ismember(Ci, modules(1:uq)));
                    start_col = sum(num_cols(1:uq))+1;
                end
                
                % Rearrange roi_names
                [~,loc] = sort(Ci);
                r_roi_names = roi_names(loc);
                
                % Add rearranged names to fig_settings
                if ~isfield(fig_settings, 'xlabels') || isempty(fig_settings.xlabels)
                    fig_settings.xlabels = r_roi_names;
                end
                
                if ~isfield(fig_settings, 'ylabels') || isempty(fig_settings.ylabels)
                    fig_settings.ylabels = r_roi_names;
                end
                
                % Output name
                if num_visulizations == 1
                    out_name = fullfile(output_dir, 'connectivity_visualization',   ...
                                        atlas_name{atlas},                          ...
                                        [subj_list{1,atlas}{sub}, '_',              ...
                                        atlas_name{atlas}, '_',                     ...
                                        conn_list{1,atlas}{1}, '_',                 ...
                                        cond_list{1,atlas}{cond},                   ...
                                        '.', fig_settings.img_type]);
                else
                    out_name = fullfile(output_dir, 'connectivity_visualization',   ...
                                        atlas_name{atlas},                          ...
                                        [subj_list{1,atlas}{sub}, '_',              ...
                                        atlas_name{atlas}, '_',                     ...
                                        conn_list{1,atlas}{1}, '_',                 ...
                                        cond_list{1,atlas}{cond}, '_modularity',    ...
                                        '.', fig_settings.img_type]);
                end
                
                % Figure title
                fig_settings.title = [subj_list{1,atlas}{sub}, ': ',    ...
                                      cond_list{1,atlas}{cond}, ' (',   ...
                                      atlas_name{atlas}, ') [M]'];
                
                % Display
                display_matrix(rr_conn_mat, idx_m, out_name, num_visulizations);
            end
            
            if original
                % Working on original matrix display
                r_conn_mat = weight_conversion(conn_mat, 'autofix');
                
                % Rearranged roi_names
                r_roi_names = roi_names;
                
                % Add rearranged names to fig_settings
                if ~isfield(fig_settings, 'xlabels') || isempty(fig_settings.xlabels)
                    fig_settings.xlabels = r_roi_names;
                end
                
                if ~isfield(fig_settings, 'ylabels') || isempty(fig_settings.ylabels)
                    fig_settings.ylabels = r_roi_names;
                end
                
                % Output name
                if num_visulizations == 1
                    out_name = fullfile(output_dir, 'connectivity_visualization',   ...
                                        atlas_name{atlas},                          ...
                                        [subj_list{1,atlas}{sub}, '_',              ...
                                        atlas_name{atlas}, '_',                     ...
                                        conn_list{1,atlas}{1}, '_',                 ...
                                        cond_list{1,atlas}{cond}, '_original',      ...
                                        '.', fig_settings.img_type]);
                else
                    out_name = fullfile(output_dir, 'connectivity_visualization',   ...
                                        atlas_name{atlas},                          ...
                                        [subj_list{1,atlas}{sub}, '_',              ...
                                        atlas_name{atlas}, '_',                     ...
                                        conn_list{1,atlas}{1}, '_',                 ...
                                        cond_list{1,atlas}{cond}, '.', fig_settings.img_type]);
                end
                
                % Figure title
                fig_settings.title = [subj_list{1,atlas}{sub}, ': ',    ...
                                      cond_list{1,atlas}{cond}, ' (',   ...
                                      atlas_name{atlas}, ') [O]'];
                
                % Display
                display_matrix(r_conn_mat, idx_o, out_name, num_visulizations);
            end
        end
    end
end

function display_matrix(matrix, idx, out_name, max_vis)
global fig_settings

% Create figure if needed
if idx == 1
    fig = figure('DefaultAxesPosition', [0.1, 0.1, 0.8, 0.8]);
    
    % Set figure paper units and paper size
    fig.PaperUnits = fig_settings.PaperUnits;
    fig.PaperSize  = [fig_settings.size_x fig_settings.size_y];
end

% Move to idx specific subplot
subplot(fig_settings.sub_1, fig_settings.sub_2, idx, 'DefaultAxesPosition', [0.1, 0.1, 0.8, 0.8]);

% Plot matrix
imagesc(matrix);

% Show y labels
if fig_settings.show_y_labels
    yticks(1:num_rois);
    yticklabels(r_roi_names);
    set(gca, 'FontSize', fig_settings.ysize);
else
    yticks([]);
end

% Show x labels
if fig_settings.show_x_labels
    xticks(1:num_rois);
    xticklabels(r_roi_names);
    xtickangle(90);
    set(gca, 'FontSize', fig_settings.xsize);
else
    xticks([]);
end

% Remove ticks and set aspect ratio to 1
set(gca, 'TickLength', [0 0]);
pbaspect([1 1 1]);

% Figure title
title(fig_settings.title, 'FontSize', fig_settings.titlesize);

% Colourmap and colourbar
colormap(fig_settings.colourmap);
colorbar;

% Wait for other plots
hold on

% Decide if priting is needed
if idx==max_vis
    print(out_name, '-dpng', '-r300');
    close
end