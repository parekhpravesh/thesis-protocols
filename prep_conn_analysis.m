function prep_conn_analysis(analysis_dir)
% Function to setup connectivity analysis using Conn
%% Input:
% analysis_dir:     full path to analysis directory
%
%% Outputs:
% Conn projects are created in the 'func_connectivity' sub-folder inside
% analysis_dir; additionally, a summary file is written in
% <analysis_dir>/summary named summary_prep_conn_analysis_ddmmmyyyy.txt
%
%% Notes:
% Assumes analysis_dir (minimal) structre:
%
% <analysis_dir>/
%
%   anat/
%       mri_mni/
%           <contains normalized segmentations and T1 file created by
%           normalize_cat_output>
%
%   func_preprocess/
%       <sub-xxxx>/
%           <task-task_name>/
%               <wusub-xxxx_task-task_name_1_bold.nii>
%               <swusub-xxxx_task-task_name_1_bold.nii>
%               <rp_*.txt>
%               <other preprocessing files>
%           <task-task_name>/
%               <wusub-xxxx_task-task_name_1_bold.nii>
%               <swusub-xxxx_task-task_name_1_bold.nii>
%               <rp_*.txt>
%               <other preprocessing files>
%       <sub-xxxx>/
%
%   rois/
%       <task_name_1>/
%           <rois for task 1>
%       <task_name_2>/
%           <rois for task 2>
%
%% Author(s):
% Parekh, Pravesh
% March 31, 2018
% MBIAL

%% Check basic structure of analysis_dir
if ~exist(analysis_dir, 'dir')
    error('Analysis directory not found');
end

% Check if anat folder exists
if ~exist(fullfile(analysis_dir, 'anat'), 'dir')
    error('anat directory not found');
end

% Check if func_preprocess folder exists
if ~exist(fullfile(analysis_dir, 'func_preprocess'), 'dir')
    error('func_preprocess directory not found')
end

% Check if mri directory exists inside anat folder
if ~exist(fullfile(analysis_dir, 'anat', 'mri_mni'), 'dir')
    error('mri_mni directory not found');
end

%% Prepare summary file
% Create summary folder if it does not exist
if ~exist(fullfile(analysis_dir, 'summary'), 'dir')
    mkdir(fullfile(analysis_dir, 'summary'));
end

% Name summary file
summary_loc = fullfile(analysis_dir, 'summary', ...
    ['summary_prep_conn_analysis', datestr(now, 'ddmmmyyyy'), '.txt']);

% Check if file exists; if yes, append; else create a new one
if exist(summary_loc, 'file')
    fid_summary = fopen(summary_loc, 'a');
else
    fid_summary = fopen(summary_loc, 'w');
end

% Save some information
fprintf(fid_summary, '%s\r\n', ['Date:         ', datestr(now, 'ddmmmyyyy')]);
fprintf(fid_summary, '%s\r\n', ['Time:         ', datestr(now, 'HH:MM:SS PM')]);
fprintf(fid_summary, '%s\r\n', ['analysis_dir: ', analysis_dir]);

% Create func_connectivity folder in analysis_dir
if ~exist(fullfile(analysis_dir, 'func_connectivity'), 'dir')
    mkdir(fullfile(analysis_dir, 'func_connectivity'));
end

%% Parse analysis_dir
cd(fullfile(analysis_dir, 'anat', 'mri_mni'));

% Create a list of subjects for which skull-stripped T1w is present
list_files = dir('wp0*.nii');
list_subjs = cell(length(list_files),1);

% Create subject list
for subj = 1:length(list_files)
    tmp = list_files(subj).name;
    tmp = regexprep(tmp, {'wp0', '_T1w', '.nii'}, '');
    list_subjs{subj} = tmp;
end
num_subjs = length(list_subjs);

% Update summary
disp([num2str(num_subjs), ' T1w scans found']);
fprintf(fid_summary, '%s\n', [num2str(num_subjs), ' T1w scans found']);

% Create a list of all task folders which exist in func_preprocess folder
cd(fullfile(analysis_dir, 'func_preprocess'));
list_tasks = dir([pwd, '\**\task-*']);

