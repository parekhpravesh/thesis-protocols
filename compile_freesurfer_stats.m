function compile_freesurfer_stats(data_dir, freesurfer_dir, full_bids)
% Compiles various measures from the stats directory of subjects present in
% data_dir
%% Inputs:
% data_dir:         fullpath to directory containing sub-* folders
% freesurfer_dir:   fullpath to where FreeSurfer is installed
% full_bids:        yes/no indicating if folders in data_dir follow full
%                   BIDS specification
% 
%% Output:
% Creates a folder named "summary_stats_freesurfer" in the data_dir
% containing a list of subjects saved as "list_subjs.txt" and summary 
% statistics files
% 
%% Notes:
% Only passes structural T1w file to FreeSurfer
% 
% Assumes Linux!
% 
% Assumes that recon-all was successfully completed for all the subjects
% 
% The FreeSurfer subject level output folders are assumed to be present in
% the sub-* folder (if full_bids=no) or in the anat folder inside sub-*
% folder (if full_bids=yes)
% 
% Subject IDs are "freesurfer_sub-*"
% 
% Inefficiently uses the source command before each command run
% 
%% Default:
% full_bids:       'yes'
% 
%% Author(s):
% Parekh, Pravesh
% January 10, 2019
% MBIAL

%% Check inputs and assign default value
% Check data_dir
if ~exist('data_dir', 'var') || isempty(data_dir)
    error('data_dir needs to be provided');
else
    if ~exist(data_dir, 'dir')
        error(['Cannot find: ', data_dir]);
    end
end

% Check freesurfer_dir
if ~exist('freesurfer_dir', 'var') || isempty(freesurfer_dir)
    error('freesurfer_dir needs to be provided');
else
    if ~exist(freesurfer_dir, 'dir')
        error(['Cannot find: ', freesurfer_dir]);
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
            error(['Incorrect value for full_bids: ', full_bids]);
        end
    end
end

% Check if Windows
if ispc
    error('Cannot run on Windows!');
end

%% Compile subject list
cd(data_dir);
list_subjs = dir('sub-*');
list_subjs = struct2cell(list_subjs);
list_subjs(2:end,:) = [];
list_subjs = list_subjs';
num_subjs  = length(list_subjs);

%% Save list_subjs
out_dir = fullfile(data_dir, 'summary_stats_freesurfer');

% Create output folder if needed
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

% Edit list_subjs to include paths and "freesurfer_" prefix
if full_bids
    list_subjs_write = strcat(list_subjs, {'/'}, {'anat'}, {'/'}, ...
                             {'freesurfer_'}, list_subjs);
else
    list_subjs_write = strcat(list_subjs, {'/'}, ...
                             {'freesurfer_'}, list_subjs);
end

% Write out list_subjs
fid = fopen(fullfile(out_dir, 'list_subjs.txt'), 'w');
for sub = 1:num_subjs
    fprintf(fid, '%s\r\n', list_subjs_write{sub});
end
fclose(fid);

%% Run FreeSurfer commands
cd(out_dir);
subj_file = fullfile(out_dir, 'list_subjs.txt');

% Source FreeSurfer
system(['source ', freesurfer_dir, '/SetUpFreeSurfer.sh']);

% -------------------------------------------------------------------------
% aseg file
% -------------------------------------------------------------------------
% Volume (mm^3)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
         'asegstats2table --subjectsfile ', subj_file, ' --all-segs ', ...
        '--delimiter comma --meas volume --stats aseg.stats ',         ...
        '--tablefile aseg_volumes.csv']);

% Mean intensity (MR units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                      ...
        'asegstats2table --subjectsfile ', subj_file, ' --all-segs ', ...
        '--delimiter comma --meas mean --stats aseg.stats '           ...
        '--tablefile aseg_mean_intensities.csv']);
    
% Subject level intensity standard deviation (MR units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                      ...
        'asegstats2table --subjectsfile ', subj_file, ' --all-segs ', ...
        '--delimiter comma --meas std --stats aseg.stats '            ...
        '--tablefile aseg_std.csv']);

% -------------------------------------------------------------------------
% wmparc file
% -------------------------------------------------------------------------
% Volume (mm^3)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                      ...
        'asegstats2table --subjectsfile ', subj_file, ' --all-segs ', ...
        '--delimiter comma --meas volume --stats wmparc.stats ',      ...
        '--tablefile wmparc_volumes.csv']);
    
