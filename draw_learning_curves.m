function draw_learning_curves(data, cov_mat, cov_loc, feat_size, bc, ...
                              steps, num_splits, ranking, std_method, out_dir)
% Function to draw learning curves for linear SVM given a set of features
%% Inputs:
% data:         table type containing SubjectID as the first column, Class 
%               as the second column, and features from third column onwards
% cov_mat:      table type containing SubjectID as the first column and
%               covariates that need to be regressed from second column onwards
% cov_loc:      cell type containing names of variables (from data)
%               corresponding to features which should be regressed OR 
%               numbers indicating which column numbers in data should
%               be regressed (see Notes)
% feat_size:    number indicating how many features to include in the model
% bc:           number(s) indicating which box constraint value to use for
%               linear SVM
% steps:        fraction indicating increment size to vary sample size
% num_splits:   number indicating how many splits to do 
% ranking:      which feature ranking method to use
% std_method:   which method of standardization to use
% out_dir:      full path to where learning curves will be saved
% 
%% Outputs:
% Learning curves corresponding to different feature sizes are written in
% out_dir 
%
%% Notes:
% cov_loc has a lot of room for confusion. It should contain either the
% names of the features OR should indicate numbers saying which columns of
% feature_file should be regressed; these numbers should account for
% SubjectID and Class columns of feature_file. For example, if the first
% feature of feature_file should be regressed, then cov_loc should be 3
% 
% If cov_loc contains numbers, they are internally converted to feature
% names to avoid errors when unusable features are removed
% 
% If all variables need to be regressed, leave cov_loc empty
% 
% If multiple box constriant values are passed, the process is repeated for
% each value of box constraint
% 
% If multiple feat_size are passed, the entire process is repeated for each
% feature size
%
%% Defaults:
% cov_mat:      ''
% cov_loc:      ''
% feat_size:    1
% bc:           logspace(-3, 3, 10)
% steps:        0.05
% num_splits:   5
% ranking:      'median'
% std_method:   'std'
% out_dir:      pwd/learning_curves
%
%% Author(s):
% Parekh, Pravesh
% March 18, 2020
% MBIAL

%% Check inputs
% Check data
if ~exist('data', 'var') || isempty(data)
    error('Please provide the data table to work with');
else
    if ~istable(data)
        error(['data variable should be table type with SubjectID as first column, ', ...
               'Class as second column, and features from third variable onwards']);
    end
end

% Check cov_mat
if ~exist('cov_mat', 'var') || isempty(cov_mat)
    cov_mat = '';
    to_regress = false;
else
    if ~istable(cov_mat)
        error(['cov_mat should be a table with SubjectID as first column, ', ...
               'and regressors from second column onwards']);
    else
        to_regress = true;
    end
end

% Check cov_loc
if ~exist('cov_loc', 'var') || isempty(cov_loc)
    cov_loc = '';
end

% Check feat_size
if ~exist('feat_size', 'var') || isempty(feat_size)
    feat_size = 1;
end

% Check bc
if ~exist('bc', 'var') || isempty(bc)
    bc = logspace(-3, 3, 10);
else
    if ~isnumeric(bc)
        error('Box constraint value should be a number');
    end
end

% Check steps
if ~exist('steps', 'var') || isempty(steps)
    steps = 0.05;
end

% Check num_splits
if ~exist('num_splits', 'var') || isempty(num_splits)
    num_splits = 5;
end

% Check ranking
if ~exist('ranking', 'var') || isempty(ranking)
    ranking = 'median';
end

% Check std_method
if ~exist('std_method', 'var') || isempty(std_method)
    std_method = 'std';
end

% Check out_dir
if ~exist('out_dir', 'var') || isempty(out_dir)
    out_dir = fullfile(pwd, 'LearningCurves');
end
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

%% Work out which features to regress
all_names = data.Properties.VariableNames;
if to_regress
    if isempty(cov_loc)
        feat_to_regress = all_names(3:end);
    else
        if iscell(cov_loc)
            % Check if feature names in cov_loc exist in data
            if sum(ismember(all_names(3:end), cov_loc)) ~= length(cov_loc)
                error('One or more features in cov_loc do not exist');
            else
                feat_to_regress = cov_loc;
            end
        else
            if isnumeric(cov_loc)
                feat_to_regress = all_names(cov_loc);
            end
        end
    end
else
    feat_to_regress = '';
end

%% Remove unusable features
[exclude_location, feat_removed] = remove_features(data, 3);
if ~isempty(exclude_location)
    data(:, exclude_location) = [];
    loc = ismember(feat_to_regress, feat_removed);
    if ~isempty(loc)
        feat_to_regress(loc) = [];
    end
end
feat_names    = data.Properties.VariableNames(3:end);
loc_regress   = ismember(feat_names, feat_to_regress);

%% Shrink feat_size if necessary
feat_size(feat_size>length(feat_names)) = [];

%% Split data and initialize
rng('shuffle');
cv_object    = cvpartition(data.Class, 'KFold', num_splits);
to_vary      = [0.9:-steps:0.1,1];
train_errors = zeros(length(to_vary),num_splits);
test_errors  = zeros(length(to_vary),num_splits);
samplesize   = zeros(length(to_vary),num_splits);
feat_names   = data.Properties.VariableNames(3:end);
selectedfeat       = cell(1, length(bc));
results_samplesize = cell(1, length(bc));
results_trainerror = cell(1, length(bc));
results_testerror  = cell(1, length(bc));

