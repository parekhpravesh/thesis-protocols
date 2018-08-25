function qc_fmri_roi_signal(data_dir, roi_dir, task_name, summary_measure, ...
                            mask_gm, mask_prob, smoothed, full_bids, clean)
% Function to extract and plot summary time series from a set of regions of
% interest for quality check
%% Inputs:
% data_dir:         full path to a directory having sub-* folders (BIDS
%                   style; see Notes for how functional files are detected)
% roi_dir:          full path to a directory having binary regions of
%                   interest file (.nii)
% task_name:        functional file name pattern for which QC is being 
%                   performed (example: 'rest')
% summary_measure:  measure to be used for extracting time series using
%                   REX; can be one of the following:
%                       * 'mean'
%                       * 'eigenvariate'
%                       * 'median'
% mask_gm:          yes/no to indicate if subject specific GM mask should
%                   be applied before signal extraction; GM segmentation
%                   files should be present in subject directory (in the
%                   anat folder if full_bids, otherwise in the same folder
%                   as the functional files)
% mask_prob:    	probability value at which subject specific GM mask is
%                   thresholded before applying to ROI file
% smoothed:         yes/no to indicate if signal should be extracted from
%                   smoothed normalized file or just normalized file
% full_bids:        yes/no to indicate if the data_dir is a full BIDS style
%                   folder (i.e. it has anat and func sub-folders) or all 
%                   files are present in a single folder (see Notes)
% clean:            yes/no to indicate if the saved subject specific ROI
%                   files should be deleted or retained afterwards
% 
%% Outputs:
% A folder named 'quality_check_<task_name>' is created in each sub-* 
% folder inside data_dir. If full_bids is specified, quality_check is made 
% inside the func folder. Inside this folder, signal profiles are stored 
% as graphs and mat files. A csv file having voxel count for subject 
% specific ROI is also written out.
%
%% Notes:
% Within a subject sub- folder, a search is made for smoothed normalized
% and unwarped (swu*.nii) files. Once done, native space is simply the same
% filename without the 'sw' (smoothed, normalized); however, native space
% data is derived from realigned and unwarped file (otherwise voxels might
% not be in alignment with each other)
%
% Only a single functional file per subject is worked on. If multiple files
% matching the task_name pattern is found, a warning is displayed and the
% subject is skipped
%
% If normalized GM segmentation files' (wc1*.nii) dimension does not match
% MNI space (2mm isotropic, 91x109x91), the deformation field is used to
% rewrite the segmentation file. This file is written in the
% "quality_check" folder inside the subject folder.
%
% All ROIs should be in MNI space (2mm isotropic, 91x109x91)
% 
% Native space signal extraction is now deprecated
% 
% Full BIDS specification means that there are separate anat and func
% folders inside the subject folder; if specified as no, the files should
% still be named following BIDS specification but all files are assumed to
% be in the same folder
% 
% If number of ROIs >=3 and <= 12, colour scheme of the plot is selected
% from colorbrewer2 (http://colorbrewer2.org) qualitative series; 
% in other cases, colour scheme is left to MATLAB
% 
% If clean is specified, all NIfTI files present in the subject's
% quality_check_<task_name> folder will be deleted
% 
% Requires REX from Conn toolbox
%
%% Defaults:
% summary_measure:  'mean'
% mask_gm:          'yes'
% mask_gm_prob:     0.2
% smoothed:         'no'
% full_bids:        'yes'
% clean:            'no'
%
%% Author(s)
% Parekh, Pravesh
% June 09, 2018
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

% Check roi_dir
if ~exist('roi_dir', 'var') || isempty(roi_dir)
    error('roi_dir needs to be given');
else
    if ~exist(roi_dir, 'dir')
        error(['Unable to find roi_dir: ', roi_dir]);
    end
end

% Check task_name
if ~exist('task_name', 'var') || isempty(task_name)
    error('task_name needs to be given');
end

% Check summary_measure
if ~exist('summary_measure', 'var') || isempty(summary_measure)
    summary_measure = 'mean';
else
    if ~ismember(summary_measure, {'mean', 'eigenvariate', 'median'})
        error(['Unknown summary_measure: ', summary_measure, ' provided']);
    end
end

% Check mask_gm
if ~exist('mask_gm', 'var') || isempty(mask_gm)
    mask_gm = 1;
else
    if strcmpi(mask_gm, 'yes')
        mask_gm = 1;
    else
        if strcmpi(mask_gm, 'no')
            mask_gm = 0;
        else
            error(['Invalid mask_gm value specified :', mask_gm]);
        end
    end
end

% Check mask_prob
if ~exist('mask_prob', 'var') || isempty(mask_prob)
    mask_prob = 0.2;
else
    if mask_prob < 0 || mask_prob > 1
        error('mask_prob value should be between 0 and 1');
    end
end

% Check smoothed
if ~exist('smoothed', 'var') || isempty(smoothed)
    smoothed = 0;
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

% Check clean
if ~exist('clean', 'var') || isempty(clean)
    clean = 0;
else
    if strcmpi(clean, 'yes')
        clean = 1;
    else
        if strcmpi(clean, 'no')
            clean = 0;
        else
            error(['Invalid clean value specified: ', clean]);
        end
    end
end

%% Create subject list
cd(data_dir);
list_subjs = dir('sub-*');
num_subjs  = length(list_subjs);

%% Create ROI list and read in ROIs
cd(roi_dir)
list_rois = dir('*.nii');
num_rois  = length(list_rois);

% Load all ROIs into a single variable; assumes all ROIs have MNI dimension
% of 91x109x91
roi_data = zeros(91,109,91,num_rois);
for rois = 1:num_rois
    tmp = spm_read_vols(spm_vol(fullfile(roi_dir, list_rois(rois).name)));
    [x,y,z] = size(tmp);
    if x ~= 91 || y ~= 109 || z ~= 91
        error(['ROI ', list_rois(rois).name, ' has incorrect dimensions']);
    else
        roi_data(:,:,:,rois) = tmp;
    end
end

% Save some header information for further use
header = spm_vol(list_rois(1).name);

%% Colour scheme
if num_rois >=3 && num_rois <=9
    % 9-class Set 1
    colour_scheme = [228 26 28 ; 55 126 184; 77 175 74; 152 78 163; 255 127 0; ...
                     255 255 51; 166 86 40 ; 247 129 191; 153 153 153]./255;
else
    if num_rois >9 && num_rois <=12
        % 12-class Set 3
        colour_scheme = [141 211 199; 255 255 179; 190 186 218; 251 128 114; ...
                         128 177 211; 253 180 98 ; 179 222 105; 252 205 229; ...
                         217 217 217; 188 128 189; 204 235 197; 255 237 111]./255;
    end
end

%% Work on each subject
for sub = 1:num_subjs
    
    if full_bids
        cd(fullfile(data_dir, list_subjs(sub).name, 'func'));
    else
        cd(fullfile(data_dir, list_subjs(sub).name));
    end
    
    % List smoothed normalized or normalized files which match the
    % task_name pattern
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
    
    if ~skip
        func_files = list_func_files(1).name;
        
        % Make quality_check folder for this subject
        if full_bids
            qc_dir = fullfile(data_dir, list_subjs(sub).name, 'func',  ['quality_check_', task_name]);
            if ~exist(fullfile(data_dir, list_subjs(sub).name, 'func', ['quality_check_', task_name]), 'dir')
                mkdir(fullfile(data_dir, list_subjs(sub).name, 'func', ['quality_check_', task_name]));
            end
        else
            qc_dir = fullfile(data_dir, list_subjs(sub).name,  ['quality_check_', task_name]);
            if ~exist(fullfile(data_dir, list_subjs(sub).name, ['quality_check_', task_name]), 'dir')
                mkdir(fullfile(data_dir, list_subjs(sub).name, ['quality_check_', task_name]));
            end
        end
        
        % Initialize some variables
        sub_roi_data   = zeros(91,109,91,num_rois);
        list_sub_roi_files = cell(num_rois,1);
        
        if mask_gm
            roi_vox_count  = cell(num_rois+1,2);
        else
            roi_vox_count  = cell(num_rois,2);
        end
        
        % If mask_gm, get GM segmentation file
        if mask_gm
            if full_bids
                cd(fullfile(data_dir, list_subjs(sub).name, 'anat'));
            end
            gm_file = dir('wc1*.nii');
            gm_file = gm_file(1).name;
            gm_data = spm_read_vols(spm_vol(gm_file));
            
            % Check if the gm_data has the same dimensions as 91x109x91
            [x,y,z] = size(gm_data);
            if x ~= 91 || y ~= 109 || z ~= 91
                % Find forward deformation field and rewrite the normalized
                % file to the MNI dimensions
                fwd_deform = dir('y*.nii');
                
                if isempty(fwd_deform)
                    warning(['Forward deformation field not found for ', ...
                            list_subjs(sub).name, '; skipping']);
                        skip = 1;
                else
                    if length(fwd_deform) > 1
                        warning(['Multiple deformation fields found for ', ...
                                 list_subjs(sub).name, '; selecting: ', ...
                                 fwd_deform(1).name]);
                        fwd_deform = fwd_deform(1).name;
                    else
                        fwd_deform = fwd_deform(1).name;
                    end
                end
                
                if ~skip
                    % Run normalize module
                    matlabbatch{1}.spm.spatial.normalise.write.subj.def = {fwd_deform};
                    matlabbatch{1}.spm.spatial.normalise.write.subj.resample = ...
                            {fullfile(data_dir, list_subjs(sub).name, gm_file)};
                    matlabbatch{1}.spm.spatial.normalise.write.woptions.bb     = [NaN NaN NaN
                                                                                  NaN NaN NaN];
                    matlabbatch{1}.spm.spatial.normalise.write.woptions.vox    = [2 2 2];
                    matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 7;
                    matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'MNI_';
                    spm_jobman('run',matlabbatch);
                    
                    % Read this file
                    gm_file = dir('MNI_*.nii');
                    gm_file = gm_file(1).name;
                    gm_data = spm_read_vols(spm_vol(gm_file));
                end
            end
            
            % Threshold and binarize
            gm_data(gm_data <  mask_prob) = 0;
            gm_data(gm_data >= mask_prob) = 1;
            
            % Save binarized GM segmentation file
            header.fname = fullfile(qc_dir, [list_subjs(sub).name, ...
                                    '-GM_mask_', num2str(mask_prob, '%0.2f'), '.nii']);
            spm_write_vol(header, gm_data);
            
            % Get voxel count for GM mask
            roi_vox_count{1,1}  = [list_subjs(sub).name, '-GM_mask_', ...
                                  num2str(mask_prob, '%0.2f')];
            roi_vox_count{1,2}  = length(nonzeros(gm_data(:)));
        end
        
        % Threshold ROIs and write subject specific ROIs; also count number
        % of voxels present in the mask
        for rois = 1:num_rois
            if mask_gm
                header.fname = fullfile(qc_dir, [list_subjs(sub).name, '-', ...
                                        strrep(list_rois(rois).name, '.nii', ''), ...
                                        '_', num2str(mask_prob, '%0.2f'), '.nii']);
                                
                sub_roi_data(:,:,:,rois)   = roi_data(:,:,:,rois).*gm_data;
                list_sub_roi_files{rois,1} = header.fname;
                roi_vox_count{rois+1,1}    = list_rois(rois).name;
                roi_vox_count{rois+1,2}    = length(nonzeros(sub_roi_data(:,:,:,rois)));
            else
                header.fname = fullfile(qc_dir, [list_subjs(sub).name, '-', ...
                                        list_rois(rois).name]);
                sub_roi_data(:,:,:,rois)   = roi_data(:,:,:,rois);
                list_sub_roi_files{rois,1} = header.fname;
                roi_vox_count{rois,1}      = list_rois(rois).name;
                roi_vox_count{rois,2}      = length(nonzeros(sub_roi_data(:,:,:,rois)));
            end
            spm_write_vol(header, squeeze(sub_roi_data(:,:,:,rois)));
        end
        
        % Get time series for all ROIs
        if full_bids
            time_series = rex(fullfile(data_dir, list_subjs(sub).name, 'func', ...
                              func_files), list_sub_roi_files, ...
                              'summary_measure', summary_measure);
        else
            time_series = rex(fullfile(data_dir, list_subjs(sub).name, func_files), ...
                          list_sub_roi_files, 'summary_measure', summary_measure);
        end
        
        % Write out voxel count for all ROIs
        writetable(cell2table(roi_vox_count, 'VariableNames', ...
                  {'ROI_Name', 'Voxel_Count'}), fullfile(qc_dir, ...
                  [list_subjs(sub).name, '_', task_name, '_VoxelCount.csv']));
        
        % Save the variable containing the time series for the subject
        save(fullfile(qc_dir, [list_subjs(sub).name, '_', task_name, ...
                     '_TimeSeries.mat']), 'time_series', 'list_sub_roi_files');
         
         % Create legend entries
         legend_entries = cell(num_rois, 1);
         for rois = 1:num_rois
             [~, tmp] = fileparts(list_sub_roi_files{rois});
             % Remove subject name and hyphen from ROI name
             tmp = strrep(tmp, [list_subjs(sub).name, '-'], '');
             legend_entries{rois} = tmp;
         end
         
         % Plot time_series and save the figure
         fig = figure('PaperType', 'A5', 'Color', [1 1 1], 'Visible', 'off');
         if num_rois >=3 && num_rois <=12
             for roi_count = 1:num_rois
                 plot(time_series(:,roi_count), 'Color', colour_scheme(roi_count,:));
                 hold on;
             end
         else
             plot(time_series);
         end
         box off;
         title([list_subjs(sub).name, ': ', task_name, ' - Time Series']);
         legend(legend_entries, 'Interpreter', 'none', ...
                'Location', 'northeastoutside', 'FontSize', 6, ...
                'Orientation', 'vertical', 'Box', 'off')
         print(fig, fullfile(qc_dir, [list_subjs(sub).name, '_', task_name, ...
                             '_TimeSeries.png']), '-dpng', '-r600');
         close(fig);
         
         % Remove subject level ROI files created if user wants
         if clean
             cd(qc_dir);
             list_files = dir('*.nii');
             for file = 1:length(list_files)
                 delete(list_files(file).name);
             end
         end
        
        % Clear some variables to prevent any conflicts
        clear list_func_files idx files vol skip func_files sub_roi_data ...
              list_sub_roi_files roi_vox_count gm_file gm_data time_series   ...
              matlabbatch tmp fig legend_entries sub_name
    end
end

%% Deprecated module for native space signal extraction
% 
% If native space signal is also needed, inverse deformation field is
% applied to ROI files for converting to native space; these ROIs are
% additionally saved in the quality_check folder
% 
% native:           yes/no to indicate if signal should be additionally
%                   extracted from native space realigned image
% smooth_native:    yes/no to indicate if native space data should be
%                   smoothed before signal extraction
% smooth_fwhm:      single value to indicate the smoothing amount (same
%                   value is used for all three directions)
%
%
% native:           'yes'
% smooth_native:    'no'
% smooth_fwhm:      6

% Check native
% if ~exist('native', 'var') || isempty(native)
%     native = 1;
% else
%     if strcmpi(native, 'yes')
%         native = 1;
%     else
%         if strcmpi(native, 'no')
%             native = 0;
%         else
%             error(['Invalid native value specified: ', native]);
%         end
%     end
% end
% 
% % Check smooth_native
% if ~exist('smooth_native', 'var') || isempty(smooth_native)
%     smooth_native = 0;
% else
%     if strcmpi(smooth_native, 'yes')
%         smooth_native = 1;
%     else
%         if strcmpi(smooth_native, 'no')
%             smooth_native = 0;
%         else
%             error(['Invalid smooth_native value specified: ', smooth_native]);
%         end
%     end
% end
% 
% % Check smooth_fwhm
% if ~exist('smooth_fwhm', 'var') || isempty(smooth_fwhm)
%     smooth_fwhm = [6 6 6];
% else
%     smooth_fwhm = [smooth_fwhm smooth_fwhm smooth_fwhm];
% end
% 
% % If native files are additionally needed
% if native
%     
%     % Get native unwarped functional files
%     if smoothed
%         native_func_file = regexprep(func_files, 'sw', '', 'once');
%     else
%         native_func_file = regexprep(func_files, 'w', '', 'once');
%     end
%     
%     cd(fullfile(data_dir, list_subjs(sub).name));
%     if ~exist(native_func_file, 'file')
%         warning(['Unable to find native file for ', list_subjs(sub).name]);
%         skip = 1;
%     else
%         skip = 0;
%     end
%     
%     % If smoothing is required, smooth
%     if ~skip && smooth_native
%         count = 1;
%         native_vol = spm_vol(native_func_file);
%         for files = 1:length(native_vol)
%             matlabbatch{1}.spm.spatial.smooth.data{count,1} = ...
%                 fullfile(data_dir, list_subjs(sub).name, ...
%                 [native_func_file, ',', num2str(files)]);
%             count = count + 1;
%         end
%         
%         matlabbatch{1}.spm.spatial.smooth.fwhm = smooth_fwhm;
%         matlabbatch{1}.spm.spatial.smooth.dtype = 0;
%         matlabbatch{1}.spm.spatial.smooth.im = 0;
%         matlabbatch{1}.spm.spatial.smooth.prefix = 'smooth_native_';
%         spm_jobman('run',matlabbatch);
%         
%         % Move smoothed native file to quality_check folder
%         movefile(fullfile(data_dir, list_subjs(sub).name, ...
%             ['smooth_native_', native_func_file]),   ...
%             fullfile(data_dir, list_subjs(sub).name, 'quality_check', ...
%             ['smooth_native_', native_func_file]));
%         tmp = ['smooth_native_', native_func_file];
%         native_func_file = tmp;
%         clear tmp;
%     end
%     
%     % Find inverse deformation field
%     inv_def_field = dir('iy*.nii');
%     if isempty(inv_def_field)
%         warning(['Cannot find inverse deformation field for ', ...
%             list_subjs(sub).name, ...
%             '; skipping native space signal extraction']);
%     else
%         if length(inv_def_field) > 1
%             warning(['Multiple inverse deformation field found for ', ...
%                 list_subjs(sub).name, '; selecting first one: ', ...
%                 inv_def_field(1).name]);
%         end
%         inv_def_field = inv_def_field(1).name;
%         
%         % Transform all ROIs to structural native space by using
%         % inverse deformation field
%         clear matlabbatch
%         matlabbatch{1}.spm.spatial.normalise.write.subj.def = {inv_def_field};
%         
%         % Add all ROIs in the roi_dir
%         for rois = 1:num_rois
%             matlabbatch{1}.spm.spatial.normalise.write.subj.resample{rois,1} = ...
%                 fullfile(roi_dir, [list_rois(rois).name, ',1']);
%         end
%         
%         matlabbatch{1}.spm.spatial.normalise.write.woptions.bb     = [NaN NaN NaN
%             NaN NaN NaN];
%         matlabbatch{1}.spm.spatial.normalise.write.woptions.vox    = [1 1 1];
%         matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 0;
%         matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'native_str_';
%         spm_jobman('run',matlabbatch);
%         
%         % Move all the native space files to the quality_check
%         % folder of this subject
%         cd(roi_dir);
%         list_native_rois = dir('native_str_*.nii');
%         num_native_rois  = length(list_native_rois);
%         for rois = 1:num_native_rois
%             movefile(fullfile(roi_dir, list_native_rois(rois).name), ...
%                 fullfile(data_dir, list_subjs(sub).name, ...
%                 'quality_check', [list_subjs(sub).name, ...
%                 '-', list_native_rois(rois).name]));
%         end
%         cd(fullfile(data_dir, list_subjs(sub).name, 'quality_check'));
%         list_native_rois = dir('*native_str_*.nii');
%         cd(fullfile(data_dir, list_subjs(sub).name));
%         
%         % Transform these native_str_* ROI files from structural
%         % space to native functional space by using coregister and
%         % reslice function; the reference is the first volume of
%         % the functional file while the source is the structural
%         % file. The ROIs are specified as other images.
%         % Once the coregistration is complete, the low resolution
%         % structural file is deleted.
%         clear matlabbatch
%         
%         % Specify reference as the first unwarped functional file
%         if smooth_native
%             matlabbatch{1}.spm.spatial.coreg.estwrite.ref = ...
%                 {fullfile(data_dir, list_subjs(sub).name, ...
%                 'quality_check', [native_func_file, ',1'])};
%         else
%             matlabbatch{1}.spm.spatial.coreg.estwrite.ref = ...
%                 {fullfile(data_dir, list_subjs(sub).name, ...
%                 [native_func_file, ',1'])};
%         end
%         % Specify source as the structural file
%         matlabbatch{1}.spm.spatial.coreg.estwrite.source = ...
%             {fullfile(data_dir, list_subjs(sub).name, ...
%             [list_subjs(sub).name, '_T1w.nii,1'])};
%         
%         % Specify all the native space ROIs as other files
%         for rois = 1:num_native_rois
%             matlabbatch{1}.spm.spatial.coreg.estwrite.other{rois,1} = ...
%                 fullfile(data_dir, list_subjs(sub).name, ...
%                 'quality_check', list_native_rois(rois).name);
%         end
%         
%         % If mask_gm, also add the c1 file
%         if mask_gm
%             cd(fullfile(data_dir, list_subjs(sub).name));
%             native_gm_file = dir('c1*.nii');
%             matlabbatch{1}.spm.spatial.coreg.estwrite.other{end+1,1} = ...
%                 fullfile(data_dir, list_subjs(sub).name, native_gm_file(1).name);
%         end
%         
%         % Other parameters
%         matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
%         matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep      = [4 2];
%         matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.tol      = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
%         matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.fwhm     = [7 7];
%         matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp   = 0;
%         matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.wrap     = [0 0 0];
%         matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.mask     = 0;
%         matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix   = 'native_func_';
%         spm_jobman('run',matlabbatch);
%         
%         % Delete low resolution coregistered T1w image
%         delete(fullfile(data_dir, list_subjs(sub).name, ...
%             ['native_func_', list_subjs(sub).name, '_T1w.nii']));
%         
%         % Delete ROI files written out in the structural space
%         for rois = 1:num_native_rois
%             delete(fullfile(data_dir, list_subjs(sub).name, ...
%                 'quality_check', list_native_rois(rois).name));
%         end
%         
%         % Replace native_str from all newly created ROIs and
%         % rebuild list_native_rois list
%         cd(fullfile(data_dir, list_subjs(sub).name, 'quality_check'));
%         list_native_rois = dir('native_func_*.nii');
%         for rois = 1:num_native_rois
%             new_name = strrep(strrep(list_native_rois(rois).name, ...
%                 'native_func_', ''), 'native_str', 'native');
%             movefile(fullfile(data_dir, list_subjs(sub).name, ...
%                 'quality_check', list_native_rois(rois).name),...
%                 fullfile(data_dir, list_subjs(sub).name, ...
%                 'quality_check', new_name));
%         end
%         list_native_rois = dir('*native*.nii');
%         
%         % If smooth_native functional file has been listed, remove
%         % it from list_native_rois
%         for rois = 1:length(list_native_rois)
%             if ~isempty(regexpi(list_native_rois(rois).name, 'smooth_native_u'))
%                 list_native_rois(rois) = [];
%                 break
%             end
%         end
%         
%         % Move low resolution c1 file to quality_check folder
%         if mask_gm
%             movefile(fullfile(data_dir, list_subjs(sub).name, ...
%                 ['native_func_c1', list_subjs(sub).name, '_T1w.nii']), ...
%                 fullfile(data_dir, list_subjs(sub).name, 'quality_check', ...
%                 [list_subjs(sub).name, '-native_GM_mask_', num2str(mask_prob), '.nii']));
%         end
%         % If GM masking is needed, read the files and write out
%         % masked ROIs; else simply read and store in a variable;
%         % additionally, count the number of voxels
%         native_header   = spm_vol(fullfile(data_dir, list_subjs(sub).name, ...
%             'quality_check', list_native_rois(1).name));
%         native_data     = spm_read_vols(native_header);
%         native_roi_data = zeros([size(native_data), num_native_rois]);
%         
%         list_native_sub_files = cell(num_native_rois,1);
%         native_roi_vox_count  = cell(num_native_rois+1,2);
%         
%         if mask_gm
%             % Get low resolution c1 file; threshold and binarize
%             native_gm_file  = fullfile(data_dir, ...
%                 list_subjs(sub).name, ...
%                 'quality_check', ...
%                 [list_subjs(sub).name, ...
%                 '-native_GM_mask_', ...
%                 num2str(mask_prob), '.nii']);
%             native_gm_header = spm_vol(native_gm_file);
%             native_gm_data   = spm_read_vols(native_gm_header);
%             
%             % Threshold and binarize
%             native_gm_data(native_gm_data <  mask_prob) = 0;
%             native_gm_data(native_gm_data >= mask_prob) = 1;
%             
%             % Save binarized native space GM segmentation file
%             spm_write_vol(native_gm_header, native_gm_data);
%             
%             % Get voxel count for native GM mask
%             native_roi_vox_count{1,1}  = [list_subjs(sub).name, ...
%                 '-native_GM_mask_', ...
%                 num2str(mask_prob), '.nii'];
%             native_roi_vox_count{1,2}  = length(nonzeros(native_gm_data(:)));
%             
%             % Read and make subject specific masked ROIs; also
%             % count the number of voxels present in each masked ROI
%             for rois = 1:num_native_rois
%                 native_roi_data(:,:,:,rois) = spm_read_vols(spm_vol(list_native_rois(rois).name));
%                 native_header.fname = fullfile(data_dir, ...
%                     list_subjs(sub).name, ...
%                     'quality_check', ...
%                     [strrep(list_native_rois(rois).name,...
%                     '.nii', ''), '_', ...
%                     num2str(mask_prob), '.nii']);
%                 native_roi_data(:,:,:,rois) = native_roi_data(:,:,:,rois).*native_gm_data;
%                 spm_write_vol(native_header, squeeze(native_roi_data(:,:,:,rois)));
%                 native_roi_vox_count{rois+1,1}  = list_native_rois(rois).name;
%                 native_roi_vox_count{rois+1,2}  = length(nonzeros(native_roi_data(:,:,:,rois)));
%                 list_native_sub_files{rois,1} = native_header.fname;
%             end
%             
%             % Delete unmasked files
%             for rois = 1:num_native_rois
%                 delete(fullfile(data_dir, list_subjs(sub).name, ...
%                     'quality_check', list_native_rois(rois).name));
%             end
%             
%         else
%             % Read in subject specific native ROIs and count the
%             % number of voxels present in each native ROI
%             for rois = 1:num_native_rois
%                 native_roi_data(:,:,:,rois)   = spm_read_vols(spm_vol(list_native_rois(rois).name));
%                 native_roi_vox_count{rois,1}  = list_native_rois(rois).name;
%                 native_roi_vox_count{rois,2}  = length(nonzeros(native_roi_data(:,:,:,rois)));
%                 list_native_sub_files{rois,1} = fullfile(data_dir, ...
%                     list_subjs(sub).name, ...
%                     'quality_check', ...
%                     list_native_rois(rois).name);
%             end
%         end
%         
%         % Get time series for all native ROIs
%         if smooth_native
%             native_time_series = rex(fullfile(data_dir, list_subjs(sub).name, ...
%                 'quality_check', native_func_file), ...
%                 list_native_sub_files, ...
%                 'summary_measure', summary_measure);
%         else
%             native_time_series = rex(fullfile(data_dir, list_subjs(sub).name, ...
%                 native_func_file), list_native_sub_files, ...
%                 'summary_measure', summary_measure);
%         end
%         
%         % Write out voxel count for all ROIs
%         writetable(cell2table(native_roi_vox_count, 'VariableNames', ...
%             {'ROI_Name', 'Voxel_Count'}), fullfile(data_dir, ...
%             list_subjs(sub).name, 'quality_check', ...
%             [list_subjs(sub).name, '_VoxelCount_native.csv']));
%         
%         % Save the variable containing the time series for the subject
%         save(fullfile(data_dir, list_subjs(sub).name, 'quality_check', ...
%             [list_subjs(sub).name, '_TimeSeries_native.mat']), ...
%             'native_time_series', 'list_native_sub_files');
%         
%         % Create a new figure for plotting time series
%         fig = figure('PaperType', 'A5', 'Color', [1 1 1], 'Visible', 'off');
%         
%         % Create new legend entries
%         legend_entries = cell(num_native_rois, 1);
%         for rois = 1:num_native_rois
%             [~, tmp] = fileparts(list_native_sub_files{rois});
%             % Remove subject name and hyphen from ROI name
%             tmp = strrep(tmp, [list_subjs(sub).name, '-'], '');
%             legend_entries{rois} = tmp;
%         end
%         
%         % Plot time_series and save the figure
%         plot(native_time_series);
%         box off;
%         title([list_subjs(sub).name, ': Time Series (native)']);
%         legend(legend_entries, 'Interpreter', 'none', ...
%             'Location', 'northeastoutside', 'FontSize', 6, ...
%             'Orientation', 'vertical', 'Box', 'off')
%         print(fig, fullfile(data_dir, list_subjs(sub).name, 'quality_check', ...
%             [list_subjs(sub).name, '_native_TS.png']), '-dpng', '-r600');
%         close(fig);
%     end
% end