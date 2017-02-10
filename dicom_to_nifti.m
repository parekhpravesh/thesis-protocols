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

% Detect number of subjects which is counted as the number of folders at
% the <source-dir> level

% Removing all files and '.' '..' folders
source_contents = dir(source_dir);
check_dir = [source_contents.isdir]';
check_names = {source_contents(check_dir).name}';
to_remove = ismember(check_names, {'.', '..'});
source_contents(to_remove) = [];

% Prepare path names
num_subjs = length(source_contents);
input_full_paths = fullfile(source_dir, {source_contents.name})';
output_full_paths = strcat(fullfile(source_dir, {source_contents.name}, ...
    {source_contents.name})', '_nifti');

% Move to mricrogl_dir
cd(mricrogl_dir);

% Convert to NIfTI
for ns = 1:num_subjs
    mkdir(output_full_paths{ns});
    
    % Open log file for writing output of dcm2niix
    fid = fopen(fullfile(output_full_paths{ns}, ...
        strcat(source_contents(ns).name, '_dcm2niix_log.txt')), 'w');
    
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