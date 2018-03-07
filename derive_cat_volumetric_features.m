function derive_cat_volumetric_features(in_dir, out_dir)
% Function to compile whole brain volumetric features obtained from CAT
% segmentation
%% Inputs:
% in_dir:           fullpath to directory having main cat results folder
%                   where cat_subjlist_volumes_ddmmmyyyy.txt and
%                   cat_subjlist_get_volumes_ddmmmyyyy.txt files are
%                   present
% out_dir:          fullpath to where the csv file is to be written
% 
%% Output:
% A .csv file is written at out_dir having the following fields:
% sub_ID:           as mentioned in subjlist (see prep_cat_get_volumes)
% TIV:              total intracranial volume
% GM:               gray matter volume
% WM:               white matter volume
% CSF:              cerebrospinal fluid volume
% TBV:              total brain volume (GM+WM volumes)
% WMH:              white matter hyperintensities
% the file is named cat_volumes_ddmmmyyyy.csv
% 
%% Defaults:
% If out_dir is not specified, file is written at in_dir
% 
%% Notes:
% If cat_subjlist_get_volumes_ddmmmyyyy.txt file is not found in in_dir,
% user is prompted via GUI to select the file; similarly, if multiple files
% are found, user is prompted via GUI to select the correct file; similar
% UI prompting is done for subjlist
% 
%% Author(s):
% Parekh, Pravesh
% March 07, 2018
% MBIAL

%% Check inputs
if ~exist(in_dir, 'dir')
    error([in_dir, ' not found']);
else
    % Check if volume file is present
    cd(in_dir);
    vol_file = dir('cat_subjlist_volumes*.txt');
    if isempty(vol_file)
        % Prompt user to provide file
        warning('Volume file not found at location; please select the file');
        [vol_file, vol_loc] = uigetfile('.txt', 'Select file having volumes');
    else
        % Check if multiple files are present
        if length(vol_file) > 1
            % Prompt user to provide file
            warning('Multiple volume files found at location; please select the correct file');
            [vol_file, vol_loc] = uigetfile('.txt', 'Select file having volumes');
        else
            vol_loc  = in_dir;
            vol_file = vol_file.name;
        end
    end
end

% Check if subjlist exists
cd(in_dir);
subj_file = dir('cat_subjlist_get_volumes_*.txt');
if isempty(subj_file)
    warning('Subect list not found; please select the file');
    [subj_file, subj_loc] = uigetfile('.txt', 'Select file having subject list');
else
    % Check if multiple files are present
    if length(subj_file) > 1
        % Prompt user to provide file
        warning('Multiple subject lists found; please select correct file');
        [subj_file, subj_loc] = uigetfile('.txt', 'Select file having subject list');
    else
        subj_loc  = in_dir;
        subj_file = subj_file.name;
    end
end

if ~exist('out_dir', 'var')
    out_dir = in_dir;
end

%% Read volume file and subject list
data_volumes  = dlmread(fullfile(vol_loc, vol_file));
fid           = fopen(fullfile(subj_loc, subj_file), 'r');
data_subjects = textscan(fid, '%s');
fclose(fid);

%% Sanity check
if length(data_subjects{1}) ~= size(data_volumes,1)
    error('Mismatch between number of subjects in subjlist and number of volumes');
end

%% Prepare results table
volumes_table = cell2table(cell(length(data_subjects{1}),7));
volumes_table.Properties.VariableNames = {'sub_ID', 'TIV', 'GM', 'WM', 'CSF', 'TBV', 'WMH'};

%% Assign volumes to results table
volumes_table.sub_ID = data_subjects{1};
volumes_table.TIV    = data_volumes(:,1);
volumes_table.GM     = data_volumes(:,2);
volumes_table.WM     = data_volumes(:,3);
volumes_table.CSF    = data_volumes(:,4);
volumes_table.TBV    = data_volumes(:,2) + data_volumes(:,3);
volumes_table.WMH    = data_volumes(:,5);

%% Save table as csv file
writetable(volumes_table, fullfile(out_dir, ['cat_volumes_', datestr(now, 'ddmmmyyyy'), '.csv']));