% Find unique tasks
unique_tasks = unique({list_tasks(:).name});
num_tasks    = length(unique_tasks);

% Initialize
subj_str = false(num_subjs, num_tasks);

% Loop over each subject and find tasks which exist
for subj = 1:num_subjs
    
    % Find all task folders for this subject
    cd(fullfile(analysis_dir, 'func_preprocess', list_subjs{subj}));
    subj_task_list = dir('task-*');
    subj_task_list = {subj_task_list(:).name};
    
    % Find which tasks are present for this subject
    [~,~,tmp_loc] = intersect(subj_task_list, unique_tasks);
    subj_str(subj,tmp_loc) = 1;
end

% Number of subjects for each task
num_subjs_tasks = sum(subj_str);

% Update summary with number of subjects found for each task; also make
% task folders in func_connectivity folder
for task = 1:num_tasks
    
    % Update summary
    disp(['Task: ', unique_tasks{task}, '        ', ...
        num2str(num_subjs_tasks(task)), ' subjects']);
    fprintf(fid_summary, '%s\n', ['Task: ', unique_tasks{task}, '        ', ...
        num2str(num_subjs_tasks(task)), ' subjects']);
    
    % Make task folders
    if ~exist(fullfile(analysis_dir, 'func_connectivity', unique_tasks{task}), 'dir')
        mkdir(fullfile(analysis_dir, 'func_connectivity', unique_tasks{task}));
    end
    
end

