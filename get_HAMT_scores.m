function HAMT_scores = get_HAMT_scores(filename)
% Function to read an exported (in Excel format) edat text file and compute
% performance score and AVH status for HAMT task
%% Input:
% filename:         cell containing rows of name(s)/full paths of text 
%                   file(s) which were previously exported in Excel format 
%                   from E-DataAid
% 
%% Outputs: 
% HAMT_scores:      table containing all HAMT scores (see Notes)
% 
% A csv file named behavioural_data_HAMT_DDMMMYYYY is written in the pwd 
% containing HAMT_scores; a mat file named behavioural_data_HAMT_DDMMMYYYY 
% is written in the pwd containing HAMT_scores
% 
%% Notes:
% The input text files should have been exported in Excel format without
% selecting unicode from E-DataAid
% 
% HAMT scores consist of the following entries:
% filename:         name(s) of file(s) which were input
% baseline_score:   the number of times subject pressed a button for the 
%                   first condition (press any button of your choice): FA
% change_scores:    the number of times the subject responded correctly to 
%                   the second condition (count the number of times the 
%                   image changed on the screen): VA
% AVH_noHall:       the number of times the subject responded as "no voices
%                   were heard" during third condition: HA
% AVH_Hall_lt50:    the number of times the subject responded as "voices
%                   were heard for less than 50% of time" during 
%                   third condition: HA
% AVH_Hall_gt50:    the number of times the subject responded as "voices
%                   were heard for more than 50% of time" during third 
%                   condition: HA
% AVH_status:       AVH+ or AVH- (a subject is classified as AVH+ if they 
%                   had AVH_Hall_gt50 score of 3 or more; i.e. the subject 
%                   heard voices for more than 50% of time for 3 or more 
%                   blocks) during condition 3: HA; 
% 
% AVH_status of healthy subjects is NaN
% 
% Response encoding
% left button     = 9;
% middle button   = 8;
% right button    = 7;
% 
%% Author(s):
% Parekh, Pravesh
% June 26, 2019
% MBIAL

%% Validate input
if ~exist('filename', 'var') || isempty(filename)
    error('At least one file name should be provided');
else
    % Get number of files
    num_files = size(filename, 1);
end

%% Initialize
scores_desc = {'filename';   'baseline_score'; 'change_scores'; ...
               'AVH_noHall'; 'AVH_Hall_lt50';  'AVH_Hall_gt50'; 'AVH_status'};
           
HAMT_scores = cell(num_files, length(scores_desc));

%% Work on each file
for files = 1:num_files
    
    % Read file as a table
    data = readtable(filename{files});

    % Decide if condition 3 (HA) is present or not
    if height(data)>120
        HA = true;
    else
        HA = false;
    end
    
    % Get SessionDate
    sess_date  = datetime(datestr(data.SessionDate{1}));
    
    % Decide if errors need to be corrected 
    check_date = datetime('25-Jun-2018');
    if sess_date < check_date
        correct_HAMT = true;
    else
        correct_HAMT = false;
    end
    
    % All condition locations
    loc_FA = ~cellfun(@isempty, (regexpi(data.BlockCondition, 'FA')));
    loc_VA = ~cellfun(@isempty, (regexpi(data.BlockCondition, 'VS')));
    loc_HA = ~cellfun(@isempty, (regexpi(data.BlockCondition, 'AH')));
    
    % Locations to pick up responses from
    loc_resp_FA = data.SubTrial==1 & loc_FA;
    loc_resp_VA = data.SubTrial==1 & loc_VA;
    loc_resp_HA = data.SubTrial==1 & loc_HA;

    % Get all correct responses for VA
    corr_responses = data.asQ_CRESP(loc_resp_VA)';

    % Correct VA responses, if required
    if ~HA && correct_HAMT
        % Recording number of times the pattern changed for HS
        % act_changes   = [7 3 7 3 6];
        corr_responses  = [8 7 7 7 7];
    else
        if HA && correct_HAMT
            % Recording number of times the pattern changed for SZ
            % For SZ, for second block, correct response can be 8 or 9 as
            % the number of changes is 6 and options are 2, 5, and 7
            % act_changes  = [7 6 3 4 7];
            corr_responses = [8 9 9 9 8];
        end
    end
    
    % Get all VA responses
    all_VA_responses = data.asQ_RESP(loc_resp_VA);
    
    % Score VA responses
    VA_correct = all_VA_responses == corr_responses';
    
    % Account for SZ second block ambiguous response
    if HA && correct_HAMT
        if all_VA_responses(2) == 8 || all_VA_responses(2) == 9
            VA_correct(2) = true;
        end
    end
    
    % Get HA responses, if condition 3 is present
    if HA
        all_HA_responses    = data.ahQ_RESP(loc_resp_HA);
        AVH_noHall          = sum(all_HA_responses==9);
        AVH_Hall_lt50       = sum(all_HA_responses==8);
        AVH_Hall_gt50       = sum(all_HA_responses==7);
        
        if AVH_Hall_gt50 >= 3
            AVH_Status = 'AVH+';
        else
            AVH_Status = 'AVH-';
        end
    else
        AVH_noHall      = NaN;
        AVH_Hall_lt50   = NaN;
        AVH_Hall_gt50   = NaN;
        AVH_Status      = NaN;
    end
    
    % Record responses
    HAMT_scores{files,1} = filename{files};
    HAMT_scores{files,2} = sum(~isnan(data.faQ_RESP(loc_resp_FA)));
    HAMT_scores{files,3} = sum(VA_correct);
    HAMT_scores{files,4} = AVH_noHall;
    HAMT_scores{files,5} = AVH_Hall_lt50;
    HAMT_scores{files,6} = AVH_Hall_gt50;
    HAMT_scores{files,7} = AVH_Status;
end

%% Convert to table
HAMT_scores = cell2table(HAMT_scores, 'VariableNames', scores_desc);

%% Write table as csv file
writetable(HAMT_scores, ['behavioural_data_HAMT_', datestr(now, 'ddmmmyyyy'), '.csv']);

%% Save all variables
save(['behavioural_data_HAMT_', datestr(now, 'ddmmmyyyy'), '.mat'], 'HAMT_scores');