function [conditions, TR] = get_fmri_task_design_conn(task_name, num_subjs)
% Function that returns fMRI experiment task design for Conn
%% Inputs:
% task_name:  can be any of the following (case insensitive):
%             	* vftclassic   verbal fluency task
%             	* vftmodern    modified VFT with hallucination query
%             	* pm            prospective memory task
%             	* hamths       hallucination attention modulation task (HS)
%               * hamtsz       hallucination attention modulation task (SZ)
%               * rest          resting state
% 
% num_subjs:  number of subjects for which design has to be returned
% 
%% Outputs:
% conditions: structure containing the requested task design
%             	structure fields:
%               	* names:      names of the condition
%                   * onsets:     onset of the condition in seconds
%                   * durations:  duration of the condition in seconds
% 
% TR:         repetition time
% 
%% Author(s):
% Parekh, Pravesh
% March 30, 2018
% MBIAL

%% Check inputs and set defaults
% Check if task_name is provided
if ~exist('task_name', 'var')
    error('Task name needs to be provided');
end

% Check validity of task_name
if ~ismember(task_name, ...
        {'vftclassic', 'vftmodern', 'pm', 'hamths', 'hamtsz', 'rest'})
    error('Incorrect task_name provided');
end

% Check if number of subjects is provided
if ~exist('num_subjs', 'var')
    error('Number of subjects needs to be provided');
end

