function create_brain_masks(outdir)
%% Function to create brain masks
%% Input:
% outdir: location where mask files will be saved
% 
%% Output:
% The following mask files are saved:
% 1)  whole brain
% 2)  left
% 3)  left anterior
% 4)  left posterior
% 5)  left superior
% 6)  left inferior
% 7)  left anterior superior
% 8)  left anterior inferior
% 9)  left posterior superior
% 10) left posterior inferior
% 11) right
% 12) right anterior
% 13) right posterior
% 14) right superior
% 15) right inferior
% 16) right anterior superior
% 17) right anterior inferior
% 18) right posterior superior
% 19) right posterior inferior
% 20) anterior superior
% 21) anterior inferior
% 22) posterior superior
% 23) posterior inferior
% 24) anterior
% 25) posterior
% 26) superior
% 27) inferior
% 
%% Notes:
% brainmask is created by running coregister and reslice on mask_ICV using
% avg152T1 as the reference image
% 
% If a file named brainmask.nii exists in outdir, new mask creation is
% skipped
% 
%% Author(s):
% Parekh, Pravesh
% MBIAL
% February 19, 2018

%% Check inputs
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

%% Create brainmask, if needed
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
    
    %% Coregister: Estimate and Reslice batch
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
    
    %% Delete intermediate files
    disp('Deleting temporary files');
    spm_tmp = ['spm_', datestr(now, 'yyyymmmdd'), '.ps'];
    if exist(spm_tmp, 'file')
        delete(spm_tmp);
    end
    delete(reference_file);
    delete(source_file);
end

%% ROI creation

% Attempt to read brainmask file
mask_vol = spm_vol(brainmask);
[mask_data, mask_xyz] = spm_read_vols(mask_vol);
mask_xyz = mask_xyz';

% Initialize header for all the brain masks
[   left_vol, ...
    left_ant_vol, ...
    left_pos_vol, ...
    left_sup_vol, ...
    left_inf_vol, ...
    left_ant_sup_vol, ...
    left_ant_inf_vol, ...
    left_pos_sup_vol, ...
    left_pos_inf_vol, ...
    right_vol, ...
    right_ant_vol, ...
    right_pos_vol, ...
    right_sup_vol, ...
    right_inf_vol, ...
    right_ant_sup_vol, ...
    right_ant_inf_vol, ...
    right_pos_sup_vol, ...
    right_pos_inf_vol, ...
    ant_vol, ...
    pos_vol, ...
    sup_vol, ...
    inf_vol, ...
    ant_sup_vol, ...
    ant_inf_vol, ...
    pos_sup_vol, ...
    pos_inf_vol] = deal(mask_vol);

% Initialize empty matrices for all the brain masks
[   left, ...
    left_ant, ...
    left_pos, ...
    left_sup, ...
    left_inf, ...
    left_ant_sup, ...
    left_ant_inf, ...
    left_pos_sup, ...
    left_pos_inf, ...
    right, ...
    right_ant, ...
    right_pos, ...
    right_sup, ...
    right_inf, ...
    right_ant_sup, ...
    right_ant_inf, ...
    right_pos_sup, ...
    right_pos_inf, ...
    ant, ...
    pos, ...
    sup, ...
    inf, ...
    ant_sup, ...
    ant_inf, ...
    pos_sup, ...
    pos_inf]  = deal(zeros(size(mask_data)));

% Change filenames in the header
left_vol.fname          = 'left_brainmask.nii';
left_ant_vol.fname      = 'left_ant_brainmask.nii';
left_pos_vol.fname      = 'left_pos_brainmask.nii';
left_sup_vol.fname      = 'left_sup_brainmask.nii';
left_inf_vol.fname      = 'left_inf_brainmask.nii';
left_ant_sup_vol.fname  = 'left_ant_sup_brainmask.nii';
left_ant_inf_vol.fname  = 'left_ant_inf_brainmask.nii';
left_pos_sup_vol.fname  = 'left_pos_sup_brainmask.nii';
left_pos_inf_vol.fname  = 'left_pos_inf_brainmask.nii';

right_vol.fname         = 'right_brainmask.nii';
right_ant_vol.fname     = 'right_ant_brainmask.nii';
right_pos_vol.fname     = 'right_pos_brainmask.nii';
right_sup_vol.fname     = 'right_sup_brainmask.nii';
right_inf_vol.fname     = 'right_inf_brainmask.nii';
right_ant_sup_vol.fname = 'right_ant_sup_brainmask.nii';
right_ant_inf_vol.fname = 'right_ant_inf_brainmask.nii';
right_pos_sup_vol.fname = 'right_pos_sup_brainmask.nii';
right_pos_inf_vol.fname = 'right_pos_inf_brainmask.nii';

ant_vol.fname           = 'anterior_brainmask.nii';
pos_vol.fname           = 'posterior_brainmask.nii';
sup_vol.fname           = 'superior_brainmask.nii';
inf_vol.fname           = 'inferior_brainmask.nii';

ant_sup_vol.fname       = 'anterior_superior_brainmask.nii';
ant_inf_vol.fname       = 'anterior_inferior_brainmask.nii';
pos_sup_vol.fname       = 'postieror_superior_brainmask.nii';
pos_inf_vol.fname       = 'posterior_inferior_brainmask.nii';

