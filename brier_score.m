function brier_score = brier_score(predicted_prob, class_labels)
% Function to return Brier score based on predicted probabilities and given
% class labels 
%% Inputs:
% predicted_prob:       vector of probabilities output from some ML method
%                       for the positive class
% class_labels:         vector of 0's and 1's indicating if that instance
%                       belongs to class 0 or class 1
%                       
%% Output:
% brier_score:          calculated Brier score
% 
%% Notes:
% Calculation of Brier score is based on Wikipedia article: 
% https://en.wikipedia.org/wiki/Brier_score
% Brier Score = sum((predicted_prob - class_labels).^2)/N
% 
%% Author(s):
% Parekh, Pravesh
% October 13, 2019
% MBIAL

%% Validate input
% Check predicted_prob
if ~exist('predicted_prob', 'var') || isempty(predicted_prob)
    error('Please provide a vector of probabilities');
else
    N = length(predicted_prob);
end

% Check class_labels
if ~exist('class_labels', 'var') || isempty(class_labels)
    error('Please provide class label vector');
else
    if length(class_labels) ~= N
        error('predicted_prob and class_labels should have same number of entries');
    else
        if sum(class_labels ~= 0 & class_labels ~= 1) ~= 0
            error('Class labels should be either 0 or 1');
        end
    end
end

%% Calculate Brier score
brier_score = (sum((predicted_prob - class_labels).^2))/N;