% Mean intensity (MR units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                      ...
        'asegstats2table --subjectsfile ', subj_file, ' --all-segs ', ...
        '--delimiter comma --meas mean --stats wmparc.stats ',        ...
        '--tablefile wmparc_mean_intensities.csv']);
    
% Subject level intensity standard deviation (MR units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                      ...
        'asegstats2table --subjectsfile ', subj_file, ' --all-segs ', ...
        '--delimiter comma --meas std --stats wmparc.stats ',         ...
        '--tablefile wmparc_std.csv']);

% -------------------------------------------------------------------------
% Left hemisphere: lh.aparc.a2009s
% -------------------------------------------------------------------------
% Surface area (mm^2)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas area --parc aparc.a2009s ',          ...
        '--tablefile aparc_a2009s_LH_surf_area.csv']);

% Gray matter volume (mm^3)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',  ...
        ' --delimiter comma --meas volume --parc aparc.a2009s ',        ...
        '--tablefile aparc_a2009s_LH_gray_volume.csv']);
    
% Average Thickness (mm)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas thickness --parc aparc.a2009s ',      ...
        '--tablefile aparc_a2009s_LH_avg_thickness.csv']);
    
% Thickness standard deviation (mm)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                         ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',   ...
        '--delimiter comma --meas thicknessstd --parc aparc.a2009s ',    ...
        '--tablefile aparc_a2009s_LH_std_thickness.csv']);

% Integrated Rectified Mean Curvature (mm^-1)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas meancurv --parc aparc.a2009s ',       ...
        '--tablefile aparc_a2009s_LH_mean_curvature.csv']);
    
% Integrated Rectified Gaussian Curvature (mm^-2)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas gauscurv --parc aparc.a2009s ',       ...
        '--tablefile aparc_a2009s_LH_gaussian_curvature.csv']);
    
% Folding Index (no units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas foldind --parc aparc.a2009s ',        ...
        '--tablefile aparc_a2009s_LH_folding_index.csv']);
    
% Intrinsic Curvature Index (no units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas curvind --parc aparc.a2009s ',        ...
        '--tablefile aparc_a2009s_LH_curvature_index.csv']);

% -------------------------------------------------------------------------
% Right hemisphere: rh.aparc.a2009s
% -------------------------------------------------------------------------
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas area --parc aparc.a2009s ',          ...
        '--tablefile aparc_a2009s_RH_surf_area.csv']);

% Gray matter volume (mm^3)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas volume --parc aparc.a2009s ',         ...
        '--tablefile aparc_a2009s_RH_gray_volume.csv']);
    
% Average Thickness (mm)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas thickness --parc aparc.a2009s ',      ...
        '--tablefile aparc_a2009s_RH_avg_thickness.csv']);
    
% Thickness standard deviation (mm)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas thicknessstd --parc aparc.a2009s ',   ...
        '--tablefile aparc_a2009s_RH_std_thickness.csv']);

% Integrated Rectified Mean Curvature (mm^-1)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas meancurv --parc aparc.a2009s ',       ...
        '--tablefile aparc_a2009s_RH_mean_curvature.csv']);
    
% Integrated Rectified Gaussian Curvature (mm^-2)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas gauscurv --parc aparc.a2009s ',       ...
        '--tablefile aparc_a2009s_RH_gaussian_curvature.csv']);
    
% Folding Index (no units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas foldind --parc aparc.a2009s ',        ...
        '--tablefile aparc_a2009s_RH_folding_index.csv']);
    
% Intrinsic Curvature Index (no units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas curvind --parc aparc.a2009s ',        ...
        '--tablefile aparc_a2009s_RH_curvature_index.csv']);

% -------------------------------------------------------------------------
% Left hemisphere: lh.aparc.DKTatlas40
% -------------------------------------------------------------------------
% Surface area (mm^2)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas area --parc aparc.DKTatlas40 ',       ...
        '--tablefile aparc_DKTatlas40_LH_surf_area.csv']);

% Gray matter volume (mm^3)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas volume --parc aparc.DKTatlas40 ',    ...
        '--tablefile aparc_DKTatlas40_LH_gray_volume.csv']);
    
% Average Thickness (mm)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas thickness --parc aparc.DKTatlas40 ',  ...
        '--tablefile aparc_DKTatlas40_LH_avg_thickness.csv']);
    
