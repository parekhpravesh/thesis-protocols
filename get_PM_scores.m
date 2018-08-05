function [summary_data, scores, latencies, task_load, ...
          scores_desc, latencies_desc, task_load_desc] ...
         = get_PM_scores(filename, score_type, latency_type)
% Function to read an exported (in Excel format) edat text file and compute
% performance scores and latencies for PM task
%% Inputs:
% filename:                 cell containing rows of name(s)/full paths of
%                           text file(s) which were previously exported in
%                           Excel format from E-DataAid
% score_type:               method for calculating scores; one of the
%                           following methods should be specified:
%                           	* 'score'
%                               * 'percentage'
% latency_type:             method for calculating latency; one of the
%                           following methods should be spcified:
%                               * 'all'
%                               * 'all_ig_miss'
%                               * 'correct'
% 
% See Notes for a description of these methods
% 
%% Outputs: 
% summary_data:             table having summarized behavioural data
% scores:                   matrix with performance data; if multiple files
%                           are given, third dimension indexes the file 
% latencies:                matrix with latency data; if multiple files are 
%                           given, third dimension indexes the file
% task_load:                matrix with WM and PM load per trial; if 
%                           multiple files are given,
%                           third dimension indexes the file
% scores_desc:              a description of columns of scores 
% latencies_desc:           a description of columns of latencies
% task_load_desc:           a description of columns of task_load
% 
% See Notes for a description of organization of these variables
% 
%% Notes:
% The input text files should have been exported in Excel format without
% selecting unicode from E-DataAid
% 
% By default all reaction times less than equal to 200 ms are treated as 
% invalid i.e. the responses corresponding to these RT are set to NaN and 
% the RT of such trials is set to zero. 
% 
% This would increase the number of missed responses for each condition; 
% to correct for this, the number of responses with timing less than equal 
% to 200 ms is subtracted from the number of missed responses
% 
% The summary_data variable is a table with the following columns:
% 01) file_name:            file name
% 02) Score_BL:             BL condition performance
% 03) Score_OT:             OT condition performance
% 04) Score_WM:             WM condition performance
% 05) Score_PM:             PM condition performance (overall)
% 06) Score_PM_in_PM:       PM performance in PM condition (precise)
% 07) Score_PM_in_PM_Lib:   PM performance in PM condition (liberal)
% 08) Score_OT_in_PM:       OT performance in PM condition
% 09) Score_WM_Query:       WM condition query slide performance 
% 10) Score_OT_WM:          OT performance (OT condition) -
%                           WM performance (WM condition)
% 11) Score_OT_PM:          OT performance (OT condition) - 
%                           PM performance (overall; OT+PM)
% 12) RT_BL:                mean BL condition latency
% 13) RT_OT:                mean OT condition latency
% 14) RT_WM:                mean WM condition latency
% 15) RT_PM:                mean PM condition latency (overall)
% 16) RT_PM_in_PM:          mean PM condition latency (PM trials only)
% 17) RT_OT_in_PM:          mean PM condition latency (OT trials only)
% 18) RT_WM_OT:             mean WM condition latency (WM condition) - 
%                           mean OT condition latency (OT condition)
% 19) RT_PM_OT:             mean PM condition latency (PM condition; OT+PM) -
%                           mean OT condition latency (OT condition)
% 20) BL_missed:            number of trials missed in BL condition
% 21) OT_missed:            number of trials missed in OT condition
% 22) WM_missed:            number of trials missed in WM condition
% 23) PM_missed:            number of trials missed in PM condition
% 24) BL_lt200ms:           number of BL trials with <= 200 ms latency 
% 25) OT_lt200ms:           number of OT trials with <= 200 ms latency
% 26) WM_lt200ms:           number of WM trials with <= 200 ms latency
% 27) PM_lt200ms:           number of PM trials with <= 200 ms latency
% 28) WMOT_negative:        number of trials resulting in a negative value
%                           when subtracting mean WM and mean OT latencies
% 29) PMOT_negative:        number of trials resulting in a negative value
%                           when subtracting mean PM and mean OT latencies
% 30) score_type:           unit of scores: 'score' or 'percentage'
% 31) latency_type:         method for calculating latency
% 
% The scores variable is a 2D or 3D matrix having trial level performance 
% information stored in the following columns (NaN values for empty spots):
% 01) trial_number:         trial number from 1:40
% 02) Score_BL:             BL condition performance
% 03) Score_OT:             OT condition performance
% 04) Score_WM:             WM condition performance
% 05) Score_PM:             PM condition performance
% 06) Score_PM_in_PM:       PM condition performance (PM trials; precise)
% 07) Score_PM_in_PM_Lib:   PM condition performance (PM trials; libral)
% 08) Score_OT_in_PM:       PM condition performance (OT trials only)
% 09) Score_WM_Query:       WM condition query slide performance 
% 
% The latencies variable is a 2D or 3D matrix having trial level latency
% information stored in the following columns (NaN values for empty spots):
% 01) trial_number:         trial number from 1:40
% 02) RT_BL:                BL condition latencies
% 03) RT_OT:                OT condition latencies
% 04) RT_WM:                WM condition latencies
% 05) RT_PM:                PM condition latencies
% 06) RT_PM_in_PM:          PM condition latencies (PM trials only)
% 07) RT_OT_in_PM:          PM condition latencies (OT trials only)
% 
% The task_load variable is a 2D or 3D matrix having WM/PM trial load
% stored in the following columns:
% 01) trial_number:         trial number from 1:40
% 02) WM_load:              WM load for all fourty trials
% 03) PM_load:              PM load for all fourty trials
% The load is essentially the cumulative sum of numbers for a particular
% block (WM) or till the PM trial happens (PM)
%
% To calculate PM accuracy (PM trials only), two methods are considered:
% 'precise':                PM trial is considered correct if the middle 
%                           button is pressed exactly at the trial when the 
%                           sum becomes 7 or greater than 7
% 'liberal':                PM trial is considered correct if the middle 
%                           button is pressed one trial before, during the 
%                           trial, or one trial after the actual PM trial
% 
% score_type can be either of the following:
% 'score':                  scores are returned as numbers
% 'percentage':             scores are returned as percentages
% 
% latency_type can be any of the following:
% 'all':                    latency for every trial is considered
%                           irrespective of their value (missing values = 0
%                           are also counted for calculating mean)
% 'all_ig_miss':            latency for all trials are considered (missing
%                           values are not considered for calculating mean;
%                           note that any trial with latency less than 
%                           200 ms is considered as missing response)
% 'correct':                only latency for trials with correct responses 
%                           are considered
% 
% MATLAB table loading warnings about variablenames are turned off 
% 
%% Defaults:
% score_type:               score
% latency_type:             all_ig_miss
% 
%% Author(s):
% Parekh, Pravesh
% May 29, 2018
% MBIAL

