function qc_fmri_brainmask(data_dir, task_name, threshold, smoothed, full_bids)
% Function to create and count the number of voxels in the whole brain mask
% created as a percentage of global signal
%% Inputs:
% data_dir:         full path to a directory having sub-* folders (BIDS
%                   style; see Notes)
% task_name:        functional file name pattern for which QC is being 
%                   performed (example: 'rest')
% threshold:        value between 0-1 indicating the percentage of global
%                   signal threshold to be used for creating brain mask
% smoothed:         yes/no to indicate if brain mask should be created from
%                   smoothed normalized file or just normalized file
% full_bids:        yes/no to indicate if the data_dir is a full BIDS style
%                   folder (i.e. it has anat and func sub-folders) or all 
%                   files are present in a single folder (see Notes)
% 
%% Outputs:
% Within the already existing 'quality_check_<task_name>' in each subject's
% folder, task specific brain mask file is created named
% <subject_ID>_<task_name>_brainmask.nii
% The number of voxels in the brain mask are written in a mat file named
% <subject_ID>_<task_name>_brainmask_voxcount.mat
% Image showing different slices of the brainmask are also saved named
% <subject_ID>_<task_name>_brainmask_sagittal.png
% <subject_ID>_<task_name>_brainmask_coronal.png
% <subject_ID>_<task_name>_brainmask_transverse.png
% 
%% Notes:
% Each sub-* folder should have a quality_check_<task_name> folder (created
% by qc_fmri_roi_signal)
% 
% Full BIDS specification means that there are separate anat and func
% folders inside the subject folder; if specified as no, the files should
% still be named following BIDS specification but all files are assumed to
% be in the same folder
% 
% A resliced version of the brainmask file having dimensions 91x109x91 is
% created by coregistering and reslicing the ICV.nii file (located in the
% TPM folder inside SPM directory). avg152T1.nii file (located in the
% canonical folder inside SPM directory) is used as a reference file.
% 
% Requires calc_rows_cols_subplot
% 
%% Default:
% threshold:        0.8
% smoothed:         'yes'
% full_bids:        'yes'
% 
%% Author(s)
% Parekh, Pravesh
% August 23, 2018
% MBIAL

%% Validate input and assign defaults
% Check data_dir
if ~exist('data_dir', 'var') || isempty(data_dir)
    error('data_dir needs to be given');
else
    if ~exist(data_dir, 'dir')
        error(['Unable to find data_dir: ', data_dir]);
    end
end

% Check task_name
if ~exist('task_name', 'var') || isempty(task_name)
    error('task_name needs to be given');
end

% Check threshold
if ~exist('threshold', 'var') || isempty(threshold)
    threshold = 0.8;
else
    if threshold < 0 || threshold > 1
        error('threshold value should be between 0 and 1');
    end
end

% Check smoothed
if ~exist('smoothed', 'var') || isempty(smoothed)
    smoothed = 1;
else
    if strcmpi(smoothed, 'yes')
        smoothed = 1;
    else
        if strcmpi(smoothed, 'no')
            smoothed = 0;
        else
            error(['Invalid smoothed value specified: ', smoothed]);
        end
    end
end

% Check full_bids
if ~exist('full_bids', 'var') || isempty(full_bids)
    full_bids = 1;
else
    if strcmpi(full_bids, 'yes')
        full_bids = 1;
    else
        if strcmpi(full_bids, 'no')
            full_bids = 0;
        else
            error(['Invalid full_bids value specified: ', full_bids]);
        end
    end
end

%% Create subject list
cd(data_dir);
list_subjs = dir('sub-*');
num_subjs  = length(list_subjs);

%% Create resliced version of brainmask.nii
% Save the brainmask file in the first subject's quality_check directory
if full_bids
    out_dir = fullfile(data_dir, list_subjs(1).name, 'func', ...
                       ['quality_check_', task_name]);
else
    out_dir = fullfile(data_dir, list_subjs(1).name, ...
                       ['quality_check_', task_name]);
