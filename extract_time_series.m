function time_series = extract_time_series(fname, rois, summary, return_vox)
% Extracts fMRI time series from ROIs from a 4D NIfTI file
% Input:
% fname:        File from which time series is to be extracted
% rois:         Binary mask(s)/ROI(s) from which time series is extracted
% time_points:  Time points from which time series is to be extracted
% summary:      Summary function
%               'mean':     mean time series in a region (default)
%               'median':   meadian time series in a region
% return_vox:   [1/0] value of 1 means that voxel level time series will
%               also be returned in the structure
% 
% Output:
% time_series:  Structure with the following fields
%               ts:         time series data [time_points x num_rois]
%               fname:      path to image file from which ts is extracted
%               rois:       path(s) to ROI(s) from which ts is extracted
%               summary:    method used for summarizing the regional time
%                           series
%               vox_ts:     voxel level time series (only returned if
%                           return_vox is passed as 1 in the input)
%
% Parekh, Pravesh
% February 28, 2017
% MBIAL


% Evaluate input
if nargin<2
    error('Insufficient number of inputs');
else
    if nargin==2
        summary = 'mean';
        return_vox = 0;
    end
end

num_rois = size(rois,1);

% Read in the file structure
vol_read = spm_vol(fname);

% Take the first volume's affine transformation matrix
vol_mat = vol_read(1).mat;

% Find number of time points to find
num_time_points = length(vol_read);

% Initialize time_series structure
time_series.ts = zeros(num_time_points, num_rois);
time_series.fname = fname;
time_series.rois = rois;
time_series.summary = summary;

% Extract time series
% Loop over ROIs
for roi = 1:num_rois
    
    % Read in ROI
    if iscell(rois)
        roi_read = spm_vol(rois{roi});
    else
        roi_read = spm_vol(rois(roi,:));
    end
    roi_data = spm_read_vols(roi_read);
    roi_mat = roi_read.mat;
    
    % Find voxels in the ROI
    voxels = find(roi_data);
    
    % Get i,j,k entries for the voxels
    [i,j,k] = ind2sub([size(roi_data,1), size(roi_data,2), ...
        size(roi_data,3)], voxels);
    
    % Move to image space
    res = vol_mat\(roi_mat*[i j k ones(length(i),1)]');
    
    % Get time series
    vox_ts = spm_get_data(vol_read, res);
    
    % Save voxel time series if required
    if return_vox == 1
        time_series.vox_ts{roi,:,:} = vox_ts;
    end
    
    % Get summary time series for the ROI
    switch summary
        case 'mean'
            time_series.ts(:,roi) = mean(vox_ts,2);
        case 'meadian'
            time_series.ts(:,roi) = median(vox_ts,2);
    end
end
if return_vox == 1
    time_series.vox_ts = time_series.vox_ts';
end