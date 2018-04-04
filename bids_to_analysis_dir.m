function bids_to_analysis_dir(bids_dir, analysis_dir)
% Function to reorganize bids_dir to analysis_dir style
%% Input:
% bids_dir:     full path to bids_dir
% analysis_dir: full path to where analysis_dir needs to be created
% 
%% Output:
% analysis_dir is created and files are copied in the appropriate location;
% a summary file is written in analysis_dir/summary named
% summary_bids_to_analysis_dir_ddmmmyyyy.txt
%
%% Notes:
% If files already exist in analysis_dir, then those files are skipped
%
% Assumes that all fmaps have already been associated with fMRI scans and
% any non required fmaps have been removed
% 
%% Default:
% If analysis_dir is not provided, it is created at one level above
% bids_dir
%
%% Author(s):
% Parekh, Pravesh
% April 03, 2018
% MBIAL

%% Check input and create bids_dir if needed
if ~exist('bids_dir', 'var')
    error('bids_dir needs to be provided');
else
    if ~exist(bids_dir, 'dir')
        error(['Cannot find bids_dir: ', bids_dir]);
    else
        if ~exist('analysis_dir', 'var')
            % Go a level above bids_dir and create analysis_dir
            cd(bids_dir);
            cd('..');
            analysis_dir = fullfile(pwd, 'analysis_dir');
            if ~exist('analysis_dir', 'dir')
                mkdir('analysis_dir');
            end
        else
            if ~exist(analysis_dir, 'dir')
                mkdir(analysis_dir);
            end
        end
    end
end

%% Create subject list
cd(bids_dir);
list_subjs = dir('sub-*');

% Remove any files that might have been listed
list_subjs(~[list_subjs.isdir]) = [];

% Convert to cell type and remove other structure fields
list_subjs = {list_subjs(:).name};

% Total number of subjects to work on
num_subjs = length(list_subjs);

%% Prepare summary file
% Create summary folder if it does not exist
if ~exist(fullfile(analysis_dir, 'summary'), 'dir')
    mkdir(fullfile(analysis_dir, 'summary'));
end

% Name summary file
summary_loc = fullfile(analysis_dir, 'summary', ...
    ['summary_bids_to_analysis_dir_', datestr(now, 'ddmmmyyyy'), '.txt']);

% Check if file exists; if yes, append; else create a new one
if exist(summary_loc, 'file')
    fid_summary = fopen(summary_loc, 'a');
else
    fid_summary = fopen(summary_loc, 'w');
end

% Save some information
fprintf(fid_summary, '%s\r\n', ['Date:         ', datestr(now, 'ddmmmyyyy')]);
fprintf(fid_summary, '%s\r\n', ['Time:         ', datestr(now, 'HH:MM:SS PM')]);
fprintf(fid_summary, '%s\r\n', ['bids_dir:     ', bids_dir]);
fprintf(fid_summary, '%s\r\n', ['analysis_dir: ', analysis_dir]);

% Update summary with number of subjects
disp([num2str(num_subjs), ' subjects found']);
fprintf(fid_summary, '%s\r\n', [num2str(num_subjs), ' subjects found']);

%% Create basic folder structure of analysis_dir
cd(analysis_dir);
mkdir('anat');
mkdir('func_preprocess');
mkdir('dwi');
mkdir(fullfile(analysis_dir, 'anat', 'str_files'));

