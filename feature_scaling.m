function [scaled_feature_matrix, scaling_parameters] = ...
          feature_scaling(feature_matrix, method, scaling_parameters)
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
% scaling_parameters:   structure having the parameters to be applied to 
%                       feature_matrix depending on method (see Notes):
%                           if 'rescale', then should contain: 
%                               min_val (minimum value per feature) and 
%                               max_val (maximum value per feature)
%                           if 'mean', then should contain: 
%                               min_val (minimum value per feature)
%                               max_val (maximum value per feature)
%                               mean_val (mean value per feature)
%                           if 'std', then should contain:
%                               mean_val (mean value per feature)
%                               std_val (standard deviation per feature)
%                       
%% Outputs:
% scaled_feature_matrix: matrix of scaled features
% scaling_parameters:    structure containing a vector of values used 
%                        during feature scaling
% 
%% Default:
% method:               'rescale'
% scaling_parameters:   [] (i.e. parameters are estimated)
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
% If no parameters are passed, the minimum, maximum, mean, and standard
% deviation values (as needed) are calculated from the data; these values
% are returned as a structure in scaling_parameters; this is typically the 
% case when the input is the training data
% 
% If parameters are passed, these parameters are simply applied to the
% data; this is typically the case when applying the same feature scaling
% as training data to a test data; the same values are returned as
% scaling_parameters 
% 
% Variables in the scaling_parameters structure should have the same number
% of values as the number of features and should be ordered the same as the
% actual feature vector; sanity check is restricted to checking the number
% of features
% 
% Each variable in scaling_parameters should be a vector of numbers
% 
% If scaling_parameters are passed as input, the output scaling_parameters
% is the same set of value 
% 
%% Author(s):
% Parekh, Pravesh
% May 24, 2018
% MBIAL

%% Validate inputs and assign defaults
% Check feature_matrix
if ~exist('feature_matrix', 'var') || isempty(feature_matrix)
    error('Feature matrix should be provided');
else
    % Number of features is the number of columns
    num_features = size(feature_matrix, 2);
end

% Check method
if ~exist('method', 'var') || isempty(method)
    method = 'rescale';
else
    if ~ismember(method, {'rescale', 'mean', 'std'})
        error(['Unknown method specified: ', method]);
    end
end

% Check scaling_parameters
if ~exist('scaling_parameters', 'var') || isempty(scaling_parameters)
    to_scale = true;
else
    to_scale = false;
    % Check if required fields are present
    if strcmpi(method, 'rescale')
        if ~isfield(scaling_parameters, 'min_val') || ...
           ~isfield(scaling_parameters, 'max_val')
                error('min_val and max_val values should be provided');
        else
            % Check for sizes of scaling parameters
            if numel(scaling_parameters.min_val) ~= num_features || ...
               numel(scaling_parameters.max_val) ~= num_features
                error(['Mismatch between number of features: ', ...
                       num2str(num_features), ' and the scaling parameters']);
            end
        end
    else
        if strcmpi(method, 'mean')
            if ~isfield(scaling_parameters, 'min_val') || ...
               ~isfield(scaling_parameters, 'max_val') || ...
               ~isfield(scaling_parameters, 'mean_val')
                    error('min_val, max_val, and mean_val should be provided');
            else
                % Check for sizes of scaling parameters
                if numel(scaling_parameters.min_val)  ~= num_features || ...
                   numel(scaling_parameters.max_val)  ~= num_features || ...
                   numel(scaling_parameters.mean_val) ~= num_features
                        error(['Mismatch between number of features:' ,  ...
                               num2str(num_features), ' and the scaling parameters']);
                end
            end
        else
            if ~isfield(scaling_parameters, 'mean_val') || ...
               ~isfield(scaling_parameters, 'std_val')
                    error('mean_val and std_val should be provided');
            else
                % Check for sizes of scaling parameters
                if numel(scaling_parameters.mean_val) ~= num_features || ...
                   numel(scaling_parameters.std_val)  ~= num_features
                        error(['Mismatch between number of features ', ...
                               num2str(num_features), ' and the scaling parameters']);
                end
            end
        end
    end
end

%% Rescale each feature independently
switch(method)
    case 'rescale'
        if to_scale
            % Get minimum and maximum values
            scaling_parameters.min_val = min(feature_matrix);
            scaling_parameters.max_val = max(feature_matrix);
        end
        
        % Apply scaling
        % scaled_feature_matrix = (feature_matrix - scaling_parameters.min_val)./ ...
        %                         (scaling_parameters.max_val - scaling_parameters.min_val);
        scaled_feature_matrix = bsxfun(@rdivide, bsxfun(@minus, feature_matrix,             scaling_parameters.min_val), ...
                                                 bsxfun(@minus, scaling_parameters.max_val, scaling_parameters.min_val));

    case 'mean'
        if to_scale
            % Get minimum, maximum, and mean values
            scaling_parameters.min_val  = min(feature_matrix);
            scaling_parameters.max_val  = max(feature_matrix);
            scaling_parameters.mean_val = mean(feature_matrix);
        end
        
        % Apply scaling
        % scaled_feature_matrix = (feature_matrix - scaling_parameters.mean_val)./ ...
        %                         (scaling_parameters.max_val - scaling_parameters.min_val);
        scaled_feature_matrix = bsxfun(@rdivide, bsxfun(@minus, feature_matrix,             scaling_parameters.mean_val), ...
                                                 bsxfun(@minus, scaling_parameters.max_val, scaling_parameters.min_val));

    case 'std'
        if to_scale
            % Get mean and standard deviation
            scaling_parameters.mean_val = mean(feature_matrix);
            scaling_parameters.std_val  = std(feature_matrix);
        end
        
        % Apply scaling
        % scaled_feature_matrix = (feature_matrix - scaling_parameters.mean_val)./ ...
        %                         scaling_parameters.std_val;
        scaled_feature_matrix = bsxfun(@rdivide, bsxfun(@minus, feature_matrix, scaling_parameters.mean_val), ...
                                                 scaling_parameters.std_val);
end