function batch_reorient(analysis_dir)
% Function that applies reorientation matrix (calculated from ACPC
% alignment - SPM) to all functional and fieldmap images (original files
% are overwritten)
%% Inputs:
% analysis_dir:     fullpath to the analysis directory
%
%% Output:
% Images are reoriented (original files are overwritten); batch files for
% each subject and each modality/task is also saved; a summary file is
% created in the <analysis_dir>/summary folder named
% summary_reorient_ddmmmyyyy.txt
%
%% Notes:
% Assumes analysis_dir (minimal) structre:
% <analysis_dir>/
%   anat/
%       reorient/
%           <all reorientation matrices are saved here>
%   func_preprocess/
%       <sub-xxxx>/
%           <task-task_name>/
%               <sub-xxxx_task-task_name_1_bold.nii>
%           <task-task_name>/
%               <sub-xxxx_task-task_name_2_bold.nii>
%           <fmap-acq_task_name>/
%               <all fmap images and vdm file>
%           <fmap>/
%               <all fmap images and vdm file>
%       <sub-xxxx>/
%
%% Author(s)
% Parekh, Pravesh
% March 14, 2018
% MBIAL

%% Check analysis_dir and make list of subjects to process
if exist('analysis_dir', 'var')
    if exist(analysis_dir, 'dir')
        % Find reorient folder
        if exist(fullfile(analysis_dir, 'anat', 'reorient'), 'dir')
            % Make list of subjects to reorient
            cd(fullfile(analysis_dir, 'anat', 'reorient'));
            list_mat   = dir('*.mat');
            list_subjs = cell(length(list_mat), 1);
            for i = 1:length(list_mat)
                list_subjs{i} = regexprep(list_mat(i).name, ...
                    {'_T1w', '_reorient.mat'}, '');
            end
            num_subjs = length(list_subjs);
            disp([num2str(num_subjs), ' reorient matrices found']);
        else
            error('reorient folder not found');
        end
    else
        error([analysis_dir, ' not found']);
    end
else
    error('analysis_dir must be provided');
end

%% Prepare summary file

% Create summary folder if it does not exist
if ~exist(fullfile(analysis_dir, 'summary'), 'dir')
    mkdir(fullfile(analysis_dir, 'summary'));
end

% Name summary file
summary_loc = fullfile(analysis_dir, 'summary', ['summary_reorient_', ...
    datestr(now, 'ddmmmyyyy'), '.txt']);

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
fprintf(fid_summary, '%s\r\n', [num2str(num_subjs), ' reorient matrices found']);

% Initialize SPM batch interface system
spm_jobman('initcfg');

