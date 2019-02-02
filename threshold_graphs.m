function threshold_graphs(conn_dir, atlas_name, cond_name, subj_id, ...
                          thresh_type, thresh_weight, binarize, neg_discard, ...
                          out_dir)
% Function to threshold a set of connectivity matrices
%% Inputs:
% conn_dir:         fullpath to directory having connectivity matrices
% atlas_name:       name(s) of atlases to create graphs for (or 'all')
% cond_name:        name(s) of condition to create graphs for (or 'all')
% subj_id:          cell type with rows being subject ID(s) (or 'all')
% thresh_type:      threshold type; should be one of:
%                       * 'absolute'
%                       * 'proportional'
% thresh_weight:    weight(s) to be used for thresholding
% binarize:         yes/no indicating if binary graphs are needed
% neg_discard:      yes/no indicating if negative values in the 
%                   connectivity matrices should be discarded 
% out_dir:          output directory where results will be saved
% 
%% Output:
% Graphs are created in the output directory as follows:
% <out_dir>/
%   <atlas_name>/
%       <cond_name>/
%           graphs_<conn_type>_<thresh_type>_<wei/bin>_<thresh_weight>/
%               graph_<subj_ID>_<conn_type>_<atlas_name>_<thresh_type>_<wei/bin>_<thresh_weight>.mat
% 
% Graphs are saved as variable 'adj' while 'roi_names', and 'xyz' are
% retained from connectivity matrix variable. A variable named 'notes' is
% also saved containing details of processing (variable 'notes' from
% connectivty matrices is preserved)
% 
%% Notes:
% Relies on output format from get_ts_conn.m and calc_connectivity_ts.m
% 
% Requires the Brain Connectivity Toolbox (BCT)
% 
% atlas names are the folders inside conn_dir
% 
% thresh_weight should be between 0-1 for proportional thresholding
% 
% Calls the weight_conversion function of BCT using autofix after
% thresholding is done
%
%% Defaults:
% atlas_name:       'all'
% cond_name:        'all'
% subj_id:          'all'
% thresh_type:      'proportional'
% thresh_weight:    0.01:0.01:1 (for proportional; required for absolute)
% binarize:         'no'
% neg_discard:      'yes'
% output_dir:       one level above conn_dir named "graphs'
% 
%% Author(s):
% Parekh, Pravesh
% January '31, 2019
% MBIAL

%% Check inputs and assign defaults
% Check conn_dir
if ~exist('conn_dir', 'var') || isempty(conn_dir)
    error('conn_dir should be provided');
else
    if ~exist(conn_dir, 'dir')
        error(['Cannot find: ', conn_dir]);
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

% Check thresh_type
if ~exist('thresh_type', 'var') || isempty(thresh_type)
    thresh_type = 'proportional';
else
    if ~ismember(thresh_type, {'absolute', 'proportional'})
        error(['Unknown thresh_type specified: ', thresh_type]);
    end
end

% Check thresh_weight
if ~exist('thresh_weight', 'var') || isempty(thresh_weight)
    if strcmpi(thresh_type, 'absolute')
        error('Need to specify thresh_weight for absolute thresholding');
    else
    thresh_weight = 0.01:0.01:1;
    end
else
    if ~strcmpi(thresh_type, 'absolute')
        if sum(thresh_weight < 0 | thresh_weight > 1) ~= 0
            error('thresh_weight should be between 0-1');
        end
    end
end

% Check binarize
if ~exist('binarize', 'var') || isempty(binarize)
    binarize = 0;
else
    if strcmpi(binarize, 'yes')
        binarize = 1;
    else
        if strcmpi(binarize, 'no')
            binarize = 0;
        else
            error(['Unknown value specified for binarize: ', binarize]);
        end
    end
end

% Check neg_discard
if ~exist('neg_discard', 'var') || isempty(neg_discard)
    neg_discard = 1;
else
    if strcmpi(neg_discard, 'yes')
        neg_discard = 1;
    else
        if strcmpi(neg_discard, 'no')
            neg_discard = 0;
        else
            error(['Unknown value specified for neg_discard: ', neg_discard]);
        end
    end
end

% Check out_dir
if ~exist('out_dir', 'var') || isempty(out_dir)
        cd(conn_dir);
        cd('..');
        out_dir = fullfile(pwd, 'graphs');
else
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
end

%% Check atlas names
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


%% Get all conditions for each atlas
cond_list = cell(1,num_atlases);
for atlas = 1:num_atlases
    cd(fullfile(conn_dir, atlas_name{atlas}));
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

%% Get all subject IDs for each atlas for given condition(s)
cd(conn_dir);
subj_list  = cell(1,num_atlases);
conn_list  = cell(1,num_atlases);

