function prep_cat_segment(in_dir, mode, num_cores)
% Function to create CAT segmentation batch in either regular or expert
% mode (not development mode)
%% Inputs:
% in_dir:           fullpath to directory having T1w images
%                   (output of prep_anat_analysis)
% mode:             can be:
%                       * 'expert'
%                       * 'regular'
% num_cores:        specify number of cores to parallelize to
% 
%% Output:
% A batch file named cat_segment_<mode>_ddmmmyyyy.mat is saved in the in_dir
%
%% Default(s):
% mode:             expert
% num_cores:        30
% 
%% Author(s):
% Parekh, Pravesh
% March 05, 2018
% MBIAL

%% Check inputs and assign defaults
if ~exist(in_dir, 'dir')
    error([in_dir, ' not found']);
end

if ~exist('mode', 'var')
    mode = 'expert';
end

if ~exist('num_cores', 'var')
    num_cores = 30;
end

% Get SPM and CAT12 location
spm_loc         = which('spm'); 
[spm_loc, ~, ~] = fileparts(spm_loc);
cat_loc         = which('cat12');
[cat_loc, ~, ~] = fileparts(cat_loc);

%% Process list of subjects
cd(in_dir);
list_files = dir('*T1*.nii');
num_files  = length(list_files);
disp([num2str(num_files), ' T1w files found']);

%% Create CAT12 segment batch

switch mode
    case 'expert'
        for subj = 1:num_files
            matlabbatch{1}.spm.tools.cat.estwrite.data{subj,1} = {fullfile(in_dir, list_files(subj).name)};
        end
        matlabbatch{1}.spm.tools.cat.estwrite.nproc = num_cores;
        matlabbatch{1}.spm.tools.cat.estwrite.opts.tpm = {fullfile(spm_loc, 'tpm', 'TPM.nii')};
        matlabbatch{1}.spm.tools.cat.estwrite.opts.affreg = 'mni';
        matlabbatch{1}.spm.tools.cat.estwrite.opts.biasstr = 0.5;
        matlabbatch{1}.spm.tools.cat.estwrite.opts.samp = 3;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.segmentation.APP = 1070;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.segmentation.NCstr = -Inf;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.segmentation.LASstr = 0.5;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.segmentation.gcutstr = 0.5;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.segmentation.cleanupstr = 0.5;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.segmentation.WMHCstr = 0.5;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.segmentation.WMHC = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.segmentation.restypes.best = [0.5 0.3];
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.registration.darteltpm = {fullfile(cat_loc, 'templates_1.50mm', 'Template_1_IXI555_MNI152.nii')};
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.registration.shootingtpm = {fullfile(cat_loc, 'templates_1.50mm', 'Template_0_IXI555_MNI152_GS.nii')};
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.registration.regstr = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.vox = 1.5;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.surface.pbtres = 0.5;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.surface.scale_cortex = 0.7;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.surface.add_parahipp = 0.1;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.surface.close_parahipp = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.admin.ignoreErrors = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.admin.verb = 2;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.admin.print = 2;
        matlabbatch{1}.spm.tools.cat.estwrite.output.surface = 12;
        matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.hammers = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.neuromorphometrics = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.lpba40 = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.cobra = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.ibsr = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.aal = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.mori = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.anatomy = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.GM.native = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.GM.warped = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.GM.mod = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.GM.dartel = 3;
        matlabbatch{1}.spm.tools.cat.estwrite.output.WM.native = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.WM.warped = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.WM.mod = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.WM.dartel = 3;
        matlabbatch{1}.spm.tools.cat.estwrite.output.CSF.native = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.CSF.warped = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.CSF.mod = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.CSF.dartel = 3;
        matlabbatch{1}.spm.tools.cat.estwrite.output.WMH.native = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.output.WMH.warped = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.output.WMH.mod = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.output.WMH.dartel = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.output.label.native = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.label.warped = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.label.dartel = 3;
        matlabbatch{1}.spm.tools.cat.estwrite.output.bias.native = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.bias.warped = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.bias.dartel = 3;
        matlabbatch{1}.spm.tools.cat.estwrite.output.las.native = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.las.warped = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.las.dartel = 3;
        matlabbatch{1}.spm.tools.cat.estwrite.output.jacobian.warped = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.warps = [1 1];
        
    case 'regular'
        for subj = 1:num_files
            matlabbatch{1}.spm.tools.cat.estwrite.data{subj,1} = {fullfile(in_dir, list_files(subj).name)};
        end
        matlabbatch{1}.spm.tools.cat.estwrite.nproc = num_cores;
        matlabbatch{1}.spm.tools.cat.estwrite.opts.tpm = {fullfile(spm_loc, 'tpm', 'TPM.nii')};
        matlabbatch{1}.spm.tools.cat.estwrite.opts.affreg = 'mni';
        matlabbatch{1}.spm.tools.cat.estwrite.opts.biasstr = 0.5;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.APP = 1070;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.LASstr = 0.5;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.gcutstr = 0.5;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.cleanupstr = 0.5;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.darteltpm = {fullfile(cat_loc, 'templates_1.50mm', 'Template_1_IXI555_MNI152.nii')};
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.vox = 1.5;
        matlabbatch{1}.spm.tools.cat.estwrite.output.surface = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.ROI = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.GM.native = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.GM.mod = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.GM.dartel = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.output.WM.native = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.WM.mod = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.WM.dartel = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.output.bias.warped = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.jacobian.warped = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.warps = [1 1];
        
    otherwise
        error('Unknown mode specified');
end

%% Save batch
save(fullfile(in_dir, ['cat_segment_', mode, '_', datestr(now, 'ddmmmyyyy'), '.mat']), 'matlabbatch');