%% Validate input and assign defaults
if ~exist('filename', 'var')
    error('At least one file name should be provided');
else
    % Get number of files
    num_files = size(filename, 1);
end

if ~exist('score_type', 'var') || isempty(score_type)
    score_type = 'score';
else
    if ~ismember(score_type, {'score', 'percentages'})
        error(['Unknown score_type provided: ', score_type]);
    end
end

if ~exist('latency_type', 'var') || isempty(latency_type)
    latency_type = 'all_ig_miss';
else
    if ~ismember(latency_type, {'all', 'all_ig_miss', 'correct'})
        error(['Unknown latency_type provided: ', latency_type]);
    end
end

%% Get MATLAB version and suppress warning
tmp = version('-release');
tmp(end) = '';
tmp = str2double(tmp);
if tmp > 2016
    warning('OFF', 'MATLAB:table:ModifiedAndSavedVarnames');
else
    warning('OFF', 'MATLAB:table:ModifiedVarnames');
end

%% Initialize
max_trials      = 40;
summary_data    = cell(num_files, 31);
column_names    = {'file_name', 'Score_BL', 'Score_OT', 'Score_WM', 'Score_PM', ...
                   'Score_PM_in_PM', 'Score_PM_in_PM_Lib', 'Score_OT_in_PM',    ...
                   'Score_WM_Query', 'Score_OT_WM', 'Score_OT_PM',              ...
                   'RT_BL', 'RT_OT', 'RT_WM', 'RT_PM', 'RT_PM_in_PM',           ...
                   'RT_OT_in_PM', 'RT_WM_OT', 'RT_PM_OT', 'BL_missed',          ...
                   'OT_missed', 'WM_missed', 'PM_missed', 'BL_lt200ms',         ...
                   'OT_lt200ms', 'WM_lt200ms', 'PM_lt200ms', 'WMOT_negative',   ...
                   'PMOT_negative', 'score_type', 'latency_type'};

