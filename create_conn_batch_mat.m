function create_conn_batch_mat(data_dir,        task_name,      list_subjs,   ...
                               anat_prefix,     func_prefix,    atlas_file,   ...
                               outlier_loc,     outlier_prefix, num_par_jobs, ... 
                               project_name,    output_name,    full_bids)
% Function to read in pre-processed data and create a mat file which can be
% read by conn_batch
%% Inputs:
% data_dir:         fullpath to directory containing sub-* folders
% task_name:        name of the task
% list_subjs:       cell type having list of subjects to process
% anat_prefix:      prefix for normalized skull stripped data
% func_prefix:      prefix for smoothed normalized functional data
% atlas_file:       fullpath(s) to an/multiple atlas file(s)
% outlier_loc:      location template to a mat file containing outliers
% outlier_prefix:   name/template of a mat file containing outliers
% num_par_jobs:     number of parallel jobs to run (0 for serial)
% project_name:     name for conn project
% output_name:      name of the mat file to be saved
% full_bids:        yes/no indicating if subject folders in data_dir 
%                   follow full BIDS specification
% 
%% Output:
% Saves <output_name>.mat or batch_<task_name>_<DDMMMYYYY>.mat file in 
% data_dir which can be loaded into Conn using conn_batch(filename)
% 
%% Notes:
% task_name can be any of the following: 
% 	* vftclassic    verbal fluency task (VFT)
%   * vftmodern     modified VFT with hallucination query
%   * pm            prospective memory task
%   * hamths        hallucination attention modulation task (HS)
%   * hamtsz        hallucination attention modulation task (SZ)
%   * rest          resting state
% 
% anat_prefix should be the prefix associated with skull stripped normalized
% structural data (for example, 'wc0')
% 
% func_prefix should be the prefix associated with the smoothed normalized
% functional data (for example, 'swau')
% 
% For structural data, assumes:
%   * wc1*:         Normalized grey matter segmentation file
%   * wc2*:         Normalized white matter segmentation file
%   * wc3*:         Normalized CSF segmentation file
% 
% For functional data, assumes:
%   * removing 's' from the prefix results in normalized functional file
%   * sub-<subj_ID>_task-<task_name>_bold.nii is the original file
% 
% Lookup file for atlas_file should be in the same location as the
% atlas_file itself
% 
% Multiple atlas files can be provided as a cell type with each row
% corresponding to an atlas file
% 
% outlier_loc specifies a directory inside each subject folder where the 
% outlier file is present. For example 'DVARS' in which case the path to 
% the outlier variable becomes:
%   * fullfile(data_dir, subj_dir, func, 'DVARS') (if full BIDS) OR
%   * fullfile(data_dir, subj_dir, 'DVARS') (in case of partial BIDS)
% if outlier_loc is empty, assumes:
%   * the outlier file is in 'func' folder of subj_dir (if full BIDS)
%   * the outlier file is in subj_dir (in case of partial BIDS)
% 
% outlier_prefix specifies a variable name or a template variable name to
% the actual file which contains outliers:
%   * specify a variable name if the same variable name contains the
%     outliers for every subject; if outlier_prefix ends with a .mat then
%     it is assumed to be the variable name
%   * specify a template name if the variable containing the outliers
%     varies for every subject; a search using "*<outlier_prefix>*.mat" is
%     made in the outlier_loc for every subject
% 
% The actual outlier variable is a variable 'R' which contains a natrix of 
% 0's and 1's with as many number of columns as number of outliers; for
% each column the row entry should have 1 to the volume that has been 
% marked as an outlier
% 
% Performs all the steps till first level ROI-to-ROI connectivity
% 
% For either VFT, automatically specifies sparse acquisition
% 
% Assumes only one session per subject
% 
% Written for CONN functional connectivity toolbox 18b
% 
%% Defaults:
% task_name:        'rest'
% list_subjs:       'all'
% anat_prefix:      'wc0'
% func_prefix:      'swau'
% atlas_file:       'atlas.nii' (from Conn)
% outlier_loc:      ''
% outlier_prefix:   outliers.mat
% num_par_jobs:     0
% project_name:     conn_<task_name>_DDMMMYYYY
% output_name:      batch_<task_name>_<DDMMMYYYY>.mat
% full_bids:        'yes'
% 
%% Author(s):
% Parekh, Pravesh
% January 16, 2019
% MBIAL

