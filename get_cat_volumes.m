function get_cat_volumes(in_dir)
% Function to calculate and compile whole brain volumetric features
% obtained from CAT segmentation
%% Inputs:
% in_dir:           fullpath to directory having main cat results folder
%                   (not the report directory)
% 
%% Output:
% A batch file named cat_get_volumes_ddmmmyyyy.mat is saved in the in_dir;
% 
% CAT outputs a text file having volumes which is saved as 
% volumes_ddmmmyyyy.txt in in_dir; 
% 
% A .csv file (cat_volumes_ddmmmyyyy.csv) is written at out_dir having the
% following fields:
% sub_ID:           subject list
% TIV:              total intracranial volume
% GM:               gray matter volume
% WM:               white matter volume
% CSF:              cerebrospinal fluid volume
% TBV:              total brain volume (GM+WM volumes)
% WMH:              white matter hyperintensities
% GM_WM_ratio:      gray matter to white matter ratio
% 
%% Author(s):
% Parekh, Pravesh
% March 07, 2018
% MBIAL

%% Check inputs
if ~exist(in_dir, 'dir')
    error([in_dir, ' not found']);
else
    if ~exist(fullfile(in_dir, 'report'), 'dir')
        error('Segmentation results not found');
    end
end

%% Prepare list of xml files
cd(fullfile(in_dir, 'report'));
list_files = dir('cat*.xml');
num_files  = length(list_files);
disp([num2str(num_files), ' xml files found']);

%% Create batch
% Create output file name
tmp_fname = ['volumes_', datestr(now, 'ddmmmyyyy'), '.txt'];

% Create batch
for file = 1:num_files
    matlabbatch{1}.spm.tools.cat.tools.calcvol.data_xml(file,1) = ...
        {fullfile(in_dir, 'report', list_files(file).name)};
end
matlabbatch{1}.spm.tools.cat.tools.calcvol.calcvol_TIV = 0;
matlabbatch{1}.spm.tools.cat.tools.calcvol.calcvol_name = tmp_fname;


%% Save batch
save(fullfile(in_dir, ['cat_get_volumes', datestr(now, 'ddmmmyyyy'), ...
                       '.mat']), 'matlabbatch');

%% Run batch
spm_jobman('run', matlabbatch);

%% Move the created file to in_dir
movefile(fullfile(in_dir, 'report', tmp_fname), in_dir);

%% Compile subjlist
subj_list = cell(num_files,1);
for file = 1:num_files
    subj_list{file} = regexprep(list_files(file).name, {'cat_', '_T1w', '.xml'}, '');
end

%% Read volume file which was just created
data_volumes = dlmread(fullfile(in_dir, tmp_fname));

%% Prepare results table
volumes_table = cell2table(cell(num_files,8));
volumes_table.Properties.VariableNames = {'sub_ID', 'TIV', 'GM', 'WM', ...
                                          'CSF', 'TBV', 'WMH', 'GM_WM_ratio'};

%% Assign volumes to results table
volumes_table.sub_ID        = subj_list;
volumes_table.TIV           = data_volumes(:,1);
volumes_table.GM            = data_volumes(:,2);
volumes_table.WM            = data_volumes(:,3);
volumes_table.CSF           = data_volumes(:,4);
volumes_table.TBV           = data_volumes(:,2) + data_volumes(:,3);
volumes_table.WMH           = data_volumes(:,5);
volumes_table.GM_WM_ratio   = data_volumes(:,2) ./ data_volumes(:,3);

%% Save table as csv file
writetable(volumes_table, fullfile(in_dir, ['cat_volumes_', ...
    datestr(now, 'ddmmmyyyy'), '.csv']));

%% Update user
disp('Finished compiling volumeteric data');