%% Loop over subjects and apply reorientation matrices
for subj = 1:num_subjs
    
    % Check if subject folder exists
    if ~exist(fullfile(analysis_dir, 'func_preprocess', list_subjs{subj}), 'dir')
        
        % Update summary and move on
        disp([list_subjs{subj}, '...not found in func_preprocess...skipping']);
        fprintf(fid_summary, '%s', [list_subjs{subj}, '...not found in func_preprocess...skipping']);
        continue;
    else
        
        % Location of reorientation matrix
        reorient_mat  = fullfile(analysis_dir, 'anat', 'reorient', list_mat(subj).name);
        
        % Go to func_preprocess folder
        cd(fullfile(analysis_dir, 'func_preprocess', list_subjs{subj}));
        
        % Get list of tasks and fmaps
        list_tasks = dir('task-*');
        list_fmaps = dir('fmap*');
        
        % Number of tasks and fmaps
        num_tasks = length(list_tasks);
        num_fmaps = length(list_fmaps);
        
        % Update summary with task information
        disp([list_subjs{subj}, '...', num2str(num_tasks), ' tasks found']);
        fprintf(fid_summary, '%s', [list_subjs{subj}, '...', num2str(num_tasks), ' tasks found']);
        
        % Update summary with fmap information
        disp([list_subjs{subj},     '...', num2str(num_fmaps), ' fieldmaps found']);
        fprintf(fid_summary, '%s', ['...', num2str(num_tasks), ' fieldmaps found']);
        
        % Loop over each task
        for task = 1:num_tasks
            cd(fullfile(analysis_dir, 'func_preprocess', ...
                list_subjs{subj}, list_tasks(task).name));
            
            % All files present in the directory will be reoriented
            list_files = dir('*.nii');
            
            % Update summary
            disp([list_subjs{subj},     '...', num2str(length(list_files)), ...
                ' images found for ', list_tasks(task).name]);
            fprintf(fid_summary, '%s', ['...', num2str(length(list_files)), ...
                ' images found for ', list_tasks(task).name]);
            
            % Loop over each file
            for files = 1:length(list_files)
                
                % Read the file and get number of volumes
                vol = spm_vol(fullfile(analysis_dir, 'func_preprocess', ...
                    list_subjs{subj}, list_tasks(task).name, ...
                    list_files(files).name));
                num_vol = length(vol);
                
                % Update summary
                disp([list_subjs{subj},     '...', num2str(num_vol), ...
                    ' volumes found for ', list_tasks(task).name, ':', ...
                    list_files(files).name]);
                fprintf(fid_summary, '%s', ['...', num2str(num_vol), ...
                    ' volumes found for ', list_tasks(task).name, ':', ...
                    list_files(files).name]);
                
                % Loop over each volume and create entry for batch
                for volumes = 1:num_vol
                    matlabbatch{1}.spm.util.reorient.srcfiles(volumes,1) = ...
                        {[fullfile(analysis_dir, 'func_preprocess', ...
                        list_subjs{subj}, list_tasks(task).name, ...
                        list_files(files).name), ',', num2str(volumes)]};
                end
                
                matlabbatch{1}.spm.util.reorient.transform.transF = {reorient_mat};
                matlabbatch{1}.spm.util.reorient.prefix           = '';
                
                % Save batch
                save(fullfile(analysis_dir, 'func_preprocess', ...
                    list_subjs{subj}, list_tasks(task).name, ...
                    ['reorient_', list_files(files).name, '.mat']), ...
                    'matlabbatch');
                
                % Run batch
                spm_jobman('run', matlabbatch);
                
                % Update summary
                disp([list_subjs{subj},     '...reoriented ', ...
                    list_tasks(task).name, ': ', list_files(files).name]);
                fprintf(fid_summary, '%s', ['...reoriented ', ...
                    list_tasks(task).name, ': ', list_files(files).name]);
                
                clear matlabbatch
            end
        end
        
        % Loop over each fieldmap
        for fmap = 1:num_fmaps
            cd(fullfile(analysis_dir, 'func_preprocess', ...
                list_subjs{subj}, list_fmaps(fmap).name));
            
            % All files present in the directory will be reoriented
            list_files = dir('*.nii');
            
            % Update summary
            disp([list_subjs{subj},     '...', num2str(length(list_files)), ...
                ' images found for ', list_fmaps(fmap).name]);
            fprintf(fid_summary, '%s', ['...', num2str(length(list_files)), ...
                ' images found for ', list_fmaps(fmap).name]);
            
            % Loop over each file
            for files = 1:length(list_files)
                
                % Read the file and get number of volumes
                vol     = spm_vol(fullfile(analysis_dir, 'func_preprocess', ...
                    list_subjs{subj}, list_fmaps(fmap).name, ...
                    list_files(files).name));
                num_vol = length(vol);
                
                % Update summary
                disp([list_subjs{subj},     '...', num2str(num_vol), ...
                    ' volumes found for ', list_fmaps(fmap).name, ':', ...
                    list_files(files).name]);
                fprintf(fid_summary, '%s', ['...', num2str(num_vol), ...
                    ' volumes found for ', list_fmaps(fmap).name, ':', ...
                    list_files(files).name]);
                
                % Loop over each volume and create entry for batch
                for volumes = 1:num_vol
                    matlabbatch{1}.spm.util.reorient.srcfiles(volumes,1) = ...
                        {[fullfile(analysis_dir, 'func_preprocess', ...
                        list_subjs{subj}, list_fmaps(fmap).name, ...
                        list_files(files).name), ',', num2str(volumes)]};
                end
                
                matlabbatch{1}.spm.util.reorient.transform.transF = {reorient_mat};
                matlabbatch{1}.spm.util.reorient.prefix           = '';
                
                % Save batch
                save(fullfile(analysis_dir, 'func_preprocess', ...
                    list_subjs{subj}, list_fmaps(fmap).name, ...
                    ['reorient_', list_files(files).name, '.mat']), ...
                    'matlabbatch');
                
                % Run batch
                spm_jobman('run', matlabbatch);
                
                % Update summary
                disp([list_subjs{subj},     '...reoriented ', ...
                    list_fmaps(fmap).name, ': ', list_files(files).name]);
                fprintf(fid_summary, '%s', ['...reoriented ', ...
                    list_fmaps(fmap).name, ': ', list_files(files).name]);
                
                clear matlabbatch
            end
        end
    end
    
    % Print new line in summary file
    fprintf(fid_summary, '\r\n');
end

% Print new line in summary file
fprintf(fid_summary, '\r\n');

% Close summary file
fclose(fid_summary);