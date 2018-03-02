function create_brain_masks(outdir)
% Function to create the following brain masks:
% 1) whole brain
% 2) left anterior superior
% 3) left anterior inferior
% 4) left posterior superior
% 5) left posterior inferior
% 6) right anterior superior
% 7) right anterior inferior
% 8) right posterior superior
% 9) right posterior inferior
% brainmask is created by running coregister and reslice using avg152T1
% as the reference image
% 
% If a file named brainmask.nii exists in outdir, new mask creation is
% skipped
% 
% Parekh, Pravesh
% MBIAL
% February 19, 2018

% Check inputs
if ~exist('outdir', 'var') || isempty(outdir)
    warning('No output directory specified. Using present directory');
    outdir = pwd;
end
brainmask = fullfile(outdir, 'brainmask.nii');

if ~exist(brainmask, 'file')
    disp('No brainmask found; will create brainmask');
    create_brainmask = 1;
else
    disp('Brainmask found; will use this brainmask');
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

% Initialize header for all the brain masks
left_ant_sup_vol  = mask_vol;
left_ant_inf_vol  = mask_vol;
left_pos_sup_vol  = mask_vol;
left_pos_inf_vol  = mask_vol;
right_ant_sup_vol = mask_vol;
right_ant_inf_vol = mask_vol;
right_pos_sup_vol = mask_vol;
right_pos_inf_vol = mask_vol;

% Initialize empty matrices for all the brain masks
left_ant_sup  = zeros(size(mask_data)); 
left_ant_inf  = zeros(size(mask_data));
left_pos_sup  = zeros(size(mask_data));
left_pos_inf  = zeros(size(mask_data));
right_ant_sup = zeros(size(mask_data));
right_ant_inf = zeros(size(mask_data));
right_pos_sup = zeros(size(mask_data));
right_pos_inf = zeros(size(mask_data));

% Change filenames in the header
left_ant_sup_vol.fname  = 'left_ant_sup_brainmask.nii';
left_ant_inf_vol.fname  = 'left_ant_inf_brainmask.nii';
left_pos_sup_vol.fname  = 'left_pos_sup_brainmask.nii';
left_pos_inf_vol.fname  = 'left_pos_inf_brainmask.nii';
right_ant_sup_vol.fname = 'right_ant_sup_brainmask.nii';
right_ant_inf_vol.fname = 'right_ant_inf_brainmask.nii';
right_pos_sup_vol.fname = 'right_pos_sup_brainmask.nii';
right_pos_inf_vol.fname = 'right_pos_inf_brainmask.nii';

% Select rows in xyz
% Left ----------- x <= 0
% Right ---------- x >  0
% Anterior ------- y <= 0
% Posterior ------ y <  0
% Superior ------- z <= 0
% Inferior ------- z <  0
left_select      = mask_xyz(:,1)<=0;
right_select     = mask_xyz(:,1)> 0;
anterior_select  = mask_xyz(:,2)<=0;
posterior_select = mask_xyz(:,2)> 0;
superior_select  = mask_xyz(:,3)<=0;
inferior_select  = mask_xyz(:,3)> 0;

% Assign into appropriate matrices 
left_ant_sup (left_select  & anterior_select  & superior_select) = 1;
left_ant_inf (left_select  & anterior_select  & inferior_select) = 1;
left_pos_sup (left_select  & posterior_select & superior_select) = 1;
left_pos_inf (left_select  & posterior_select & inferior_select) = 1;
right_ant_sup(right_select & anterior_select  & superior_select) = 1;
right_ant_inf(right_select & anterior_select  & inferior_select) = 1;
right_pos_sup(right_select & posterior_select & superior_select) = 1;
right_pos_inf(right_select & posterior_select & inferior_select) = 1;

% Restrict to the voxels labeled as 1 in brainmask
left_ant_sup  = left_ant_sup .*mask_data;
left_ant_inf  = left_ant_inf .*mask_data;
left_pos_sup  = left_pos_sup .*mask_data;
left_pos_inf  = left_pos_inf .*mask_data;
right_ant_sup = right_ant_sup.*mask_data;
right_ant_inf = right_ant_inf.*mask_data;
right_pos_sup = right_pos_sup.*mask_data;
right_pos_inf = right_pos_inf.*mask_data;

% Write out files
disp('Writing out mask files');
spm_write_vol(left_ant_sup_vol, left_ant_sup);
spm_write_vol(left_ant_inf_vol, left_ant_inf);
spm_write_vol(left_pos_sup_vol, left_pos_sup);
spm_write_vol(left_pos_inf_vol, left_pos_inf);
spm_write_vol(right_ant_sup_vol, right_ant_sup);
spm_write_vol(right_ant_inf_vol, right_ant_inf);
spm_write_vol(right_pos_sup_vol, right_pos_sup);
spm_write_vol(right_pos_inf_vol, right_pos_inf);