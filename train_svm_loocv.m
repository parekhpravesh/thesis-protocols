function [sample_id_conf,confusion_matrix, description] = ...
         train_svm_loocv(features, classes, scaling, kernel, c, k, xnames)
% Function to train a support vector machine model using leave one out
% cross validation
%% Inputs:
% features:         matrix with each column representing one feature
% classes:          vector having 1 and 0 values for classes
% scaling:          one of the following can be specified:
%                       * 'rescale'
%                       * 'mean'
%                       * 'std'
%                       * 'none'
% kernel:           one of the following can be specified:
%                       * 'linear'
%                       * 'rbf'
% c:                box constraint value
% k:                kernel parameters
% xnames:           names of the features
% 
%% Outputs:
% sample_id_conf:   table having the sample id which is the test case, 
%                   the prediction, and 1/0 value indicating whether the 
%                   prediction was correct, TP, FP, TN, or FN (in that order)
% confusion_matrix: structure having the following overall values: 
%                   number of TP, FP, TN, and FN;
%                   accuracy, sensitivity, and specificity;
%                   TPR, FPR, PPV, NPV, and FDR 
% description:      mentions the names of columns of sample_id_conf
% 
%% Notes:
% Feature scaling is done by calling feature_scaling.m file; see file for
% details of implementation of feature scaling
% 
% xnames should have the same number of names as the number of features
% 
% Definition of confusion matrix and associated terms taken from Wikipedia:
% https://en.wikipedia.org/wiki/Sensitivity_and_specificity
% 
% Requires the Statistics and Machine Learning toolbox
% 
%% Defaults:
% scaling:          'rescale'
% kernel:           'linear'
% c:                1
% k:                1
% xnames:           'var1', 'var2', ..., etc.
% 
%% Author(s)
% Parekh, Pravesh
% July 08, 2018
% MBIAL

%% Validate input
% Validate feature vector
if ~exist('features', 'var') || isempty(features)
    error('Features should be provided');
else
    num_features = size(features,2);
    num_samples  = size(features,1);
end

% Validate classes
if ~exist('classes', 'var') || isempty(classes)
    error('Classes should be provided');
else
    if length(unique(classes)) ~= 2
        error('Method only implemented for two class problem');
    end
end

% Validate scaling
if ~exist('scaling', 'var') || isempty(scaling)
    scaling = 'rescale';
else
    if ~ismember(scaling, {'rescale', 'mean', 'std', 'none'})
        error('Incorrect scaling method provided');
    end
end

% Validate kernel choice
if ~exist('kernel', 'var') || isempty(kernel)
    kernel = 'linear';
else
    if ~ismember(kernel, {'linear', 'rbf'})
        error('Incorrect kernel choice');
    end
end

% Validate box-constraing value
if ~exist('c', 'var') || isempty(c)
    c = 1;
end

% Validate kernel parameter, if needed
if ~exist('k', 'var') || isempty(k)
    k = 1;
end

% Validate xnames
if ~exist('xnames', 'var') || isempty(xnames)
    xnames = cell(num_features,1);
    for feature = 1:num_features
        xnames(feature) = strcat({'Var'}, num2str(feature));
    end
else
    if length(xnames) ~= num_features
        error('Incorrect number of feature names provided');
    end
end

%% Scale features if needed
if ~strcmpi(scaling, 'none')
    features = feature_scaling(features, scaling);
end

%% Initialize some variables
all_samples     = 1:num_samples;
sample_id_conf  = zeros(num_samples,7);
TP              = 0;
TN              = 0;
FP              = 0;
FN              = 0;
description     = {'sample_id', 'prediction', 'correct', ...
                   'TP', 'FP', 'TN', 'FN'};
sample_id_conf(:,1) = all_samples;

%% Split data and fit logistic regression model
for sample = 1:num_samples
    idx = all_samples ~= sample;
    traindata    = features(idx,:);
    trainclasses = classes(idx);
    testdata     = features(sample,:);
    testclass    = classes(sample);
    model        = fitcsvm(traindata, trainclasses, ...
                          'BoxConstraint', c, ...
                          'KernelFunction', kernel, ...
                          'KernelScale', k, ...
                          'Standardize', false, ...
                          'PredictorNames', xnames);
    prediction   = predict(model,testdata);
    sample_id_conf(sample,2) = prediction;
    
    % Check accuracy of prediction
    if testclass == prediction
        sample_id_conf(sample,3) = 1;
    else
        sample_id_conf(sample,3) = 0;
    end
    
    % Work out TP/TN/FP/FN
    % True positive case
    if testclass == 1 && testclass == prediction
        TP = TP + 1;
        sample_id_conf(sample,4)     = 1;
        sample_id_conf(sample,5:end) = 0;
    else
        % False negative case
        if testclass == 1 && testclass ~= prediction
            FN = FN + 1;
            sample_id_conf(sample,end)     = 1;
            sample_id_conf(sample,4:end-1) = 0;
        else
            % True negative case
            if testclass == 0 && testclass == prediction
                TN = TN + 1;
                sample_id_conf(sample,5)       = 1;
                sample_id_conf(sample,[4:5,7]) = 0;
            else
                % False positive case
                FP = FP + 1;
                sample_id_conf(sample,5)       = 1;
                sample_id_conf(sample,[4,6:7]) = 0;
            end
        end
    end
end

%% Populate confusion matrix
confusion_matrix.TP = TP;
confusion_matrix.TN = TN;
confusion_matrix.FP = FP;
confusion_matrix.FN = FN;

confusion_matrix.accuracy    = mean(sample_id_conf(:,3));
confusion_matrix.sensitivity = TP/(TP+FN);
confusion_matrix.specificity = TN/(TN+FP);

confusion_matrix.PPV = TP/(TP+FP);
confusion_matrix.NPV = TN/(TN+FN);
confusion_matrix.FPR = FP/(FP+TN);
confusion_matrix.FNR = FN/(TP+FN);
confusion_matrix.FDR = FP/(TP+FP);

%% Convert sample_id_conf to table
sample_id_conf = array2table(sample_id_conf, 'VariableNames', description);