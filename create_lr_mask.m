function create_lr_mask(outdir, brainmask)
% Function to create left and right hemisphere masks
% brainmask is created by running coregister and reslice using avg152T1
% as the reference image
% 
% Parekh, Pravesh
% MBIAL
% February 16, 2018

% Check inputs
if ~exist('outdir', 'var') || isempty(outdir)
    warning('No output directory specified. Using present directory');
    outdir = pwd;
end
if ~exist('brainmask', 'var')
    disp('No brainmask specified; will create brainmask');
    create_brainmask = 1;
else
    create_brainmask = 0;
end

% Create brainmask if needed
if create_brainmask
    
    % Get SPM directory
    spm_loc = which('spm');
    [spm_loc, ~] = fileparts(spm_loc);
    
    % Copy the files out of spm directories into the output directory
    reference_file  = fullfile(spm_loc, 'canonical', 'avg152T1.nii');
    source_file     = fullfile(spm_loc, 'tpm', 'mask_ICV.nii');
    copyfile(reference_file, outdir);
    copyfile(source_file, outdir);
    
    % Update reference and source locations
    reference_file  = fullfile(outdir, 'avg152T1.nii');
    source_file     = fullfile(outdir, 'mask_ICV.nii');
    
    % Coregister: Estimate and Reslice batch
    matlabbatch{1}.spm.spatial.coreg.estwrite.ref               = {reference_file};
    matlabbatch{1}.spm.spatial.coreg.estwrite.source            = {source_file};
    matlabbatch{1}.spm.spatial.coreg.estwrite.other             = {''};
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep      = [4 2];
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.tol      = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.fwhm     = [7 7];
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp   = 0;
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.wrap     = [0 0 0];
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.mask     = 0;
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix   = 'r';
    
    % Switch to output directory and run job
    cd(outdir);
    spm_jobman('initcfg');
    spm_jobman('run', matlabbatch);
    
    % Rename the created file to brainmask.nii
    movefile('rmask_ICV.nii', 'brainmask.nii')
    brainmask = 'brainmask.nii';
    
    % Delete intermediate files
    disp('Deleting temporary files');
    spm_tmp = ['spm_', datestr(now, 'yyyymmmdd'), '.ps'];
    if exist(spm_tmp, 'file')
        delete(spm_tmp);
    end
    delete(reference_file);
    delete(source_file);
end

% Attempt to read brainmask file
mask_vol = spm_vol(brainmask);
[mask_data, mask_xyz] = spm_read_vols(mask_vol);
mask_xyz = mask_xyz';

% Initialize header and empty matrix for left and right
left_vol    = mask_vol;
right_vol   = mask_vol;
left_data   = zeros(size(mask_data));
right_data  = zeros(size(mask_data));

% Change filenames in the header
left_vol.fname  = 'left_brainmask.nii';
right_vol.fname = 'right_brainmask.nii';

% Select rows in xyz belonging to left and right side
% Left <= 0
% Right > 0
left_select  = mask_xyz(:,1)<=0;
right_select = mask_xyz(:,1)> 0;

% Assign into left_data and right_data
left_data(left_select)    = 1;
right_data(right_select)  = 1;

% Restrict to the voxels labeled as 1 in brainmask
left_data   = left_data.*mask_data;
right_data  = right_data.*mask_data;

% Write out files
disp('Writing left and right mask files');
spm_write_vol(left_vol, left_data);
spm_write_vol(right_vol, right_data);