%% Check inputs and assign defaults
% Check data_dir
if ~exist('data_dir', 'var') || isempty(data_dir)
    error('data_dir needs to be provided');
else
    if ~exist(data_dir, 'dir')
        error(['Cannot find: ', data_dir]);
    end
end

% Check task_name
if ~exist('task_name', 'var') || isempty(task_name)
    task_name = 'rest';
else
    task_name = lower(task_name);
    if ~ismember(task_name, {'vftclassic', 'vftmodern', 'pm', 'hamths', ...
                             'hamtsz', 'rest'})
        error(['Unknown task_name provided: ', task_name]);
    end
end

% Check list_subj
if ~exist('list_subjs', 'var') || isempty(list_subjs)
    list_subjs = 'all';
end

% Check anat_prefix
if ~exist('anat_prefix', 'var') || isempty(anat_prefix)
    anat_prefix = 'wc0';
end

% Check func_prefix
if ~exist('func_prefix', 'var') || isempty(func_prefix)
    func_prefix = 'swau';
end

% Check atlas_file
if ~exist('atlas_file', 'var') || isempty(atlas_file)
    atlas_file = fullfile(fileparts(which('conn')), 'rois', 'atlas.nii');
    num_atlas  = 1;
else
    if ischar(atlas_file)
        atlas_file = {atlas_file};
    end
    num_atlas = size(atlas_file, 1);
    for atlas = 1:num_atlas
        if ~exist(atlas_file{atlas}, 'file')
            error(['Cannot find: ', atlas_file{atlas}]);
        end
    end
end

% Check outlier_loc
if ~exist('outlier_loc', 'var')
    outlier_loc = '';
end

% Check outlier_prefix
if ~exist('outlier_prefix', 'var') || isempty(outlier_prefix)
    outlier_prefix = 'outliers.mat';
end

% Check num_par_jobs
if ~exist('num_par_jobs', 'var') || isempty(num_par_jobs)
    num_par_jobs = 0;
end

% Check project_name
if ~exist('project_name', 'var') || isempty(project_name)
    project_name = ['conn_', task_name, '_', datestr(now, 'ddmmmyyyy')];
end

% Check output_name
if ~exist('output_name', 'var') || isempty(output_name)
    output_name = ['batch_', task_name, '_', datestr(now, 'ddmmmyyyy'), '.mat'];
end

% Check full_bids
if ~exist('full_bids', 'var') || isempty(full_bids)
    full_bids = 1;
else
    if strcmpi(full_bids, 'yes')
        full_bids = 1;
    else
        if strcmpi(full_bids, 'no')
            full_bids = 0;
        else
            error(['Invalid full_bids value specified: ', full_bids]);
        end
    end
end

%% Make list of subjects
if strcmpi(list_subjs, 'all')
    cd(data_dir);
    list_subjs = dir('sub-*');
    list_subjs = struct2cell(list_subjs);
    list_subjs(2:end,:) = [];
    list_subjs = list_subjs';
end
num_subjs  = length(list_subjs);

%% Get task design and TR
conditions = get_fmri_task_design_conn(task_name, num_subjs);
tmp_design = get_fmri_task_design_spm(task_name, 'seconds');
TR = tmp_design.RT;
clear tmp_design

%% Determine acquisition type
if ismember(task_name, {'vftclassic', 'vftmodern'})
    acquisition_type = 0;
else
    acquisition_type = 1;
end

%% Determine if fixed outlier_prefix
[~,~,outlier_chk] = fileparts(outlier_prefix);
if strcmpi(outlier_chk, '.mat')
    outlier_chk = 1;
else
    outlier_chk = 0;
end

%% Determine band-pass filter
if strcmpi(task_name, 'rest')
    bpf = [0.008 0.09];
else
    bpf = [0.008 Inf];
end

%% BATCH.parallel
BATCH.parallel.N = num_par_jobs;

%% BATCH.Setup subject independent fields
BATCH.filename              = ['conn_', project_name, '.mat'];
BATCH.Setup.isnew           = 1;
BATCH.Setup.done            = 1;
BATCH.Setup.nsubjects       = num_subjs;
BATCH.Setup.RT              = TR;
BATCH.Setup.acquisitiontype = acquisition_type;
BATCH.Setup.conditions      = conditions;
BATCH.Setup.analyses        = [1,2,3,4];
BATCH.Setup.voxelmask       = 1;
BATCH.Setup.outputfiles     = [0,1,0,0,0,1];

