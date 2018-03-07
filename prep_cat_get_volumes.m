function prep_cat_get_volumes(in_dir)
% Function to get TIV, GM, WM, and CSF volumes after segmentation is over
%% Inputs:
% in_dir:           fullpath to directory having main cat results folder
%                   (not the surf directory)
% 
%% Output:
% A batch file named cat_get_volumes_ddmmmyyyy.mat is saved in the in_dir
%
%% Author(s):
% Parekh, Pravesh
% March 07, 2018
% MBIAL

%% Check inputs
if ~exist(in_dir, 'dir')
    error([in_dir, ' not found']);
else
    if ~exist(fullfile(in_dir, 'report'), 'dir')
        error('Segmentation results not found');
    end
end

%% Prepare list of xml files
cd(fullfile(in_dir, 'report'));
list_files = dir('cat*.xml');
num_files  = length(list_files);
disp([num2str(num_files), ' xml files found']);

%% Create batch
for file = 1:num_files
    matlabbatch{1}.spm.tools.cat.tools.calcvol.data_xml(file,1) = {fullfile(in_dir, 'report', list_files(file).name)};
end
matlabbatch{1}.spm.tools.cat.tools.calcvol.calcvol_TIV = 0;
matlabbatch{1}.spm.tools.cat.tools.calcvol.calcvol_name = ['volumes_', datestr(now, 'ddmmmyyyy'), '.txt'];

%% Save batch
save(fullfile(in_dir, ['cat_get_volumes', datestr(now, 'ddmmmyyyy'), '.mat']), 'matlabbatch');