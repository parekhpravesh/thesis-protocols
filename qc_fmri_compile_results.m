function qc_fmri_compile_results(data_dir, task_name, ref_roi_name, full_bids)
% Function to compile results of fMRI QC pipeline into a csv file
%% Inputs:
% data_dir:         full path to a directory having sub-* folders (BIDS
%                   style; see Notes)
% task_name:        functional file name pattern for which QC is being 
%                   performed (example: 'rest')
% ref_roi_name:     name of the ROI to be used as a reference (see Notes)
% full_bids:        yes/no to indicate if the data_dir is a full BIDS style
%                   folder (i.e. it has anat and func sub-folders) or all 
%                   files are present in a single folder (see Notes)
% 
%% Output:
% A csv file and a mat file containing the QC measures from all the 
% subjects in the data_dir are written out in data_dir named 
% summary_fMRI_QC_<task_name>_<DDMMYYYY>.csv
% summary_fMRI_QC_<task_name>_<DDMMYYYY>.mat
% 
%% Notes:
% Each sub-* folder should have a quality_check_<task_name> folder from
% which subject measures will be picked up
% 
% Reference ROI name is the name of the reference ROI specified while 
% running qc_fmri_roi_signal_change
% 
% Assumes that the entire pipeline has been run
% 
% Assumes that the same ROI files and settings were used for all subjects
% for a given task; if not, the compiled sheet would be incorrect
% 
% % Full BIDS specification means that there are separate anat and func
% folders inside the subject folder; if specified as no, the files should
% still be named following BIDS specification but all files are assumed to
% be in the same folder
% 
%% Default:
% full_bids:        'yes'
% 
%% Author(s)
% Parekh, Pravesh
% August 26, 2018
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

%% Create header for saving results
if full_bids
    qc_dir = fullfile(data_dir, list_subjs(1).name, 'func', ...
                      ['quality_check_', task_name]);
else
    qc_dir = fullfile(data_dir, list_subjs(1).name, ...
                      ['quality_check_', task_name]);
end

load_name = fullfile(qc_dir, [list_subjs(1).name, '_', task_name, ...
                     '_PSC_ref_', ref_roi_name, '.mat']);
    
if ~exist(load_name, 'file')
    error(['Incorrect reference ROI name specified: ', ref_roi_name]);
else
    load(load_name, 'target_names');
    num_target_rois = length(target_names);
    min_names  = strcat('min_PSC_', strrep(target_names,  ...
                        [list_subjs(1).name, '-'], ''),   ...
                        '_ref_', ref_roi_name);
    max_names  = strcat('max_PSC_', strrep(target_names,  ...
                        [list_subjs(1).name, '-'], ''),   ...
                        '_ref_', ref_roi_name);
    mean_names = strcat('mean_PSC_', strrep(target_names, ...
                        [list_subjs(1).name, '-'], ''),   ...
                        '_ref_', ref_roi_name);
    std_names  = strcat('std_PSC_', strrep(target_names,  ...
                        [list_subjs(1).name, '-'], ''),   ...
                        '_ref_', ref_roi_name);
    
    header = {'subject_ID',                   'task_name',                   ...
              'refRMS_threshold',             'refRMS_num_outliers',         ...
              'DVARS_threshold',              'DVARS_num_outliers',          ...
              'FD_threshold',                 'FD_num_outliers',             ...
              'total_num_outliers',           'num_common_outliers',         ...
              'LR_correlation',               'brainmask_threshold',         ...
              'vox_count_template_brainmask', 'vox_count_subject_brainmask', ...
              'vox_count_difference',         'vox_count_percentage_difference'};
          
    more_header_names = cell(1, num_target_rois*4);
    count = 1;
    for roi = 1:num_target_rois
        more_header_names{count} = min_names{roi};
        count = count + 1;
        more_header_names{count} = max_names{roi};
        count = count + 1;
        more_header_names{count} = mean_names{roi};
        count = count + 1;
        more_header_names{count} = std_names{roi};
        count = count + 1;
    end
    
    header = [header, more_header_names];
    summary_qc = cell(num_subjs, length(header));
    
    clear min_names max_names mean_names std_names more_header_names target_name
end

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
        % Add subject info in summary_qc
        summary_qc{sub, 1} = list_subjs(sub).name;
        summary_qc{sub, 2} = task_name;
        
        % Load motion_profile
        load_name = fullfile(qc_dir, [list_subjs(sub).name, '_', task_name,   ...
                            '_motion_profile.mat']);
        load(load_name, 'outlier');
        
        % Populate results into summary_qc
        summary_qc{sub, 3}  = outlier.refRMS.threshold;
        summary_qc{sub, 4}  = outlier.refRMS.num_outliers;
        summary_qc{sub, 5}  = outlier.dvars.threshold;
        summary_qc{sub, 6}  = outlier.dvars.num_outliers;
        summary_qc{sub, 7}  = outlier.FD.threshold;
        summary_qc{sub, 8}  = outlier.FD.num_outliers;
        summary_qc{sub, 9}  = outlier.num_total_outliers;
        summary_qc{sub, 10} = outlier.num_common_outliers;
        clear outlier
        
        % Load LRcorr.mat
        load_name = fullfile(qc_dir, [list_subjs(sub).name, '_', task_name, ...
                             'LR_corr.mat']);
        load(load_name, 'lr_corr');
        
        % Populate results into summary_qc
        summary_qc{sub, 11} = lr_corr;
        clear lr_corr
        
        % Load brainmask voxel count
        load_name = fullfile(qc_dir, [list_subjs(sub).name, '_', task_name, ...
                             '_brainmask_voxcount.mat']);
        load(load_name, 'threshold', 'vox_count_template', ...
                        'vox_count_brainmask', 'vox_count_difference');
        
        % Populate results into summary_qc
        summary_qc{sub, 12} = threshold;
        summary_qc{sub, 13} = vox_count_template;
        summary_qc{sub, 14} = vox_count_brainmask;
        summary_qc{sub, 15} = vox_count_difference;
        summary_qc{sub, 16} = (vox_count_difference/vox_count_template)*100;
        clear threshold vox_count_template vox_count_brainmask vox_count_difference
         
        % Load PSC
        load_name = fullfile(qc_dir, [list_subjs(sub).name, '_', task_name, ...
                             '_PSC_ref_', ref_roi_name]);
        load(load_name, 'min_percent_diff',  'max_percent_diff', ...
                        'mean_percent_diff', 'std_percent_diff');
        
        count = 16;
        % Populate results into summary_qc
        for roi = 1:num_target_rois
            count = count + 1;
            summary_qc{sub, count} = min_percent_diff(roi);
            count = count + 1;
            summary_qc{sub, count} = max_percent_diff(roi);
            count = count + 1;
            summary_qc{sub, count} = mean_percent_diff(roi);
            count = count + 1;
            summary_qc{sub, count} = std_percent_diff(roi);
        end
    end
end

%% Save as csv and mat files
summary_qc = cell2table(summary_qc, 'VariableNames', header);
save_name = fullfile(data_dir, ['summary_fMRI_QC_', task_name, '_', ...
                     datestr(now, 'ddmmmyyyy'), '.mat']);
save(save_name, 'summary_qc');
save_name = fullfile(data_dir, ['summary_fMRI_QC_', task_name, '_', ...
                     datestr(now, 'ddmmmyyyy'), '.csv']);
writetable(summary_qc, save_name);