scores          = zeros(max_trials, 9, num_files);
scores_desc     = {'trial_number', 'Score_BL', 'Score_OT', 'Score_WM', ...
                   'Score_PM', 'Score_PM_in_PM', 'Score_PM_in_PM_Lib', ...
                   'Score_OT_in_PM', 'Score_WM_Query'};
            
latencies       = zeros(max_trials, 7, num_files);
latencies_desc  = {'trial_number', 'RT_BL', 'RT_OT', 'RT_WM', 'RT_PM', ...
                   'RT_PM_in_PM', 'RT_OT_in_PM'};

task_load       = zeros(max_trials, 3, num_files);
task_load_desc  = {'trial_number', 'WM_load', 'PM_load'};

%% Working on each file
for files = 1:num_files
    %% Make decisions about each file
    % Read file as a table
    data = readtable(filename{files});
    
    % Get SessionDate
    sess_date  = datetime(datestr(data.SessionDate{1}));
    
    % Decide if data is Philips Ingenia or Siemens Skyra
    % If year >= 2017, Philips Ingenia ; else Siemens Skyra
    file_year = str2double(datestr(data.SessionDate(1), 10));
    if file_year >= 2017
        philips = 1;
    else
        philips = 0;
    end
    
    % Decide if PM error in Block 4 1st PM trial needs to be corrected;
    % For Philips, if the SessionDate is before 30-Apr-2018, correct it
    % For Siemens, check if the number for Block 4 1st trial is 1 or 3. 
    % If 1, 1st PM trial needs to be corrected
    if philips
        check_date = datetime('30-Apr-2018');
        if sess_date <= check_date
            correct_PM = 1;
        else
            correct_PM = 0;
        end
    else
        tmp = data.number(strcmpi(data.BlockCondition, 'PMtask'));
        if tmp(31) == 1
            correct_PM = 1;
        else
            correct_PM = 0;
        end
    end
    
    % Determine the middle and left button responses
    % For Philips, the responses are 9/8/7 (L/M/R)
    % For Siemens, the responses are either 1/2/3 (L/M/R) or 2/3/4 (L/M/R);
    % if any CRESP values are equal to 1, 1/2/3 are the correct responses
    if philips
        middle_button = 8;
        left_button   = 9;
    else
        % If any CRESP is 1, then middle button is 2; left button is 1
        if ~isempty(nonzeros(data.probe_CRESP == 1))
            middle_button = 2;
            left_button   = 1;
        else
            % middle button is 3; left button is 2
            middle_button = 3;
            left_button   = 2;
        end
    end
    
    % Determine which are the PM trials among all 40 trials
    % For Philips, if correction should be applied, there are 11 PM trials
    % For Philips, if no correction should be applied, there are 12 PM
    % trials but the ordering is shifted by one
    % For Siemens, if correction should be appied, there are 11 PM trials;
    % the ordering is same as Philips case with correction
    % For Siemens, if no correction should be applied, there are 12 PM
    % trials, but the ordering remains unchanged
    if philips
        if correct_PM
            PM_trial_locations = [4, 7, 10, 13, 16, 20, 22, 25, 28, 36, 39];
        else
            PM_trial_locations = [4, 7, 10, 13, 16, 20, 22, 25, 28, 33, 37, 40];
        end
    else
        if correct_PM
            PM_trial_locations = [4, 7, 10, 13, 16, 20, 22, 25, 28, 36, 39];
        else
            PM_trial_locations = [4, 7, 10, 13, 16, 20, 22, 25, 28, 32, 36, 39];
        end
    end
    
    % Number of trials
    num_query_trials  = 4;
    num_PM_trials = length(PM_trial_locations);
    num_OT_trials = max_trials - length(PM_trial_locations);
    
    % Determine if WM query slide CRESP needs to be corrected
    % For Philips data acquired before 31st May 2018, WM Query correct
    % responses were incorrectly specified for the first three occurrences;
    % the last query slide response was correct because the correct 
    % response is the middle button. 
    % Block 1 Query correct response: left button   (9)
    % Block 2 Query correct response: right button  (7)
    % Block 3 Query correct response: left button   (9)
    % Block 4 Query correct response: middle button (8)
    if philips
        check_date = datetime('31-May-2018');
        if sess_date <= check_date
            correct_WM = 1;
        else
            correct_WM = 0;
        end
    else
        correct_WM = 0;
    end
    
    %% Gathering raw scores and latency values
    
    % Number of trials with RT > 0 ms and <= 200 ms
    % ---------------------------------------------
    % BL
    summary_data{files,24} = length(nonzeros(data.probe_RT > 0 ...
                                   & data.probe_RT <= 200      ...
                                   & strcmpi(data.BlockCondition, 'BLTask')));
    % OT
    summary_data{files,25} = length(nonzeros(data.probe_RT > 0 ...
                                   & data.probe_RT <= 200      ...
                                   & strcmpi(data.BlockCondition, 'OTTask')));
    % WM
    summary_data{files,26} = length(nonzeros(data.probe_RT > 0 ...
                                   & data.probe_RT <= 200      ...
                                   & strcmpi(data.BlockCondition, 'WMTask')));
    % PM
    summary_data{files,27} = length(nonzeros(data.probe_RT > 0 ...
                                   & data.probe_RT <= 200      ...
                                   & strcmpi(data.BlockCondition, 'PMTask')));
                                   
    % Check for latency values less than equal to 200 ms; if any are 
    % present mark that response as NaN so that it gets treated as missing
    % response. Also mark that RT as zero so that it is not counted
    chk_loc = data.probe_RT < 200;
    data.probe_RESP(chk_loc) = NaN;
    data.probe_RT(chk_loc) = 0;
    
    % Fill in trial numbers
    scores(:,1,files)    = 1:max_trials;
    latencies(:,1,files) = 1:max_trials;
    
    % BL condition score
    % ------------------
    trial_items = strcmpi(data.BlockCondition, 'BLtask'); 
    trial_resp  = data.probe_RESP(trial_items);
    scores(~isnan(trial_resp),2,files) = 1;
    latencies(:,2,files) = data.probe_RT(trial_items);
    
    % OT condition score
    % ------------------
    trial_items = strcmpi(data.BlockCondition, 'OTtask');
    trial_resp  = data.probe_RESP(trial_items);
    corr_resp   = data.probe_CRESP(trial_items);
    scores(corr_resp==trial_resp,3,files) = 1;
    latencies(:,3,files) = data.probe_RT(trial_items);
    
    % WM condition score
    % ------------------
    trial_items = strcmpi(data.BlockCondition, 'WMtask');
    % Remove the query slide entries if Philips data
    if philips
        trial_items(~isnan(data.WMQList)) = [];
    end
    trial_resp  = data.probe_RESP(trial_items);
    corr_resp   = data.probe_CRESP(trial_items);
    scores(corr_resp==trial_resp,4,files) = 1;
    latencies(:,4,files) = data.probe_RT(trial_items);
    
    % PM condition score
    % ------------------
    trial_items = strcmpi(data.BlockCondition, 'PMtask');
    trial_resp  = data.probe_RESP(trial_items);
    corr_resp   = data.probe_CRESP(trial_items);
    % Apply correction to Block 4 PM condition 1st PM trial (overall trial
    % number 32 out of 40 PM trials), if needed; change the middle button
    % response to left button
    if correct_PM
        corr_resp(32) = left_button;
    end
    scores(corr_resp==trial_resp,5,files) = 1;
    latencies(:,5,files) = data.probe_RT(trial_items);
    
    % PM condition PM scores (precise)
    % ----------------------
    scores(corr_resp==trial_resp,6,files)  = 1;
    latencies(:,6,files) = data.probe_RT(trial_items);
    % Convert non-PM trial scores and latencies to NaN
    tmp = zeros(40,1);
    tmp(PM_trial_locations) = 1;
    scores(~tmp,6,files)    = NaN;
    latencies(~tmp,6,files) = NaN;
    
    % PM condition PM score (liberal)
    % -------------------------------
    % Get all correct PM responses and save them
    temp_PM_check = (corr_resp == trial_resp);
    PM_direct     = temp_PM_check(PM_trial_locations);
    % Check, for incorrect responses, if participant pressed the middle 
    % button one trial prior; treat them as correct response
    incorrect  = find(~PM_direct);
    prior_resp = trial_resp(PM_trial_locations(~PM_direct)-1) == middle_button;
    PM_direct(incorrect(prior_resp)) = 1;
    % Check, for remaining incorrect responses, if participant pressed the 
    % middle button one trial after; treat them as correct response
    incorrect  = find(~PM_direct);
    post_resp  = trial_resp(PM_trial_locations(~PM_direct)+1) == middle_button;
    PM_direct(incorrect(post_resp)) = 1;
    % PM performance score (liberal)
    scores(PM_trial_locations,7,files) = PM_direct;
    % Convert non-PM trial scores to NaN
    tmp = zeros(40,1);
    tmp(PM_trial_locations) = 1;
    scores(~tmp,7,files)    = NaN;
    
    % PM condition OT scores
    % ----------------------
    scores(corr_resp==trial_resp,8,files) = 1;
    latencies(:,7,files) = data.probe_RT(trial_items);
    % Convert PM trial scores and latencies to NaN
    scores(PM_trial_locations,8,files)    = NaN;
    latencies(PM_trial_locations,7,files) = NaN;
    
    % WM condition query scores
    % -------------------------
    % For Siemens Skyra, return NaNs for WM Query as the response was vocal
    if ~philips
        scores(:,9,files) = NaN;
    else
        % Get all WM Query correct responses
        loc        = ~isnan(data.TotalQ_CRESP);
        trial_resp = data.TotalQ_RESP(loc);
        corr_resp  = data.TotalQ_CRESP(loc);
        % Apply WM correction, if needed
        if correct_WM
            corr_resp(1) = 9;
            corr_resp(2) = 7;
            corr_resp(3) = 9;
        end
        scores(trial_resp==corr_resp,8,files) = 1;
        % Pad remaining spots with NaN
        scores(5:end,9,files) = NaN;
    end
    
    %% Compiling information for summary variable 
    summary_data{files,1} = filename{files};
    
    % Compiling scores
    % ----------------
    if strcmpi(score_type, 'score')
        % BL score
        summary_data{files,2} = sum(scores(:,2,files),'omitnan');
        % OT score
        summary_data{files,3} = sum(scores(:,3,files),'omitnan');
        % WM score
        summary_data{files,4} = sum(scores(:,4,files),'omitnan');
        % PM score
        summary_data{files,5} = sum(scores(:,5,files),'omitnan');
        % PM in PM score (precise)
        summary_data{files,6} = sum(scores(:,6,files),'omitnan');
        % PM in PM score (liberal)
        summary_data{files,7} = sum(scores(:,7,files),'omitnan');
        % OT in PM score
        summary_data{files,8} = sum(scores(:,8,files),'omitnan');
        % WM query score
        summary_data{files,9} = sum(scores(:,9,files),'omitnan');
    else
        % BL score
        summary_data{files,2} = sum(scores(:,2,files),'omitnan')/max_trials*100;
        % OT score
        summary_data{files,3} = sum(scores(:,3,files),'omitnan')/max_trials*100;
        % WM score
        summary_data{files,4} = sum(scores(:,4,files),'omitnan')/max_trials*100;
        % PM score
        summary_data{files,5} = sum(scores(:,5,files),'omitnan')/max_trials*100;
        % PM in PM score (precise)
        summary_data{files,6} = sum(scores(:,6,files),'omitnan')/num_PM_trials*100;
        % PM in PM score (liberal)
        summary_data{files,7} = sum(scores(:,7,files),'omitnan')/num_PM_trials*100;
        % OT in PM score
        summary_data{files,8} = sum(scores(:,8,files),'omitnan')/num_OT_trials*100;
        % WM query score
        summary_data{files,9} = sum(scores(:,9,files),'omitnan')/num_query_trials*100;
    end
    % OT - WM score
    summary_data{files,10} = summary_data{files,3} - summary_data{files,4};
    % OT - PM score
    summary_data{files,11} = summary_data{files,3} - summary_data{files,5};
    
    % Compiling reaction time
    % -----------------------
    switch latency_type
        case 'all'
            % RT BL
            summary_data{files,12} = mean(latencies(:,2,files));
            % RT OT
            summary_data{files,13} = mean(latencies(:,3,files));
            % RT WM
            summary_data{files,14} = mean(latencies(:,4,files));
            % RT PM
            summary_data{files,15} = mean(latencies(:,5,files));
            % RT PM in PM
            summary_data{files,16} = mean(latencies(PM_trial_locations,5,files));
            % RT OT in PM
            tmp = zeros(40,1);
            tmp(PM_trial_locations) = 1;
            summary_data{files,17} = mean(latencies(~tmp,5,files));
            % RT WM - RT OT
            summary_data{files,18} = summary_data{files,14} - summary_data{files,13};
            % RT PM - RT OT
            summary_data{files,19} = summary_data{files,15} - summary_data{files,13};
            
        case 'all_ig_miss'
            % Convert all zero values to NaN
            temp_latencies = squeeze(latencies(:,:,files));
            temp_latencies(temp_latencies==0) = NaN;
            % RT BL
            summary_data{files,12} = mean(temp_latencies(:,2),'omitnan');
            % RT OT
            summary_data{files,13} = mean(temp_latencies(:,3),'omitnan');
            % RT WM
            summary_data{files,14} = mean(temp_latencies(:,4),'omitnan');
            % RT PM
            summary_data{files,15} = mean(temp_latencies(:,5),'omitnan');
            % RT PM in PM
            summary_data{files,16} = mean(temp_latencies(PM_trial_locations,5),'omitnan');
            % RT OT in PM
            tmp = zeros(40,1);
            tmp(PM_trial_locations) = 1;
            summary_data{files,17} = mean(temp_latencies(~tmp,5),'omitnan');
            % RT WM - RT OT
            summary_data{files,18} = summary_data{files,14} - summary_data{files,13};
            % RT PM - RT OT
            summary_data{files,19} = summary_data{files,15} - summary_data{files,13};
            
        case 'correct'
            % Only consider correct values
            % RT BL
            summary_data{files,12} = mean(latencies(scores(:,2,files)==1,2,files));
            % RT OT
            summary_data{files,13} = mean(latencies(scores(:,3,files)==1,3,files));
            % RT WM
            summary_data{files,14} = mean(latencies(scores(:,4,files)==1,4,files));
            % RT PM
            summary_data{files,15} = mean(latencies(scores(:,5,files)==1,5,files));
            % RT PM in PM
            summary_data{files,16} = mean(latencies(scores(PM_trial_locations,5,files)==1,5,files));
            % RT OT in PM
            tmp = zeros(40,1);
            tmp(PM_trial_locations) = 1;
            summary_data{files,17} = mean(latencies(scores(~tmp,5,files)==1,5,files));
            % RT WM - RT OT
            summary_data{files,18} = summary_data{files,14} - summary_data{files,13};
            % RT PM - RT OT
            summary_data{files,19} = summary_data{files,15} - summary_data{files,13};
    end
    
    % Missed trials
    % -------------
    % BL
    summary_data{files,20} = length(nonzeros(isnan(data.probe_RESP(strcmpi(...
                                    data.BlockCondition, 'BLTask')))));
    % Correct for trials with RT > 0 and < = 200 ms
    if summary_data{files,24} > 0
        summary_data{files,20} = summary_data{files,20}-summary_data{files,24};
    end
    
    % OT
    summary_data{files,21} = length(nonzeros(isnan(data.probe_RESP(strcmpi(...
                                    data.BlockCondition, 'OTTask')))));
    % Correct for trials with RT > 0 and < = 200 ms
    if summary_data{files,25} > 0
        summary_data{files,21} = summary_data{files,21}-summary_data{files,25};
    end
    
    % WM
    summary_data{files,22} = length(nonzeros(isnan(data.probe_RESP(strcmpi(...
                                    data.BlockCondition, 'WMTask')))));
    % Correct for trials with RT > 0 and < = 200 ms
    if summary_data{files,26} > 0
        summary_data{files,22} = summary_data{files,22}-summary_data{files,26};
    end
    
    % PM
    summary_data{files,23} = length(nonzeros(isnan(data.probe_RESP(strcmpi(...
                                    data.BlockCondition, 'PMTask')))));
    % Correct for trials with RT > 0 and < = 200 ms
    if summary_data{files,27} > 0
        summary_data{files,23} = summary_data{files,23}-summary_data{files,27};
    end

    % Number of trials leading to negative values
    % -------------------------------------------
    % WM-OT
    summary_data{files,28} = length(nonzeros(latencies(:,4,files) - ...
                                    latencies(:,3,files) < 0));
    % PM-OT
    summary_data{files,29} = length(nonzeros(latencies(:,5,files) - ...
                                    latencies(:,3,files) < 0));

    % Other details
    % -------------
    summary_data{files,30} = score_type;
    summary_data{files,31} = latency_type;
    
    %% Compiling information for task_load variable
    % Fill in trial numbers
    task_load(:,1,files)    = 1:max_trials;

    % Working memory load per trial
    % -----------------------------
    % Get all numbers 
    all_numbers = data.number(strcmpi(data.BlockCondition, 'WMTask'));
    % Assign to task_load
    task_load(:,2,files) = [cumsum(all_numbers(1:10));  ...
                            cumsum(all_numbers(11:20)); ...
                            cumsum(all_numbers(21:30)); ...
                            cumsum(all_numbers(31:40));];
    
    % Prospective memory load per trial
    % ---------------------------------
    % Get all numbers and restart locations
    all_numbers = data.number(strcmpi(data.BlockCondition, 'PMTask'));
    tmp = 1:max_trials;
    restart_locations = tmp(strcmpi(data.bckg(...
                        strcmpi(data.BlockCondition, 'PMTask')), 'Restart'));
    
    % Get cumulative sum
    cum_pm_sum = zeros(max_trials,1);
    counter    = 1;
    for pm_trials = 1:length(restart_locations)
        cum_pm_sum(counter:restart_locations(pm_trials)) = ...
            cumsum(all_numbers(counter:restart_locations(pm_trials)));
        counter = restart_locations(pm_trials)+1;
        if counter == max_trials
            cum_pm_sum(counter) = all_numbers(counter);
        end
    end
    
    % Assign to task_load
    task_load(:,3,files) = [cum_pm_sum(1:10);  ...
                            cum_pm_sum(11:20); ...
                            cum_pm_sum(21:30); ...
                            cum_pm_sum(31:40);];

end
%% Convert to table
summary_data = cell2table(summary_data,'VariableNames', column_names);

%% Turn warnings back on
if tmp > 2016
    warning('ON', 'MATLAB:table:ModifiedAndSavedVarnames');
else
    warning('ON', 'MATLAB:table:ModifiedVarnames');
end