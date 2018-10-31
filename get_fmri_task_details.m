function [TR, num_vols, hpf] = get_fmri_task_details(task_name)
% Function that returns the following details for task fMRI analysis:
% Repetition time (TR)
% Number of volumes
% High pass filter (twice the block length)
%% Input:
% task_name:  can be any of the following (case insensitive):
%             	* vftclassic   verbal fluency task
%             	* vftmodern    modified VFT with hallucination query
%             	* pm           prospective memory task
%             	* hamths       hallucination attention modulation task (HS)
%               * hamtsz       hallucination attention modulation task (SZ)
%
%% Output:
% TR:         Repetition time
% num_vols:   Number of volumes
% hpf:        High pass filter cutoff in seconds (twice the block length)
% 
%% Author(s):
% Parekh, Pravesh
% October 29, 2018
% MBIAL

%% Check task_name
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

%% Return information based on task_name
switch(task_name)
    case 'vftclassic'
        TR       = 4;
        num_vols = 108;
        hpf      = 144;
        
    case 'vftmodern'
        TR       = 4;
        num_vols = 132;
        hpf      = 176;
        
    case 'pm'
        TR       = 3;
        num_vols = 220;
        hpf      = 330;
        
    case 'hamths'
        TR       = 3;
        num_vols = 139;
        hpf      = 168;
        
    case 'hamtsz'
        TR       = 3;
        num_vols = 209;
        hpf      = 252;
end