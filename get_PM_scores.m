function [PM_scores, PM_latencies] = get_PM_scores(filename, show_results)
% Function to read an exported (in Excel format) edat text file and compute
% performance scores and latencies for PM task
%% Inputs:
% filename:             cell containing rows of name(s) of text file(s)
%                       (previously exported in Excel format from
%                       E-DataAid)
% show_results:         whether to show results on the screen (1/0)
% 
%% Outputs:
% PM_scores:            table containing behavioural performance where each
%                       row has data for a particular subject (see Notes)
% PM_latencies:         2D/3D matrix with columns having latencies and the
%                       third dimension indexing the filename (see Notes)
% 
% If show_results == 1, results are also displayed on the screen; latency
% results are not displayed to prevent clutter
% 
%% Notes:
% PM scores and PM latency values are organized in columns. The following
% is the order of columns for scores:
% file_name:            file name(s)
% BL_Score:             baseline condition score
% OT_Score:             ongoing condition score
% WM_Score:             working memory condition score
% PM_Score:             prospective memory condition score
% OT_in_PM_Score:       ongoing task in the PM condition score
% WM_Query_Score:       score for query slide (working memory condition)
% 
% Latency is the reaction time reported by E-Prime. The following is the
% order of columns for latency variable:
% BL_latencies:         baseline condition reaction times
% OT_latencies:         ongoing condition reaction times
% WM_latencies:         working memmory condition reaction times
% PM_latencies:         prospective memory condition reaction times
% OT_in_PM_latencies:   ongoing task in PM ocndition reaction times
% 
% OT_in_PM_latencies is padded with NaNs towards the end
% 
% MATLAB table loading warnings about variablenames are turned off 
% 
%% Default:
% show_results: 1
% 
%% Author(s):
% Parekh, Pravesh
% May 29, 2018
% MBIAL

%% Validate inputs and assign default
if ~exist('filename', 'var')
    error('At least one file name should be provided');
else
    % Get number of files
    num_files = size(filename, 1);
end

if ~exist('show_results', 'var')
    show_results = 1;
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

%% Work on each file

% Initialize
PM_scores       = cell(num_files,7);
PM_scores_names = {'file_name', 'BL_Score', 'OT_Score', 'WM_Score', ...
                   'PM_Score', 'OT_in_PM_Score', 'WM_Query_Score'};
PM_latencies    = zeros(40, 5, num_files);
               
