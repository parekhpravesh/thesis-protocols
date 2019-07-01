function VFT_AVH_scores = get_VFT_scores(filename)
% Function to read an exported (in Excel format) edat text file and compute
% AVH status for VFT task
%% Input:
% filename:         cell containing rows of name(s)/full paths of text 
%                   file(s) which were previously exported in Excel format 
%                   from E-DataAid
% 
%% Outputs: 
% VFT_AVH_scores:   table containing VFT AVH score and AVH status (see Notes)
% 
% A csv file named VFT_AVH_DDMMMYYYY is written in the pwd containing 
% VFT_AVH_scores; a mat file named VFT_AVH_DDMMMYYYY is written in the pwd 
% containing VFT_AVH_scores
% 
%% Notes:
% The input text files should have been exported in Excel format without
% selecting unicode from E-DataAid
% 
% VFT_AVH_scores consist of the following entries:
% filename:         name(s) of file(s) which were input
% WR_AVH_noHall:    the number of times the subject responded as "no voices
%                   were heard" during word repetition (WR) condition
% WR_AVH_Hall_lt50: the number of times the subject responded as "voices
%                   were heard for less than 50% of time" during word 
%                   repetition (WR) condition
% WR_AVH_Hall_gt50: the number of times the subject responded as "voices
%                   were heard for more than 50% of time" during word 
%                   repetition (WR) condition
% WG_AVH_noHall:    the number of times the subject responded as "no voices
%                   were heard" during word generation (WG) condition
% WG_AVH_Hall_lt50: the number of times the subject responded as "voices
%                   were heard for less than 50% of time" during word 
%                   generation (WG) condition
% WG_AVH_Hall_gt50: the number of times the subject responded as "voices
%                   were heard for more than 50% of time" during word 
%                   generation (WG) condition
% WR_AVH_status:    AVH+ or AVH- (a subject is classified as AVH+ if they 
%                   had WR_AVH_Hall_gt50 score of 4 or more; i.e. the  
%                   subject heard voices for more than 50% of time for 4  
%                   or more blocks) during word repetition (WR) condition
% WG_AVH_status:    AVH+ or AVH- (a subject is classified as AVH+ if they 
%                   had WG_AVH_Hall_gt50 score of 4 or more; i.e. the  
%                   subject heard voices for more than 50% of time for 4 
%                   or more blocks) during word generation (WG) condition
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
scores_desc = {'filename';         'WR_AVH_noHall'; 'WR_AVH_Hall_lt50'; ...
               'WR_AVH_Hall_gt50'; 'WG_AVH_noHall'; 'WG_AVH_Hall_lt50'; ...
               'WG_AVH_Hall_gt50'; 'WR_AVH_status'; 'WG_AVH_status'};
           
VFT_AVH_scores = cell(num_files, length(scores_desc));

%% Work on each file
for files = 1:num_files
    
    % Read file as a table
    data = readtable(filename{files});
    
    % Decide if HS or SZ
    if strcmpi(data.SubjectGroup, 'Healthy')
        VFT_AVH_scores{files,1} = filename{files};
        VFT_AVH_scores{files,2} = NaN;
        VFT_AVH_scores{files,3} = NaN;
        VFT_AVH_scores{files,4} = NaN;
        VFT_AVH_scores{files,5} = NaN;
        VFT_AVH_scores{files,6} = NaN;
        VFT_AVH_scores{files,7} = NaN;
        VFT_AVH_scores{files,8} = NaN;
        VFT_AVH_scores{files,9} = NaN;
    else
        
        % Get all WR and WG conditions
        loc_WR = ~cellfun(@isempty, (regexpi(data.BlockCondition, 'vftnBaseBlock')));
        loc_WG = ~loc_WR;
        
        % Locations to pick up responses from
        loc_resp_WR = data.SubTrial==1 & loc_WR;
        loc_resp_WG = data.SubTrial==1 & loc_WG;
        
        % Get all responses
        all_WR_responses = data.ahQ_RESP(loc_resp_WR);
        all_WG_responses = data.ahQ_RESP(loc_resp_WG);
        
        % Save filename
        VFT_AVH_scores{files,1} = filename{files};
        
        % WR_AVH_noHall
        VFT_AVH_scores{files,2} = sum(all_WR_responses==9);
        
        % WR_AVH_Hall_lt50
        VFT_AVH_scores{files,3} = sum(all_WR_responses==8);
        
        % WR_AVH_Hall_gt50
        VFT_AVH_scores{files,4} = sum(all_WR_responses==7);
        
        % WG_AVH_noHall
        VFT_AVH_scores{files,5} = sum(all_WG_responses==9);
        
        % WG_AVH_Hall_lt50
        VFT_AVH_scores{files,6} = sum(all_WG_responses==8);
        
        % WG_AVH_Hall_gt50
        VFT_AVH_scores{files,7} = sum(all_WG_responses==7);
        
        % WR_AVH_status
        if sum(all_WR_responses==7) >= 4
            VFT_AVH_scores{files,8} = 'AVH+';
        else
            VFT_AVH_scores{files,8} = 'AVH-';
        end
        
        % WG_AVH_status
        if sum(all_WG_responses==7) >= 4
            VFT_AVH_scores{files,9} = 'AVH+';
        else
            VFT_AVH_scores{files,9} = 'AVH-';
        end
    end
end

%% Convert to table
VFT_AVH_scores = cell2table(VFT_AVH_scores, 'VariableNames', scores_desc);

%% Write table as csv file
writetable(VFT_AVH_scores, ['VFT_AVH_', datestr(now, 'ddmmmyyyy'), '.csv']);

%% Save all variables
save(['VFT_AVH_', datestr(now, 'ddmmmyyyy'), '.mat'], 'VFT_AVH_scores');