for atlas = 1:num_atlases
    for cond = 1:length(cond_list{1,atlas})
        cd(fullfile(conn_dir, atlas_name{atlas}, cond_list{1,atlas}{cond}));
        tmp_list = dir(['conn_mat_*_', atlas_name{atlas}, '_', ...
                        cond_list{1,atlas}{cond}, '_*.mat']);
        tmp_list  = struct2cell(tmp_list);
        tmp_list(2:end,:) = [];
        tmp_list = tmp_list';
        
        % Get subject IDs and connectivity type for this condition
        tmp = cellfun(@(x) strsplit(x, '_'),            ...
                                             regexprep(tmp_list,               ...
                                             {'conn_mat_*_',                   ...
                                             [atlas_name{atlas}, '_'],         ...
                                             [cond_list{1,atlas}{cond}, '_'],  ...
                                             '.mat'}, ''), 'UniformOutput', false);
        for tmp_var = 1:length(tmp)
            subj_list{1,atlas}{1,cond}{tmp_var,1} = tmp{tmp_var}{2};
            conn_list{1,atlas}{1,cond}{tmp_var,1} = tmp{tmp_var}{1};
        end
        
        % Check if subj_id exist in subj_list
        if ~strcmpi(subj_id, 'all')
            if ~ismember(subj_id, subj_list{1,atlas}{1,cond})
                error(['Could not find one or more subjects in ', ...
                       cond_list{1,atlas}{cond}]);
            else
                % Remove subjects and connectivity types which are not needed 
                to_remove = ~ismember(subj_list{1,atlas}{1,cond}, subj_id);
                subj_list{1,atlas}{1,cond}(to_remove) = [];
                conn_list{1,atlas}{1,cond}(to_remove) = [];
            end
        end
    end
end

%% Prepare output folder
if binarize
    template_name = [thresh_type, '_bin_'];
else
    template_name = [thresh_type, '_wei_'];
end

%% Create graphs
for atlas = 1:num_atlases
    for cond = 1:length(cond_list{1,atlas})
        for sub = 1:length(subj_list{1,atlas}{1,cond})
%             for con = 1:length(conn_list{1,atlas})
                % Load variables
                load(fullfile(conn_dir, list_atlases{atlas},            ...
                             cond_list{1,atlas}{cond},                  ...
                             ['conn_mat_',                              ...
                             conn_list{1,atlas}{cond}{sub}, '_',        ...
                             list_atlases{atlas}, '_',                  ...
                             cond_list{1,atlas}{cond}, '_',             ...
                             subj_list{1,atlas}{cond}{sub}, '.mat']),   ...
                             'conn_mat', 'xyz', 'roi_names', 'notes');
                
                % Convert to graph
                switch(thresh_type)
                    case 'absolute'
                        for thresh = 1:max(size(thresh_weight))
                            
                            % Output directory and name
                            save_dir  = fullfile(out_dir, list_atlases{atlas},  ...
                                                cond_list{1,atlas}{cond},       ...
                                                [template_name,                 ...
                                                num2str(thresh_weight(thresh), '%0.2f')]);
                                            
                            if ~exist(save_dir, 'dir')
                                mkdir(save_dir);
                            end
                                            
                            out_name = fullfile(save_dir, ['graphs_',                  ...
                                                subj_list{1,atlas}{1,cond}{sub}, '_',  ...
                                                conn_list{1,atlas}{1,cond}{sub}, '_',  ...
                                                list_atlases{atlas}, '_',              ...
                                                template_name,                         ...
                                                num2str(thresh_weight(thresh),         ...
                                                '%0.2f'), '.mat']);
                            
                            % Threshold
                            adj = threshold_absolute(conn_mat, thresh_weight(thresh));
                            
                            % Discard negative weights, if needed
                            if neg_discard
                                adj(adj<0) = 0;
                            end
                            
                            % Binarize, if needed
                            if binarize
                                adj = weight_conversion(adj, 'binarize');
                            end
                            
                            % Autofix
                            adj = weight_conversion(adj, 'autofix');
                            
                            % Make notes
                            notes.binarize      = binarize;
                            notes.neg_discard   = neg_discard;
                            notes.thresh_type   = thresh_type;
                            notes.thresh_weight = thresh_weight(thresh);
                            notes.input_dir     = conn_dir;
                            
                            % Save
                            save(out_name, 'adj', 'roi_names', 'xyz', 'notes');
                        end
                        
                    case 'proportional'
                        for thresh = 1:max(size(thresh_weight))
                            
                            % Output directory and name
                            save_dir  = fullfile(out_dir, list_atlases{atlas},   ...
                                                 cond_list{1,atlas}{cond},       ...
                                                 [template_name,                 ...
                                                 num2str(thresh_weight(thresh), '%0.2f')]);
                                            
                            if ~exist(save_dir, 'dir')
                                mkdir(save_dir);
                            end
                                            
                            out_name = fullfile(save_dir, ['graphs_',                  ...
                                                subj_list{1,atlas}{1,cond}{sub}, '_',  ...
                                                conn_list{1,atlas}{1,cond}{sub}, '_',  ...
                                                list_atlases{atlas}, '_',              ...
                                                template_name,                         ...
                                                num2str(thresh_weight(thresh),         ...
                                                '%0.2f'), '.mat']);
                            
                            % Threshold
                            adj = threshold_proportional(conn_mat, thresh_weight(thresh));
                            
                            % Discard negative weights, if needed
                            if neg_discard
                                adj(adj<0) = 0;
                            end
                            
                            % Binarize, if needed
                            if binarize
                                adj = weight_conversion(adj, 'binarize');
                            end
                            
                            % Autofix
                            adj = weight_conversion(adj, 'autofix');
                            
                            % Make notes
                            notes.binarize      = binarize;
                            notes.neg_discard   = neg_discard;
                            notes.thresh_type   = thresh_type;
                            notes.thresh_weight = thresh_weight(thresh);
                            notes.input_dir     = conn_dir;
                            
                            % Save
                            save(out_name, 'adj', 'roi_names', 'xyz', 'notes');
                        end
                end
        end
    end
end