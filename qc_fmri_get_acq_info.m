function qc_fmri_get_acq_info(data_dir, task_name, full_bids)
% Function to compile basic acquisition details from structural and
% functional scans (from images and JSON sidecar file)
%% Inputs:
% data_dir:         full path to a directory having sub-* folders (BIDS
%                   style; see Notes)
% task_name:        functional file name pattern for which QC is being 
%                   performed (example: 'rest')
% full_bids:        yes/no to indicate if the data_dir is a full BIDS style
%                   folder (i.e. it has anat and func sub-folders) or all 
%                   files are present in a single folder (see Notes)
% 
%% Output:
% A mat file containing the basic acquisition details from both structural 
% and functional scans is saved; acquisition details are also saved from
% the JSON sidecar file. This file is named 
% <subject_ID>_acq_details_<task_name>.mat
% 
%% Notes:
% Each sub-* folder should have a T1w structural scan named 
% sub-<subject_ID>_T1w.nii and a functional scan named 
% sub-<subject_ID>_task-<task_name>_bold.nii. Same named JSON files should 
% also be present. If the data is full_bids style, T1w file is in the anat
% folder and the functional file is in the func folder; otherwise, they are
% present in the same folder
% 
% Full BIDS specification means that there are separate anat and func
% folders inside the subject folder; if specified as no, the files should
% still be named following BIDS specification but all files are assumed to
% be in the same folder
% 
% Since DICOM header is not queried, the values might be rounded-off
% 
% If values cannot be found, NaN is reported
% 
% Original units are retained so the values may not match directly
% 
%% Default:
% full_bids:        'yes'
% 
%% Author(s)
% Parekh, Pravesh
% August 26, 2018
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