for files = 1:num_files
    
    % Read file as a table
    data = readtable(filename{files});
    
    % Decide if data is Philips Ingenia or Siemens Skyra
    % If year >= 2017, Philips Ingenia ; else Siemens Skyra
    file_year = str2double(datestr(data.SessionDate(1), 10));
    if file_year >= 2017
        philips = 1;
    else
        philips = 0;
    end
    
    % Decide if PM error in Block 4 1st PM trial needs to be corrected for;
    % If the SessionDate is before 30-Apr-2018, correct for it
    check_date = datetime('30-Apr-2018');
    sess_date  = datetime(datestr(data.SessionDate{1}));
    if sess_date <= check_date
        correct = 1;
    else
        correct = 0;
    end
    
    %% Recording filename
    PM_scores{files, 1} = filename{files};
    
    %% Working on BL condition
    trial_items = strcmpi(data.BlockCondition, 'BLtask');
    trial_resp  = data.probe_RESP(trial_items);
    
    % Convert NaN values to zeros
    trial_resp(isnan(trial_resp)) = 0;
    
    % If response was given, it is correct; score it
    PM_scores{files, 2} = length(nonzeros(trial_resp));
    
    % Get latency values
    PM_latencies(:, 1, files) = data.probe_RT(trial_items);
    
    %% Working on OT condition
    trial_items = strcmpi(data.BlockCondition, 'OTtask');
    trial_resp  = data.probe_RESP(trial_items);
    
    % Convert NaN values to zeros
    trial_resp(isnan(trial_resp)) = 0;
    
    % Get correct responses
    corr_resp = data.probe_CRESP(trial_items);
    
    % Check if CRESP and RESP match and score
    PM_scores{files, 3} = length(nonzeros(corr_resp == trial_resp));
    
    % Get latency values
    PM_latencies(:, 2, files) = data.probe_RT(trial_items);
    
    %% Working on WM condition
    trial_items = strcmpi(data.BlockCondition, 'WMtask');
    
    % Remove the query slide entries
    trial_items(~isnan(data.WMQList)) = [];
    
    trial_resp  = data.probe_RESP(trial_items);
    
    % Convert NaN values to zeros
    trial_resp(isnan(trial_resp)) = 0;
    
    % Get correct responses
    corr_resp = data.probe_CRESP(trial_items);
    
    % Check if CRESP and RESP match and score
    PM_scores{files, 4} = length(nonzeros(corr_resp == trial_resp));
    
    % Get latency values
    PM_latencies(:, 3, files) = data.probe_RT(trial_items);
    
    %% Working on PM condition
    trial_items = strcmpi(data.BlockCondition, 'PMtask');
    trial_resp  = data.probe_RESP(trial_items);
    
    % Convert NaN values to zeros
    trial_resp(isnan(trial_resp)) = 0;
    
    % Get correct responses
    corr_resp = data.probe_CRESP(trial_items);
    
    % Generate warning if any CRESP value is 1; this is relevant in case
    % there was any experiment version on Siemens Skyra that had the first
    % button as a response option
    if ~isempty(nonzeros(corr_resp == 1))
        warning('CRESP variable has response as 1; please check!');
    end
    
    % Apply correction, if needed
    if correct && philips
        % Change the correct response for Block 4, PM condition, 1st PM
        % trial i.e. Block 4, PM condition, trial number 2: from '8' to '9'
        % i.e. left button (overall trial number 32)
        corr_resp(32) = 9;
    else
        if correct && ~philips
            % Change the correct response for Block 4, PM condition, 1st PM
            % trial i.e. Block 4, PM condition, trial number 2: from '2' to
            % '1' i.e. left button (overall trial number 32)
            corr_resp(32) = 1;
        end
    end
    
    % Check if CRESP and RESP match and score
    PM_scores{files, 5} = length(nonzeros(corr_resp == trial_resp));
    
    % Get latency values
    PM_latencies(:, 4, files) = data.probe_RT(trial_items);
    
    %% Working on OT in PM condition
    % PM scores have already been retrieved above and correction applied,
    % if needed; check performance for trials where the CRESP is not the
    % middle button
    if philips
        loc = corr_resp ~= 8;
    else
        loc = corr_resp ~= 3;
    end
    
    % Subset trial_resp, corr_resp, and PM_latencies
    trial_resp(~loc)  = [];
    corr_resp(~loc)   = [];
    tmp_latency       = PM_latencies(:,4,files);
    tmp_latency(~loc) = [];
    
    % Check if CRESP and RESP match and score
    PM_scores{files, 6} = length(nonzeros(corr_resp == trial_resp));
    
    % Get latency values
    PM_latencies(:, 5, files) = [tmp_latency; NaN(40 - length(tmp_latency),1)];
    
    %% Working on WM Query socre
    % If data is Philips and before 30th May 2018, correct WM Query CRESP;
    % the CRESP were incorrectly specified for Philips Current Design
    % response pads for the first three occurrences; the last query slide
    % response was correct because the correct response is the middle
    % button. 
    % Block 1 Query correct response: left button   (9)
    % Block 2 Query correct response: right button  (7)
    % Block 3 Query correct response: left button   (9)
    % Block 4 Query correct response: middle button (8)
    
    % Get all WM Query correct responses 
    loc       = ~isnan(data.TotalQ_CRESP);
    corr_resp = data.TotalQ_CRESP(loc);
    
    % Figure out if correction needs to be made
    check_date = datetime('30-May-2018');
    if sess_date <= check_date
        corr_resp(1) = 9;
        corr_resp(2) = 7;
        corr_resp(3) = 9;
    end
    
    % Get responses for query slide and convert NaNs to zeros
    trial_resp = data.TotalQ_RESP(loc);
    trial_resp(isnan(trial_resp)) = 0;
    
    % Check if CRESP and RESP match and score
    PM_scores{files, 7} = length(nonzeros(corr_resp == trial_resp));
end

%% Convert results to table
PM_scores = cell2table(PM_scores, 'VariableNames', PM_scores_names);

%% Display results, if required
if show_results
    disp(PM_scores);
end

%% Turn warnings back on
if tmp > 2016
    warning('ON', 'MATLAB:table:ModifiedAndSavedVarnames');
else
    warning('ON', 'MATLAB:table:ModifiedVarnames');
end