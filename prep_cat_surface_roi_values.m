function prep_cat_surface_roi_values(in_dir)
% Function to create batch for extracting ROI based surface values
%% Inputs:
% in_dir:           fullpath to directory having main cat results folder
%                   (not the surf directory)
% 
%% Output:
% A batch file named cat_surface_roi_values_<measure>_ddmmmyyyy.mat is
% saved in the in_dir
%
%% Author(s):
% Parekh, Pravesh
% March 06, 2018
% MBIAL

%% Check inputs
if ~exist(in_dir, 'dir')
    error([in_dir, ' not found']);
else
    if ~exist(fullfile(in_dir, 'surf'), 'dir')
        error('Surface results not found');
    end
end

%% Part I: cortical thickness
% Prepare list of surfaces
cd(fullfile(in_dir, 'surf'));
list_surfaces = dir('lh.thickness*');
num_surfaces  = length(list_surfaces);
disp([num2str(num_surfaces), ' thickness surfaces found']);

% Loop over surfaces and prepare batch
for surface = 1:num_surfaces
matlabbatch{1}.spm.tools.cat.stools.surf2roi.cdata(surface,1) = {{fullfile(in_dir, 'surf', list_surfaces(surface).name)}}';
end

% Save batch
save(fullfile(in_dir, ['cat_surface_roi_values_cortthickness', datestr(now, 'ddmmmyyyy'), '.mat']), 'matlabbatch');
clear matlabbatch

%% Part II: cortical complexity
% Prepare list of surfaces
cd(fullfile(in_dir, 'surf'));
list_surfaces = dir('lh.fractaldimension*');
num_surfaces  = length(list_surfaces);
disp([num2str(num_surfaces), ' cortical complexity surfaces found']);

% Loop over surfaces and prepare batch
for surface = 1:num_surfaces
matlabbatch{1}.spm.tools.cat.stools.surf2roi.cdata(surface,1) = {{fullfile(in_dir, 'surf', list_surfaces(surface).name)}}';
end

% Save batch
save(fullfile(in_dir, ['cat_surface_roi_values_cortcomplexity', datestr(now, 'ddmmmyyyy'), '.mat']), 'matlabbatch');
clear matlabbatch

%% Part III: gyrification
% Prepare list of surfaces
cd(fullfile(in_dir, 'surf'));
list_surfaces = dir('lh.gyrification*');
num_surfaces  = length(list_surfaces);
disp([num2str(num_surfaces), ' gyrification surfaces found']);

% Loop over surfaces and prepare batch
for surface = 1:num_surfaces
matlabbatch{1}.spm.tools.cat.stools.surf2roi.cdata(surface,1) = {{fullfile(in_dir, 'surf', list_surfaces(surface).name)}}';
end

% Save batch
save(fullfile(in_dir, ['cat_surface_roi_values_gyrification', datestr(now, 'ddmmmyyyy'), '.mat']), 'matlabbatch');
clear matlabbatch

%% Part IV: sulcal depth
% Prepare list of surfaces
cd(fullfile(in_dir, 'surf'));
list_surfaces = dir('lh.sqrtsulc*');
num_surfaces  = length(list_surfaces);
disp([num2str(num_surfaces), ' sulcal depth surfaces found']);

% Loop over surfaces and prepare batch
for surface = 1:num_surfaces
matlabbatch{1}.spm.tools.cat.stools.surf2roi.cdata(surface,1) = {{fullfile(in_dir, 'surf', list_surfaces(surface).name)}}';
end

% Save batch
save(fullfile(in_dir, ['cat_surface_roi_values_sulcaldepth', datestr(now, 'ddmmmyyyy'), '.mat']), 'matlabbatch');
clear matlabbatch