% Thickness standard deviation (mm)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                          ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',    ...
        '--delimiter comma --meas thicknessstd --parc aparc.DKTatlas40 ', ...
        '--tablefile aparc_DKTatlas40_LH_std_thickness.csv']);

% Integrated Rectified Mean Curvature (mm^-1)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas meancurv --parc aparc.DKTatlas40 ',   ...
        '--tablefile aparc_DKTatlas40_LH_mean_curvature.csv']);
    
% Integrated Rectified Gaussian Curvature (mm^-2)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas gauscurv --parc aparc.DKTatlas40 ',   ...
        '--tablefile aparc_DKTatlas40_LH_gaussian_curvature.csv']);
    
% Folding Index (no units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...    
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas foldind --parc aparc.DKTatlas40 ',    ...
        '--tablefile aparc_DKTatlas40_LH_folding_index.csv']);
    
% Intrinsic Curvature Index (no units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas curvind --parc aparc.DKTatlas40 ',    ...
        '--tablefile aparc_DKTatlas40_LH_curvature_index.csv']);

% -------------------------------------------------------------------------
% Right hemisphere: rh.aparc.DKTatlas40
% -------------------------------------------------------------------------
% Surface area (mm^2)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas area --parc aparc.DKTatlas40 ',      ...
        '--tablefile aparc_DKTatlas40_RH_surf_area.csv']);

% Gray matter volume (mm^3)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...  
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas volume --parc aparc.DKTatlas40 ',    ...
        '--tablefile aparc_DKTatlas40_RH_gray_volume.csv']);
    
% Average Thickness (mm)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas thickness --parc aparc.DKTatlas40 ', ...
        '--tablefile aparc_DKTatlas40_RH_avg_thickness.csv']);
    
% Thickness standard deviation (mm)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                          ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',    ...
        '--delimiter comma --meas thicknessstd --parc aparc.DKTatlas40 ', ...
        '--tablefile aparc_DKTatlas40_RH_std_thickness.csv']);

% Integrated Rectified Mean Curvature (mm^-1)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                         ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',   ...
        '--delimiter comma --meas meancurv --parc aparc.DKTatlas40 ',    ...
        '--tablefile aparc_DKTatlas40_RH_mean_curvature.csv']);
    
% Integrated Rectified Gaussian Curvature (mm^-2)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas gauscurv --parc aparc.DKTatlas40 ',   ...
        '--tablefile aparc_DKTatlas40_RH_gaussian_curvature.csv']);
    
% Folding Index (no units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas foldind --parc aparc.DKTatlas40 ',    ...
        '--tablefile aparc_DKTatlas40_RH_folding_index.csv']);
    
% Intrinsic Curvature Index (no units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas curvind --parc aparc.DKTatlas40 ',    ...
        '--tablefile aparc_DKTatlas40_RH_curvature_index.csv']);

% -------------------------------------------------------------------------
% Left hemisphere: lh.aparc
% -------------------------------------------------------------------------
% Surface area (mm^2)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas area --parc aparc ',                 ...
        '--tablefile aparc_LH_surf_area.csv']);

% Gray matter volume (mm^3)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas volume --parc aparc ',               ...
        '--tablefile aparc_LH_gray_volume.csv']);
    
% Average Thickness (mm)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas thickness --parc aparc ',            ...
        '--tablefile aparc_LH_avg_thickness.csv']);
    
% Thickness standard deviation (mm)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas thicknessstd --parc aparc ',          ...
        '--tablefile aparc_LH_std_thickness.csv']);

% Integrated Rectified Mean Curvature (mm^-1)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas meancurv --parc aparc ',             ...
        '--tablefile aparc_LH_mean_curvature.csv']);
    
% Integrated Rectified Gaussian Curvature (mm^-2)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas gauscurv --parc aparc ',             ...
        '--tablefile aparc_LH_gaussian_curvature.csv']);
    
% Folding Index (no units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas foldind --parc aparc ',              ...
        '--tablefile aparc_LH_folding_index.csv']);
    
% Intrinsic Curvature Index (no units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas curvind --parc aparc ',              ...
        '--tablefile aparc_LH_curvature_index.csv']);

% -------------------------------------------------------------------------
% Right hemisphere: rh.aparc
% -------------------------------------------------------------------------
% Surface area (mm^2)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas area --parc aparc ',                 ...
        '--tablefile aparc_RH_surf_area.csv']);

