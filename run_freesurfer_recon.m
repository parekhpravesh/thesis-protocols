function run_freesurfer_recon(data_dir, freesurfer_dir, batch_size, full_bids)
% Function to run recon-all pipeline using FreeSurfer for multiple subjects
%% Inputs:
% data_dir:         fullpath to directory containing sub-* folders
% freesurfer_dir:   fullpath to where FreeSurfer is installed
% batch_size:       number of subjects to be processed together
% full_bids:        yes/no indicating if folders in data_dir follow full
%                   BIDS specification
% 
%% Output:
% Within each subject folder (or anat folder, if full_bids), a folder named 
% "freesurfer_<subj_ID>" is created. Freesurfer output folders and files 
% are generated in this folder.
% 
%% Notes:
% Only passes structural T1w file to FreeSurfer
% 
% Assumes Linux!
% 
% Relies on a crude form of parallel processing where the command is called
% batch_size number of times; we wait for the last of these commands to get
% over but do not check if the other commands executed before the last one
% are over; this can sometimes create problem when the last job in a batch
% gets over than its preceeding jobs in which case the script will add
% another batch_size number of subjects into processing. Hopefully the
% difference between time required to process each subject should not be 
% too different; if running on a system with very limited resources, try
% and reduce the batch_size a little so as not to overwhelm the resources
% 
%% Defaults:
% batch_size:      10
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

% Check batch_size
if ~exist('batch_size', 'var') || isempty(batch_size)
    batch_size = 10;
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

%% Run FreeSurfer commands
count = 1;
for sub = 1:num_subjs
    
    % Subject directory
    if full_bids
        subj_dir = fullfile(data_dir, list_subjs{sub}, 'anat');
    else
        subj_dir = fullfile(data_dir, list_subjs{sub});
    end
    
    % Get T1w file for this subject
    T1w_file = fullfile(subj_dir, [list_subjs{sub}, '_T1w.nii']);
    
    % Check if file exists
    if ~exist(T1w_file, 'file')
        warning(['Cannot find T1w file for: ', list_subjs{sub}, '; skipping!']);
    else
        % Subject ID
        subj_id = ['freesurfer_', list_subjs{sub}];
        
        % Create all commands
        if count == batch_size
            command = [['source ', freesurfer_dir, '/SetUpFreeSurfer.sh && '], ...
                       ['export SUBJECTS_DIR=', subj_dir, ' && '], ...
                       ['recon-all -i ', T1w_file, ' -subjid ', subj_id, ' && '], ...
                       ['recon-all -all -subjid ', subj_id]];
            system(command);
            count = 1;
        else
            command = [['source ', freesurfer_dir, '/SetUpFreeSurfer.sh && '], ...
                       ['export SUBJECTS_DIR=', subj_dir, ' && '], ...
                       ['recon-all -i ', T1w_file, ' -subjid ', subj_id, ' && '], ...
                       ['recon-all -all -subjid ', subj_id, ' &']];
            system(command);
            count = count + 1;
        end
    end
end