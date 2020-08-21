function create_cat_batches(dir_in, batch_size, dir_out)
% Function to create CAT serial batches by padding a dummy subject at the
% beginning of the session
%% Inputs:
% dir_in:       full path to a directory having sub-*.nii images for CAT
%               segmentation (images should be AC-PC aligned)
% batch_size:   number of subjects to include in batch
% dir_out:      full path to where batches should be written out
% 
%% Outputs:
% CAT expert mode batch file(s) with most of the options set to yes is/are 
% written out in dir_out
% 
%% Notes:
% Designed for CAT12.6 v1450 which has a bug that yields slightly different
% results for the first segmentation that is run at the beginning of a
% MATLAB session
%
%% Reference:
% https://www.jiscmail.ac.uk/cgi-bin/wa-jisc.exe?A2=ind2008&L=SPM&D=0&O=D&P=44613
% 
%% Defaults:
% batch_size:   20
% dir_out:      same as dir_in
% 
%% Author(s):
% Parekh, Pravesh
% August 21, 2020
% MBIAL

%% Check inputs
% Check dir_in
if ~exist('dir_in', 'var') || isempty(dir_in)
    error('Please provide full path to a directory having AC-PC aligned T1w images');
else
    if ~exist(dir_in, 'dir')
        error(['Unable to find: ', dir_in]);
    end
end

% Check batch_size
if ~exist('batch_size', 'var') || isempty(batch_size)
    batch_size = 20;
else
    if ~isnumeric(batch_size)
        error('batch_size should be a number');
    end
end

% Check out_dir
if ~exist('dir_out', 'var') || isempty(dir_out)
    dir_out = dir_in;
end
if ~exist(dir_out, 'dir') 
    mkdir(dir_out);
end

%% Build subject list
cd(dir_in);
list_subjs  = dir('sub-*.nii');
num_subjs   = length(list_subjs);
act_list    = fullfile(dir_in, strcat({list_subjs(:).name}, ',1'))';

%% Work out installation directories
dir_spm = fileparts(which('spm'));
dir_cat = fileparts(which('cat12'));

%% Figure out batches
batch_lims  = 1:batch_size:num_subjs;
num_batches = length(batch_lims);
for batch   = 1:num_batches
        
    % Handle the case of first batch
    if batch == 1
        to_include = act_list(1:batch_lims(2)-1);
    else
        % Handle last case
        if batch == num_batches
            to_include = act_list(batch_lims(batch):end);
        else
            % Handle other cases
            to_include = act_list(batch_lims(batch):batch_lims(batch+1)-1);
        end
    end
    
    % Identify dummy subject
    [~, dummy] = fileparts(to_include{1});
    
    % Create a copy in the source directory
    copyfile(fullfile(dir_in, [dummy, '.nii']), fullfile(dir_in, ['dum', dummy, '.nii']));
    
    % Put the dummy scan on the top of the list
    to_include = [fullfile(dir_in, ['dum', dummy, '.nii,1']); to_include]; %#ok<AGROW>
    
    % Populate CAT12.6 v1450 expert batch
    clear matlabbatch
    % Initial settings
    matlabbatch{1}.spm.tools.cat.estwrite.data                                  = to_include;
    matlabbatch{1}.spm.tools.cat.estwrite.nproc                                 = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.opts.tpm                              = {fullfile(dir_spm, 'tpm', 'TPM.nii')};
    matlabbatch{1}.spm.tools.cat.estwrite.opts.affreg                           = 'mni';
    matlabbatch{1}.spm.tools.cat.estwrite.opts.biasstr                          = 0.5;
    matlabbatch{1}.spm.tools.cat.estwrite.opts.accstr                           = 0.5;
    matlabbatch{1}.spm.tools.cat.estwrite.extopts.segmentation.APP              = 1070;
    matlabbatch{1}.spm.tools.cat.estwrite.extopts.segmentation.NCstr            = -Inf;
    matlabbatch{1}.spm.tools.cat.estwrite.extopts.segmentation.LASstr           = 0.5;
    matlabbatch{1}.spm.tools.cat.estwrite.extopts.segmentation.gcutstr          = 2;
    matlabbatch{1}.spm.tools.cat.estwrite.extopts.segmentation.cleanupstr       = 0.5;
    matlabbatch{1}.spm.tools.cat.estwrite.extopts.segmentation.WMHC             = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.extopts.segmentation.SLC              = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.extopts.segmentation.restypes.fixed   = [1 0.1];
    matlabbatch{1}.spm.tools.cat.estwrite.extopts.registration.dartel.darteltpm = {fullfile(dir_cat, 'templates_1.50mm', 'Template_1_IXI555_MNI152.nii')};
    matlabbatch{1}.spm.tools.cat.estwrite.extopts.vox                           = 1.5;
    matlabbatch{1}.spm.tools.cat.estwrite.extopts.surface.pbtres                = 0.5;
    matlabbatch{1}.spm.tools.cat.estwrite.extopts.surface.scale_cortex          = 0.7;
    matlabbatch{1}.spm.tools.cat.estwrite.extopts.surface.add_parahipp          = 0.1;
    matlabbatch{1}.spm.tools.cat.estwrite.extopts.surface.close_parahipp        = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.extopts.admin.ignoreErrors            = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.extopts.admin.verb                    = 2;
    matlabbatch{1}.spm.tools.cat.estwrite.extopts.admin.print                   = 2;
    matlabbatch{1}.spm.tools.cat.estwrite.output.surface                        = 1;

    % ROI/atlas options
    matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.neuromorphometrics = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.lpba40             = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.cobra              = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.hammers            = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.ibsr               = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.aal                = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.mori               = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.anatomy            = 1;

    % Saving various files
    matlabbatch{1}.spm.tools.cat.estwrite.output.GM.native      = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.GM.warped      = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.output.GM.mod         = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.GM.dartel      = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.output.WM.native      = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.WM.warped      = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.output.WM.mod         = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.WM.dartel      = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.output.CSF.native     = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.CSF.warped     = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.output.CSF.mod        = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.CSF.dartel     = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.output.WMH.native     = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.output.WMH.warped     = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.output.WMH.mod        = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.output.WMH.dartel     = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.output.SL.native      = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.output.SL.warped      = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.output.SL.mod         = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.output.SL.dartel      = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.output.atlas.native   = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.atlas.dartel   = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.output.label.native   = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.label.warped   = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.label.dartel   = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.output.bias.native    = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.bias.warped    = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.bias.dartel    = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.output.las.native     = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.las.warped     = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.las.dartel     = 0;
    matlabbatch{1}.spm.tools.cat.estwrite.output.jacobianwarped = 1;
    matlabbatch{1}.spm.tools.cat.estwrite.output.warps          = [1 1];
    
    % Save this batch
    save(fullfile(dir_out, ['batch_segment_cat12expert_', num2str(batch, '%03d'), '.mat']), 'matlabbatch');
end