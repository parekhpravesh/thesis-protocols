function [summary_data, scores, latencies, task_load, scores_desc, ...
          latencies_desc, task_load_desc] = get_PM_scores(filename, latency_type)
% Function to read an exported (in Excel format) edat text file and compute
% performance scores and latencies for PM task
%% Inputs:
% filename:                 cell containing rows of name(s)/full paths of
%                           text file(s) which were previously exported in
%                           Excel format from E-DataAid
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
% A csv file named summary_PM_DDMMMYYYY is written in the pwd containing
% summary_data; a mat file named behavioural_data_PM_DDMMMYYYY is written
% in the pwd containing all the variables including input variables
% (pwd = present working directory)
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
% 02) score_BL:             BL condition performance
% 03) score_OT:             OT condition performance
% 04) score_WM:             WM condition performance
% 05) score_PM:             PM condition performance (overall)
% 06) score_PM_in_PM:       PM performance in PM condition (precise)
% 07) score_PM_in_PM_Lib:   PM performance in PM condition (liberal)
% 08) score_OT_in_PM:       OT performance in PM condition
% 09) score_WM_Query:       WM condition query slide performance
% 10) prnct_BL:             percentage of trials correct in BL condition
% 11) prnct_OT:             percentage of trials correct in OT condition
% 12) prnct_WM:             percentage of trials correct in WM condition
% 13) prnct_PM:             percentage of trials correct in PM condition
% 14) prnct_PM_in_PM:       percentage of PM trials correct in PM condition (precise)
% 15) prnct_PM_in_PM_Lib:   percentage of PM trials correct in PM condition (liberal)
% 16) prnct_OT_in_PM:       percentage of OT trials correct in PM condition
% 17) prnct_WM_Query:       percentage of WM query slides correct
% 18) RT_BL:                mean BL condition latency
% 19) RT_OT:                mean OT condition latency
% 20) RT_WM:                mean WM condition latency
% 21) RT_PM:                mean PM condition latency (overall)
% 22) RT_PM_in_PM:          mean PM condition latency (PM trials only)
% 23) RT_OT_in_PM:          mean PM condition latency (OT trials only)
% 24) Missed_BL:            number of trials missed in BL condition
% 25) Missed_OT:            number of trials missed in OT condition
% 26) Missed_WM:            number of trials missed in WM condition
% 27) Missed_PM:            number of trials missed in PM condition
% 28) BL_lt200ms:           number of BL trials with <= 200 ms latency 
% 29) OT_lt200ms:           number of OT trials with <= 200 ms latency
% 30) WM_lt200ms:           number of WM trials with <= 200 ms latency
% 31) PM_lt200ms:           number of PM trials with <= 200 ms latency
% 32) num_PM_in_PM_trials:  number of PM trials in the PM condition
% 33) num_OT_in_PM_trials:  number of OT trials in the PM condition
% 34) score_OT_WM:          OT performance (OT condition) -
%                           WM performance (WM condition)
% 35) score_OT_PM:          OT performance (OT condition) - 
%                           PM performance (overall; OT+PM)
% 36) RT_WM_OT:             mean WM condition latency (WM condition) - 
%                           mean OT condition latency (OT condition)
% 37) RT_PM_OT:             mean PM condition latency (PM condition; OT+PM) -
%                           mean OT condition latency (OT condition)
% 38) WMOT_negative:        number of trials resulting in a negative value
%                           when subtracting WM and OT latencies
% 39) PMOT_negative:        number of trials resulting in a negative value
%                           when subtracting PM and OT latencies
% 40) latency_type:         method for calculating latency
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
% The task_load variable is a 2D or 3D matrix having WM/PM trial load and
% actual numbers shown to participant stored in the following columns:
% 01) trial_number:         trial number from 1:40
% 02) WM_load:              WM load for all fourty trials
% 03) PM_load:              PM load for all fourty trials
% 04) WM_numbers:           WM numbers for all fourty trials
% 05) PM_numbers:           PM numbers for all fourty trials
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

if ~exist('latency_type', 'var') || isempty(latency_type)
    latency_type = 'all_ig_miss';
else
    if ~ismember(latency_type, {'all', 'all_ig_miss', 'correct'})
        error(['Unknown latency_type provided: ', latency_type]);
    end
end

%% Get MATLAB version and suppress warning
matlab_ver = version('-release');
matlab_ver(end) = '';
matlab_ver = str2double(matlab_ver);
if matlab_ver > 2016
    warning('OFF', 'MATLAB:table:ModifiedAndSavedVarnames');
else
    warning('OFF', 'MATLAB:table:ModifiedVarnames');