%% Loop over tasks and create batch
for task = 1:num_tasks
    
    % switch(unique_tasks{task})
    % case 'vft_classic'
    
    % Conn project name
    BATCH.filename = fullfile(analysis_dir, 'func_connectivity',...
        unique_tasks{task}, ['conn_', unique_tasks{task}, '.mat']);
    
    % Number of subjects
    BATCH.Setup.nsubjects = num_subjs_tasks(task);
    
    % Number of sessions
    BATCH.Setup.nsessions = num2cell(ones(num_subjs_tasks(task),2));
    
    % Spatial resolution
    BATCH.Setup.spatialresolution = 1;
    
    % Analysis mask
    BATCH.Setup.analysismask = 1;
    
    % Analysis units
    BATCH.Setup.analysisunits = 1;
    
    % Output files
    BATCH.Setup.outputfiles = [1,1,1,1,1,1];
    
    % Specify functional and structural volumes, gray, white,
    % and CSF masks, and ROI files
    BATCH.Setup.functionals = cell(num_subjs_tasks(task),1);
    for subj = 1:num_subjs_tasks(task)
        % Check if the subject has the task present
        if subj_str(task,subj)
            
            % Specify functional volume
            BATCH.Setup.functionals{subj}{1} = ...
                fullfile(analysis_dir, 'func_preprocess', ...
                list_subjs{subj}, unique_tasks{task}, ...
                ['swu', list_subjs{subj}, '_', ...
                unique_tasks{task}, '_bold.nii']);
            
            % Specify structural volume
            BATCH.Setup.structurals{subj} = ...
                fullfile(analysis_dir, 'anat', 'mri_mni', ...
                ['wp0', list_subjs{subj}, '_T1w.nii']);
            
            % Specify gray matter roi file and dimensions
            BATCH.Setup.masks.Grey.files{subj} = ...
                fullfile(analysis_dir, 'anat', 'mri_mni', ...
                ['wp1', list_subjs{subj}, '_T1w.nii']);
            BATCH.Setup.masks.Grey.dimensions = 1;
            
            % Specify white matter mask file and dimensions
            BATCH.Setup.masks.White.files{subj} = ...
                fullfile(analysis_dir, 'anat', 'mri_mni', ...
                ['wp2', list_subjs{subj}, '_T1w.nii']);
            BATCH.Setup.masks.White.dimensions = 16;
            
            % Specify CSF mask file and dimensions
            BATCH.Setup.masks.CSF.files{subj} = ...
                fullfile(analysis_dir, 'anat', 'mri_mni', ...
                ['wp3', list_subjs{subj}, '_T1w.nii']);
            BATCH.Setup.masks.CSF.dimensions = 16;
            
            % Specifying ROI files
            % Check if ROI directory exists
            if exist(fullfile(analysis_dir, 'rois', unique_tasks{task}), 'dir')
                
                % Get all ROIs for this task
                cd(fullfile(analysis_dir, 'rois', unique_tasks{task}));
                list_rois  = dir('*.nii');
                list_rois  = {list_rois(:).name};
                names_rois = regexprep(list_rois, '.nii', '');
                num_rois   = length(list_rois);
                
                % Specify ROI names and dimensions
                BATCH.Setup.rois.names = names_rois;
                BATCH.Setup.rois.dimensions = num2cell(ones(1,2));
                
                BATCH.Setup.rois.files = cell(1,num_rois);
                % Loop over each ROI
                for roi = 1:num_rois
                    BATCH.Setup.rois.files{roi} = ...
                        fullfile(analysis_dir, 'rois', ...
                        unique_tasks{task}, list_rois{roi});
                end
            end
        end
    end
    
    % Based on task name get conditions, specify RT, and acquisition type
    switch(unique_tasks{task})
        case 'task-vft_classic'
            % Specify RT = 4
            BATCH.Setup.RT = repmat(4,num_subjs_tasks(task),1);
            
            % Get task design
            BATCH.Setup.conditions = ...
                get_fmri_task_design_conn('vft_classic', ...
                num_subjs_tasks(task));
            
            % Acquisition Type = sparse
            BATCH.Setup.acquisitiontype = 0;
            
        case 'task-vft_modern'
            % Specify RT = 4
            BATCH.Setup.RT = repmat(4,num_subjs_tasks(task),1);
            
            % Get task design
            BATCH.Setup.conditions = ...
                get_fmri_task_design_conn('vft_modern', ...
                num_subjs_tasks(task));
            
            % Acquisition Type = sparse
            BATCH.Setup.acquisitiontype = 0;
            
        case 'task-pm'
            % Specify RT = 3
            BATCH.Setup.RT = repmat(3,num_subjs_tasks(task),1);
            
            % Get task design
            BATCH.Setup.conditions = ...
                get_fmri_task_design_conn('pm', ...
                num_subjs_tasks(task));
            
            % Acquisition Type = continuous
            BATCH.Setup.acquisitiontype = 1;
            
        case 'task-hamt_hs'
            % Specify RT = 3
            BATCH.Setup.RT = repmat(4,num_subjs_tasks(task),1);
            
            % Get task design
            BATCH.Setup.conditions = ...
                get_fmri_task_design_conn('hamt_hs', ...
                num_subjs_tasks(task));
            
            % Acquisition Type = continuous
            BATCH.Setup.acquisitiontype = 1;
            
        case 'task-hamt_sz'
            % Specify RT = 3
            BATCH.Setup.RT = repmat(4,num_subjs_tasks(task),1);
            
            % Get task design
            BATCH.Setup.conditions = ...
                get_fmri_task_design_conn('hamt_sz', ...
                num_subjs_tasks(task));
            
            % Acquisition Type = continuous
            BATCH.Setup.acquisitiontype = 1;
            
        case 'task-rest'
            % Specify RT = 3
            BATCH.Setup.RT = repmat(4,num_subjs_tasks(task),1);
            
            % Get task design
            BATCH.Setup.conditions = ...
                get_fmri_task_design_conn('rest', ...
                num_subjs_tasks(task));
            
            % Acquisition Type = continuous
            BATCH.Setup.acquisitiontype = 1;
    end
    
    % Specify isnew
    BATCH.Setup.isnew = 1;
    
    % Save BATCH
    save(fullfile(analysis_dir, 'func_connectivity', unique_tasks{task}, ...
        ['batch_conn_', unique_tasks{task}]), 'BATCH');
    
    % Update summary
    disp(['Creating batch for task: ', unique_tasks{task}, '...done!']);
    fprintf(fid_summary, '%s\n', ...
        ['Creating batch for task: ', unique_tasks{task}, '...done!']);
end

% Close summary file
fclose(fid_summary);