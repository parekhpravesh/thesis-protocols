function [num_func_scans, func_scans_paths] = find_func_scans(subject_dir)
% Function to find functional scans in a NIfTI folder of a given subject
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

% Defining criteria for selecting functional scans
allowed_func = {'FMRI', 'EPI'};
cd(subject_dir);
list_scans = dir('*.nii*');
list_scans_name = {list_scans.name}';
protocol_names = cell(length(list_scans_name),1);

% Split each scan name into its components; the second component would
% correspond to the protocol name; check the protocol name against
% allowed_func to find anatomical scans
for scans = 1:length(list_scans_name)
    split_name = strsplit(list_scans_name{scans}, '_');
    protocol_names(scans) = split_name(2);
end
loc_func = ismember(lower(protocol_names), lower(allowed_func));
num_func_scans = sum(loc_func);
func_scans_paths = fullfile(subject_dir, list_scans_name(loc_func));