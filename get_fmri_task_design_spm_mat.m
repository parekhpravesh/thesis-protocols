function get_fmri_task_design_spm_mat(task_name, units, save_dir)
% Function to output task design as a mat file which can be used for first
% level specification
%% Inputs:
% task_name:  can be any of the following (case insensitive):
%             	* vftclassic   verbal fluency task
%             	* vftmodern    modified VFT with hallucination query
%             	* pm           prospective memory task
%             	* hamths       hallucination attention modulation task (HS)
%               * hamtsz       hallucination attention modulation task (SZ)
%
% units:      can be either (case insensitive)
%               * scans
%               * seconds
%
% save_dir:   location where the task design mat file is saved
% 
%% Output:
% A mat file is saved in save_dir having names, onsets, durations, and tmod
% variables. This can be input as multiple conditions when specifying first
% level analysis in SPM. File is named task_design-<task_name>_<units>.mat
%
%% Default:
% units:      seconds
% save_dir:   pwd
%% Notes:
% See spm_fMRI_design, spm_get_ons, spm_hrf, spm_get_bf, spm_Volterra,
% spm_fmri_concatenate, and spm_spm
%
%% Author(s):
% Parekh, Pravesh
% October 22, 2018
% MBIAL

%% Check inputs and set defaults
% Check if task_name is provided
if ~exist('task_name', 'var')
    error('Task name should be provided');
else
    % Check validity of task_name
    task_name = lower(task_name);
    if ~ismember(task_name, {'vftclassic', 'vftmodern', 'pm', 'hamths', 'hamtsz'})
        error('Incorrect task_name provided');
    end
end

% Check if units is provided; otherwise default to seconds
if ~exist('units', 'var')
    units = 'seconds';
else
    % Check if correct units is provided
    if ~strcmpi(units, 'scans') && ~strcmpi(units, 'seconds')
        error('Incorrect units provided');
    end
end

% Check if save_dir is provided; otherwise default to pwd
if ~exist('save_dir', 'var')
    save_dir = pwd;
else
    % Create save_dir if it doesn't exist
    if ~exist(save_dir, 'dir')
        mkdir(save_dir);
    end
end