%% Work on each subject
for sub = 1:num_subjs
    
    % Anatomical and functional scan names
    if full_bids
        anat_file = fullfile(data_dir, 'anat', list_subjs(sub).name, ...
                            [list_subjs(sub).name, '_T1w.nii']);
        func_file = fullfile(data_dir, 'func', list_subjs(sub).name, ...
                            [list_subjs(sub).name, '_task-', task_name, '_bold.nii']);
    else
        anat_file = fullfile(data_dir, list_subjs(sub).name, ...
                            [list_subjs(sub).name, '_T1w.nii']);
        func_file = fullfile(data_dir, list_subjs(sub).name, ...
                            [list_subjs(sub).name, '_task-', task_name, '_bold.nii']);
    end
    
    % Check if both the files exist
    if ~exist(anat_file, 'file') || ~exist(func_file, 'file')
        warning(['Cannot find anatomical/functional scan for ', ...
                 list_subjs(sub).name, '; skipping']);
    else
        
        % Record subject information
        acq_info.subjectID     = list_subjs(sub).name;
        acq_info.task_name     = task_name;
        acq_info.anat_filename = anat_file;
        acq_info.func_filename = func_file;
        
        % Read anatomical scan and find TR, TE, voxel size, and image dim
        vol = spm_vol(anat_file);
        dat = spm_read_vols(vol);
        tmp = strsplit(vol.private.descrip, ';');
        tmp = tmp{1};
        vox = spm_imatrix(vol.mat);
        
        % Check for NaN
        if isempty(vol.private.timing.tspace)
            acq_info.anat.img_TR = NaN;
        else
            acq_info.anat.img_TR = vol.private.timing.tspace;
        end
        acq_info.anat.img_TE       = str2double(strrep(tmp, 'TE=', ''));
        acq_info.anat.img_vox_size = [num2str(abs(vox(7))), ' x ', ...
                                      num2str(abs(vox(8))), ' x ', ...
                                      num2str(abs(vox(9)))];
        acq_info.anat.img_dim      = [num2str(size(dat,1)), ' x ', ...
                                      num2str(size(dat,2)), ' x ', ...
                                      num2str(size(dat,3))];
                                  
       % Read anatomical JSON file and find TR, TE, and flip angle
       fid                        = fopen(strrep(anat_file, '.nii', '.json'), 'r');
       anat_data                  = textscan(fid, '%s %s %s', 'Delimiter', '\t:');
       acq_info.anat.json_TR      = str2double(cell2mat(strrep(anat_data{1,3}(strcmpi(anat_data{1,2}, ...
                                             '"RepetitionTime"')), ',', '')));
       acq_info.anat.json_TE      = str2double(cell2mat(strrep(anat_data{1,3}(strcmpi(anat_data{1,2}, ...
                                        '"EchoTime"')), ',', '')));
       acq_info.anat.json_flipAng = str2double(cell2mat(strrep(anat_data{1,3}(strcmpi(anat_data{1,2}, ...
                                        '"FlipAngle"')), ',', '')));
                                    
       fclose(fid);
       clear fid anat_data tmp vol dat vox
       
       % Read functional scan and find TR, TE, voxel size, image dim, and
       % number of volumes
       vol     = spm_vol(func_file);
       num_vol = length(vol);
       vol     = vol(1);
       dat     = spm_read_vols(vol);
       tmp     = strsplit(vol.private.descrip, ';');
       tmp     = tmp{1};
       vox     = spm_imatrix(vol.mat);
       
        % Check for NaN
        if isempty(vol.private.timing.tspace)
            acq_info.func.img_TR = NaN;
        else
            acq_info.func.img_TR = vol.private.timing.tspace;
        end
        acq_info.func.img_TE       = str2double(strrep(tmp, 'TE=', ''));
        acq_info.func.img_vox_size = [num2str(abs(vox(7))), ' x ', ...
                                      num2str(abs(vox(8))), ' x ', ...
                                      num2str(abs(vox(9)))];
        acq_info.func.img_dim      = [num2str(size(dat,1)), ' x ', ...
                                      num2str(size(dat,2)), ' x ', ...
                                      num2str(size(dat,3))];
        acq_info.func.num_vol      = num_vol;
        
        % Read functional JSON file and find TR, TE, and flip angle
       fid                        = fopen(strrep(func_file, '.nii', '.json'), 'r');
       func_data                  = textscan(fid, '%s %s %s', 'Delimiter', '\t:');
       acq_info.func.json_TR      = str2double(cell2mat(strrep(func_data{1,3}(strcmpi(func_data{1,2}, ...
                                             '"RepetitionTime"')), ',', '')));
       acq_info.func.json_TE      = str2double(cell2mat(strrep(func_data{1,3}(strcmpi(func_data{1,2}, ...
                                             '"EchoTime"')), ',', '')));
       acq_info.func.json_flipAng = str2double(cell2mat(strrep(func_data{1,3}(strcmpi(func_data{1,2}, ...
                                             '"FlipAngle"')), ',', '')));
                                    
       fclose(fid);
       clear fid func_data tmp vol dat vox num_vol
       
       % Create quality_check_<task_name> directory if it doesn't exist
       if full_bids
           qc_dir = fullfile(data_dir, list_subjs(sub).name,  'func', ['quality_check_', task_name]);
           if ~exist(fullfile(data_dir, list_subjs(sub).name, 'func', ['quality_check_', task_name]), 'dir')
               mkdir(fullfile(data_dir, list_subjs(sub).name, 'func', ['quality_check_', task_name]));
           end
       else
           qc_dir = fullfile(data_dir, list_subjs(sub).name,  ['quality_check_', task_name]);
           if ~exist(fullfile(data_dir, list_subjs(sub).name, ['quality_check_', task_name]), 'dir')
               mkdir(fullfile(data_dir, list_subjs(sub).name, ['quality_check_', task_name]));
           end
       end 
           
       % Save the mat file
       save_name = fullfile(qc_dir, [list_subjs(sub).name, '_acq_details_', task_name, '.mat']);
       save(save_name, 'acq_info');
       clear save_name acq_info qc_dir
    end
end