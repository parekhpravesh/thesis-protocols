function nifti_to_bids_anat(subject_dir, dest_dir)
% Converts a subejct's NIfTI anatomical scans (T1w only) to BIDS
% specification
% Parekh, Pravesh
% February 10, 2017
% MBIAL
%
% Assumes the following structure
% <some-location>/
%   <source-dir>/
%       <some-subj-name>/
%           DICOM/
%           <some-subj-name>_nifti/
%               <some-subj-name>_T1*.nii*

cd(subject_dir);
list_T1 = dir('*T1*.nii*');

% Check if no T1 files are present
if isempty(list_T1)
    warning([subject_dir, ' does not have any T1w files']);
else
    % Report if multiple files are present and do nothing
    if length(list_T1) > 1
        [~,file_name,~] = fileparts(list_T1.name);
        name = strsplit(file_name, '_');
        subj_name = name{1};
        warning([subj_name, ' has ', num2str(length(list_T1)), ' T1w files']);
    else
        % Copy T1w file and associated JSON sidecar to dest_dir
        [~,file_name,~] = fileparts(list_T1.name);
        name = strsplit(file_name, '_');
        subj_name = name{1};
        
        % Make folders inside dest_dir
        cd(dest_dir);
        mkdir(subj_name);
        cd(subj_name);
        mkdir('anat');
        
        % Copy NIfTI file
        copyfile(fullfile(subject_dir, list_T1.name), ...
            fullfile(dest_dir, subj_name, 'anat', [subj_name, '_T1w.nii']));
        
        % Copy JSON file
        copyfile(fullfile(subject_dir, [subj_name, '.json']), ...
            fullfile(dest_dir, subj_name, 'anat', [subj_name, '_T1w.json']));
    end
end