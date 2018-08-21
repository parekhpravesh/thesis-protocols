function qc_fmri_roi_signal_change(data_dir, task_name, ref_roi_name, ...
                                   mask_gm, mask_prob, full_bids)
% Function to calculate signal change in ROIs using a reference ROI
%% Inputs:
% data_dir:         full path to a directory having sub-* folders (BIDS
%                   style; see Notes)
% task_name:        functional file name pattern for which QC is being 
%                   performed (example: 'rest')
% ref_roi_name:     name of the ROI to be used as a reference (see Notes)
% mask_gm:          yes/no to indicate if subject specific GM mask was
%                   applied before signal extraction while running 
%                   qc_fmri_roi_signal
% mask_prob:        probability value which was specified for thresholding
%                   GM mask while running qc_fmri_roi_signal
% full_bids:        yes/no to indicate if the data_dir is a full BIDS style
%                   folder (i.e. it has anat and func sub-folders) or all 
%                   files are present in a single folder (see Notes)
% 
%% Outputs:
% Within the already existing 'quality_check_<task_name>' in each subject's
% folder, a mat file is written having the min, max, mean, and variance 
% values of percent difference with respect to the baseline for each ROI. 
% This file is named as <subject_ID>_<task_name>_PSC_ref_<ref_roi_name>.mat
%
%% Notes:
% Uses the output of qc_fmri_roi_signal
% 
% Each sub-* folder should have a quality_check_<func_name> folder having 
% that subject's time series files saved as a mat file
% 
% Reference ROI should be one of the ROIs which was present in the roi_dir 
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
% Difference between the time series of the reference ROI and the regional
% time series is calculated. Then divided by the reference ROI time series
% and multiplied by 100; the minimum, maximum, mean, and the standard 
% deviation of this percentage value is recorded in the csv file
% 
%% Default:
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

% Check ref_roi_name
if ~exist('ref_roi_name', 'var') || isempty(ref_roi_name)
    error('ref_roi_name needs to be given');
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
        
        % Find reference ROI and target ROIs
        ref_loc = find(strcmpi(target_rois, [list_subjs(sub).name, '-', ref_roi_name]), 1);
        if isempty(ref_loc)
            warning(['Cannot find reference ROI ', ...
                    [list_subjs(sub).name, '-', ref_roi_name], ' for ', ...
                    list_subjs(sub).name, '; skipping']);
        else
            target_loc   = setdiff(1:num_sub_rois, ref_loc);
            target_names = target_rois(target_loc);
            
            % Calculate percentage difference between regional time series
            % and reference time series and compute descriptive statistics
            percent_diff = ((time_series(:,ref_loc) - ...
                             time_series(:,target_loc))./...
                             time_series(:,ref_loc))*100;
            min_percent_diff  = min(percent_diff);
            max_percent_diff  = max(percent_diff);
            mean_percent_diff = mean(percent_diff);
            std_percent_diff  = std(percent_diff);
            
            % Save this subject's mat file
            mat_name = [list_subjs(sub).name, '_', task_name, '_PSC_ref_', ...
                        ref_roi_name, '.mat'];
            save(mat_name, 'list_sub_roi_files', 'percent_diff',   ...
                           'min_percent_diff', 'max_percent_diff', ...
                           'mean_percent_diff', 'std_percent_diff', ...
                           'target_names', 'ref_roi_name');
        end
    end
end