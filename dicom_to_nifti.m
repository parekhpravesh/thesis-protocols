function dicom_to_nifti(source_dir)
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
mricrogl_dir = 'E:\mricrogl';

% Getsubject list and paths from create_subj_list
[subj_names, full_paths] = create_subj_list(source_dir);

% Prepare path names
num_subjs = length(subj_names);
input_full_paths = full_paths;
output_full_paths = fullfile(full_paths, strcat(subj_names, '_nifti'));
logfile_full_paths = fullfile(output_full_paths, strcat(subj_names, ...
    '_dcm2niix_log.txt'));

% Move to mricrogl_dir
cd(mricrogl_dir);

% Convert to NIfTI
for ns = 1:num_subjs
    mkdir(output_full_paths{ns});
    
    % Open log file for writing output of dcm2niix
    fid = fopen(logfile_full_paths{ns}, 'w');
    
    % Create string to be passed to system
    cmd_string = ['dcm2niix -b y -z n -f %f_%p -o "', ...
        output_full_paths{ns}, '" "', input_full_paths{ns}, '"'];
    
    % Call dcm2niix and write the output to log file
    [~, log_text] = system(cmd_string);
    fprintf(fid, '%s', log_text);
    fclose(fid);
end

% Return control to source_dir
cd(source_dir);