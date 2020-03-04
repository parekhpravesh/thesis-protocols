function kappa = cohen_kappa(predicted_labels, actual_labels)
% Function to calculate Cohen's Kappa
%% Inputs:
% predicted_labels:     vector of 0's and 1's output from some ML method 
% class_labels:         vector of 0's and 1's indicating if that instance
%                       belongs to class 0 or class 1
%                       
%% Output:
% kappa:                calculated Cohen's Kappa
% 
%% Notes:
% Calculation of Cohen's Kappa is based on: 
% https://stats.stackexchange.com/questions/82162/cohens-kappa-in-plain-english
% https://en.wikipedia.org/wiki/Cohen's_kappa
% Cohen's Kappa = (observed accuracy - expected accuracy)/(1 - expected accuracy)
% 
% Assumes only two classes are present
% 
%% Author(s):
% Parekh, Pravesh
% October 14, 2019
% MBIAL

%% Validate inputs
% Check predicted_labels
if ~exist('predicted_labels', 'var') || isempty(predicted_labels)
    error('Please provide a vector of predicted labels');
end

% Check actual_labels
if ~exist('actual_labels', 'var') || isempty(actual_labels)
    error('Please provide a vector of actual labels');
end

% Ensure number of observations are the same
num_observations = length(predicted_labels);
if length(actual_labels) ~= num_observations
    error('Mismatch between number of predicted labels and number of actual labels');
end

%% Confusion matrix
num_correct_pred_0   = length(nonzeros(predicted_labels(actual_labels==0)==0));
num_incorrect_pred_0 = length(nonzeros(predicted_labels(actual_labels==1)==0));
num_pred_0           = num_correct_pred_0 + num_incorrect_pred_0;
num_actual_0         = length(nonzeros(actual_labels==0));

num_correct_pred_1   = length(nonzeros(predicted_labels(actual_labels==1)==1));
num_incorrect_pred_1 = length(nonzeros(predicted_labels(actual_labels==0)==1));
num_pred_1           = num_correct_pred_1 + num_incorrect_pred_1;
num_actual_1         = length(nonzeros(actual_labels==1));

%% Expected accuracy
exp_prob_0 = (num_pred_0 * num_actual_0)/num_observations;
exp_prob_1 = (num_pred_1 * num_actual_1)/num_observations;
exp_prob   = (exp_prob_0 + exp_prob_1)/num_observations;

%% Observed accuracy
obs_prob = (num_correct_pred_0 + num_correct_pred_1)/num_observations;

%% Cohen's Kappa
kappa = (obs_prob - exp_prob)/(1 - exp_prob);