end

%% Initialize
% Maximum trials per condition is 40, 10 per block
max_trials = 40;

% Initialize summary_data and its header
column_names = {'file_name', 'score_BL', 'score_OT', 'score_WM',            ...
                'score_PM', 'score_PM_in_PM', 'score_PM_in_PM_Lib',         ...
                'score_OT_in_PM', 'score_WM_Query', 'prnct_BL',             ...
                'prnct_OT', 'prnct_WM', 'prnct_PM', 'prnct_PM_in_PM',       ...
                'prnct_PM_in_PM_Lib', 'prnct_OT_in_PM', 'prnct_WM_Query',   ...
                'RT_BL', 'RT_OT', 'RT_WM', 'RT_PM', 'RT_PM_in_PM',          ...
                'RT_OT_in_PM', 'Missed_BL', 'Missed_OT', 'Missed_WM',       ...
                'Missed_PM', 'BL_lt200ms', 'OT_lt200ms', 'WM_lt200ms',      ...
                'PM_lt200ms', 'num_PM_in_PM_trials', 'num_OT_in_PM_trials', ...
                'score_OT_WM', 'score_OT_PM', 'RT_WM_OT', 'RT_PM_OT',       ...
                'WMOT_negative', 'PMOT_negative', 'latency_type'};
summary_data = cell(num_files, length(column_names));

% Initialize scores and its header
scores_desc = {'trial_number', 'score_BL', 'score_OT', 'score_WM', ...
               'score_PM', 'score_PM_in_PM', 'score_PM_in_PM_Lib', ...
               'score_OT_in_PM', 'score_WM_Query'};
scores      = zeros(max_trials, length(scores_desc), num_files);

% Initialize latencies and its header
latencies_desc = {'trial_number', 'RT_BL', 'RT_OT', 'RT_WM', 'RT_PM', ...
                  'RT_PM_in_PM', 'RT_OT_in_PM'};
latencies      = zeros(max_trials, length(latencies_desc), num_files);

% Initialize task_load and its header
task_load_desc = {'trial_number', 'WM_load', 'PM_load', ...
                  'WM_all_numbers', 'PM_all_numbers'};