% Gray matter volume (mm^3)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas volume --parc aparc ',               ...
        '--tablefile aparc_RH_gray_volume.csv']);
    
% Average Thickness (mm)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas thickness --parc aparc ',            ...
        '--tablefile aparc_RH_avg_thickness.csv']);
    
% Thickness standard deviation (mm)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas thicknessstd --parc aparc ',         ...
        '--tablefile aparc_RH_std_thickness.csv']);

% Integrated Rectified Mean Curvature (mm^-1)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas meancurv --parc aparc ',             ...
        '--tablefile aparc_RH_mean_curvature.csv']);
    
% Integrated Rectified Gaussian Curvature (mm^-2)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas gauscurv --parc aparc ',             ...
        '--tablefile aparc_RH_gaussian_curvature.csv']);
    
% Folding Index (no units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas foldind --parc aparc ',              ...
        '--tablefile aparc_RH_folding_index.csv']);
    
% Intrinsic Curvature Index (no units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas curvind --parc aparc ',              ...
        '--tablefile aparc_RH_curvature_index.csv']);
    
% -------------------------------------------------------------------------
% Left hemisphere: lh.BA
% -------------------------------------------------------------------------
% Surface area (mm^2)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas area --parc BA ',                     ...
        '--tablefile BA_LH_surf_area.csv']);

% Gray matter volume (mm^3)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas volume --parc BA ',                  ...
        '--tablefile BA_LH_gray_volume.csv']);
    
% Average Thickness (mm)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas thickness --parc BA ',                ...
        '--tablefile BA_LH_avg_thickness.csv']);
    
% Thickness standard deviation (mm)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas thicknessstd --parc BA ',             ...
        '--tablefile BA_LH_std_thickness.csv']);

% Integrated Rectified Mean Curvature (mm^-1)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas meancurv --parc BA ',                ...
        '--tablefile BA_LH_mean_curvature.csv']);
    
% Integrated Rectified Gaussian Curvature (mm^-2)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas gauscurv --parc BA ',                 ...
        '--tablefile BA_LH_gaussian_curvature.csv']);
    
% Folding Index (no units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas foldind --parc BA ',                 ...
        '--tablefile BA_LH_folding_index.csv']);
    
% Intrinsic Curvature Index (no units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas curvind --parc BA ',                 ...
        '--tablefile BA_LH_curvature_index.csv']);

% -------------------------------------------------------------------------
% Right hemisphere: rh.BA
% -------------------------------------------------------------------------
% Surface area (mm^2)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas area --parc BA ',                    ...
        '--tablefile BA_RH_surf_area.csv']);

% Gray matter volume (mm^3)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                       ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ', ...
        '--delimiter comma --meas volume --parc BA ',                  ...
        '--tablefile BA_RH_gray_volume.csv']);
    
% Average Thickness (mm)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas thickness --parc BA ',                ...
        '--tablefile BA_RH_avg_thickness.csv']);
    
% Thickness standard deviation (mm)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas thicknessstd --parc BA ',             ...
        '--tablefile BA_RH_std_thickness.csv']);

% Integrated Rectified Mean Curvature (mm^-1)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas meancurv --parc BA ',                 ...
        '--tablefile BA_RH_mean_curvature.csv']);
    
% Integrated Rectified Gaussian Curvature (mm^-2)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas gauscurv --parc BA ',                 ...
        '--tablefile BA_RH_gaussian_curvature.csv']);
    
% Folding Index (no units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas foldind --parc BA ',                  ...
        '--tablefile BA_RH_folding_index.csv']);
    
% Intrinsic Curvature Index (no units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                        ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',  ...
        '--delimiter comma --meas curvind --parc BA ',                  ... 
        '--tablefile BA_RH_curvature_index.csv']);
    
% -------------------------------------------------------------------------
% Left hemisphere: lh.BA_thresh.thresh
% -------------------------------------------------------------------------
% Surface area (mm^2)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                           ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',     ...
        '--delimiter comma --meas area --parc BA.thresh ',          ...
        '--tablefile BA_thresh_LH_surf_area.csv']);

% Gray matter volume (mm^3)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                           ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',     ...
        '--delimiter comma --meas volume --parc BA.thresh ',        ...
        '--tablefile BA_thresh_LH_gray_volume.csv']);
    
