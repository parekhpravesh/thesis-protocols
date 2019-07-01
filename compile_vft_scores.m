function compile_vft_scores(dir_scores, dir_output)
% Function to compile VFT scores from individual score sheets
%% Inputs:
% dir_scores:       fullpath to directory having Excel sheets with VFT 
%                   scores for individual subjects
% dir_output:       fullpath to where summary sheet will be saved
%
%% Output:
% A file named 'summary_VFTscores_DDMMMYYYY.xlsx' is saved in dir_output
%
%% Default:
% dir_output:       same folder as dir_scores
% 
%% Author(s):
% Parekh, Pravesh
% July 01, 2019
% MBIAL
%
%% Validate inputs
% Check dir_scores
if ~exist('dir_scores', 'var') || isempty(dir_scores)
    error('Directory having individual scores should be provided');
else
    if ~exist(dir_scores, 'dir')
        error(['Unable to find directory: ', dir_scores]);
    end
end

% Check dir_output
if ~exist('dir_output', 'var') || isempty(dir_output)
    dir_output = dir_scores;
else
    if ~exist(dir_output, 'dir')
        mkdir(dir_output);
    end
end

%% Initialize
cd(dir_scores);
list_vft_files = dir('*.xlsx');
results        = cell(length(list_vft_files), 8);
header         = {'File_Name', 'WR', 'VFCR', 'VFMR', 'VFPR', 'VFRR', 'VFIR', 'VFTR'};

%% Extract scores
for files = 1:length(list_vft_files)
    data  = readtable(fullfile(dir_scores, list_vft_files(files).name));
    results{files,1} = list_vft_files(files).name;
    results{files,2} = data.Correct(48);
    results{files,3} = data.Correct_1(49);
    results{files,4} = data.Correct_1(50);
    results{files,5} = data.Correct_1(51);
    results{files,6} = data.Correct_1(52);
    results{files,7} = data.Correct_1(53);
    results{files,8} = data.Correct_1(54);
end

%% Write output
results = cell2table(results, 'VariableNames', header);
writetable(results, fullfile(dir_output, ['summary_VFTscores_', datestr(now, 'ddmmmyyyy'), '.xlsx']));