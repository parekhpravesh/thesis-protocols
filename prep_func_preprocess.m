function prep_func_preprocess(analysis_dir)
% Function to create preprocessing batch for various functional images
%% Inputs:
% analysis_dir:     fullpath to the analysis directory
%
%% Output:
% Preprocessing batch is created for each task type found in each subject
% directory; additionally, a summary file is written in
% <analysis_dir>/summary named summary_prep_func_preprocess_ddmmmyyyy.txt
% 
%% Notes:
% Assumes analysis_dir (minimal) structre:
% <analysis_dir>/
%   anat/
%       mri/
%           <contains forward deformation field calculated from CAT>
%   func_preprocess/
%       <sub-xxxx>/
%           <task-task_name>/
%               <sub-xxxx_task-task_name_1_bold.nii>
%           <task-task_name>/
%               <sub-xxxx_task-task_name_2_bold.nii>
%           <fmaps>/
%               <all fmap images and vdm files for all tasks>
%       <sub-xxxx>/
%
% voxel displacement maps are selected based on their file name; if the
% filename for any vdm contains the task name, that specific vdm is chosen
% for that task; if no vdm is found, none is selected
% 
% Batch is only created for subjects for whom deformation field is present
% in the <analysis_dir>/anat/mri directory
% 
%% Author(s)
% Parekh, Pravesh
% March 15, 2018
% MBIAL

%% Check analysis_dir and make list of subjects to process
if exist('analysis_dir', 'var')
    if exist(analysis_dir, 'dir')
        % Find mri folder
        if exist(fullfile(analysis_dir, 'anat', 'mri'), 'dir')
            % Make list of subjects for whom deformation field is present
            cd(fullfile(analysis_dir, 'anat', 'mri'));
            list_deforms    = dir('y_*.nii');
            list_subjs      = cell(length(list_deforms), 1);
            for i = 1:length(list_deforms)
                list_subjs{i} = regexprep(list_deforms(i).name, ...
                    {'_T1w', 'y_', '.nii'}, '');
            end
            num_subjs = length(list_subjs);
            disp([num2str(num_subjs), ' deformation fields found']);
        else
            error('mri folder not found');
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
summary_loc = fullfile(analysis_dir, 'summary', ...
    ['summary_prep_func_preprocess_', datestr(now, 'ddmmmyyyy'), '.txt']);

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
fprintf(fid_summary, '%s\r\n', [num2str(num_subjs), ' deformation fields found']);