% Average Thickness (mm)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                            ...    
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',      ...
        '--delimiter comma --meas thickness --parc BA.thresh ',      ...
        '--tablefile BA_thresh_LH_avg_thickness.csv']);
    
% Thickness standard deviation (mm)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                             ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',       ...
        '--delimiter comma --meas thicknessstd --parc BA.thresh ',    ...
        '--tablefile BA_thresh_LH_std_thickness.csv']);

% Integrated Rectified Mean Curvature (mm^-1)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                            ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',      ...
        '--delimiter comma --meas meancurv --parc BA.thresh ',       ...
        '--tablefile BA_thresh_LH_mean_curvature.csv']);
    
% Integrated Rectified Gaussian Curvature (mm^-2)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                            ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',      ...
        '--delimiter comma --meas gauscurv --parc BA.thresh ',       ...
        '--tablefile BA_thresh_LH_gaussian_curvature.csv']);
    
% Folding Index (no units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                            ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',      ...
        '--delimiter comma --meas foldind --parc BA.thresh ',        ...
        '--tablefile BA_thresh_LH_folding_index.csv']);
    
% Intrinsic Curvature Index (no units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                            ...
        'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',      ...
        '--delimiter comma --meas curvind --parc BA.thresh ',        ...
        '--tablefile BA_thresh_LH_curvature_index.csv']);

% -------------------------------------------------------------------------
% Right hemisphere: rh.BA_thresh.thresh
% -------------------------------------------------------------------------
% Surface area (mm^2)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                            ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',      ...
        '--delimiter comma --meas area --parc BA.thresh ',           ...
        '--tablefile BA_thresh_RH_surf_area.csv']);

% Gray matter volume (mm^3)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                            ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',      ...
        '--delimiter comma --meas volume --parc BA.thresh ',         ...
        '--tablefile BA_thresh_RH_gray_volume.csv']);
    
% Average Thickness (mm)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                           ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',     ...
        '--delimiter comma --meas thickness --parc BA.thresh ',     ...
        '--tablefile BA_thresh_RH_avg_thickness.csv']);
    
% Thickness standard deviation (mm)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                             ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',       ...
        '--delimiter comma --meas thicknessstd --parc BA.thresh ',    ...
        '--tablefile BA_thresh_RH_std_thickness.csv']);

% Integrated Rectified Mean Curvature (mm^-1)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                            ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',      ...
        '--delimiter comma --meas meancurv --parc BA.thresh ',       ...
        '--tablefile BA_thresh_RH_mean_curvature.csv']);
    
% Integrated Rectified Gaussian Curvature (mm^-2)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                            ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',      ...
        '--delimiter comma --meas gauscurv --parc BA.thresh ',       ...
        '--tablefile BA_thresh_RH_gaussian_curvature.csv']);
    
% Folding Index (no units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                            ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',      ...
        '--delimiter comma --meas foldind --parc BA.thresh ',        ...
        '--tablefile BA_thresh_RH_folding_index.csv']);
    
% Intrinsic Curvature Index (no units)
system(['export SUBJECTS_DIR=', data_dir, '&& ',                            ...
        'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',      ...
        '--delimiter comma --meas curvind --parc BA.thresh ',        ...
        '--tablefile BA_thresh_RH_curvature_index.csv']);

