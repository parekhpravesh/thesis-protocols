function prep_cat_mean_roi_values(in_dir, out_dir)
% Function to create batch for calculating mean values inside an ROI
%% Inputs:
% in_dir:           fullpath to directory having main cat results folder
%                   (not the label directory)
% out_dir:          fullpath to where the ROI results will be written
% 
%% Output:
% A batch file named cat_mean_roi_values_ddmmmyyyy.mat is saved in the
% in_dir
%
%% Author(s):
% Parekh, Pravesh
% March 06, 2018
% MBIAL

%% Check inputs
if ~exist(in_dir, 'dir')
    error([in_dir, ' not found']);
else
    if ~exist(fullfile(in_dir, 'label'), 'dir')
        error('ROI results not found');
    end
end

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

%% Prepare list of xml files
cd(fullfile(in_dir, 'label'));
list_files = dir('catROI*.xml');
num_files  = length(list_files);
disp([num2str(num_files), ' xml files found']);

%% Create batch
for file = 1:num_files
    matlabbatch{1}.spm.tools.cat.tools.calcroi.roi_xml(file,1) = {fullfile(in_dir, 'label', list_files(file).name)};
end
matlabbatch{1}.spm.tools.cat.tools.calcroi.point = '.';
matlabbatch{1}.spm.tools.cat.tools.calcroi.outdir = {out_dir};
matlabbatch{1}.spm.tools.cat.tools.calcroi.calcroi_name = 'ROI';

%% Save batch
save(fullfile(in_dir, ['cat_mean_roi_valuse', datestr(now, 'ddmmmyyyy'), '.mat']), 'matlabbatch');