% Select rows in xyz
% Left ----------- x <= 0
% Right ---------- x >  0
% Anterior ------- y >  0
% Posterior ------ y <= 0
% Superior ------- z >  0
% Inferior ------- z <= 0
left_select      = mask_xyz(:,1) <= 0;
right_select     = mask_xyz(:,1) >  0;
anterior_select  = mask_xyz(:,2) >  0;
posterior_select = mask_xyz(:,2) <= 0;
superior_select  = mask_xyz(:,3) >  0;
inferior_select  = mask_xyz(:,3) <= 0;

% Assign into appropriate matrices 
left         (left_select                                      ) = 1;
left_ant     (left_select  & anterior_select                   ) = 1;
left_pos     (left_select  & posterior_select                  ) = 1;
left_sup     (left_select                     & superior_select) = 1;
left_inf     (left_select                     & inferior_select) = 1;
left_ant_sup (left_select  & anterior_select  & superior_select) = 1;
left_ant_inf (left_select  & anterior_select  & inferior_select) = 1;
left_pos_sup (left_select  & posterior_select & superior_select) = 1;
left_pos_inf (left_select  & posterior_select & inferior_select) = 1;

right        (right_select                                     ) = 1;
right_ant    (right_select & anterior_select                   ) = 1;
right_pos    (right_select & posterior_select                  ) = 1;
right_sup    (right_select                    & superior_select) = 1;
right_inf    (right_select                    & inferior_select) = 1;
right_ant_sup(right_select & anterior_select  & superior_select) = 1;
right_ant_inf(right_select & anterior_select  & inferior_select) = 1;
right_pos_sup(right_select & posterior_select & superior_select) = 1;
right_pos_inf(right_select & posterior_select & inferior_select) = 1;

ant          (               anterior_select                   ) = 1;
pos          (               posterior_select                  ) = 1;
sup          (                                  superior_select) = 1;
inf          (                                  inferior_select) = 1;

ant_sup      (               anterior_select  & superior_select) = 1;
ant_inf      (               anterior_select  & inferior_select) = 1;
pos_sup      (               posterior_select & superior_select) = 1;
pos_inf      (               posterior_select & inferior_select) = 1;

% Restrict to the voxels labeled as 1 in brainmask
left          = left         .*mask_data;
left_ant      = left_ant     .*mask_data;
left_pos      = left_pos     .*mask_data;
left_sup      = left_sup     .*mask_data;
left_inf      = left_inf     .*mask_data;
left_ant_sup  = left_ant_sup .*mask_data;
left_ant_inf  = left_ant_inf .*mask_data;
left_pos_sup  = left_pos_sup .*mask_data;
left_pos_inf  = left_pos_inf .*mask_data;

right         = right        .*mask_data;
right_ant     = right_ant    .*mask_data;
right_pos     = right_pos    .*mask_data;
right_sup     = right_sup    .*mask_data;
right_inf     = right_inf    .*mask_data;
right_ant_sup = right_ant_sup.*mask_data;
right_ant_inf = right_ant_inf.*mask_data;
right_pos_sup = right_pos_sup.*mask_data;
right_pos_inf = right_pos_inf.*mask_data;

ant           = ant          .*mask_data;
pos           = pos          .*mask_data;
sup           = sup          .*mask_data;
inf           = inf          .*mask_data;

ant_sup       = ant_sup      .*mask_data;
ant_inf       = ant_inf      .*mask_data;
pos_sup       = pos_sup      .*mask_data;
pos_inf       = pos_inf      .*mask_data;

% Write out files
disp('Writing out mask files');
spm_write_vol(left_vol,          left);
spm_write_vol(left_ant_vol,      left_ant);
spm_write_vol(left_pos_vol,      left_pos);
spm_write_vol(left_sup_vol,      left_sup);
spm_write_vol(left_inf_vol,      left_inf);
spm_write_vol(left_ant_sup_vol,  left_ant_sup);
spm_write_vol(left_ant_inf_vol,  left_ant_inf);
spm_write_vol(left_pos_sup_vol,  left_pos_sup);
spm_write_vol(left_pos_inf_vol,  left_pos_inf);

spm_write_vol(right_vol,         right);
spm_write_vol(right_ant_vol,     right_ant);
spm_write_vol(right_pos_vol,     right_pos);
spm_write_vol(right_sup_vol,     right_sup);
spm_write_vol(right_inf_vol,     right_inf);
spm_write_vol(right_ant_sup_vol, right_ant_sup);
spm_write_vol(right_ant_inf_vol, right_ant_inf);
spm_write_vol(right_pos_sup_vol, right_pos_sup);
spm_write_vol(right_pos_inf_vol, right_pos_inf);

spm_write_vol(ant_vol,           ant);
spm_write_vol(pos_vol,           pos);
spm_write_vol(sup_vol,           sup);
spm_write_vol(inf_vol,           inf);

spm_write_vol(ant_sup_vol,       ant_sup);
spm_write_vol(ant_inf_vol,       ant_inf);
spm_write_vol(pos_sup_vol,       pos_sup);
spm_write_vol(pos_inf_vol,       pos_inf);