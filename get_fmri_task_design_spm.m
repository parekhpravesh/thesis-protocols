function design = get_fmri_task_design_spm(task_name, units)
% Function that returns fMRI experiment task design for SPM
%% Inputs:
% task_name:  can be any of the following (case insensitive):
%             	* vftclassic   verbal fluency task
%             	* vftmodern    modified VFT with hallucination query
%             	* pm            prospective memory task
%             	* hamths       hallucination attention modulation task (HS)
%               * hamtsz       hallucination attention modulation task (SZ)
%
% units:      can be either (case insensitive)
%               * scans
%               * seconds
%
%% Output:
% design:     structure containing the requested task design
%             	structure fields:
%               	* units:      units as input
%                   * RT:         repeat time (TR)
%                   * cond:       condition having following:
%                   	* name:       name of the condition
%                       * onset:      onset of the condition in units
%                       * duration:   duration of the condition in units
%                   * hpf:        twice the length of the block
%
%% Default(s):
% units:      seconds
%
%% Author(s):
% Parekh, Pravesh
% March 02, 2018
% MBIAL

%% Check inputs and set defaults
% Check if task_name is provided; if not, ask the user
if ~exist('task_name', 'var')
    error('Task name should be provided');
end

% Check validity of task_name
if ~ismember(task_name, ...
        {'vftclassic', 'vftmodern', 'pm', 'hamths', 'hamtsz'})
    error('Incorrect task_name provided');
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

