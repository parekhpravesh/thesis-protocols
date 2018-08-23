function qc_fmri_lr_corr(data_dir, task_name, roi_left,  roi_right, ...
                         mask_gm,  mask_prob, full_bids)
% Function to calculate correlation between the global signal from left and
% the right hemispheres of the brain
%% Inputs:
% data_dir:         full path to a directory having sub-* folders (BIDS
%                   style; see Notes)
% task_name:        functional file name pattern for which QC is being 
%                   performed (example: 'rest')
% roi_left:         name of the left hemisphere ROI
% roi_right:        name of the right hemisphere ROI
% mask_gm:          yes/no to indicate if subject specific GM mask was
%                   applied before signal extraction while running 
%                   qc_fmri_roi_signal
% mask_prob:        probability value which was specified for thresholding
%                   GM mask while running qc_fmri_roi_signal
% full_bids:        yes/no to indicate if the data_dir is a full BIDS style
%                   folder (i.e. it has anat and func sub-folders) or all 
%                   files are present in a single folder (see Notes)
% 
%% Output:
% Within the already existing 'quality_check_<task_name>' in each subject's
% folder, a mat file is written having the correlation between the left and
% the right hemispheres. This file is named as 
% <subject_ID>_<task_name>_LR_corr.mat
%
%% Notes:
% Uses the output of qc_fmri_roi_signal
% 
% Each sub-* folder should have a quality_check_<task_name> folder having 
% that subject's time series files saved as a mat file
% 
% roi_left and roi_right are the names of the ROIs corresponding to the
% left and the right hemispheres which were present in the roi_dir 
% while running qc_fmri_roi_signal
% 
% User must specify if mask_gm was specified while running
% qc_fmri_roi_signal and if yes, also provide the probability value at
% which thresholding was performed; this is important because the ROI names
% would have the probability value appended to their names if mask_gm was
% set to yes
% 
% Full BIDS specification means that there are separate anat and func
% folders inside the subject folder; if specified as no, the files should
% still be named following BIDS specification but all files are assumed to
% be in the same folder
% 
%% Defaults:
% mask_gm:          'yes'
% mask_gm_prob:     0.2
% full_bids:        'yes'
%
%% Author(s)
% Parekh, Pravesh
% August 21, 2018
% MBIAL

%% Validate input and assign defaults
% Check data_dir
if ~exist('data_dir', 'var') || isempty(data_dir)
    error('data_dir needs to be given');
else
    if ~exist(data_dir, 'dir')
        error(['Unable to find data_dir: ', data_dir]);
    end
end

% Check task_name
if ~exist('task_name', 'var') || isempty(task_name)
    error('task_name needs to be given');
end

% Check roi_left
if ~exist('roi_left', 'var') || isempty(roi_left)
    error('roi_left needs to be given');
end

% Check roi_right
if ~exist('roi_right', 'var') || isempty(roi_right)
    error('roi_right needs to be given');
end

% Check mask_gm
if ~exist('mask_gm', 'var') || isempty(mask_gm)
    mask_gm = 1;
else
    if strcmpi(mask_gm, 'yes')
        mask_gm = 1;
    else
        if strcmpi(mask_gm, 'no')
            mask_gm = 0;
        else
            error(['Invalid mask_gm value specified :', mask_gm]);
        end
    end
end

% Check mask_prob
if ~exist('mask_prob', 'var') || isempty(mask_prob)
    mask_prob = 0.2;
else
    if mask_prob < 0 || mask_prob > 1
        error('mask_prob value should be between 0 and 1');
    end
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

%% Create subject list
cd(data_dir);
list_subjs = dir('sub-*');
num_subjs  = length(list_subjs);

%% Work on each subject
for sub = 1:num_subjs
    
    % Locate quality_check folder
    if full_bids
        qc_dir = fullfile(data_dir, list_subjs(sub).name, 'func', ...
                          ['quality_check_', task_name]);
    else
        qc_dir = fullfile(data_dir, list_subjs(sub).name, ...
                          ['quality_check_', task_name]);
    end
    
    if ~exist(qc_dir, 'dir')
        warning(['Cannot locate quality_check_', task_name, ' for ', ...
              list_subjs(sub).name, '; skipping']);
    else
        % Load mat file having time series
        cd(qc_dir);
        list_sub_roi_files = [];
        time_series        = [];
        load([list_subjs(sub).name, '_', task_name, '_TimeSeries.mat'], ...
             'list_sub_roi_files', 'time_series');
        
        % Parse ROI names
        num_sub_rois = length(list_sub_roi_files);
        target_rois = cell(num_sub_rois,1);
        for roi = 1:num_sub_rois
            [~,target_rois{roi}] = fileparts(list_sub_roi_files{roi});
        end
        
        % Remove threshold values if present
        if mask_gm
            target_rois = regexprep(target_rois, ['_', num2str(mask_prob, '%0.2f')], '');
        end
        
        % Find roi_left and roi_right
        left_loc   = find(strcmpi(target_rois, [list_subjs(sub).name, '-', roi_left]),  1);
        right_loc  = find(strcmpi(target_rois, [list_subjs(sub).name, '-', roi_right]), 1);
        left_name  = target_rois(left_loc);
        right_name = target_rois(right_loc);
        
        % Restore the names of left and right regions if mask_gm
        if mask_gm
            left_name  = strcat(left_name, ['_', num2str(mask_prob, '%0.2f')]);
            right_name = strcat(right_name, ['_', num2str(mask_prob, '%0.2f')]);
        end
        
        if isempty(left_loc) || isempty(right_loc)
            warning(['Cannot find left/right ROI for ', ...
                    list_subjs(sub).name, '; skipping']);
        else
            lr_corr = corr(time_series(:,left_loc), time_series(:,right_loc));
            
            % Save mat file
            mat_name = [list_subjs(sub).name, '_', task_name, 'LR_corr.mat'];
            save(mat_name, 'list_sub_roi_files', 'lr_corr', 'left_name', 'right_name');
        end
    end
end