function update_spmmat(mat, old_path, new_path, h_slash)
% Function to update all paths in SPM.mat variable to a new path
%% Inputs:
% mat:      full path to a SPM.mat file
% old_path: path that needs to be replaced
% new_path: path that will replace old_path
% h_slash:  character type; should be one of the following:
%               ' ': no need to change / or \ in paths
%               '\': replace all / with \
%               '/': replace all \ with /
% 
%% Output:
% A backup of SPM.mat is created and new SPM.mat with updated paths is
% saved in the same location as older SPM.mat; if full path is not provided
% with input, then thne new file is saved in pwd
% 
%% Notes:
% A path or part thereof can be replaced by providing a new path; this is
% often useful if analysis directories need to be updated. Consider the
% case where SPM.mat was located as '/home/analysis/sub-001/SPM.mat' and 
% has been shifted to 'D:\sub-001\SPM.mat' (note the change of OS), then
% old_path = '/home/analysis/', and new_path = 'D:\'
% 
% h_slash handles forward and backslash in the paths; if left empty, only
% old_path is replaced with new_path; if backslash is passed, it attempts
% to replace all forward slashes with backslashes; if forward slash is 
% passed, it attempts to replace all reverse slashes with backslashes
% 
%% Default:
% h_slash:  ' '
% 
%% Author(s):
% Parekh, Pravesh
% October 03, 2019
% MBIAL

%% Parse inputs
% Check mat
if ~exist('mat', 'var') || isempty(mat)
    error('Please provide full path to a SPM.mat file');
else
    if ~exist(mat, 'file')
        error(['Unable to read: ', mat]);
    else
        [loc,~] = fileparts(mat);
        if isempty(loc)
            loc = pwd;
        end
    end
end

% Check old_path
if ~exist('old_path', 'var') || isempty(old_path)
    error('Please provide old path to search and replace');
end

% Check new_path
if ~exist('new_path', 'var') || isempty(new_path)
    error('Please provide new path to update SPM.mat with');
end

% Check h_slash
if ~exist('h_slash', 'var') || isempty(h_slash)
    h_slash = ' ';
else
    if ~ismember(h_slash, {' ', '\', '/'})
        error(['Unknown h_slash value provided: ', h_slash]);
    end
end

%% Backup
new_name = fullfile(loc, ['SPM_', char(datetime('now', 'Format', 'yyyyMMMdd_HHmmss')), '.mat']);
copyfile(mat, new_name);

%% Load SPM.mat
load(mat, 'SPM');

%% Update paths
SPM = do_replace(SPM, old_path, new_path);

% Handle slashes
switch h_slash
    case '\'
        do_replace(SPM, '/', '\');
    case '/'
        do_replace(SPM, '\', '/');
end

%% Save
save(fullfile(loc, 'SPM.mat'), 'SPM');

function SPM = do_replace(SPM, old_str, new_str)

% Get number of volumes
num_vols = SPM.nscan;

% SPM.xY.P and SPM.xY.VY
P = cell(num_vols, 1);
for iter = 1:num_vols
    P{iter}               = strrep(SPM.xY.P(iter,:),      old_str, new_str);
    SPM.xY.VY(iter).fname = strrep(SPM.xY.VY(iter).fname, old_str, new_str);
end
SPM.xY.P = char(P);

% SPM.xM.VM
SPM.xM.VM.fname = strrep(SPM.xM.VM.fname, old_str, new_str);

% SPM.swd
SPM.swd = strrep(SPM.swd, old_str, new_str);