%% ROIs
for atlas = 1:num_atlas
    [~, atlas_name]  = fileparts(atlas_file{atlas});
    if isempty(atlas_name)
        atlas_name = atlas_file;
    end
    
    % Atlas name
    BATCH.Setup.rois.names{atlas} = atlas_name;
    
    % Atlas file
    BATCH.Setup.rois.files{atlas} = atlas_file{atlas};
    
    % Extract average time series from atlas
    BATCH.Setup.rois.dimensions{atlas} = 1;
    
    % Do not weight the time series
    BATCH.Setup.rois.weighted(atlas) = 0;
    
    % Set as multiple label file
    BATCH.Setup.rois.multiplelabels(atlas) = 1;
    
    % Do not mask with grey matter
    BATCH.Setup.rois.mask(atlas) = 0;
    
    % Do not regress covariates
    BATCH.Setup.rois.regresscovariates(atlas) = 0;
    
    % Point ROIs to secondary dataset
    BATCH.Setup.rois.dataset(atlas) = 1;
end

%% Set all subject specific fields
for sub = 1:num_subjs
    % Subject Name
    subj_name = list_subjs{sub};
    
    %% Define paths
    if full_bids
        func_path = fullfile(data_dir, subj_name, 'func');
        anat_path = fullfile(data_dir, subj_name, 'anat');
    else
        func_path = fullfile(data_dir, subj_name);
        anat_path = fullfile(data_dir, subj_name);
    end
        
    %% Scans
    % Functional scans
    cd(func_path);
    func_file = dir([func_prefix, '*.nii']);
    BATCH.Setup.functionals{sub}{1} = fullfile(func_path, func_file(1).name);
    
    % Structural scan
    cd(anat_path);
    anat_file = dir([anat_prefix, '*.nii']);
    BATCH.Setup.structurals{sub} = fullfile(anat_path, anat_file(1).name);

    % Secondary functional dataset (after removing s)
    BATCH.Setup.secondarydatasets.functionals_label            = 'unsmoothed volumes';
    BATCH.Setup.secondarydatasets.functionals_explicit{sub}{1} = fullfile(func_path, func_file(1).name(2:end));
    
    %% Masks
    % Get masks
    cd(anat_path);
    grey_file  = dir('wc1*.nii');
    white_file = dir('wc2*.nii');
    csf_file   = dir('wc3*.nii');
    
    % Assign masks
    BATCH.Setup.masks.Grey{sub}  = fullfile(anat_path, grey_file(1).name);
    BATCH.Setup.masks.White{sub} = fullfile(anat_path, white_file(1).name);
    BATCH.Setup.masks.CSF{sub}   = fullfile(anat_path, csf_file(1).name);
    
    %% First level covariates
    % Get realignment file
    cd(func_path);
    realignment_file = dir('rp_*.txt');
    
    % Get scrubbing file
    cd(fullfile(func_path, outlier_loc));
    if outlier_chk
        scrubbing_file = fullfile(func_path, outlier_loc, outlier_prefix);
    else
        scrubbing_file = dir(['*', outlier_prefix, '*.mat']);
        scrubbing_file = fullfile(func_path, outlier_loc, scrubbing_file(1).name);
    end
    
    % Realignment
    BATCH.Setup.covariates.names{1}         = 'realignment';
    BATCH.Setup.covariates.files{1}{sub}{1} = fullfile(func_path, realignment_file(1).name);
    
    % Scrubbing
    BATCH.Setup.covariates.names{2}         = 'scrubbing';
    BATCH.Setup.covariates.files{2}{sub}{1} = scrubbing_file; 
end

%% Denoising
BATCH.Denoising.done        = 1;
BATCH.Denoising.filter      = bpf;
BATCH.Denoising.detrending  = 1;
BATCH.Denoising.despiking   = 0;
BATCH.Denoising.regbp       = 1;

%% First level: ROI-to-ROI (HRF weighted)
BATCH.Analysis.done             = 1;
BATCH.Analysis.analysis_number  = 1;
BATCH.Analysis.measure          = 1;
BATCH.Analysis.weight           = 2;
BATCH.Analysis.modulation       = 0;
BATCH.Analysis.type             = 1;

%% Save batch
save_name = fullfile(data_dir, output_name);
save(save_name, 'BATCH');