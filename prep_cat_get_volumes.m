function prep_cat_get_volumes(in_dir)
% Function to get TIV, GM, WM, and CSF volumes after segmentation is over
%% Inputs:
% in_dir:           fullpath to directory having main cat results folder
%                   (not the report directory)
% 
%% Output:
% A batch file named cat_get_volumes_ddmmmyyyy.mat is saved in the in_dir;
% also export a subject list in the order in which xml files were read;
% this is saved as cat_subjlist_get_volumes_ddmmmyyyy.txt
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

%% Save subjlist
fid = fopen(fullfile(in_dir, ['cat_subjlist_volumes_', datestr(now, 'ddmmmyyyy'), '.txt']), 'w');
for file = 1:num_files
    fprintf(fid, '%s\r\n', list_files(file).name);
end
fclose(fid);