end

% Get SPM directory
spm_loc = which('spm');
[spm_loc, ~] = fileparts(spm_loc);

% Copy the files out of spm directories into the output directory
reference_file  = fullfile(spm_loc, 'canonical', 'avg152T1.nii');
source_file     = fullfile(spm_loc, 'tpm', 'mask_ICV.nii');
copyfile(reference_file, out_dir);
copyfile(source_file, out_dir);

% Update reference and source locations
reference_file  = fullfile(out_dir, 'avg152T1.nii');
source_file     = fullfile(out_dir, 'mask_ICV.nii');

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
cd(out_dir);
spm_jobman('initcfg');
spm_jobman('run', matlabbatch);

% Rename the created file to brainmask.nii
movefile('rmask_ICV.nii', 'brainmask.nii')

% Delete intermediate files
spm_tmp = ['spm_', datestr(now, 'yyyymmmdd'), '.ps'];
if exist(spm_tmp, 'file')
    delete(spm_tmp);
end
delete(reference_file);
delete(source_file);
brainmask = fullfile(out_dir, 'brainmask.nii');

% Calculate number of voxels in the template brain mask
tmp_data = spm_read_vols(spm_vol(brainmask));
vox_count_template = length(nonzeros(tmp_data==1));
clear tmp_data

%% Initialize variables and set defaults for saving images
dim_i   = 91;
dim_j   = 109;
dim_k   = 91;
gap     = 2;
row_gap = 10;
col_off = 5;

if ~isunix
    fontname = 'consolas';
else
    fontname = 'DejaVu Sans';
end

img_colours = [0 0 0; 0.8784 0.8784 0.8784];
text_colour = [0.8784 0.8784 0.8784];

set(0, 'defaultTextFontSize',12);
set(0, 'defaultTextFontName',fontname);
set(0, 'defaultTextColor',text_colour);


