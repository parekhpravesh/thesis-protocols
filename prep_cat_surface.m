function prep_cat_surface(in_dir, num_cores)
% Function to create batch for extracting surface parameters using CAT12
%% Inputs:
% in_dir:           fullpath to directory having main cat results folder
%                   (not the surf directory)
% num_cores:        specify number of cores to parallelize to
% 
%% Output:
% A batch file named cat_extract_surface_params_ddmmmyyyy.mat is saved in
% the in_dir
%
%% Default(s):
% num_cores:        30
% 
%% Author(s):
% Parekh, Pravesh
% March 05, 2018
% MBIAL

%% Check inputs and assign defaults
if ~exist(in_dir, 'dir')
    error([in_dir, ' not found']);
else
    if ~exist(fullfile(in_dir, 'surf'), 'dir')
        error('surf results not found');
    end
end

if ~exist('num_cores', 'var')
    num_cores = 30;
end

%% Prepare list of surfaces
cd(fullfile(in_dir, 'surf'));
list_surfaces = dir('lh.central.*.gii');
num_surfaces  = length(list_surfaces);
disp([num2str(num_surfaces), ' found']);

%% Loop over surfaces and prepare batch
for surface = 1:num_surfaces
    matlabbatch{1}.spm.tools.cat.stools.surfextract.data_surf{surface,1} = {fullfile(in_dir, 'surf', list_surfaces(surface).name)};
end
matlabbatch{1}.spm.tools.cat.stools.surfextract.GI = 1;
matlabbatch{1}.spm.tools.cat.stools.surfextract.FD = 1;
matlabbatch{1}.spm.tools.cat.stools.surfextract.SD = 1;
matlabbatch{1}.spm.tools.cat.stools.surfextract.nproc = num_cores;

%% Save batch
save(fullfile(in_dir, ['cat_extract_surface_params', datestr(now, 'ddmmmyyyy'), '.mat']), 'matlabbatch');