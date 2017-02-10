function [subj_names, full_paths] = create_subj_list(source_dir)
% Creates a list of subjects given a directory
% Returns subject names and full path to each subject directory
% Parekh, Pravesh
% February 10, 2017
% MBIAL
% 
% Assumes the following structure
% <some-location>/
%   <source-dir>/
%       <some-subj-name>/
%           <folders>/
%           <files>
% 

% Removing all files and '.' '..' folders
source_contents = dir(source_dir);
check_dir = [source_contents.isdir]';
check_names = {source_contents(check_dir).name}';
to_remove = ismember(check_names, {'.', '..'});
source_contents(to_remove) = [];

subj_names = {source_contents.name}';
full_paths = fullfile(source_dir, {source_contents.name})';