%% Work on each subject
for sub = 1:num_subjs
    
    % Locate quality_check folder
    if full_bids
        qc_dir = fullfile(data_dir, list_subjs(sub).name, 'func', ...
                          ['quality_check_', task_name]);
    else
        qc_dir = fullfile(data_dir, list_subjs(sub).name, ...
                          ['quality_check_', task_name]);
    end
    
    if ~exist(qc_dir, 'dir')
        warning(['Cannot locate quality_check_', task_name, ' for ', ...
                list_subjs(sub).name, '; skipping']);
    else
        
        % Locate EPI file for this subject
        if full_bids
            epi_dir = fullfile(data_dir, list_subjs(sub).name, 'func');
        else
            epi_dir = fullfile(data_dir, list_subjs(sub).name);
        end
        cd(epi_dir);
        if smoothed
            list_func_files = dir(['sw*', task_name, '*.nii']);
        else
            list_func_files = dir(['w*', task_name, '*.nii']);
        end
        
         % Remove any files which got listed and are not 4D files
         idx = false(length(list_func_files),1);
         for files = 1:length(list_func_files)
             vol = spm_vol(list_func_files(files).name);
             if size(vol,1) == 1
                 idx(files) = 1;
             end
         end
         list_func_files(idx) = [];
         
         % If none or multiple files exist, show warning and skip this subject
         if isempty(list_func_files)
             warning(['No matching files found for ', list_subjs(sub).name, '; skipping']);
             skip = 1;
         else
             if length(list_func_files) > 1
                 warning(['Multiple files found for ', list_subjs(sub).name, '; skipping']);
                 skip = 1;
             else
                 skip = 0;
             end
         end
         
         % Create mask
         if ~skip
             func_file = list_func_files(1).name;
             
             % Get global signal
             gs = spm_global(spm_vol(fullfile(epi_dir, func_file)));
             
             % Create mask
             spm_mask(func_file, brainmask, threshold*gs);
             
             % Rename saved mask
             cd(out_dir);
             mrmask    = dir('mbrainmask.nii');
             move_name = fullfile(qc_dir, [list_subjs(sub).name, '_', ...
                                  task_name, '_brainmask.nii']);
             movefile(fullfile(out_dir, mrmask.name), move_name);
             
             % Load the mask and count number of voxels
             mask_data = spm_read_vols(spm_vol(move_name));
             vox_count_brainmask  = length(nonzeros(mask_data==1));
             vox_count_difference = vox_count_template - vox_count_brainmask;
             
             % Save mat file having voxel count
             save_name = fullfile(qc_dir, [list_subjs(sub).name, '_', ...
                                  task_name, '_brainmask_voxcount.mat']);
             save(save_name, 'vox_count_brainmask', 'vox_count_difference', ...
                             'vox_count_template',  'func_file', 'threshold');

             % Create sagittal, coronal, and axial images
             %% Sagittal view
             %  -------------
             % Find first slice where there is some intensity value
             for i = 1:dim_i
                 tmp = squeeze(mask_data(i,:,:));
                 if ~isempty(nonzeros(tmp))
                     min_i = i;
                     break
                 end
             end
             
             % Find last slice where there is some intensity value
             for i = dim_i:-1:1
                 tmp = squeeze(mask_data(i,:,:));
                 if ~isempty(nonzeros(tmp))
                     max_i = i;
                     break
                 end
             end
             
             % Figure out number of plots to be made
             loc = min_i:gap:max_i;
             [rows, cols] = calc_rows_cols_subplot(length(loc));
             
             % Initialize
             overall_image = zeros((dim_k*cols)+(row_gap*cols*1.2), (dim_j*rows));
             empty_image   = zeros(dim_k,dim_j);
             count         = 1;
             row_begin     = 1;
             col_begin     = 1;
             
             % Stitch together images
             for row = 1:rows
                 if count > length(loc)
                     break
                 else
                     for col = 1:cols
                         if count > length(loc)
                             overall_image(row_begin:row_begin+dim_k-1, ...
                             col_begin:col_begin+dim_j-1) = empty_image;
                         else
                             overall_image(row_begin:row_begin+dim_k-1, ...
                             col_begin:col_begin+dim_j-1) = ...
                             rot90(squeeze(mask_data(loc(count),:,:)));
                         end
                         col_begin = col_begin+dim_j;
                         count = count + 1;
                     end
                 end
                 row_begin = row_begin+dim_k;
                 col_begin = 1;
             end
             
             % Show the image
             fig1 = figure('Color', [0 0 0], 'PaperType', 'A5', ...
                           'InvertHardCopy', 'off', 'Visible', 'off');
             imshow(overall_image, 'border', 'tight');
             colormap(img_colours);
             
             % Add text
             num_slices = length(loc);
             num_lines  = ceil(num_slices/15);
             multiplier  = 3;
             start_slice = 1;
             if smoothed
                 text(col_off, dim_k*rows+row_gap, [list_subjs(sub).name, ...
                     ' ', task_name, ' smoothed Brainmask (',             ...
                     num2str(threshold*100), '% GS); ',                   ...
                     num2str(vox_count_brainmask), ' vx; ',               ...
                     num2str(vox_count_difference), ' vx less']);
             else
                 text(col_off, dim_k*rows+row_gap, [list_subjs(sub).name, ...
                     ' ', task_name, ' non-smoothed Brainmask (',         ...
                     num2str(threshold*100), '% GS); ',                   ...
                     num2str(vox_count_brainmask), ' vx; ',               ...
                     num2str(vox_count_difference), ' vx less']);
             end

             for line = 1:num_lines
                 if line == num_lines
                     text(col_off, dim_k*rows+row_gap*multiplier, ...
                         ['Slices: ', num2str(loc(start_slice:end), '%02d, ')]);
                 else
                     text(col_off, dim_k*rows+row_gap*multiplier, ...
                         ['Slices: ', num2str(loc(start_slice:start_slice+14), '%02d, ')]);
                 end
                 multiplier  = multiplier  + 1.5;
                 start_slice = start_slice + 15;
             end
             
             % Save the image
             print(fig1, fullfile(qc_dir, [list_subjs(sub).name, '_', ...
                 task_name, '_brainmask_sagittal.png']), '-dpng', '-r600');
             close(fig1);
             
             %% Coronal view
             %  -------------
             % Find first slice where there is some intensity value
             for j = 1:dim_j
                 tmp = squeeze(mask_data(:,j,:));
                 if ~isempty(nonzeros(tmp))
                     min_j = j;
                     break
                 end
             end
             
             % Find last slice where there is some intensity value
             for j = dim_j:-1:1
                 tmp = squeeze(mask_data(:,j,:));
                 if ~isempty(nonzeros(tmp))
                     max_j = j;
                     break
                 end
             end
             
             % Figure out number of plots to be made
             loc = fliplr(min_j:gap:max_j);
             [rows, cols] = calc_rows_cols_subplot(length(loc));
             
             % Initialize
             overall_image = zeros((dim_i*cols)+(row_gap*cols*1.2), (dim_k*rows));
             empty_image   = zeros(dim_i,dim_k);
             count         = 1;
             row_begin     = 1;
             col_begin     = 1;
             
             % Stitch together images
             for col = 1:cols
                 if count > length(loc)
                     break
                 else
                     for row = 1:rows
                         if count > length(loc)
                             overall_image(row_begin:row_begin+dim_i-1, ...
                                 col_begin:col_begin+dim_k-1) = empty_image;
                         else
                             overall_image(row_begin:row_begin+dim_i-1, ...
                                 col_begin:col_begin+dim_k-1) = ...
                                 rot90(squeeze(mask_data(:,loc(count),:)));
                         end
                         col_begin = col_begin+dim_k;
                         count     = count + 1;
                     end
                 end
                 row_begin = row_begin+dim_i;
                 col_begin = 1;
             end
             
             % Show the image
             fig2 = figure('Color', [0 0 0], 'PaperType', 'A5', ...
                           'InvertHardCopy', 'off', 'Visible', 'off');
             imshow(overall_image, 'border', 'tight');
             colormap(img_colours);
             
             % Add text
             num_slices = length(loc);
             num_lines  = ceil(num_slices/15);
             multiplier  = 3;
             start_slice = 1;
             if smoothed
                 text(col_off, dim_i*cols+row_gap, [list_subjs(sub).name, ...
                     ' ', task_name, ' smoothed Brainmask (',             ...
                     num2str(threshold*100), '% GS); ',                   ...
                     num2str(vox_count_brainmask), ' vx; ',               ...
                     num2str(vox_count_difference), ' vx less']);
             else
                 text(col_off, dim_i*cols+row_gap, [list_subjs(sub).name, ...
                     ' ', task_name, ' non-smoothed Brainmask (',         ...
                     num2str(threshold*100), '% GS); ',                   ...
                     num2str(vox_count_brainmask), ' vx; ',               ...
                     num2str(vox_count_difference), ' vx less']);
             end

             for line = 1:num_lines
                 if line == num_lines
                     text(col_off, dim_i*cols+row_gap*multiplier, ...
                         ['Slices: ', num2str(loc(start_slice:end), '%02d, ')]);
                 else
                     text(col_off, dim_i*cols+row_gap*multiplier, ...
                         ['Slices: ', num2str(loc(start_slice:start_slice+14), '%02d, ')]);
                 end
                 multiplier  = multiplier  + 1.5;
                 start_slice = start_slice + 15;
             end
             
             % Save the image
             print(fig2, fullfile(qc_dir, [list_subjs(sub).name, '_', ...
                 task_name, '_brainmask_coronal.png']), '-dpng', '-r600');
             close(fig2);
             
             %% Transverse view
             %  ----------------
             % Find first slice where there is some intensity value
             for k = 1:dim_k
                 tmp = mask_data(:,:,k);
                 if ~isempty(nonzeros(tmp))
                     min_k = k;
                     break
                 end
             end
             
             % Find last slice where there is some intensity value
             for k = dim_k:-1:1
                 tmp = mask_data(:,:,k);
                 if ~isempty(nonzeros(tmp))
                     max_k = k;
                     break
                 end
             end
             
             % Figure out number of plots to be made
             loc = fliplr(min_k:gap:max_k);
             [rows, cols] = calc_rows_cols_subplot(length(loc));
             
             % Initialize
             overall_image = zeros((dim_j*rows)+(row_gap*cols),(dim_i*cols));
             empty_image   = zeros(dim_j,dim_i);
             count         = 1;
             row_begin     = 1;
             col_begin     = 1;
             
             % Stitch together images
             for row = 1:rows
                 if count > length(loc)
                     break
                 else
                     for col = 1:cols
                         if count > length(loc)
                             overall_image(row_begin:row_begin+dim_j-1, ...
                                 col_begin:col_begin+dim_i-1) = empty_image;
                         else
                             overall_image(row_begin:row_begin+dim_j-1, ...
                                 col_begin:col_begin+dim_i-1) = ...
                                 rot90(mask_data(:,:,loc(count)));
                         end
                         count     = count + 1;
                         col_begin = col_begin+dim_i;
                     end
                 end
                 row_begin = row_begin+dim_j;
                 col_begin = 1;
             end
             
             % Show the image
             fig3 = figure('Color', [0 0 0], 'PaperType', 'A5', ...
                           'InvertHardCopy', 'off', 'Visible', 'off');
             imshow(overall_image, 'border', 'tight');
             colormap(img_colours);
             
             % Add text
             num_slices = length(loc);
             num_lines  = ceil(num_slices/15);
             multiplier  = 3;
             start_slice = 1;
             if smoothed
                 text(col_off, dim_j*rows+row_gap, [list_subjs(sub).name, ...
                     ' ', task_name, ' smoothed Brainmask (',             ...
                     num2str(threshold*100), '% GS); ',                   ...
                     num2str(vox_count_brainmask), ' vx; ',               ...
                     num2str(vox_count_difference), ' vx less']);
             else
                 text(col_off, dim_j*rows+row_gap, [list_subjs(sub).name, ...
                     ' ', task_name, ' non-smoothed Brainmask (',         ...
                     num2str(threshold*100), '% GS); ',                   ...
                     num2str(vox_count_brainmask), ' vx; ',               ...
                     num2str(vox_count_difference), ' vx less']);
             end

             for line = 1:num_lines
                 if line == num_lines
                     text(col_off, dim_j*rows+row_gap*multiplier, ...
                         ['Slices: ', num2str(loc(start_slice:end), '%02d, ')]);
                 else
                     text(col_off, dim_j*rows+row_gap*multiplier, ...
                         ['Slices: ', num2str(loc(start_slice:start_slice+14), '%02d, ')]);
                 end
                 multiplier  = multiplier  + 1.5;
                 start_slice = start_slice + 15;
             end
             
             % Save the image
             print(fig3, fullfile(qc_dir, [list_subjs(sub).name, '_', ...
                 task_name, '_brainmask_transverse.png']), '-dpng', '-r600');
             close(fig3);
         end
    end
    % Clear some variables
    clear save_name vox_count func_file qc_dir mask_data mrmask ...
          skip list_func_files epi_dir qc_dir vol idx loc rows row cols col ...
          multiplier start_slice num_slices num_lines fig1 fig2 fig3 ...
          row_begin col_begin overall_image empty_image tmp i j k
end

%% Delete resliced version of brainmask file
delete(brainmask);

%% Restore all changed graphics settings
set(0, 'defaultTextFontSize','remove');
set(0, 'defaultTextFontName','remove');
set(0, 'defaultTextColor','remove');