%% Loop over subjects and create preprocessing batch
for subj = 1:num_subjs
    
    % Check if subject folder exists
    if ~exist(fullfile(analysis_dir, 'func_preprocess', list_subjs{subj}), 'dir')
        
        % Update summary and move on
        disp([list_subjs{subj}, '...not found in func_preprocess...skipping']);
        fprintf(fid_summary, '%s', [list_subjs{subj}, '...not found in func_preprocess...skipping']);
        continue;
    else
        
         % Go to subject folder in the func_preprocess folder 
        cd(fullfile(analysis_dir, 'func_preprocess', list_subjs{subj}));
        
        % Get list of tasks
        list_tasks = dir('task-*');
        
         % Number of tasks
        num_tasks = length(list_tasks);
        
        % Update summary with task information
        disp([list_subjs{subj}, '...', num2str(num_tasks), ' tasks found']);
        fprintf(fid_summary, '%s', [list_subjs{subj}, '...', num2str(num_tasks), ' tasks found']);
        
        % Make a list of tasks and associated fieldmaps
        task_fmap = cell(num_tasks, 2);
        
        % List of tasks
        for task = 1:num_tasks
            task_fmap{task,1} = list_tasks(task).name(...
                strfind(list_tasks(task).name,'task-'):end);
        end
        
        % Create list of fieldmaps by checking existing vdm files created
        % by create_vdm script
        cd(fullfile(analysis_dir, 'func_preprocess', list_subjs{subj}, 'fmaps'));
        list_fmaps = dir('vdm5*.nii');
        num_fmaps  = length(list_fmaps);
        
        % Update summary with fieldmap information
        disp([list_subjs{subj}, '...', num2str(num_fmaps), ' vdms found']);
        fprintf(fid_summary, '%s', [list_subjs{subj}, '...', num2str(num_fmaps), ' vdms found']);
        
        % Associate vdms to tasks
        for fmap = 1:num_fmaps
            
            % Get task name from vdm file name
            tmp = strsplit(list_fmaps(fmap).name, {'_', '.'});
            if length(tmp) == 5
                tmp = tmp{4};
            else
                tmp = tmp{5};
            end
            
            % Find where this task is in task_fmap and assign the name
            tmp2 = strcmpi(task_fmap(:,1), ['task-', tmp]);
            
            if isempty(find(tmp2,1))
                % Task not found; skip this vdm
                continue
            else
                task_fmap{tmp2,2} = list_fmaps(fmap).name;
            end

        end
        
        % Assign empty to remaining tasks (i.e. no vdms for these tasks)
        for i = 1:num_tasks
            if isempty(task_fmap{i,2})
                task_fmap{i,2} = '';
            end
        end
                 
        % Loop over each task
        for task = 1:num_tasks
            cd(fullfile(analysis_dir, 'func_preprocess', ...
                list_subjs{subj}, list_tasks(task).name));
            
            % Get relevant functional file
            func_file = dir(['*', task_fmap{task,1}, '*.nii']);
            
            % Make sure that a single func_file is found
            if length(func_file) > 1
                
                % Update summary and skip task
                 disp([list_subjs{subj},     '...multiple functional files for task: ', task_fmap{task,1}, '...skipping task']);
                 fprintf(fid_summary, '%s', ['...multiple functional files for task: ', task_fmap{task,1}, '...skipping task']);
                continue
            end
            
            % Define functional scans for this task
            % Read the file and get number of volumes
            vol = spm_vol(fullfile(analysis_dir, 'func_preprocess', ...
                list_subjs{subj}, list_tasks(task).name, func_file(1).name));
            num_vol = length(vol);
            
            func_files = cell(num_vol,1);
            % Loop over each volume and create list of functionals
            for volumes = 1:num_vol
                func_files(volumes,1) = {fullfile(analysis_dir, ...
                    'func_preprocess', list_subjs{subj}, ...
                    list_tasks(task).name, [func_file(1).name, ',', num2str(volumes)])};
            end
            
            % Define vdm file for this task
            vdm_file = {fullfile(analysis_dir, 'func_preprocess', ...
                list_subjs{subj}, 'fmaps',  [task_fmap{task,2}, ',1'])};
            
            % Define anatomical file for this task
            anat_file  = {fullfile(analysis_dir, 'anat', 'str_files', [list_subjs{subj}, '_T1w.nii'])};
            
            % Define deformation field for this task
            defor_file = {fullfile(analysis_dir, 'anat', 'mri', ['y_', list_subjs{subj}, '_T1w.nii'])};
            
            %% Create batch
            % Realign and unwarp
            matlabbatch{1}.spm.spatial.realignunwarp.data.scans             = func_files;
            matlabbatch{1}.spm.spatial.realignunwarp.data.pmscan            = vdm_file;
            matlabbatch{1}.spm.spatial.realignunwarp.eoptions.quality       = 0.9;
            matlabbatch{1}.spm.spatial.realignunwarp.eoptions.sep           = 4;
            matlabbatch{1}.spm.spatial.realignunwarp.eoptions.fwhm          = 5;
            matlabbatch{1}.spm.spatial.realignunwarp.eoptions.rtm           = 0;
            matlabbatch{1}.spm.spatial.realignunwarp.eoptions.einterp       = 7;
            matlabbatch{1}.spm.spatial.realignunwarp.eoptions.ewrap         = [0 0 0];
            matlabbatch{1}.spm.spatial.realignunwarp.eoptions.weight        = '';
            matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.basfcn      = [12 12];
            matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.regorder    = 1;
            matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.lambda      = 100000;
            matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.jm          = 0;
            matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.fot         = [4 5];
            matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.sot         = [];
            matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.uwfwhm      = 4;
            matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.rem         = 1;
            matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.noi         = 5;
            matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.expround    = 'Average';
            matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.uwwhich     = [2 1];
            matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.rinterp     = 7;
            matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.wrap        = [0 0 0];
            matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.mask        = 1;
            matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.prefix      = 'u';
            
            % Coregister
            matlabbatch{2}.spm.spatial.coreg.estimate.ref                   = anat_file;
            matlabbatch{2}.spm.spatial.coreg.estimate.source(1)             = cfg_dep('Realign & Unwarp: Unwarped Mean Image', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','meanuwr'));
            matlabbatch{2}.spm.spatial.coreg.estimate.other(1)              = cfg_dep('Realign & Unwarp: Unwarped Images (Sess 1)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','sess', '()',{1}, '.','uwrfiles'));
            matlabbatch{2}.spm.spatial.coreg.estimate.eoptions.cost_fun     = 'nmi';
            matlabbatch{2}.spm.spatial.coreg.estimate.eoptions.sep          = [4 2];
            matlabbatch{2}.spm.spatial.coreg.estimate.eoptions.tol          = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
            matlabbatch{2}.spm.spatial.coreg.estimate.eoptions.fwhm         = [7 7];
            
            % Normalize functionals
            matlabbatch{3}.spm.spatial.normalise.write.subj.def             = defor_file;
            matlabbatch{3}.spm.spatial.normalise.write.subj.resample(1)     = cfg_dep('Coregister: Estimate: Coregistered Images', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','cfiles'));
            matlabbatch{3}.spm.spatial.normalise.write.woptions.bb          = [NaN NaN NaN
                                                                               NaN NaN NaN];
            matlabbatch{3}.spm.spatial.normalise.write.woptions.vox         = [2 2 2];
            matlabbatch{3}.spm.spatial.normalise.write.woptions.interp      = 7;
            matlabbatch{3}.spm.spatial.normalise.write.woptions.prefix      = 'w';
            
            % Smoothing by 6 mm
            matlabbatch{4}.spm.spatial.smooth.data(1)                       = cfg_dep('Normalise: Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
            matlabbatch{4}.spm.spatial.smooth.fwhm                          = [6 6 6];
            matlabbatch{4}.spm.spatial.smooth.dtype                         = 0;
            matlabbatch{4}.spm.spatial.smooth.im                            = 0;
            matlabbatch{4}.spm.spatial.smooth.prefix                        = 's';
            
            % Save batch
            save(fullfile(analysis_dir, 'func_preprocess', list_subjs{subj}, ...
                    list_tasks(task).name, ['batch_preprocess_', ...
                    task_fmap{task,1}, '.mat']), 'matlabbatch');
                
            % Update summary
            disp([list_subjs{subj},  '...creation of batch for task: ', task_fmap{task,1}, '...done!']);
            fprintf(fid_summary, '%s',   ['...creation of batch for task: ', task_fmap{task,1}, '...done!']);
            
            clear matlabbatch
        end
    end
end

% Close summary file
fclose(fid_summary);