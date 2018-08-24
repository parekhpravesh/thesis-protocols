function qc_fmri_explore_motion(data_dir, task_name, full_bids)
% Function to run motion correction using different methods
%% Inputs:
% data_dir:         full path to a directory having sub-* folders (BIDS
%                   style; see Notes)
% task_name:        functional file name pattern for which QC is being 
%                   performed (example: 'rest')
% full_bids:        yes/no to indicate if the data_dir is a full BIDS style
%                   folder (i.e. it has anat and func sub-folders) or all 
%                   files are present in a single folder (see Notes)
% 
%% Outputs:
% Within the already existing 'quality_check_<task_name>' in each subject's
% folder, following files are written out for FD, DVARS, and RMS methods:
% a text file having the motion profile
% a text file having the outliers
% a log file having log from command execution
% a png file having plot created by FSL
% all files are named as <subject_ID>_<task_name>_<method>.<txt/.png>
%
%% Notes:
% Each sub-* folder should have a quality_check_<task_name> folder (created
% by qc_fmri_roi_signal)
% 
% Full BIDS specification means that there are separate anat and func
% folders inside the subject folder; if specified as no, the files should
% still be named following BIDS specification but all files are assumed to
% be in the same folder
% 
% Requires FSL
% 
%% Default:
% full_bids:        'yes'
% 
%% Author(s)
% Parekh, Pravesh
% August 24, 2018
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
        
        % Locate EPI file for this subject
        if full_bids
            epi_dir = fullfile(data_dir, list_subjs(sub).name, 'func');
        else
            epi_dir = fullfile(data_dir, list_subjs(sub).name);
        end
        cd(epi_dir);
        list_func_files = dir([list_subjs(sub).name, '_task-', task_name, '_bold.nii']);
        
         % Remove any files which got listed and are not 4D files
         idx = false(length(list_func_files),1);
         for files = 1:length(list_func_files)
             vol = spm_vol(list_func_files(files).name);
             if size(vol,1) == 1
                 idx(files) = 1;
             end
         end
         list_func_files(idx) = [];
         
         % If none or multiple files exist, show warning and skip this subject
         if isempty(list_func_files)
             warning(['No matching files found for ', list_subjs(sub).name, '; skipping']);
             skip = 1;
         else
             if length(list_func_files) > 1
                 warning(['Multiple files found for ', list_subjs(sub).name, '; skipping']);
                 skip = 1;
             else
                 skip = 0;
             end
         end

         if ~skip
             % Move the file into the quality_check folder
             list_func_files = list_func_files(1).name;
             copyfile(fullfile(epi_dir, list_func_files), qc_dir);
             prefix = [list_subjs(sub).name, '_', task_name];

             %% RMS intensity difference of volume N to reference volume
             command = ['fsl_motion_outliers -i ', ...
                        fullfile(qc_dir, list_func_files),             ' -o ', ...
                        fullfile(qc_dir, [prefix, '_refRMS_var.txt']), ' -s ', ...
                        fullfile(qc_dir, [prefix, '_refRMS.txt']),     ' -p ', ...
                        fullfile(qc_dir, [prefix, '_refRMS.png']),     ' --refrms -v >> ', ...
                        fullfile(qc_dir, [prefix, '_refRMS_log.txt'])];
             system(command);

             %% DVARS
             command = ['fsl_motion_outliers -i ', ...
                        fullfile(qc_dir, list_func_files),            ' -o ', ...
                        fullfile(qc_dir, [prefix, '_DVARS_var.txt']), ' -s ', ...
                        fullfile(qc_dir, [prefix, '_DVARS.txt']),     ' -p ', ...
                        fullfile(qc_dir, [prefix, '_DVARS.png']),     ' --dvars -v >> ', ...
                        fullfile(qc_dir, [prefix, '_DVARS_log.txt'])];
             system(command);

             %% Framewise displacement (FD)
             command = ['fsl_motion_outliers -i ', ...
                        fullfile(qc_dir, list_func_files),         ' -o ', ...
                        fullfile(qc_dir, [prefix, '_FD_var.txt']), ' -s ', ...
                        fullfile(qc_dir, [prefix, '_FD.txt']),     ' -p ', ...
                        fullfile(qc_dir, [prefix, '_FD.png']),     ' --fd -v >> ', ...
                        fullfile(qc_dir, [prefix, '_FD_log.txt'])];
             system(command);

             %% Delete the functional file from quality_check folder
             delete(fullfile(qc_dir, list_func_files));

             % Clear some variables
             clear prefix list_func_files epi_dir qc_dir idx vol
         end
    end
end