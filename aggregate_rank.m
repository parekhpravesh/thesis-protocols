function agg_ranks = aggregate_rank(rank_matrix,  agg_method, ...
                                    prenormalize, break_ties)
% Function to aggregate rank, given a matrix of ranks and a rank
% aggregation method
%% Inputs:
% rank_matrix:      a matrix with rows having ranks and columns represent
%                   ranking methods (i.e. feat_ordered output from
%                   rank_features)
% agg_method:       method used for aggregating ranks; should be one of:
%                       * 'min'
%                       * 'mean'
%                       * 'median'
%                       * 'minvar'
% prenormalize:     true or false indicating if ranks in rank_matrix should
%                   be normalized by number of features before aggregation
% break_ties:       method for breaking ties in ranks; should be one of:
%                       * 'rand'
%                       * 'ascend'
%                       * 'minvar'
%
%% Outputs:
% agg_ranks:        a vector with aggregate ranks arranged in ascending
%                   order i.e. agg_rank(1) will be the index of feature
%                   whose aggregate rank is 1
%
%% Notes:
% The input rank_matrix:
% number of features        = number of rows
% number of ranking methods = number of columns
%
% Aggregate ranking methods:
% min:              the minimum rank of a feature is its aggregate rank
% mean:             the average rank of a feature is calculated and sorted
%                   in ascending order to determine its aggregate rank
% median:           the median rank of a feature is calculated and sorted
%                   in ascending order to determine its aggregate rank
% minvar:           variance is calculated across ranking methods and the
%                   features are sorted in the order of minimum variance
%                   i.e. the feature whose rank shows the least variation
%                   is put on the top (assuming it would be the most stable
%                   feature)
% 
% Prenormalization divides the rank matrix (per column) by the total number
% of features (thereby scaling it between 1/num_features to 1) before
% performing ranking
%
% Assumes that all features are present in rank_matrix; for example, if
% there are 10 features, then each column in rank_matrix will have all 10
% values
%
% Tie breaking methods:
% rand:             ties are broken randomly
% ascend:           feature which is first, is ranked first among ties
% minvar:           features where there is a tie, the feature where the
%                   rank_matrix had minimum variance is ranked first; if
%                   the ties persist, they are broken randomly
%
%% References:
% Find duplicate rankings using Guillaume's solution
% https://in.mathworks.com/matlabcentral/answers/388695
%
%% Defaults:
% agg_method:       median
% prenormalize:     true
% break_ties:       minvar
%
%% Authors(s):
% Parekh, Pravesh
% August 28, 2020
% MBIAL

%% Check inputs and assign defaults
% Check rank_matrix
if ~exist('rank_matrix', 'var') || isempty(rank_matrix)
    error('Please provide a matrix of ranks');
else
    [num_features, ~] = size(rank_matrix);
end

% Check agg_method
if ~exist('agg_method', 'var') || isempty(agg_method)
    agg_method = 'median';
else
    agg_method = lower(agg_method);
    if ~ismember(agg_method, {'min'; 'mean'; 'median'; 'minvar'})
        error(['Incorrect agg_method specified: ', agg_method]);
    end
end

% Check prenormalize
if ~exist('prenormalize', 'var') || isempty(prenormalize)
    prenormalize = true;
else
    if ~islogical(prenormalize)
        error('prenormalize should be either true or false');
    end
end

% Check break_ties
if ~exist('break_ties', 'var') || isempty(break_ties)
    break_ties = 'minvar';
else
    break_ties = lower(break_ties);
    if ~ismember(break_ties, {'rand'; 'ascend'; 'descend'; 'minvar'})
        error(['Incorrect break_ties method specified: ', break_ties]);
    end
end

%% Prenormalize, if required
if prenormalize
    rank_matrix = rank_matrix./num_features;
end

%% Aggregate
switch agg_method
    case 'min'
        to_work = min(rank_matrix, [], 2);
        
    case 'mean'
        to_work = mean(rank_matrix, 2);
        
    case 'median'
        to_work = median(rank_matrix, 2);
        
    case 'minvar'
        to_work = var(rank_matrix, [], 2);
end
[~, agg_ranks] = sort(to_work, 'ascend');

%% Break ties
[uvalues, ~, uid]       = unique(to_work(:));
count                   = accumarray(uid, 1);                                       %easiest way to calculate the histogram of uvalues
linindices              = accumarray(uid, (1:numel(to_work))', [], @(idx) {idx});   %split linear indices according to uid
valwhere                = [num2cell(uvalues), linindices];                          %concatenate
valwhere(count == 1, :) = [] ;                                                      %remove count of 1

% Go over each duplicate and resolve them randomly
for rep = 1:size(valwhere,1)
    % Find these locations in rank
    loc = [];
    for tmp = 1:length(valwhere{rep,2})
        loc(tmp,1) = find(agg_ranks == valwhere{rep,2}(tmp));  %#ok<AGROW>
    end
    
    % Handle ties
    switch break_ties
        case 'rand'
            agg_ranks(loc) = agg_ranks(loc(randperm(length(loc), length(loc))));
            
        case 'ascend'
            % Does not need any handling
            
        case 'minvar'
            % Sort by minimum variance
            tmp_var         = var(rank_matrix(valwhere{rep,2},:), [], 2);
            [~, b]          = sort(tmp_var, 'ascend');
            agg_ranks(loc)  = agg_ranks(loc(b));
    end
end