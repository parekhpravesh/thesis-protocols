function scaled_feature_matrix = feature_scaling(feature_matrix, method)
% Function to individually scale a set of features by any of the
% following methods: rescaling between 0 and 1, mean normalization, and
% standardization
%% Inputs:
% feature_matrix:       a matrix of features where each column is a feature
% method:               choice of method for feature normalization; should 
%                       be one of the following (see Notes for explanation):
%                           * rescale
%                           * mean
%                           * std
% 
%% Output
% norm_feature_matrix:  a matrix of normalized features
% 
%% Default:
% method:               'rescale'
% 
%% Notes:
% method for feature scaling is based on the Wikipedia article on feature
% scaling: https://en.wikipedia.org/wiki/Feature_scaling
% 
% * rescale
%       normalized_value = (x - min(x))/(max(x) - min(x))
% 
% * mean
%       normalized_value = (x - mean(x))/(max(x) - min(x))
% 
% * std
%       normalized_valie = (x - mean(x))/std(x)
% 
%% Author(s):
% Parekh, Pravesh
% May 24, 2018
% MBIAL

%% Validate input and assign default
if ~exist('feature_matrix', 'var')
    error('Feature matrix should be provided');
end

if ~exist('method', 'var')
    method = 'rescale';
end

%% Rescale each feature independently
switch(method)
    case 'rescale'
        scaled_feature_matrix = (feature_matrix - min(feature_matrix))./ ...
                                (max(feature_matrix) - min(feature_matrix));
    case 'mean'
        scaled_feature_matrix = (feature_matrix - mean(feature_matrix))./ ...
                                (max(feature_matrix) - min(feature_matrix));
    case 'std'
        scaled_feature_matrix = (feature_matrix - mean(feature_matrix))./ ...
                                std(feature_matrix);
    otherwise
        error('Incorrect method provided');
end