% % -------------------------------------------------------------------------
% % Left hemisphere: lh.w-g.pct
% % -------------------------------------------------------------------------
% % Surface area (mm^2)
% system(['export SUBJECTS_DIR=', data_dir, '&& ',                          ...
%         'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',    ...
%         '--delimiter comma --meas area --parc w-g.pct ',                  ...
%         '--tablefile w-g_pct_LH_surf_area.csv']);
% 
% % Gray matter volume (mm^3)
% system(['export SUBJECTS_DIR=', data_dir, '&& ',                          ...
%         'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',    ...
%         '--delimiter comma --meas volume --parc w-g.pct ',                ...
%         '--tablefile w-g_pct_LH_gray_volume.csv']);
%     
% % Average Thickness (mm)
% system(['export SUBJECTS_DIR=', data_dir, '&& ',                          ...
%         'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',    ...
%         '--delimiter comma --meas thickness --parc w-g.pct ',             ...
%         '--tablefile w-g_pct_LH_avg_thickness.csv']);
%     
% % Thickness standard deviation (mm)
% system(['export SUBJECTS_DIR=', data_dir, '&& ',                          ...
%         'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',    ...
%         '--delimiter comma --meas thicknessstd --parc w-g.pct ',          ...
%         '--tablefile w-g_pct_LH_std_thickness.csv']);
% 
% % Integrated Rectified Mean Curvature (mm^-1)
% system(['export SUBJECTS_DIR=', data_dir, '&& ',                          ...
%         'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',    ...
%         '--delimiter comma --meas meancurv --parc w-g.pct ',              ...
%         '--tablefile w-g_pct_LH_mean_curvature.csv']);
%     
% % Integrated Rectified Gaussian Curvature (mm^-2)
% system(['export SUBJECTS_DIR=', data_dir, '&& ',                          ...
%         'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',    ...
%         '--delimiter comma --meas gauscurv --parc w-g.pct ',              ...
%         '--tablefile w-g_pct_LH_gaussian_curvature.csv']);
%     
% % Folding Index (no units)
% system(['export SUBJECTS_DIR=', data_dir, '&& ',                          ...
%         'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',    ...
%         '--delimiter comma --meas foldind --parc w-g.pct ',               ...
%         '--tablefile w-g_pct_LH_folding_index.csv']);
%     
% % Intrinsic Curvature Index (no units)
% system(['export SUBJECTS_DIR=', data_dir, '&& ',                          ...
%         'aparcstats2table --hemi lh --subjectsfile ', subj_file,  ' ',    ...
%         '--delimiter comma --meas curvind --parc w-g.pct ',               ...
%         '--tablefile w-g_pct_LH_curvature_index.csv']);
% 
% % -------------------------------------------------------------------------
% % Right hemisphere: rh.w-g.pct
% % -------------------------------------------------------------------------
% % Surface area (mm^2)
% system(['export SUBJECTS_DIR=', data_dir, '&& ',                          ...
%         'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',    ...
%         '--delimiter comma --meas area --parc w-g.pct ',                  ...
%         '--tablefile w-g_pct_RH_surf_area.csv']);
% 
% % Gray matter volume (mm^3)
% system(['export SUBJECTS_DIR=', data_dir, '&& ',                          ...
%         'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',    ...
%         '--delimiter comma --meas volume --parc w-g.pct ',                ...
%         '--tablefile w-g_pct_RH_gray_volume.csv']);
%     
% % Average Thickness (mm)
% system(['export SUBJECTS_DIR=', data_dir, '&& ',                          ...
%         'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',    ...
%         '--delimiter comma --meas thickness --parc w-g.pct ',             ...
%         '--tablefile w-g_pct_RH_avg_thickness.csv']);
%     
% % Thickness standard deviation (mm)
% system(['export SUBJECTS_DIR=', data_dir, '&& ',                          ...
%         'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',    ...
%         '--delimiter comma --meas thicknessstd --parc w-g.pct ',          ...
%         '--tablefile w-g_pct_RH_std_thickness.csv']);
% 
% % Integrated Rectified Mean Curvature (mm^-1)
% system(['export SUBJECTS_DIR=', data_dir, '&& ',                          ...
%         'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',    ...
%         '--delimiter comma --meas meancurv --parc w-g.pct ',              ...
%         '--tablefile w-g_pct_RH_mean_curvature.csv']);
%     
% % Integrated Rectified Gaussian Curvature (mm^-2)
% system(['export SUBJECTS_DIR=', data_dir, '&& ',                          ...
%         'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',    ...
%         '--delimiter comma --meas gauscurv --parc w-g.pct ',              ...
%         '--tablefile w-g_pct_RH_gaussian_curvature.csv']);
%     
% % Folding Index (no units)
% system(['export SUBJECTS_DIR=', data_dir, '&& ',                          ...
%         'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',    ...
%         '--delimiter comma --meas foldind --parc w-g.pct ',               ...
%         '--tablefile w-g_pct_RH_folding_index.csv']);
%     
% % Intrinsic Curvature Index (no units)
% system(['export SUBJECTS_DIR=', data_dir, '&& ',                          ...
%         'aparcstats2table --hemi rh --subjectsfile ', subj_file,  ' ',    ...
%         '--delimiter comma --meas curvind --parc w-g.pct ',               ...
%         '--tablefile w-g_pct_RH_curvature_index.csv']);