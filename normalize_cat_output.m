function normalize_cat_output(analysis_dir)
% Function to normalize CAT12 output to MNI (isotropic 2 mm)
%% Input:
% analysis_dir:     full path to analysis directory
% 
%% Output:
% Normalized files are written and then moved to analysis_dir/anat/mri_mni 
% into individual subject folders; batch files for each subject are saved
% in analysis_dir/anat/mri_mni/batches; a summary file is written in
% analysis_dir/summary named summary_normalize_cat_output_ddmmmyyyy.txt
% 
%% Notes:
% Batch is only created for subjects for whom deformation field is present
% in the analysis_dir/anat/mri directory
% 
%% Author(s):
% Parekh, Pravesh
% March 30, 2018
% MBIAL

%% Parse analysis_dir and get a list of deformation fields
if exist('analysis_dir', 'var')
    if exist(analysis_dir, 'dir')
        % Find mri folder
        if exist(fullfile(analysis_dir, 'anat', 'mri'), 'dir')
            % Make list of subjects for whom deformation field is present
            cd(fullfile(analysis_dir, 'anat', 'mri'));
            list_deforms    = dir('y_*.nii');
            list_subjs      = cell(length(list_deforms), 1);
            for i = 1:length(list_deforms)
                list_subjs{i} = regexprep(list_deforms(i).name, ...
                    {'_T1w', 'y_', '.nii'}, '');
            end
            num_subjs = length(list_subjs);
            disp([num2str(num_subjs), ' deformation fields found']);
        else
            error('mri folder not found');
        end
    else
        error([analysis_dir, ' not found']);
    end
else
    error('analysis_dir must be provided');
end

%% Prepare summary file

% Create summary folder if it does not exist
if ~exist(fullfile(analysis_dir, 'summary'), 'dir')
    mkdir(fullfile(analysis_dir, 'summary'));
end

% Name summary file
summary_loc = fullfile(analysis_dir, 'summary', ...
    ['summary_normalize_cat_output_', datestr(now, 'ddmmmyyyy'), '.txt']);

% Check if file exists; if yes, append; else create a new one
if exist(summary_loc, 'file')
    fid_summary = fopen(summary_loc, 'a');
else
    fid_summary = fopen(summary_loc, 'w');
end

% Save some information
fprintf(fid_summary, '%s\r\n', ['Date:         ', datestr(now, 'ddmmmyyyy')]);
fprintf(fid_summary, '%s\r\n', ['Time:         ', datestr(now, 'HH:MM:SS PM')]);
fprintf(fid_summary, '%s\r\n', ['analysis_dir: ', analysis_dir]);
fprintf(fid_summary, '%s\r\n', [num2str(num_subjs), ' deformation fields found']);

%% Prepare output folder
if ~exist(fullfile(analysis_dir, 'anat', 'mri_mni'), 'dir')
    mkdir(fullfile(analysis_dir, 'anat', 'mri_mni'));
end

if ~exist(fullfile(analysis_dir, 'anat', 'mri_mni', 'batches'), 'dir')
    mkdir(fullfile(analysis_dir, 'anat', 'mri_mni', 'batches'));
end

%% Loop over subjects and create preprocessing batch
for subj = 1:num_subjs
    
    % Deformation field
    defor_file = {fullfile(analysis_dir, 'anat', 'mri', ['y_', list_subjs{subj}, '_T1w.nii'])};
    
    % Create list of files to be normalized
    list_files = cell(4,1);
    
    % p0 file
    list_files{1} = fullfile(analysis_dir, 'anat', 'mri', ['p0', list_subjs{subj}, '_T1w.nii']);
    
    % p1 file
    list_files{2} = fullfile(analysis_dir, 'anat', 'mri', ['p1', list_subjs{subj}, '_T1w.nii']);
    
    % p2 file
    list_files{3} = fullfile(analysis_dir, 'anat', 'mri', ['p2', list_subjs{subj}, '_T1w.nii']);
    
    % p3 file
    list_files{4} = fullfile(analysis_dir, 'anat', 'mri', ['p3', 'sub-', list_subjs{subj}, '_T1w.nii']);

    % Create batch
    matlabbatch{1}.spm.spatial.normalise.write.subj.def          = defor_file;
    matlabbatch{1}.spm.spatial.normalise.write.subj.resample     = list_files;
    matlabbatch{1}.spm.spatial.normalise.write.woptions.bb       = [NaN NaN NaN
                                                                    NaN NaN NaN];
    matlabbatch{1}.spm.spatial.normalise.write.woptions.vox      = [2 2 2];
    matlabbatch{1}.spm.spatial.normalise.write.woptions.interp   = 7;
    matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix   = 'w_mni_';
    
    % Save batch file
    save(fullfile(analysis_dir, 'anat', 'mri_mni', 'batches', ['batch_', list_subjs{subj}, '_normalize_cat_output.mat']), 'matlabbatch');
    
    % Run batch
    spm_jobman('run', matlabbatch);
    
    % Move all w_mni files to mri_mni directory
    % Make subject folder
    mkdir(fullfile(analysis_dir, 'anat', 'mri_mni', list_subjs{subj}));
    
    % Moving p0 file
    movefile(fullfile(analysis_dir, 'anat', 'mri', ['w_mni_p0', list_subjs{subj}, '_T1w.nii']), ...
             fullfile(analysis_dir, 'anat', 'mri_mni', list_subjs{subj}, ['w_p0', list_subjs{subj}, '_T1w.nii']));
         
    % Moving p1 file
    movefile(fullfile(analysis_dir, 'anat', 'mri', ['w_mni_p1', list_subjs{subj}, '_T1w.nii']), ...
             fullfile(analysis_dir, 'anat', 'mri_mni', list_subjs{subj}, ['w_p1', list_subjs{subj}, '_T1w.nii']));
    
    % Moving p2 file
    movefile(fullfile(analysis_dir, 'anat', 'mri', ['w_mni_p2', list_subjs{subj}, '_T1w.nii']), ...
             fullfile(analysis_dir, 'anat', 'mri_mni', list_subjs{subj}, ['w_p2', list_subjs{subj}, '_T1w.nii']));
    
    % Moving p3 file
    movefile(fullfile(analysis_dir, 'anat', 'mri', ['w_mni_p3', list_subjs{subj}, '_T1w.nii']), ...
             fullfile(analysis_dir, 'anat', 'mri_mni', list_subjs{subj}, ['w_p3', list_subjs{subj}, '_T1w.nii']));
    
    % Update summary
    disp([list_subjs{subj}, '...normalization...done!']);
    fprintf(fid_summary, '%s', [list_subjs{subj}, '...normalization...done!']);
end

% Close summary file
fclose(fid_summary);