%% Check task type and create design
switch(task_name)
    
    % Task: VFT Classic
    case 'vftclassic'
        
        % Condition names
        names    = cell(1,3);
        names{1} = 'Instructions';
        names{2} = 'WR';
        names{3} = 'WG';
        
        % Condition onsets and durations
        onsets    = cell(1,3);
        durations = cell(1,3);
        if strcmpi(units, 'scans')
            onsets{1} = [0  9  18 27 36 45 54 63 72 81 90 99];
            onsets{2} = [2  20 38 56 74 92];
            onsets{3} = [11 29 47 65 83 101];
            
            durations{1} = 2;
            durations{2} = 7;
            durations{3} = 7;
        else
            onsets{1} = [0  36  72  108 144 180 216 252 288 324 360 396];
            onsets{2} = [8  80  152 224 296 368];
            onsets{3} = [44 116 188 260 332 404];
            
            durations{1} =  8;
            durations{2} = 28;
            durations{3} = 28;
        end
        
        % Time modulation
        tmod = cell(1,3);
        tmod{1} = 0;
        tmod{2} = 0;
        tmod{3} = 0;
        
    case 'vftmodern'
        
        % Condition names
        names = cell(1,4);
        names{1} = 'Instructions';
        names{2} = 'WR';
        names{3} = 'WG';
        names{4} = 'Query';
        
        % Condition onsets and durations
        onsets    = cell(1,4);
        durations = cell(1,4);
        if strcmpi(units, 'scans')
            onsets{1} = [0  11 22 33 44  55  66 77 88 99  110 121];
            onsets{2} = [2  24 46 68 90  112];
            onsets{3} = [13 35 57 79 101 123];
            onsets{4} = [9  20 31 42 53  64  75 86 97 108 119 130];
            
            durations{1} = 2;
            durations{2} = 7;
            durations{3} = 7;
            durations{4} = 2;
        else
            onsets{1} = [0  44  88  132 176 220 264 308 352 396 440 484];
            onsets{2} = [8  96  184 272 360 448];
            onsets{3} = [52 140 228 316 404 492];
            onsets{4} = [36 80  124 168 212 256 300 344 388 432 476 520];
            
            durations{1} =  8;
            durations{2} = 28;
            durations{3} = 28;
            durations{4} =  8;
        end
        
        % Time modulation
        tmod = cell(1,4);
        tmod{1} = 0;
        tmod{2} = 0;
        tmod{3} = 0;
        tmod{4} = 0;
        
    case 'pm'
        
        % Condition names
        names = cell(1,6);
        names{1} = 'Instruction';
        names{2} = 'BL';
        names{3} = 'OT';
        names{4} = 'WM';
        names{5} = 'PM';
        names{6} = 'Query';
        
        % Condition onsets and durations
        onsets    = cell(1,6);
        durations = cell(1,6);
        if strcmpi(units, 'scans')
           onsets{1} = [0  13  26  42 55 68 81 97 110 126 139 152 165 178 191 204];
           onsets{2} = [16 58  155 194];
           onsets{3} = [3  100 129 168];
           onsets{4} = [29 84  113 207];
           onsets{5} = [45 71  142 181];
           onsets{6} = [39 94  123 217];
           
           durations{1} =  3;
           durations{2} = 10;
           durations{3} = 10;
           durations{4} = 10;
           durations{5} = 10;
           durations{6} =  3;
       else
           onsets{1} = [0   39  78  126 165 204 243  291 330 378  417 456 495 534 573 612];
           onsets{2} = [48  174 465 582];
           onsets{3} = [9   300 387 504];
           onsets{4} = [87  252 339 621];
           onsets{5} = [135 213 426 543];
           onsets{6} = [117 282 369 651];
           
           durations{1} =  9;
           durations{2} = 30;
           durations{3} = 30;
           durations{4} = 30;
           durations{5} = 30;
           durations{6} =  9;
       end
        
       % Time modulation
        tmod = cell(1,6);
        tmod{1} = 0;
        tmod{2} = 0;
        tmod{3} = 0;
        tmod{4} = 0;
        tmod{5} = 0;
        tmod{6} = 0;
        
    case 'hamths'
        
        % Condition names
        names = cell(1,4);
        names{1} = 'Instruction';
        names{2} = 'FA';
        names{3} = 'VA';
        names{4} = 'Query';
        
        % Condition onsets and durations
        onsets    = cell(1,4);
        durations = cell(1,4);
        if strcmpi(units, 'scans')
            onsets{1} = [0  14 28 42  56 70 84 98 112 126];
            onsets{2} = [3  31 59 87  115];
            onsets{3} = [17 45 73 101 129];
            onsets{4} = [11 25 39 53  67 81 95 109 123 137];
            
            durations{1} = 3;
            durations{2} = 8;
            durations{3} = 8;
            durations{4} = 3;
        else
            onsets{1} = [0  42  84  126 168 210 252 294 336 378];
            onsets{2} = [9  93  177 261 345];
            onsets{3} = [51 135 219 303 387];
            onsets{4} = [33 75  117 159 201 243 285 327 369 411];
            
            durations{1} = 9;
            durations{2} = 24;
            durations{3} = 24;
            durations{4} = 9;
        end
        
        % Time modulation
        tmod = cell(1,4);
        tmod{1} = 0;
        tmod{2} = 0;
        tmod{3} = 0;
        tmod{4} = 0;
        
    case 'hamtsz'
        
        % Condition names
        names = cell(1,5);
        names{1} = 'Instruction';
        names{2} = 'FA';
        names{3} = 'VA';
        names{4} = 'HA';
        names{5} = 'Query';
        
        % Condition onsets and durations
        onsets    = cell(1,5);
        durations = cell(1,5);
        if strcmpi(units, 'scans')
            onsets{1} = [0  14 28  42  56 70 84 98 112 126 140 154 168 182 196];
            onsets{2} = [3  45 87  129 171];
            onsets{3} = [31 73 115 157 199];
            onsets{4} = [17 59 101 143 185];
            onsets{5} = [11 25 39  53  67 81 95 109 123 137 151 165 179 193 207];
            
            durations{1} = 3;
            durations{2} = 8;
            durations{3} = 8;
            durations{4} = 8;
            durations{5} = 3;
        else
            onsets{1} = [0  42  84  126 168 210 252 294 336 378 420 462 504 546 588];
            onsets{2} = [9  135 261 387 513];
            onsets{3} = [31 73  115 157 199];
            onsets{4} = [51 177 303 429 555];
            onsets{5} = [33 75  117 159 201 243 285 327 369 411 453 495 537 579 621];
            
            durations{1} = 9;
            durations{2} = 24;
            durations{3} = 24;
            durations{4} = 24;
            durations{5} = 9;
        end
        
        % Time modulation
        tmod = cell(1,5);
        tmod{1} = 0;
        tmod{2} = 0;
        tmod{3} = 0;
        tmod{4} = 0;
        tmod{5} = 0;
end

%% Save variable
save_name = fullfile(save_dir, ['task-design_', task_name, '_', units, '.mat']);
save(save_name, 'names', 'onsets', 'durations', 'tmod');