function global_signal = get_fmri_global_signal(func_filename, mask_ICV)
% Function to calculate global signal defined as the average signal over
% the whole brain for each functional volume; optionally user can mask the
% brain using a co-registered and resliced mask derived from the mask_ICV
% file shipped with SPM
% 
%% Inputs:
% func_filename:    filename of the functional volume
% mask_ICV:         1/0 value indicating yes/no
% 
%% Output:
% global_signal:    vector having a single global value per time point
% 
%% Notes:
% All voxels having a value of zero are excluded from mean calculation
% 
% If mask_ICV is set to 1, co-register and reslice module is called, a
% brainmask is created, and then used to block out voxels which may not
% fall inside the mask
% 
%% Default:
% mask_ICV:         0
% 
%% Author(s)
% Parekh, Pravesh
% November 07, 2018
% MBIAL

%% Check inputs
% Check func_filename
if ~exist('func_filename', 'var') || isempty(func_filename)
    error('data_dir needs to be given');
else
    if ~exist(func_filename, 'file')
        error(['Unable to find functional file: ', func_filename]);
    end
end

% Check mask_ICV
if ~exist('mask_ICV', 'var') || isempty(mask_ICV)
    mask_ICV = 0;
else
    if isnumeric(mask_ICV)
        if mask_ICV > 1 || mask_ICV < 0
            error(['Unknown mask_ICV option given: ', num2str(mask_ICV)]);
        end
    else
        error(['Unknown mask_ICV option given: ', mask_ICV]);
    end
end

%% Read functional file
vol  = spm_vol(func_filename);
data = spm_read_vols(vol);
num_vols = size(data,4);

%% Create brainmask if needed
if mask_ICV
    spm_dir     = fileparts(which('spm'));
    mask_file   = fullfile(spm_dir, 'tpm', 'mask_ICV.nii');
    copyfile(mask_file, fullfile(pwd, 'brainmask.nii'));
    ref_file    = func_filename;
    source_file = fullfile(pwd, 'brainmask.nii');
    
    % Coregister and reslice batch
    matlabbatch{1}.spm.spatial.coreg.estwrite.ref               = {[ref_file, ',1']};
    matlabbatch{1}.spm.spatial.coreg.estwrite.source            = {[source_file, ',1']};
    matlabbatch{1}.spm.spatial.coreg.estwrite.other             = {''};
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep      = [4 2];
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.tol      = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.fwhm     = [7 7];
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp   = 0;
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.wrap     = [0 0 0];
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.mask     = 0;
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';
    spm_jobman('initcfg');
    spm_jobman('run', matlabbatch);
    delete(source_file);
    source_file = fullfile(pwd, 'rbrainmask.nii');
    vol_mask  = spm_vol(source_file);
    data_mask = spm_read_vols(vol_mask);
    delete(source_file);
else
    data_mask = ones(size(data,1), size(data,2), size(data,3));
end

%% Get the mean time series
global_signal = zeros(num_vols,1);
for time = 1:num_vols
    data_tmp = squeeze(data(:,:,:,time)).*data_mask;
    loc_tmp  = data_tmp>0;
    global_signal(time) = mean(data_tmp(loc_tmp));
end