%% Check task_name and create design accordingly
switch(task_name)
    
    % Task: Verbal Fluency Task (Classic)
    case 'vftclassic'
        
        % Assign TR
        TR = 4;
        
        % Initialize conditions
        conditions.names        = {'Instruction', 'WR', 'WG'};
        conditions.onsets       = cell(3,num_subjs,1);
        conditions.durations    = cell(3,num_subjs,1);
        
        % Loop over subjects and populate onsets and durations
        for subj = 1:num_subjs
            
            % Specifying onsets
            conditions.onsets{1}{subj}{1} = [0 36 72 108 144 180 216 252 288 324 360 396];
            conditions.onsets{2}{subj}{1} = [8 80 152 224 296 368];
            conditions.onsets{3}{subj}{1} = [44 116 188 260 332 404];
            
            % Specifying durations
            conditions.durations{1}{subj}{1} =  8;
            conditions.durations{2}{subj}{1} = 28;
            conditions.durations{3}{subj}{1} = 28;
        end
        
    % Task: Verbal Fluency Task (Modern)    
    case 'vftmodern'
        
        % Assign TR
        TR = 4;
        
        % Initialize conditions
        conditions.names        = {'Instruction', 'WR', 'WG', 'Query'};
        conditions.onsets       = cell(4,num_subjs,1);
        conditions.durations    = cell(4,num_subjs,1);
        
        % Loop over subjects and populate onsets and durations
        for subj = 1:num_subjs
            
            % Specifying onsets
            conditions.onsets{1}{subj}{1} = [0 44 88 132 176 220 264 308 352 396 440 484];
            conditions.onsets{2}{subj}{1} = [8 96 184 272 360 448];
            conditions.onsets{3}{subj}{1} = [52 140 228 316 404 492];
            conditions.onsets{4}{subj}{1} = [36 80 124 168 212 256 300 344 388 432 476 520];
            
            % Specifying durations
            conditions.durations{1}{subj}{1} =  8;
            conditions.durations{2}{subj}{1} = 28;
            conditions.durations{3}{subj}{1} = 28;
            conditions.durations{4}{subj}{1} =  8;
        end
        
    % Task: Prospective Memory    
    case 'pm'
        
        % Assign TR
        TR = 3;
        
        % Initialize conditions
        conditions.names        = {'Instruction', 'BL', 'OT', 'WM', 'PM', 'Query'};
        conditions.onsets       = cell(6,num_subjs,1);
        conditions.durations    = cell(6,num_subjs,1);
        
        % Loop over subjects and populate onsets and durations
        for subj = 1:num_subjs
            
            % Specifying onsets
            conditions.onsets{1}{subj}{1} = [0 39 78 126 165 204 243 291 330 378 417 456 495 534 573 612];
            conditions.onsets{2}{subj}{1} = [48 174 465 582];
            conditions.onsets{3}{subj}{1} = [9 300 387 504];
            conditions.onsets{4}{subj}{1} = [87 252 339 621];
            conditions.onsets{5}{subj}{1} = [135 213 426 543];
            conditions.onsets{6}{subj}{1} = [117 282 369 651];
            
            % Specifying durations
            conditions.durations{1}{subj}{1} =  9;
            conditions.durations{2}{subj}{1} = 30;
            conditions.durations{3}{subj}{1} = 30;
            conditions.durations{4}{subj}{1} = 30;
            conditions.durations{5}{subj}{1} = 30;
            conditions.durations{6}{subj}{1} =  9;
        end
        
    % Task: Hallucination Attention Modulation Task (Healthy Subjects)
    case 'hamths'
        
        % Assign TR
        TR = 3;
        
        % Initialize conditions
        conditions.names        = {'Instruction', 'FA', 'VA', 'Query'};
        conditions.onsets       = cell(4,num_subjs,1);
        conditions.durations    = cell(4,num_subjs,1);
        
        % Loop over subjects and populate onsets and durations
        for subj = 1:num_subjs
            
            % Specifying onsets
            conditions.onsets{1}{subj}{1} = [0 42 84 126 168 210 252 294 336 378];
            conditions.onsets{2}{subj}{1} = [9 93 177 261 345];
            conditions.onsets{3}{subj}{1} = [51 135 219 303 387];
            conditions.onsets{4}{subj}{1} = [33 75 117 159 201 243 285 327 369 411];
            
            % Specifying durations
            conditions.durations{1}{subj}{1} =  9;
            conditions.durations{2}{subj}{1} = 24;
            conditions.durations{3}{subj}{1} = 24;
            conditions.durations{4}{subj}{1} =  9;
        end
        
    % Task: Hallucination Attention Modulation Task (Schizophrenia)
    case 'hamtsz'
        
        % Assign TR
        TR = 3;
        
        % Initialize conditions
        conditions.names        = {'Instruction', 'FA', 'VA', 'HA', 'Query'};
        conditions.onsets       = cell(5,num_subjs,1);
        conditions.durations    = cell(5,num_subjs,1);
        
        % Loop over subjects and populate onsets and durations
        for subj = 1:num_subjs
            
            % Specifying onsets
            conditions.onsets{1}{subj}{1} = [0 42 84 126 168 210 252 294 336 378 420 462 504 546 588];
            conditions.onsets{2}{subj}{1} = [9 135 261 387 513];
            conditions.onsets{3}{subj}{1} = [93 219 345 471 597];
            conditions.onsets{4}{subj}{1} = [51 177 303 429 555];
            conditions.onsets{5}{subj}{1} = [33 75 117 159 201 243 285 327 369 411 453 495 537 579 621];

            % Specifying durations
            conditions.durations{1}{subj}{1} =  9;
            conditions.durations{2}{subj}{1} = 24;
            conditions.durations{3}{subj}{1} = 24;
            conditions.durations{4}{subj}{1} = 24;
            conditions.durations{5}{subj}{1} =  9;
        end
        
    % Task: Resting State
    case 'rest'
        
        % Assign TR
        TR = 3;
        
        % Initialize conditions
        conditions.names        = {'rest'};
        conditions.onsets       = cell(1,num_subjs,1);
        conditions.durations    = cell(1,num_subjs,1);
        
        % Loop over subjects and populate onsets and durations
        for subj = 1:num_subjs
            
            % Specifying onsets
            conditions.onsets{1}{subj}{1} = 0;
            
            % Specifying durations
            conditions.durations{1}{subj}{1} = inf;
        end
end