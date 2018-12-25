function [con_names, con_weights, file_names] = get_fmri_contrasts(task_name)
% Function to return contrasts of interest (for SPM) for a given task
%% Input:
% task_name:  can be any of the following (case insensitive):
%             	* vftclassic   verbal fluency task
%             	* vftmodern    modified VFT with hallucination query
%             	* pm           prospective memory task
%             	* hamths       hallucination attention modulation task (HS)
%               * hamtsz       hallucination attention modulation task (SZ)
%
%% Output:
% con_names:    Names of the contrats of interest
% con_weights:  Weights of contrasts of interest
% file_names:   Names of the con_*.nii file created by SPM
%
%% Default:
% units:      secs
%
%% Author(s):
% Parekh, Pravesh
% December 25, 2018
% MBIAL

%% Check inputs
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

%% Get task design (get_fmri_task_design_spm_mat)
get_fmri_task_design_spm_mat(task_name, 'secs');
task_var_name = ['task-design_', task_name, '_secs.mat'];
load(task_var_name, 'names');
delete(task_var_name);
num_conditions = length(names);

%% Get contrasts
switch(task_name)
    case 'vftclassic'
        % WG-WR contrast
        vector           = zeros(1,num_conditions);
        vector(strcmpi(names, 'WG')) =  1;
        vector(strcmpi(names, 'WR')) = -1;
        con_names{1,1}   = {'WG-WR'};
        con_weights{1,1} = vector;
        file_names{1,1}  = 'con_0001.nii';
        
        % WR-WG contrast
        vector           = zeros(1,num_conditions);
        vector(strcmpi(names, 'WR')) =  1;
        vector(strcmpi(names, 'WG')) = -1;
        con_names{1,2}   = {'WR-WG'};
        con_weights{1,2} = vector;
        file_names{1,2}  = 'con_0002.nii';
        
    case 'vftmodern'
        % WG-WR contrast
        vector           = zeros(1,num_conditions);
        vector(strcmpi(names, 'WG')) =  1;
        vector(strcmpi(names, 'WR')) = -1;
        con_names{1,1}   = {'WG-WR'};
        con_weights{1,1} = vector;
        file_names{1,1}  = 'con_0001.nii';
        
        % WR-WG contrast
        vector           = zeros(1,num_conditions);
        vector(strcmpi(names, 'WR')) =  1;
        vector(strcmpi(names, 'WG')) = -1;
        con_names{1,2}   = {'WR-WG'};
        con_weights{1,2} = vector;
        file_names{1,2}  = 'con_0002.nii';
        
    case 'pm'
        % PM-OT condition
        vector           = zeros(1,num_conditions);
        vector(strcmpi(names, 'PM')) =  1;
        vector(strcmpi(names, 'OT')) = -1;
        con_names{1,1}   = {'PM-OT'};
        con_weights{1,1} = vector;
        file_names{1,1}  = 'con_0001.nii';
        
        % WM-OT condition
        vector           = zeros(1,num_conditions);
        vector(strcmpi(names, 'WM')) =  1;
        vector(strcmpi(names, 'OT')) = -1;
        con_names{1,2}   = {'WM-OT'};
        con_weights{1,2} = vector;
        file_names{1,2}  = 'con_0002.nii';
        
        % PM-WM condition
        vector           = zeros(1,num_conditions);
        vector(strcmpi(names, 'PM')) =  1;
        vector(strcmpi(names, 'WM')) = -1;
        con_names{1,3}   = {'PM-WM'};
        con_weights{1,3} = vector;
        file_names{1,3}  = 'con_0003.nii';
        
        % OT-PM condition
        vector           = zeros(1,num_conditions);
        vector(strcmpi(names, 'OT')) =  1;
        vector(strcmpi(names, 'PM')) = -1;
        con_names{1,4}   = {'OT-PM'};
        con_weights{1,4} = vector;
        file_names{1,4}  = 'con_0004.nii';
        
        % OT-WM condition
        vector           = zeros(1,num_conditions);
        vector(strcmpi(names, 'OT')) =  1;
        vector(strcmpi(names, 'WM')) = -1;
        con_names{1,5}   = {'OT-WM'};
        con_weights{1,5} = vector;
        file_names{1,5}  = 'con_0005.nii';
        
        % WM-PM condition
        vector           = zeros(1,num_conditions);
        vector(strcmpi(names, 'WM')) =  1;
        vector(strcmpi(names, 'PM')) = -1;
        con_names{1,6}   = {'WM-WM'};
        con_weights{1,6} = vector;
        file_names{1,6}  = 'con_0006.nii';
        
    case 'hamths'
        % VA-FA condition
        vector           = zeros(1,num_conditions);
        vector(strcmpi(names, 'VA')) =  1;
        vector(strcmpi(names, 'FA')) = -1;
        con_names{1,1}   = {'VA-FA'};
        con_weights{1,1} = vector;
        file_names{1,1}  = 'con_0001.nii';
        
        % FA-VA condition
        vector           = zeros(1,num_conditions);
        vector(strcmpi(names, 'FA')) =  1;
        vector(strcmpi(names, 'VA')) = -1;
        con_names{1,2}   = {'FA-VA'};
        con_weights{1,2} = vector;
        file_names{1,2}  = 'con_0002.nii';
        
    case 'hamtsz'
         % VA-FA condition
        vector           = zeros(1,num_conditions);
        vector(strcmpi(names, 'VA')) =  1;
        vector(strcmpi(names, 'FA')) = -1;
        con_names{1,1}   = {'VA-FA'};
        con_weights{1,1} = vector;
        file_names{1,1}  = 'con_0001.nii';
        
        % FA-VA condition
        vector           = zeros(1,num_conditions);
        vector(strcmpi(names, 'FA')) =  1;
        vector(strcmpi(names, 'VA')) = -1;
        con_names{1,2}   = {'FA-VA'};
        con_weights{1,2} = vector;
        file_names{1,2}  = 'con_0002.nii';
        
        % HA-VA condition
        vector           = zeros(1,num_conditions);
        vector(strcmpi(names, 'HA')) =  1;
        vector(strcmpi(names, 'VA')) = -1;
        con_names{1,3}   = {'HA-VA'};
        con_weights{1,3} = vector;
        file_names{1,3}  = 'con_0003.nii';
        
        % VA-HA condition
        vector           = zeros(1,num_conditions);
        vector(strcmpi(names, 'VA')) =  1;
        vector(strcmpi(names, 'HA')) = -1;
        con_names{1,4}   = {'VA-HA'};
        con_weights{1,4} = vector;
        file_names{1,4}  = 'con_0004.nii';
        
        % HA-FA condition
        vector           = zeros(1,num_conditions);
        vector(strcmpi(names, 'HA')) =  1;
        vector(strcmpi(names, 'FA')) = -1;
        con_names{1,5}   = {'HA-FA'};
        con_weights{1,5} = vector;
        file_names{1,5}  = 'con_0005.nii';
        
        % FA-HA condition
        vector           = zeros(1,num_conditions);
        vector(strcmpi(names, 'FA')) =  1;
        vector(strcmpi(names, 'HA')) = -1;
        con_names{1,6}   = {'FA-HA'};
        con_weights{1,6} = vector;
        file_names{1,6}  = 'con_0006.nii';
end