function plot_features(feature_matrix, classes, feature_idx, feature_names, ...
                       out_dir, class_names)
% Function to create 2D scatter plot of a pair of features from a given
% feature matrix for two classes of subjects
%% Inputs:
% feature_matrix:     matrix having columns of features
% classes:            vector indicating which rows of feature_matrix
%                     belong to which class (See Notes)
% feature_idx:        vector containing indices corresponding to columns of
%                     feature_matrix which should be plotted OR 'all'
% feature_names:      a cell array of names of features which will be used
%                     for labeling the x and y axis and also generate
%                     filenames
% out_dir:            location where plots will be saved
% class_names:        a cell array of names of classes to be used for legend
% 
%% Output:
% Pairs of features are taken together and scattered against each other.
% Positive class (class 1) is plotted as red crosses and negative class
% (class 0) is plotted as green circles. A folder named "Feature Plots" is
% created in out_dir and features are saved as png files. An example file
% name is: "Feature_1 vs Feature_2.png". If feature_names is provided,
% those names will be used instead of generic "Feature_x" name.
%
%% Defaults:
% features_names:     names will be created as "Feature_1", etc. In
%                     such a case, the numbering is based on feature_idx 
%                     i.e. if the first feature_idx value is 10, then the 
%                     first feature will be named "Feature_10". 
%                     To avoid confusion, its best to provide feature_names
% feature_idx:        all
% out_dir:            pwd
% class_names:        if no class_names are provided, "class_0", "class_1", 
%                     etc. will be used
% 
%% Notes:
% Function is defined to plot up to 6 classes. However, it is fairly
% straight forward to extend this to as many classes as required. The
% following is the list that explains the colours and symbols used for
% plotting:
%   Case 1: two classes
%           Class 0: green circles (o)
%           Class 1: red crosses (x)
%   Case 2: three classes
%           Class 0: green circles (o)
%           Class 1: red crosses (x)
%           Class 2: blue asterisk (*)
%   Case 3: four classes
%           Class 0: green circles (o)
%           Class 1: red crosses (x)
%           Class 2: blue asterisk (*)
%           Class 3: magenta plus sign (+)
%   Case 4: five classes
%           Class 0: green circles (o)
%           Class 1: red crosses (x)
%           Class 2: blue asterisk (*)
%           Class 3: magenta plus sign (+)
%           Class 4: cyan upward pointing triangle (^)
%   Case 5: six classes
%           Class 0: green circles (o)
%           Class 1: red crosses (x)
%           Class 2: blue asterisk (*)
%           Class 3: magenta plus sign (+)
%           Class 4: cyan upward pointing triangle (^)
%           Class 5: yellow left pointing triangle (<)
%
%% Author(s):
% Parekh, Pravesh
% May 22, 2018
% MBIAL

%% Validate input and assign defaults
% Check if feature_matrix is provided
if ~exist('feature_matrix', 'var')
    error('Feature matrix should be provided');
else
    % Number of features = number of rows
    num_features = size(feature_matrix, 2);
end

% Check if classes have been provided
if ~exist('classes', 'var')
    error('vector indicating classes should be provided');
else
    % Get number of classes
    num_classes = length(unique(classes));
    class_nums  = 0:num_classes-1;
    
    % Check if less than two or more than six classes exist
    if num_classes > 6 || num_classes < 2
        error('Number of classes cannot be less than two or more than six');
    else
        % Define colour and symbol scheme
        scheme_colour = ['g', 'r', 'b', 'm', 'c', 'y'];
        scheme_symbol = ['o', 'x', '*', '+', '^', '<'];
    end
end

% Check if only specific features should be plotted
if ~exist('feature_idx', 'var')
    feature_idx  = 1:num_features;
    num_features = length(feature_idx);
    flag         = 0;
else
    if strcmpi(feature_idx, 'all')
        feature_idx  = 1:num_features;
        num_features = length(feature_idx);
        flag         = 0;
    else
        % Select relevant columns from the input matrix
        feature_matrix = feature_matrix(:, feature_idx);
        num_features   = length(feature_idx);
        flag           = 1;
    end
end
% Check if feature_names have been provided
if ~exist('feature_names', 'var') || isempty(feature_names)
    if num_features < 99
        feature_names = cellstr(strcat('Feature_', num2str(feature_idx(:), '%02d')));
    else
        if num_features > 99 && num_features < 999
            feature_names = cellstr(strcat('Feature_', num2str(feature_idx(:), '%03d')));
        else
            feature_names = cellstr(strcat('Feature_', num2str(feature_idx(:), '%04d')));
        end
    end
end

% Check if out_dir is provided
if ~exist('out_dir', 'var') || isempty(out_dir)
    out_dir = pwd;
end

% Check if class_names are provided
if ~exist('class_names', 'var')
    class_names = cellstr(strcat('Class', {' '}, num2str(class_nums(:))));
else
    % Ensure that correct number of class_names are provided
    if length(class_names) ~= num_classes
        error('Incorrect number of class_names provided');
    end
end

% Sanity check: check if number of subjects and number of classes are equal
% Check if number of features and number names of feature are the same
if size(feature_matrix, 1)     ~= length(classes)        || ...
        size(feature_names, 1) ~= size(feature_matrix, 2)
    error(['Incorrect combination of number of subjects: ', ...
        num2str(size(feature_matrix, 1)), ...
        ' and number of classes: ', num2str(length(classes)), ...
        'OR number of features: ', num2str(size(feature_names, 2)), ...
        ' and number of names of features: ', num2str(size(feature_names, 1))]);
end

% Create Feature Plots directory in out_dir
out_dir = fullfile(out_dir, 'Feature Plots');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

%% Decide which pairs of features to plot
% If only a subset of features were requested, reassign feature_idx to
% start from 1 to prevent problems later
if flag
    feature_idx = 1:length(feature_idx);
end
feature_pairs = nchoosek(feature_idx, 2);

%% Let the user know the number of plots that will be created!
disp([num2str(length(feature_pairs)), ' plots will be created. ', ...
     'You can press Ctrl+C to break operation']);
 
%% Start making plots!
for plot_var = 1:length(feature_pairs)
    
    % Create figure approximately half the size of an A4 paper
    fig = figure('Units', 'centimeters', 'Position', [10 10 14 09]);
    
    % Loop over number of classes
    for class_var = 1:num_classes
        scatter(feature_matrix(classes==class_var-1, feature_pairs(plot_var,1)), ...
                feature_matrix(classes==class_var-1, feature_pairs(plot_var,2)), ...
                60, scheme_colour(class_var), scheme_symbol(class_var));
         hold on
    end
    
    % X axis label
    xlabel(feature_names(feature_pairs(plot_var,1)), ...
        'Interpreter', 'none', 'FontWeight', 'bold');
    
    % Y axis label
    ylabel(feature_names(feature_pairs(plot_var,2)), ...
        'Interpreter', 'none', 'FontWeight', 'bold');
    
    % Title of the figure
    heading = [feature_names{feature_pairs(plot_var,1)}, ' vs ', ...
           feature_names{feature_pairs(plot_var,2)}];
    title(heading, 'Interpreter', 'none');
    
    % Legend
    l = legend(class_names, 'Orientation', 'horizontal', ...
           'Location', 'southoutside');
       
    % Turn interpreter off for legend to allow for underscores
    set(l, 'Interpreter', 'none');
    
    % Save the plot
    fname = fullfile(out_dir, [heading, '.png']);
    print('-dpng', fname, '-r600');
    
    % Close the figure
    close(fig);
end