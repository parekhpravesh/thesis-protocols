function fill_holes_nii(in_file, out_name, conn_val)
% Function to fill in holes in a binary NIfTI image
%% Inputs:
% in_name:      full path to a 3D binary NIfTI image
% out_name:     name of the new file to be written (without path)
% conn_val:     connectivity value (6, 18, or 26) for connected components
% 
%% Output:
% NIfTI image with filled holes is written in the same location as in_file
% 
%% References
% https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=FSL;72a813fe.1109
% https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=FSL;401c57ea.0902
% https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=spm;fcb4cb28.1110
% https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=ind1009&L=SPM&P=R36441&1=SPM&9=A&J=on&d=No+Match%3BMatch%3BMatches&z=4
% https://en.wikibooks.org/wiki/SPM/How-to#How_to_remove_clusters_under_a_certain_size_in_a_binary_mask.3F
% 
%% Defaults:
% out_name:     '_filled' is suffixed to the in_file name
% conn_val:     6
% 
%% Author:
% Parekh, Pravesh
% May 28, 2019
% MBIAL

%% Check inputs
% Check input file
if ~exist('in_file', 'var') || isempty(in_file)
    error('Full path to a 3D binary NIfTI image should be provided');
else
    if ~exist(in_file, 'file')
        error(['Unable to read: ', in_file]);
    else
        out_loc = fileparts(in_file);
        out_loc = [out_loc, '.nii'];
        if isempty(out_loc)
            out_loc = pwd;
        end
    end
end

% Check out_name
if ~exist('out_name', 'var') || isempty(out_name)
    out_name = strrep(in_file, '.nii', '_filled.nii');
    out_loc  = '';
end

% Check conn_val
if ~exist('conn_val', 'var') || isempty(conn_val)
    conn_val = 6;
end
    
%% Read input file
hdr  = spm_vol(in_file);
data = spm_read_vols(hdr);

%% invert mask
data = (data.*-1)+1;

%% Label
[labeled_image, num_com] = spm_bwlabel(data, conn_val);

% Get size and index of clusters
[n, ni] = sort(histc(labeled_image(:),0:num_com), 1, 'descend');

% Anything which is not the largest component becomes 1
k = ni(n==max(n))-1;

%% Re-label and invert image
labeled_image(labeled_image~=k)   = 100;
labeled_image(labeled_image==k)   = 0;
labeled_image(labeled_image==100) = 1;

%% Write out
hdr.fname = fullfile(out_loc, out_name);
spm_write_vol(hdr, labeled_image);