%% Check task type and create design
switch(task_name)
    
    % Task: VFT Classic
    case 'vftclassic'
        design.units = units;
        design.RT    = 4;
        
        % Naming all conditions
        design.cond(1).name = 'Instruction';
        design.cond(2).name = 'WR';
        design.cond(3).name = 'WG';
        
        % Defining onset timing and duration in scans
        if strcmpi(units, 'scans')
            
            % Condition: Instruction
            design.cond(1).onset = [	 0
                                         9
                                        18
                                        27
                                        36
                                        45
                                        54
                                        63
                                        72
                                        81
                                        90
                                        99];
            design.cond(1).duration =	 2;
            
            % Condition: WR
            design.cond(2).onset = [     2
                                        20
                                        38
                                        56
                                        74
                                        92];
            design.cond(2).duration =    7;
            
            % Condition: WG
            design.cond(3).onset = [    11
                                        29
                                        47
                                        65
                                        83
                                       101];
            design.cond(3).duration =    7;

        % Defining onset timing and duration in seconds
        else
            
            % Condition: Instruction
            design.cond(1).onset = [     0
                                        36
                                        72
                                       108
                                       144
                                       180
                                       216
                                       252
                                       288
                                       324
                                       360
                                       396];
            design.cond(1).duration =    8;

            % Condition: WR
            design.cond(2).onset = [     8
                                        80
                                       152
                                       224
                                       296
                                       368];
            design.cond(2).duration =   28;
            
            % Condition: WG
            design.cond(3).onset = [    44
                                       116
                                       188
                                       260
                                       332
                                       404];
            design.cond(3).duration =   28;
        end    
       
        % Set high pass filter (seconds) = twice the total block length
        design.hpf = 144;
    
    % Task: VFT Modern
    case 'vftmodern'
        design.units = units;
        design.RT    = 4;
        
        % Naming all conditions
        design.cond(1).name = 'Instruction';
        design.cond(2).name = 'WR';
        design.cond(3).name = 'WG';
        design.cond(4).name = 'Query';
        
        % Defining onset timing and duration in scans
        if strcmpi(units, 'scans')
            
            % Condition: Instruction
            design.cond(1).onset = [     0
                                        11
                                        22
                                        33
                                        44
                                        55
                                        66
                                        77
                                        88
                                        99
                                       110
                                       121];
            design.cond(1).duration =    2;
            
            % Condition: WR
            design.cond(2).onset = [     2
                                        24
                                        46
                                        68
                                        90
                                       112];
            design.cond(2).duration =    7;
            
            % Condition: WG
            design.cond(3).onset = [    13
                                        35
                                        57
                                        79
                                       101
                                       123];
            design.cond(3).duration =    7;
            
            % Condition: Query
            design.cond(4).onset = [     9
                                        20
                                        31
                                        42
                                        53
                                        64
                                        75
                                        86
                                        97
                                       108
                                       119
                                       130];
            design.cond(4).duration =    2;
            
        % Defining onset timing and duration in seconds
        else
            
            % Condition: Instruction
            design.cond(1).onset = [     0
                                        44
                                        88
                                       132
                                       176
                                       220
                                       264
                                       308
                                       352
                                       396
                                       440
                                       484];
            design.cond(1).duration =    8;

            % Condition: WR
            design.cond(2).onset = [     8
                                        96
                                       184
                                       272
                                       360
                                       448];
            design.cond(2).duration =   28;
            
            % Condition: WG
            design.cond(3).onset = [    52
                                       140
                                       228
                                       316
                                       404
                                       492];
            design.cond(3).duration =   28;
            
            % Condition: Query
            design.cond(4).onset = [    36
                                        80
                                       124
                                       168
                                       212
                                       256
                                       300
                                       344
                                       388
                                       432
                                       476
                                       520];
            design.cond(4).duration =	 8;
        end
        
        % Set high pass filter (seconds) = twice the total block length
        design.hpf = 176;

    % Task: Prospective Memory    
    case 'pm'
        design.units = units;
        design.RT    = 3;
        
        % Naming all conditions
        design.cond(1).name = 'Instruction';
        design.cond(2).name = 'BL';
        design.cond(3).name = 'OT';
        design.cond(4).name = 'WM';
        design.cond(5).name = 'PM';
        design.cond(6).name = 'Query';
        
        % Defining onset timing and duration in scans
        if strcmpi(units, 'scans')
            
            % Condition: Instruction
            design.cond(1).onset = [     0
                                        13
                                        26
                                        42
                                        55
                                        68
                                        81
                                        97
                                       110
                                       126
                                       139
                                       152
                                       165
                                       178
                                       191
                                       204];
            design.cond(1).duration =    3;
            
            % Condition: Baseline (BL)
            design.cond(2).onset = [    16
                                        58
                                       155
                                       194];
            design.cond(2).duration =   10;
            
            % Condition: Ongoing (OT)
            design.cond(3).onset = [     3
                                       100
                                       129
                                       168];
            design.cond(3).duration =   10;
            
            % Condition: Working Memory (WM)
            design.cond(4).onset = [    29
                                        84
                                       113
                                       207];
            design.cond(4).duration =   10;
            
            % Condition: Prospective Memory (PM)
            design.cond(5).onset = [    45
                                        71
                                       142
                                       181];
            design.cond(5).duration =   10;
            
            % Condition: Query
            design.cond(6).onset = [    39
                                        94
                                       123
                                       217];
            design.cond(6).duration =    3;
            
        % Defining onset timing and duration in seconds
        else
            
            % Condition: Instruction
            design.cond(1).onset = [     0
                                        39
                                        78
                                       126
                                       165
                                       204
                                       243
                                       291
                                       330
                                       378
                                       417
                                       456
                                       495
                                       534
                                       573
                                       612];
            design.cond(1).duration =    9;
            
            % Condition: Baseline (BL)
            design.cond(2).onset = [    48
                                       174
                                       465
                                       582];
            design.cond(2).duration =   30;

            % Condition: Ongoing (OT)
            design.cond(3).onset = [     9
                                       300
                                       387
                                       504];
            design.cond(3).duration =   30;
            
            % Condition: Working Memory (WM)
            design.cond(4).onset = [    87
                                       252
                                       339
                                       621];
            design.cond(4).duration =   30;
            
            % Condition: Prospective Memory (PM)
            design.cond(5).onset = [   135
                                       213
                                       426
                                       543];
            design.cond(5).duration =   30;
            
            % Condition: Query
            design.cond(6).onset = [   117
                                       282
                                       369
                                       651];
            design.cond(6).duration =    9;
        end
        
        % Set high pass filter (seconds) = twice the total block length
        design.hpf = 330;
        
    % Task: Hallucination Attention Modulation Task (Healthy Subjects)    
    case 'hamths'
        design.units = units;
        design.RT    = 3;
        
        % Naming all conditions
        design.cond(1).name = 'Instruction';
        design.cond(2).name = 'FA';
        design.cond(3).name = 'VA';
        design.cond(4).name = 'Query';
        
        % Defining onset timing and duration in scans
        if strcmpi(units, 'scans')
            
            % Condition: Instruction
            design.cond(1).onset = [     0
                                        14
                                        28
                                        42
                                        56
                                        70
                                        84
                                        98
                                       112
                                       126];
            design.cond(1).duration =    3;
            
            % Condition: Free Attention (FA)
            design.cond(2).onset = [     3
                                        31
                                        59
                                        87
                                       115];
            design.cond(2).duration =    8;
            
            % Condition: Visual Attention (VA)
            design.cond(3).onset = [    17
                                        45
                                        73
                                       101
                                       129];
            design.cond(3).duration =    8;
            
            % Condition: Query
            design.cond(4).onset = [    11
                                        25
                                        39
                                        53
                                        67
                                        81
                                        95
                                       109
                                       123
                                       137];
            design.cond(4).duration =    3;

        % Defining onset timing and duration in seconds
        else
            
            % Condition: Instruction
            design.cond(1).onset = [     0
                                        42
                                        84
                                       126
                                       168
                                       210
                                       252
                                       294
                                       336
                                       378];
            design.cond(1).duration =    9;
            
            % Condition: Free Attention (FA)
            design.cond(2).onset = [     9
                                        93
                                       177
                                       261
                                       345];
            design.cond(2).duration =   24;
            
            % Condition: Visual Attention (VA)
            design.cond(3).onset = [    51
                                       135
                                       219
                                       303
                                       387];
            design.cond(3).duration =   24;
            
            % Condition: Query
            design.cond(4).onset = [    33
                                        75
                                       117
                                       159
                                       201
                                       243
                                       285
                                       327
                                       369
                                       411];
            design.cond(4).duration =    9;
        end
        
        % Set high pass filter (seconds) = twice the total block length
        design.hpf = 168;
        
    % Task: Hallucination Attention Modulation Task (Schizophrenia)    
    case 'hamtsz'
        design.units = units;
        design.RT    = 3;
        
        % Naming all conditions
        design.cond(1).name = 'Instruction';
        design.cond(2).name = 'FA';
        design.cond(3).name = 'VA';
        design.cond(4).name = 'HA';
        design.cond(5).name = 'Query';
        
        % Defining onset timing and duration in scans
        if strcmpi(units, 'scans')
            
            % Condition: Instruction
            design.cond(1).onset = [     0
                                        14
                                        28
                                        42
                                        56
                                        70
                                        84
                                        98
                                       112
                                       126
                                       140
                                       154
                                       168
                                       182
                                       196];
            design.cond(1).duration =    3;

            % Condition: Free Attention (FA)
            design.cond(2).onset = [     3
                                        45
                                        87
                                       129
                                       171];
            design.cond(2).duration =    8;
            
            % Condition: Visual Attention (VA)
            design.cond(3).onset = [    31
                                        73
                                       115
                                       157
                                       199];
            design.cond(3).duration =    8;

            % Condition: Hallucination Attention (HA)
            design.cond(4).onset = [    17
                                        59
                                       101
                                       143
                                       185];
            design.cond(4).duration =    8;
            
            % Condition: Query
            design.cond(5).onset = [    11
                                        25
                                        39
                                        53
                                        67
                                        81
                                        95
                                       109
                                       123
                                       137
                                       151
                                       165
                                       179
                                       193
                                       207];
            design.cond(5).duration =    3;

        % Defining onset timing and duration in seconds
        else
            
            % Condition: Instruction
            design.cond(1).onset = [     0
                                        42
                                        84
                                       126
                                       168
                                       210
                                       252
                                       294
                                       336
                                       378
                                       420
                                       462
                                       504
                                       546
                                       588];
            design.cond(1).duration =    9;

            % Condition: Free Attention (FA)
            design.cond(2).onset = [     9
                                       135
                                       261
                                       387
                                       513];
            design.cond(2).duration =   24;

            % Condition: Visual Attention (VA)
            design.cond(3).onset = [    31
                                        73
                                       115
                                       157
                                       199];
            design.cond(3).duration =   24;
            
            % Condition: Hallucination Attention (HA)
            design.cond(4).onset = [    17
                                        59
                                       101
                                       143
                                       185];
            design.cond(4).duration =   24;
            
            % Condition: Query
            design.cond(5).onset = [    33
                                        75
                                       117
                                       159
                                       201
                                       243
                                       285
                                       327
                                       369
                                       411
                                       453
                                       495
                                       537
                                       579
                                       621];
             design.cond(5).duration =   9;
        end
        
        % Set high pass filter (seconds) = twice the total block length
        design.hpf = 252;
end