function location = detect_outliers(matrix, method, threshold)
% Function to detect outliers within columns of a matrix, given a method
%% Inputs:
% matrix:       matrix to detect outliers in (for each column)
% method:       should be one of:
%                   * 'SD'
%                   * 'IQR'
%                   * 'MAD'
%                   * 'percentile'
% threshold:    number controlling which values get identified as outlier
%               (see Notes)

% threshold:    for cases where method is 'percentile', threshold 
%               denotes the lower and upper percentile values above which a 
%               value is declared as an outlier; for cases where method is
%               'SD', threshold denotes the number of standard deviations
%               away from the mean that a value should be before being
%               called an outlier (see Notes)
% 
%% Output:
% A logical vector indicating for each column the locations which have been
% detected as an outlier
% 
%% Notes:
% Method:       SD
% Threshold:    number indicating how many standard deviations away
%               from the mean a value has to be to be called as an outlier
% Outlier:      value > (mean + threshold*SD) OR 
%               value < (mean - threshold*SD)
% 
% Method:       IQR
% Threshold:    three numbers where:
%                 1st number: how many times away from IQR
%                 2nd number: upper percentile 
%                 3rd number: lower percentile 
% Outliers:     values > (upper percentile + threshold*IQR) OR 
%               values < (lower percentile - threshold*IQR) 
% 
% Method:       MAD
% Threshold:    number indicating how many times away from scaled median
%               absolute deviation (MAD) a number should be to be called an
%               outlier
% Outliers:     values > threshold*scaled MAD OR
%               values < threshold*scaled MAD
% Scaled MAD:   Scaled median absolute deviation is defined as:
%                   c*median(abs(A-median(A)))
%                   c=-1/(sqrt(2)*erfcinv(3/2)) [approximately 1.4826]
% 
% Method:       percentile
% Threshold:    two numbers where:
%                   1st number: upper percentile
%                   2nd number: lower percentile
% Outliers:     values > upper threshold (upper percentile) OR 
%               values < lower threshold (lower percentile) OR 
% 
% Uses the Statistics and Machine Learning Toolbox
% 
%% References:
% https://www.mathworks.com/help/matlab/ref/isoutlier.html
% https://en.wikipedia.org/wiki/Median_absolute_deviation
% 
%% Defaults:
% method:       'IQR'
% threshold:    3           (for SD)
%               [1.5 75 25] (for IQR)
%               3           (for MAD)
%               [10 90]     (for percentile)
% 
%% Author(s):
% Parekh, Pravesh
% December 23, 2019
% MBIAL

%% Check inputs and assign defaults
% Check matrix
if ~exist('matrix', 'var') || isempty(matrix)
    error('Please provide a vector or matrix to work with');
end

% Check method
if ~exist('method', 'var') || isempty(method)
    method = 'iqr';
else
    method = lower(method);
    if ~ismember(method, {'iqr'; 'sd'; 'mad'; 'percentile'})
        error('Method should be one of: IQR, SD, MAD, or percentile');
    end
end

% Check threshold
if ~exist('threshold', 'var') || isempty(threshold)
    % Assign defaults
    if strcmpi(method, 'sd')  || strcmpi(method, 'mad')
        threshold = 3;
    else
        if strcmpi(method, 'iqr')
            threshold = [1.5 75 25];
        else
            if strcmpi(method, 'percentile')
                threshold = [10 90];
            end
        end
    end
else
    % Make sure correct number of threshold values are present
    if (strcmpi(method, 'sd') || strcmpi(method, 'mad'))
        if length(threshold) ~= 1
            error('Threshold with SD or MAD only needs one threshold value');
        end
    else
        if strcmpi(method, 'percentile') 
            if length(threshold) ~= 2
                error('Upper and lower percentile values needed');
            end
        else
            if length(threshold) ~= 3
                error('Times away from IQR, and upper and lower percentile values needed');
            end
        end
    end
end

%% Detect outliers
switch(method)
    case 'sd'
        all_mean    = mean(matrix,1);
        all_SD      = std(matrix,[],1);
        cut_off_U   = all_mean + threshold*all_SD;
        cut_off_L   = all_mean - threshold*all_SD;
        location    = bsxfun(@gt, matrix, cut_off_U) | bsxfun(@lt, matrix, cut_off_L);
        
    case 'iqr'
        prctile_U   = prctile(matrix, threshold(2));
        prctile_L   = prctile(matrix, threshold(3));
        all_IQR     = iqr(matrix);
        location    = bsxfun(@gt, matrix, prctile_U + threshold(1)*all_IQR) | ...
                      bsxfun(@lt, matrix, prctile_L - threshold(1)*all_IQR);
                
    case 'mad'
        all_median  = median(matrix,1);
        c           = -1/(sqrt(2)*erfcinv(3/2));
        tmp         = bsxfun(@minus, matrix, all_median);
        MAD         = median(abs(tmp));
        cut_off_U   = all_median + (threshold*c*MAD);
        cut_off_L   = all_median - (threshold*c*MAD);
        location    = bsxfun(@gt, matrix, cut_off_U) | bsxfun(@lt, matrix, cut_off_L);
        
    case 'percentile'
        cut_off_U   = prctile(matrix, threshold(1));
        cut_off_L   = prctile(matrix, threshold(2));
        location    = bsxfun(@lt, matrix, cut_off_L) | bsxfun(@gt, matrix, cut_off_U);
end