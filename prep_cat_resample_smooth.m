function prep_cat_resample_smooth(in_dir, num_cores)
% Function to run resample and smooth on computed surface maps of cortical
% thickness, cortical complexity, gyrification, and sulcal depths
%% Inputs:
% in_dir:           fullpath to directory having main cat results folder
%                   (not the surf directory)
% num_cores:        specify number of cores to parallelize to
% 
%% Output:
% A batch file named cat_resample_smooth_<measure>_ddmmmyyyy.mat is saved
% in the in_dir
%
%% Default(s):
% num_cores:        30
% 
%% Author(s):
% Parekh, Pravesh
% March 06, 2018
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

%% Part I: cortical thickness
% Prepare list of surfaces
cd(fullfile(in_dir, 'surf'));
list_surfaces = dir('lh.thickness*');
num_surfaces  = length(list_surfaces);
disp([num2str(num_surfaces), ' thickness surfaces found']);

% Loop over surfaces and prepare batch
for surface = 1:num_surfaces
    matlabbatch{1}.spm.tools.cat.stools.surfresamp.data_surf(surface,1) = {fullfile(in_dir, 'surf', list_surfaces(surface).name)};
end
matlabbatch{1}.spm.tools.cat.stools.surfresamp.merge_hemi = 1;
matlabbatch{1}.spm.tools.cat.stools.surfresamp.mesh32k = 1;
matlabbatch{1}.spm.tools.cat.stools.surfresamp.fwhm_surf = 15;
matlabbatch{1}.spm.tools.cat.stools.surfresamp.nproc = num_cores;

% Save batch
save(fullfile(in_dir, ['cat_resample_smooth_cortthickness', datestr(now, 'ddmmmyyyy'), '.mat']), 'matlabbatch');
clear matlabbatch

%% Part II: cortical complexity
% Prepare list of surfaces
cd(fullfile(in_dir, 'surf'));
list_surfaces = dir('lh.fractaldimension*');
num_surfaces  = length(list_surfaces);
disp([num2str(num_surfaces), ' cortical complexity surfaces found']);

% Loop over surfaces and prepare batch
for surface = 1:num_surfaces
    matlabbatch{1}.spm.tools.cat.stools.surfresamp.data_surf(surface,1) = {fullfile(in_dir, 'surf', list_surfaces(surface).name)};
end
matlabbatch{1}.spm.tools.cat.stools.surfresamp.merge_hemi = 1;
matlabbatch{1}.spm.tools.cat.stools.surfresamp.mesh32k = 1;
matlabbatch{1}.spm.tools.cat.stools.surfresamp.fwhm_surf = 20;
matlabbatch{1}.spm.tools.cat.stools.surfresamp.nproc = num_cores;

% Save batch
save(fullfile(in_dir, ['cat_resample_smooth_cortcomplexity', datestr(now, 'ddmmmyyyy'), '.mat']), 'matlabbatch');
clear matlabbatch

%% Part III: gyrification
% Prepare list of surfaces
cd(fullfile(in_dir, 'surf'));
list_surfaces = dir('lh.gyrification*');
num_surfaces  = length(list_surfaces);
disp([num2str(num_surfaces), ' gyrification surfaces found']);

% Loop over surfaces and prepare batch
for surface = 1:num_surfaces
    matlabbatch{1}.spm.tools.cat.stools.surfresamp.data_surf(surface,1) = {fullfile(in_dir, 'surf', list_surfaces(surface).name)};
end
matlabbatch{1}.spm.tools.cat.stools.surfresamp.merge_hemi = 1;
matlabbatch{1}.spm.tools.cat.stools.surfresamp.mesh32k = 1;
matlabbatch{1}.spm.tools.cat.stools.surfresamp.fwhm_surf = 20;
matlabbatch{1}.spm.tools.cat.stools.surfresamp.nproc = num_cores;

% Save batch
save(fullfile(in_dir, ['cat_resample_smooth_gyrification', datestr(now, 'ddmmmyyyy'), '.mat']), 'matlabbatch');
clear matlabbatch

%% Part IV: sulcal depth
% Prepare list of surfaces
cd(fullfile(in_dir, 'surf'));
list_surfaces = dir('lh.sqrtsulc*');
num_surfaces  = length(list_surfaces);
disp([num2str(num_surfaces), ' sulcal depth surfaces found']);

% Loop over surfaces and prepare batch
for surface = 1:num_surfaces
    matlabbatch{1}.spm.tools.cat.stools.surfresamp.data_surf(surface,1) = {fullfile(in_dir, 'surf', list_surfaces(surface).name)};
end
matlabbatch{1}.spm.tools.cat.stools.surfresamp.merge_hemi = 1;
matlabbatch{1}.spm.tools.cat.stools.surfresamp.mesh32k = 1;
matlabbatch{1}.spm.tools.cat.stools.surfresamp.fwhm_surf = 20;
matlabbatch{1}.spm.tools.cat.stools.surfresamp.nproc = num_cores;

% Save batch
save(fullfile(in_dir, ['cat_resample_smooth_sulcaldepth', datestr(now, 'ddmmmyyyy'), '.mat']), 'matlabbatch');
clear matlabbatch