%% Loop over subjects
for subj = 1:num_subjs
    
    % Update summary
    disp(['Working on: ', list_subjs{subj}]);
    fprintf(fid_summary, '\n%s\r\n', ['Working on: ', list_subjs{subj}]);
    
    %% Work on T1w scan
    source_file = fullfile(bids_dir, list_subjs{subj}, 'anat', ...
                  [list_subjs{subj}, '_T1w.nii']);
    dest_file   = fullfile(analysis_dir, 'anat', 'str_files', ...
                  [list_subjs{subj}, '_T1w.nii']);
    
    % Check if T1w scan is already present in dest_file
    if exist(dest_file, 'file')
        
        % Skip copying this file; update summary
        disp([list_subjs{subj}, '_T1w.nii already exists; skipping']);
        fprintf(fid_summary, '%s\r\n', [list_subjs{subj}, ...
            '_T1w.nii already exists; skipping']);
    else
        
        % Copy T1w file
        copyfile(source_file, dest_file);
        
        % Change filename to JSON file
        source_file = strrep(source_file, '.nii', '.json');
        dest_file   = strrep(dest_file,   '.nii', '.json');
        
        % Copy T1w JSON file
        copyfile(source_file, dest_file);
    end
    
    %% Work on fMRI files
    % Get list of tasks for this subject
    cd(fullfile(bids_dir, list_subjs{subj}, 'func'));
    list_tasks = dir('*task-*.nii');
    num_tasks  = length(list_tasks);
    
    % If subject folder exists in func_preprocess, skip subject
    if exist(fullfile(analysis_dir, 'func_preprocess', list_subjs{subj}), 'dir')
        
        % Update summary
        disp([list_subjs{subj}, 'folder exists in func_preprocess; skipping']);
        fprintf(fid_summary, '%s\r\n', [list_subjs{subj}, ...
            'folder exists in func_preprocess; skipping']);
        
    else
        
        % Make subject folder in func_preprocess
        mkdir(fullfile(analysis_dir, 'func_preprocess', list_subjs{subj}));
        
        % Loop over each task
        for task = 1:num_tasks
            
            % Create task sub folder in subject folder
            mkdir(fullfile(analysis_dir, 'func_preprocess', ...
                list_subjs{subj}, strrep(strrep(list_tasks(task).name, ...
                '.nii', ''), [list_subjs{subj}, '_'], '')));
            
            % Create source and destination file names
            source_file = fullfile(bids_dir, list_subjs{subj}, 'func', ...
                list_tasks(task).name);
            dest_file   = fullfile(analysis_dir, 'func_preprocess', ...
                list_subjs{subj}, strrep(strrep(list_tasks(task).name, ...
                '.nii', ''), [list_subjs{subj}, '_'], ''), ...
                list_tasks(task).name);
            
            % Copy file
            copyfile(source_file, dest_file);
            
            % Edit source and destination file names for JSON file
            source_file = strrep(source_file, '.nii', '.json');
            dest_file   = strrep(dest_file,   '.nii', '.json');
                    
            % Copy JSON file
            copyfile(source_file, dest_file);
        end
    end
    
    %% Work on fmaps
    cd(fullfile(bids_dir, list_subjs{subj}, 'fmap'));
    
    % Get a list of fmaps which have been associated with some tasks
    % i.e. acq-task_name
    list_fmaps = dir('*_acq-*_phase1.nii');
    
    % Loop over each fmap
    for task = 1:length(list_fmaps)
        
        % Get associated task name
        acq_name = strrep(strrep(strrep(list_fmaps(task).name, ...
                   list_subjs{subj}, ''), '_acq-', ''), '_phase1.nii', '');
         
        % Make fmap-acq_task_name folder
        mkdir(fullfile(analysis_dir, 'func_preprocess', list_subjs{subj}, ...
            ['fmap_acq-', acq_name]));
        
        % Create source and destination file names
        source_file = fullfile(bids_dir, list_subjs{subj}, 'fmap', ...
                      [list_subjs{subj}, '_acq-', acq_name, '_phase1.nii']);
        dest_file   = fullfile(analysis_dir, 'func_preprocess', ...
                      list_subjs{subj}, ['fmap_acq-', acq_name], ...
                      [list_subjs{subj}, '_acq-', acq_name, '_phase1.nii']);
                  
        % Copy phase1 file
        copyfile(source_file, dest_file);
        
        % Work on phase1 JSON file and copy
        source_file = strrep(source_file, '.nii', '.json');
        dest_file   = strrep(dest_file,   '.nii', '.json');
        copyfile(source_file, dest_file);
        
        % Work on phase2 JSON file and copy
        source_file = strrep(source_file, 'phase1', 'phase2');
        dest_file   = strrep(dest_file,   'phase1', 'phase2');
        copyfile(source_file, dest_file);
        
        % Work on phase2 NIfTI file and copy
        source_file = strrep(source_file, '.json', '.nii');
        dest_file   = strrep(dest_file,   '.json', '.nii');
        copyfile(source_file, dest_file);
        
        % Work on magnitude1 NIfTI file and copy
        source_file = strrep(source_file, 'phase2', 'magnitude1');
        dest_file   = strrep(dest_file,   'phase2', 'magnitude1');
        copyfile(source_file, dest_file);
        
        % Work on magnitude1 JSON file and copy
        source_file = strrep(source_file, '.nii', '.json');
        dest_file   = strrep(dest_file,   '.nii', '.json');
        copyfile(source_file, dest_file);
        
        % Work on magnitude2 JSON file and copy
        source_file = strrep(source_file, 'magnitude1', 'magnitude2');
        dest_file   = strrep(dest_file,   'magnitude1', 'magnitude2');
        copyfile(source_file, dest_file);
        
        % Work on magnitude2 NIfTI file and copy
        source_file = strrep(source_file, '.json', '.nii');
        dest_file   = strrep(dest_file,   '.json', '.nii');
        copyfile(source_file, dest_file);
    end
    
    %% Work on diffusion files
    cd(fullfile(bids_dir, list_subjs{subj}, 'dwi'));
    list_dwi_files = dir('*.nii');
    
    % Make subject folder
    mkdir(fullfile(analysis_dir, 'dwi', list_subjs{subj}));
    
    % Loop over each file and copy
    for file = 1:length(list_dwi_files)
        
        % Create source and destination file names
        source_file = fullfile(bids_dir, list_subjs{subj}, 'dwi', ...
            list_dwi_files(file).name);
        dest_file   = fullfile(analysis_dir, 'dwi', list_subjs{subj}, ...
            list_dwi_files(file).name);
        
        % Copy file
        copyfile(source_file, dest_file);
        
        % Edit source and destination file names for JSON file
        source_file = strrep(source_file, '.nii', '.json');
        dest_file   = strrep(dest_file,   '.nii', '.json');
        
        % Copy JSON file
        copyfile(source_file, dest_file);
    end
        
    % Update summary
    disp([list_subjs{subj}, '...done!']);
    fprintf(fid_summary, '%s\r\n', [list_subjs{subj}, '...done!']);
end

% Close summary file
fclose(fid_summary);
    