%% Loop over feat_sizes
for fs = 1:length(feat_size)
    % Initialize figure
    fig          = figure;
    fig.Units    = 'centimeters';
    fig.Position = [10 10 16 16];
    
    % Optimal number of rows and columns
    [r,c] = calc_rows_cols_subplot(length(bc));
    
    % Create axes
    all_H = tight_subplot(r, c, 0.08, [0.045 0.025], 0.025);

    % Loop over box constraints
    for bx = 1:length(bc)

        for cv = 1:num_splits

            % Generate training and test data
            train_data = data(cv_object.training(cv),:);
            test_data  = data(cv_object.test(cv),:);

            % Extract features and classes
            train_features = train_data{:,3:end};
            test_features  = test_data{:,3:end};
            train_classes  = train_data.Class;
            test_classes   = test_data.Class;

            % Regress covariates, if needed
            if to_regress
                cov_red_train                          = cov_mat{cv_object.training(cv), 2:end};
                cov_red_test                           = cov_mat{cv_object.test(cv),     2:end};
                [train_features{:,loc_regress}, coeff] = regress_covariates(train_features{:,loc_regress}, cov_red_train);
                test_features{:,loc_regress}           = regress_covariates(test_features{:, loc_regress}, cov_red_test, coeff);
            end

            % Standardize data
            [train_features, sc_params]  = feature_scaling(train_features, std_method);
            test_features                = feature_scaling(test_features,  std_method, sc_params);

            % Generate feature ranking
            ranks = get_ranks(train_features, train_classes, ranking);

            % Select features
            train_features = train_features(:, ranks(1:feat_size(fs)));
            test_features  = test_features(:,  ranks(1:feat_size(fs)));

            % Save selected features
            selectedfeat{1,bx}(1:feat_size(fs),cv) = feat_names(ranks(1:feat_size(fs)));

            % Vary sample size and get performance
            for s = 1:length(to_vary)
                tmp  = cvpartition(train_classes, 'HoldOut', to_vary(s));
                tr_f = train_features(tmp.training,:);
                tr_c = train_classes(tmp.training);
                mdl = fitcsvm(tr_f, tr_c, 'BoxConstraint', bc(bx), 'KernelFunction', 'linear', 'Solver', 'SMO', 'Standardize', false);

                % Record sample size
                samplesize(s,cv) = tmp.TrainSize;

                % Training error
                prd = predict(mdl, tr_f);
                train_errors(s,cv) = sum(prd~=tr_c)/length(tr_c);

                % Test error
                prd = predict(mdl, test_features);
                test_errors(s,cv) = sum(prd~=test_classes)/length(test_classes);
            end

            % Update results variable
            results_samplesize{1,bx}(1:size(samplesize,1),cv)   = samplesize(:,cv);
            results_trainerror{1,bx}(1:size(train_errors,1),cv) = train_errors(:,cv);
            results_testerror{1,bx}(1:size(test_errors,1),cv)   = test_errors(:,cv);
        end

        % Add to plot
        hold(all_H(bx), 'on');
        plot(all_H(bx), samplesize, train_errors, 'LineStyle', '--', 'LineWidth', 0.5, 'Color', [153,142,195]./255);
        plot(all_H(bx), samplesize, test_errors, 'LineStyle', '--',  'LineWidth', 0.5, 'Color', [241,163,64]./255);
        plot(all_H(bx), mean(samplesize,2), mean(train_errors,2), 'LineStyle', '-', 'LineWidth', 1.5, 'Color', [153,142,195]./255);
        plot(all_H(bx), mean(samplesize,2), mean(test_errors,2), 'LineStyle', '-', 'LineWidth', 1.5, 'Color', [241,163,64]./255);
        ylim(all_H(bx), [0 0.6]);
        yticks(all_H(bx), 0:0.1:0.6);
        yticklabels(all_H(bx), 0:0.1:0.6);
        xticks(all_H(bx), 'auto');
        xticklabels(all_H(bx), 'auto');
        set(all_H(bx), 'FontSize', 6);
        title(all_H(bx), ['FSize: ', num2str(feat_size(fs)), ', C = ', num2str(bc(bx))], 'FontSize', 7);
        ylabel(all_H(bx), 'Classification error', 'FontSize', 6);
        xlabel(all_H(bx), 'Training sample size', 'FontSize', 6);
        box(all_H(bx), 'off');
    end

    %% Save plots
    print(fullfile(out_dir, ['FeatSize_', num2str(feat_size(fs)), '.png']), '-dpng', '-r600');
    close(fig);

    %% Save variables
    save(fullfile(out_dir, ['FeatSize_', num2str(feat_size(fs)), '.mat']), 'results_samplesize', 'results_testerror', 'results_trainerror', 'bc', 'selectedfeat');
end
end

function ranks = get_ranks(train_features, train_classes, rank_method)
if strcmpi(rank_method, 'median')
    [~, loc_ttest]   = rank_features(train_features, train_classes, 'tstats',        'none', 'none', '');
    [~, loc_wcox]    = rank_features(train_features, train_classes, 'wilcoxon',      'none', 'none', '');
    [~, loc_bhat]    = rank_features(train_features, train_classes, 'bhattacharyya', 'none', 'none', '');
    [~, loc_relieff] = rank_features(train_features, train_classes, 'relieff',       'none', 'none', '');
    [~, loc_mrmr]    = rank_features(train_features, train_classes, 'mrmr',          'none', 'none', '');
    
    % Aggregate rank using medians
    all_locs   = [loc_ttest loc_wcox loc_bhat loc_relieff loc_mrmr];
    [~, ranks] = sort(median(all_locs./size(train_features,2),2), 'ascend');
else
    ranks = rank_features(train_features, train_classes, rank_method, 'none', 'none', '');
end
end