task_load      = zeros(max_trials, length(task_load_desc), num_files);

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
    
    % WM condition query scores
    % -------------------------
    % For Siemens Skyra, return NaNs for WM Query as the response was vocal
    if ~philips
        scores(:,9,files) = NaN;
    else
        % Get all WM Query correct responses
        loc        = ~isnan(data.CorrectResponse);
        trial_resp = data.TotalQ_RESP(loc);
        corr_resp  = data.CorrectResponse(loc);
        % Apply WM correction, if needed
        if correct_WM
            corr_resp(1) = 9;
            corr_resp(2) = 7;
            corr_resp(3) = 9;
        end
        scores(trial_resp==corr_resp,9,files) = 1;
        % Pad remaining spots with NaN
        scores(5:end,9,files) = NaN;
    end
        
    % Determine if WM has 11 trials rather than 10; if yes, remove every 
    % 11th trial from only the WM condition (delete from data variable)
    % For Philips data, the Query slide is part of the WM block, 
    % leading to the 11th trial
    if philips
        loc_WM_Query = data.SubTrial==11;
        data(loc_WM_Query,:) = [];
    end
    
    % Number of trials with RT > 0 ms and <= 200 ms
    % ---------------------------------------------
    % BL
    summary_data{files,28} = length(nonzeros(data.probe_RT > 0 ...
                                   & data.probe_RT <= 200      ...
                                   & strcmpi(data.BlockCondition, 'BLTask')));
    % OT
    summary_data{files,29} = length(nonzeros(data.probe_RT > 0 ...
                                   & data.probe_RT <= 200      ...
                                   & strcmpi(data.BlockCondition, 'OTTask')));
    % WM
    summary_data{files,30} = length(nonzeros(data.probe_RT > 0 ...
                                   & data.probe_RT <= 200      ...
                                   & strcmpi(data.BlockCondition, 'WMTask')));
    % PM
    summary_data{files,31} = length(nonzeros(data.probe_RT > 0 ...
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
    % Additionally, check if PM trial is at the end of block
    % (PM_trial_locations == 40) in which case there is no post checking
    incorrect  = find(~PM_direct);
    tmp_post   = PM_trial_locations(~PM_direct);
    tmp_post(tmp_post==40) = [];
    post_resp  = trial_resp(tmp_post+1) == middle_button;
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
        
    %% Compiling information for summary variable 
    summary_data{files,1} = filename{files};
    
    % Compiling scores
    % ----------------
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
    
    % Compiling percentages
    % ---------------------
    % percentage BL score
    summary_data{files,10} = sum(scores(:,2,files),'omitnan')/max_trials*100;
    % percentage OT score
    summary_data{files,11} = sum(scores(:,3,files),'omitnan')/max_trials*100;
    % percentage WM score
    summary_data{files,12} = sum(scores(:,4,files),'omitnan')/max_trials*100;
    % percentage PM score
    summary_data{files,13} = sum(scores(:,5,files),'omitnan')/max_trials*100;
    % percentage PM in PM score (precise)
    summary_data{files,14} = sum(scores(:,6,files),'omitnan')/num_PM_trials*100;
    % percentage PM in PM score (liberal)
    summary_data{files,15} = sum(scores(:,7,files),'omitnan')/num_PM_trials*100;
    % percentage OT in PM score
    summary_data{files,16} = sum(scores(:,8,files),'omitnan')/num_OT_trials*100;
    % percentage WM query score
    summary_data{files,17} = sum(scores(:,9,files),'omitnan')/num_query_trials*100;
    
    % OT - WM score
    summary_data{files,34} = summary_data{files,3} - summary_data{files,4};
    % OT - PM score
    summary_data{files,35} = summary_data{files,3} - summary_data{files,5};
    
    % Compiling reaction time
    % -----------------------
    switch latency_type
        case 'all'
            % RT BL
            summary_data{files,18} = mean(latencies(:,2,files));
            % RT OT
            summary_data{files,19} = mean(latencies(:,3,files));
            % RT WM
            summary_data{files,20} = mean(latencies(:,4,files));
            % RT PM
            summary_data{files,21} = mean(latencies(:,5,files));
            % RT PM in PM
            summary_data{files,22} = mean(latencies(PM_trial_locations,5,files));
            % RT OT in PM
            tmp = zeros(40,1);
            tmp(PM_trial_locations) = 1;
            summary_data{files,23} = mean(latencies(~tmp,5,files));
            % RT WM - RT OT
            summary_data{files,36} = summary_data{files,20} - summary_data{files,19};
            % RT PM - RT OT
            summary_data{files,37} = summary_data{files,21} - summary_data{files,19};
            
        case 'all_ig_miss'
            % Convert all zero values to NaN
            temp_latencies = squeeze(latencies(:,:,files));
            temp_latencies(temp_latencies==0) = NaN;
            % RT BL
            summary_data{files,18} = mean(temp_latencies(:,2),'omitnan');
            % RT OT
            summary_data{files,19} = mean(temp_latencies(:,3),'omitnan');
            % RT WM
            summary_data{files,20} = mean(temp_latencies(:,4),'omitnan');
            % RT PM
            summary_data{files,21} = mean(temp_latencies(:,5),'omitnan');
            % RT PM in PM
            summary_data{files,22} = mean(temp_latencies(PM_trial_locations,5),'omitnan');
            % RT OT in PM
            tmp = zeros(40,1);
            tmp(PM_trial_locations) = 1;
            summary_data{files,23} = mean(temp_latencies(~tmp,5),'omitnan');
            % RT WM - RT OT
            summary_data{files,36} = summary_data{files,20} - summary_data{files,19};
            % RT PM - RT OT
            summary_data{files,37} = summary_data{files,21} - summary_data{files,19};
            
        case 'correct'
            % Only consider correct values
            % RT BL
            summary_data{files,18} = mean(latencies(scores(:,2,files)==1,2,files));
            % RT OT
            summary_data{files,19} = mean(latencies(scores(:,3,files)==1,3,files));
            % RT WM
            summary_data{files,20} = mean(latencies(scores(:,4,files)==1,4,files));
            % RT PM
            summary_data{files,21} = mean(latencies(scores(:,5,files)==1,5,files));
            % RT PM in PM
            summary_data{files,22} = mean(latencies(scores(PM_trial_locations,5,files)==1,5,files));
            % RT OT in PM
            tmp = zeros(40,1);
            tmp(PM_trial_locations) = 1;
            summary_data{files,23} = mean(latencies(scores(~tmp,5,files)==1,5,files));
            % RT WM - RT OT
            summary_data{files,36} = summary_data{files,20} - summary_data{files,19};
            % RT PM - RT OT
            summary_data{files,37} = summary_data{files,21} - summary_data{files,19};
    end
    
    % Missed trials
    % -------------
    % BL
    summary_data{files,24} = length(nonzeros(isnan(data.probe_RESP(strcmpi(...
                                    data.BlockCondition, 'BLTask')))));
    % Correct for trials with RT > 0 and < = 200 ms
    if summary_data{files,28} > 0
        summary_data{files,24} = summary_data{files,24}-summary_data{files,28};
    end
    
    % OT
    summary_data{files,25} = length(nonzeros(isnan(data.probe_RESP(strcmpi(...
                                    data.BlockCondition, 'OTTask')))));
    % Correct for trials with RT > 0 and < = 200 ms
    if summary_data{files,29} > 0
        summary_data{files,25} = summary_data{files,25}-summary_data{files,29};
    end
    
    % WM
    summary_data{files,26} = length(nonzeros(isnan(data.probe_RESP(strcmpi(...
                                    data.BlockCondition, 'WMTask')))));
    % Correct for trials with RT > 0 and < = 200 ms
    if summary_data{files,30} > 0
        summary_data{files,26} = summary_data{files,26}-summary_data{files,30};
    end
    
    % PM
    summary_data{files,27} = length(nonzeros(isnan(data.probe_RESP(strcmpi(...
                                    data.BlockCondition, 'PMTask')))));
    % Correct for trials with RT > 0 and < = 200 ms
    if summary_data{files,31} > 0
        summary_data{files,27} = summary_data{files,27}-summary_data{files,31};
    end
    
    % Number of trials in PM condition
    % --------------------------------
    summary_data{files,32} = num_PM_trials;
    summary_data{files,33} = num_OT_trials;

    % Number of trials leading to negative values
    % -------------------------------------------
    % WM-OT
    summary_data{files,38} = length(nonzeros(latencies(:,4,files) - ...
                                    latencies(:,3,files) < 0));
    % PM-OT
    summary_data{files,39} = length(nonzeros(latencies(:,5,files) - ...
                                    latencies(:,3,files) < 0));

    % Latency type
    % ------------
    summary_data{files,40} = latency_type;
    
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
    task_load(:,4,files) = all_numbers;
    
    % Prospective memory load per trial
    % ---------------------------------
    % Get all numbers and restart locations
    all_numbers = data.number(strcmpi(data.BlockCondition, 'PMTask'));
    tmp = 1:max_trials;
    restart_locations = tmp(strcmpi(data.bckg(...
                        strcmpi(data.BlockCondition, 'PMTask')), 'Restart'));
    restart_loc_block = [restart_locations(1:3);    ...
                         restart_locations(4:6)-10; ...
                         restart_locations(7:9)-20; ...
                         restart_locations(10:12)-30];
    all_nums_select   = [all_numbers(1:10)';  ...
                         all_numbers(11:20)'; ...
                         all_numbers(21:30)'; ...
                         all_numbers(31:40)'];

    % Get cumulative sum
    % 4 blocks, 3 PM trials per block, 10 trials per block overall
    cum_pm_sum = zeros(4,10);
    for blk = 1:4
        counter = 1;
        for pm_trials = 1:3
            cum_pm_sum(blk,counter:restart_loc_block(blk,pm_trials)) = ...
                cumsum(all_nums_select(blk,counter:restart_loc_block(blk,pm_trials)));
            counter = restart_loc_block(blk,pm_trials)+1;
            if pm_trials == 3 && restart_loc_block(blk,pm_trials) < 10
                cum_pm_sum(blk,restart_loc_block(blk,pm_trials)+1:end) = ...
                    cumsum(all_nums_select(blk,restart_loc_block(blk,pm_trials)+1:end));
            end
        end
    end
    tmp = cum_pm_sum';
    cum_pm_sum_all = tmp(:);
    
    % Assign to task_load
    task_load(:,3,files) = [cum_pm_sum_all(1:10);  ...
                            cum_pm_sum_all(11:20); ...
                            cum_pm_sum_all(21:30); ...
                            cum_pm_sum_all(31:40);];
    task_load(:,5,files) = all_numbers;

end
%% Convert to table
summary_data = cell2table(summary_data, 'VariableNames', column_names);

%% Write table as csv file
writetable(summary_data, ['summary_PM_', datestr(now, 'ddmmmyyyy'), '.csv']);

%% Save all variables
save(['behavioural_data_PM_', datestr(now, 'ddmmmyyyy'), '.mat'],       ...
     'filename', 'latency_type', 'summary_data', 'scores', 'latencies', ... 
     'task_load', 'scores_desc', 'latencies_desc', 'task_load_desc');

%% Turn warnings back on
if matlab_ver > 2016
    warning('ON', 'MATLAB:table:ModifiedAndSavedVarnames');
else
    warning('ON', 'MATLAB:table:ModifiedVarnames');
end