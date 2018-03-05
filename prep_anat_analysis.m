function prep_anat_analysis(bids_folder, out_dir)
% Function to copy all anatomical scans, the .json file, and the
% reorientation matrix to the output directory; the files are renamed as
% sub-xxxx_T1w.nii
%% Inputs:
% bids_folder:    fullpath to BIDS directory
% out_dir:        fullpath to where T1 scans are to be copied
%
%% Output:
% T1w files will be copied to out_dir and renamed as sub-xxxx_T1w.nii
% (sub-xxxx tag is taken from the bids_folder); JSON sidecar and
% reorientation matrix (if present) will also be copied and similarly
% renamed.
% A log is also created in the out_dir with the name
% summary_prep_anat_analysis_ddmmmyyyy.txt
%
%% Notes:
% If multiple T1w files are found, the subject is skipped
%
%% Author(s):
% Parekh, Pravesh
% March 05, 2018
% MBIAL

%% Check inputs
if ~exist(bids_folder, 'dir')
    error([bids_folder, ' not found']);
end

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

%% Process list of subjects
cd(bids_folder);
list_subjs = dir('sub-*');
num_subjs  = length(list_subjs);
disp([num2str(num_subjs), ' subjects found']);

%% Prepare summary file
summary_name = fullfile(out_dir, ['summary_prep_anat_analysis_', ...
               datestr(now, 'ddmmmyyyy'), '.txt']);
if exist(summary_name, 'file')
    fid_summary = fopen(summary_name, 'a');
else
    fid_summary = fopen(summary_name, 'w');
end

% Print some summary information
fprintf(fid_summary, '%s\r\n', ['Date:         ', datestr(now, 'ddmmmyyyy')]);
fprintf(fid_summary, '%s\r\n', ['Time:         ', datestr(now, 'HH:MM:SS PM')]);
fprintf(fid_summary, '%s\r\n', ['bids_dir:     ', bids_folder]);
fprintf(fid_summary, '%s\r\n', ['out_dir:      ', out_dir]);
fprintf(fid_summary, '%s\r\n', [num2str(num_subjs), ' subjects found']);

%% Loop over subjects and copy out files
for subj = 1:num_subjs
    
    % Go to subject anat folder
    cd(fullfile(bids_folder, list_subjs(subj).name, 'anat'));
    
    % Find all T1w files
    list_T1_files = dir('*_T1w.nii');
    
    % If file not found, update summary and move on
    if isempty(list_T1_file)
        disp([list_subjs(subj).name, '...T1w file not found...skipped']);
        fprintf(fid_summary, '%s\r\n', [list_subjs(subj).name, '...T1w file not found...skipped']);
        continue
    else
        % Check if multiple T1w files are present
        if isempty(list_T1_files)
            
            % Display summary and move on
            disp([list_subjs(subj).name, '...multiple T1w files found...skipped']);
            fprintf(fid_summary, '%s\r\n', [list_subjs(subj).name, '...multiple T1w files found...skipped']);
            continue
        else
            % Get base name of file
            [~, base_name, ~] = fileparts(list_T1_file.name);
            
            % Copy T1w.nii file
            copyfile(fullfile(bids_folder, list_subjs(subj).name, list_T1_file), fullfile(out_dir, [list_subjs(subj).name, '_T1w.nii']));
            
            % Copy JSON file
            copyfile(fullfile(bids_folder, list_subjs(subj).name, [base_name, '.json']), fullfile(out_dir, [list_subjs(subj).name, '_T1w.json']));
            
            % Copy reorientation matrix (if present)
            if exist(fullfile(bids_folder, list_subjs(subj).name, [base_name, '_reorient.mat']), 'file')
                copyfile(fullfile(bids_folder, list_subjs(subj).name, [base_name, '_reorient.mat']), fullfile(out_dir, [list_subjs(subj).name, '_T1w_reorient.mat']));
            end
            
            % Update summary
            disp([list_subjs(subj).name, '...done']);
            fprintf(fid_summary, '%s\r\n', [list_subjs(subj).name, '...done']);
        end
    end
end

% Close summary file
fclose(fid_summary);