function dicom_to_nifti(subject_dir, dest_dir, mricrogl_dir)
% Convert DICOM to NIfTI format
% Parekh, Pravesh
% February 10, 2017
% MBIAL
%
% Assumes the following structure
% <some-location>/
%   <source-dir>/
%       <some-subj-name>/
%           DICOM/
%           DICOMDIR
%

[~, subj_name, ~] = fileparts(subject_dir);

% Prepare output folder
cd(dest_dir);
mkdir(subj_name);

input_full_path = subject_dir;
output_full_path = fullfile(dest_dir, subj_name);
logfile_full_paths = fullfile(output_full_path, strcat(subj_name, ...
    '_dcm2niix_log.txt'));

% Move to mricrogl_dir
cd(mricrogl_dir);

% Open log file for writing output of dcm2niix
fid = fopen(logfile_full_paths, 'w');

% Create string to be passed to system
if ~isunix
    cmd_string = ['dcm2niix -b y -z n -f %f_%p -o "', ...
        output_full_path, '" "', input_full_path, '"'];
else
    cmd_string = ['./dcm2niix -b y -z n -f %f_%p -o "', ...
        output_full_path, '" "', input_full_path, '"'];
end
    
    % Call dcm2niix and write the output to log file
    [~, log_text] = system(cmd_string);
    fprintf(fid, '%s', log_text);
    fclose(fid);
    
    % Display status
    disp(['Finished converting ', subj_name]);