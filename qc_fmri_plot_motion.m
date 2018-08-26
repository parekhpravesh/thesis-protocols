function qc_fmri_plot_motion(data_dir, task_name, full_bids)
% Function to create graphics of motion profiles calculated by RMS, DVARS,
% and FD methods
%% Inputs:
% data_dir:         full path to a directory having sub-* folders (BIDS
%                   style; see Notes)
% task_name:        functional file name pattern for which QC is being 
%                   performed (example: 'rest')
% full_bids:        yes/no to indicate if the data_dir is a full BIDS style
%                   folder (i.e. it has anat and func sub-folders) or all 
%                   files are present in a single folder (see Notes)
% 
%% Outputs:
% Within the already existing 'quality_check_<task_name>' in each subject's
% folder, a single image having all three kinds of motions plotted is
% created. This image is named <subject_ID>_<task_name>_motion_profile.png;
% if design is availble, the design of the experiment is also shown along
% with the plot. Outlier information across all three methods are saved in
% a single mat file named <subject_ID>_<task)name>_motion_profile.mat
% 
%% Notes:
% Each sub-* folder should have a quality_check_<task_name> folder (created
% by qc_fmri_roi_signal)
% 
% Full BIDS specification means that there are separate anat and func
% folders inside the subject folder; if specified as no, the files should
% still be named following BIDS specification but all files are assumed to
% be in the same folder
% 
%% Default:
% full_bids:        'yes'
% 
%% Author(s)
% Parekh, Pravesh
% August 24, 2018
% MBIAL

%% Validate input and assign defaults
% Check data_dir
if ~exist('data_dir', 'var') || isempty(data_dir)
    error('data_dir needs to be given');
else
    if ~exist(data_dir, 'dir')
        error(['Unable to find data_dir: ', data_dir]);
    end
end

% Check task_name
if ~exist('task_name', 'var') || isempty(task_name)
    error('task_name needs to be given');
end

% Check full_bids
if ~exist('full_bids', 'var') || isempty(full_bids)
    full_bids = 1;
else
    if strcmpi(full_bids, 'yes')
        full_bids = 1;
    else
        if strcmpi(full_bids, 'no')
            full_bids = 0;
        else
            error(['Invalid full_bids value specified: ', full_bids]);
        end
    end
end

%% Create subject list
cd(data_dir);
list_subjs = dir('sub-*');
num_subjs  = length(list_subjs);

%% Check if task design is available
if strcmpi(task_name, 'rest')
    design = 0;
else
    try
        task_design = get_fmri_task_design_spm(task_name, 'scans');
        design = 1;
    catch
        design = 0;
    end
end

%% Number of time points
if full_bids
    tmp_data = dlmread(fullfile(data_dir, list_subjs(1).name, 'func', ...
                       ['quality_check_', task_name],       ...
                       [list_subjs(1).name, '_', task_name, '_refRMS.txt']));
else
    tmp_data = dlmread(fullfile(data_dir, list_subjs(1).name,     ...
                       ['quality_check_', task_name],   ...
                       [list_subjs(1).name, '_', task_name, '_refRMS.txt']));
end
num_time_points = length(tmp_data);
time_points     = 1:num_time_points;
clear tmp_data;

%% Colour scheme
% Colour scheme 12-class Paired from colorbrewer2 by Cynthia Brewer
colour_scheme = [166 206 227; 178 223 138; 251 154 153; 253 191 111; ...
                 202 178 214; 255 255 153; 31  120 180; 51  160  44; ...
                 227 26  28;  255 127   0; 106 61  154; 177  89  40]./255;
             
% Plot, outlier, and threshold colour based on 3-class Dark2 from 
% colorbrewer2 by Cynthia Brewer
plot_colour      = [117 112 179]./255;
outlier_colour   = [217 95    2]./255;
threshold_colour = [27 158 119]./255;

%% Font style
if ~isunix
    fontname = 'consolas';
else
    fontname = 'DejaVu Sans';
end
fontsize = 9;

%% Work on each subject
for sub = 1:num_subjs
    % Locate quality_check folder
    if full_bids
        qc_dir = fullfile(data_dir, list_subjs(sub).name, 'func', ...
                          ['quality_check_', task_name]);
    else
        qc_dir = fullfile(data_dir, list_subjs(sub).name, ...
                          ['quality_check_', task_name]);
    end
    
    if ~exist(qc_dir, 'dir')
        warning(['Cannot locate quality_check_', task_name, ' for ', ...
                list_subjs(sub).name, '; skipping']);
    else
        cd(qc_dir);
        template_name = [list_subjs(sub).name, '_', task_name];
        
        %% Read txt and var file for all three methods
        refRMS_data     = dlmread([template_name, '_refRMS.txt'], '%d');
        refRMS_outliers = dlmread([template_name, '_refRMS_var.txt'], '%d');
        dvars_data      = dlmread([template_name, '_DVARS.txt'], '%d');
        dvars_outliers  = dlmread([template_name, '_DVARS_var.txt'], '%d');
        FD_data         = dlmread([template_name, '_FD.txt'], '%d');
        FD_outliers     = dlmread([template_name, '_FD_var.txt'], '%d');

        %% Compile information
        % refRMS
        outlier.refRMS.num_outliers = size(refRMS_outliers, 2);
        [outlier.refRMS.outliers,~] = find(refRMS_outliers);
        outlier.refRMS.threshold    = quantile_iqr(refRMS_data, num_time_points);
        outlier.refRMS.minimum      = min(refRMS_data(refRMS_data>0));
        outlier.refRMS.maximum      = max(refRMS_data);
        
        % DVARS
        outlier.dvars.num_outliers  = size(dvars_outliers, 2);
        [outlier.dvars.outliers,~]  = find(dvars_outliers);
        outlier.dvars.threshold     = quantile_iqr(dvars_data, num_time_points);
        outlier.dvars.minimum       = min(dvars_data(dvars_data>0));
        outlier.dvars.maximum       = max(dvars_data);
        
        % FD
        outlier.FD.num_outliers     = size(FD_outliers, 2);
        [outlier.FD.outliers,~]     = find(FD_outliers);
        outlier.FD.threshold        = quantile_iqr(FD_data, num_time_points);
        outlier.FD.minimum          = min(FD_data(FD_data>0));
        outlier.FD.maximum          = max(FD_data);

        % Additional outlier information
        outlier.total_outliers      = unique([outlier.refRMS.outliers; ...
                                              outlier.dvars.outliers;  ...
                                              outlier.FD.outliers]);
        outlier.num_total_outliers  = length(outlier.total_outliers);
        outlier.common_outliers     = intersect(intersect(outlier.refRMS.outliers, ...
                                                          outlier.dvars.outliers), ...
                                                          outlier.FD.outliers);
        outlier.num_common_outliers = length(outlier.common_outliers);
        
        % Subject specific information
        outlier.subject_name        = list_subjs(sub).name;
        outlier.num_time_points     = num_time_points;
        outlier.task_name           = task_name;
        
        %% Save this variable
        save_name = fullfile(qc_dir, [list_subjs(sub).name, '_', task_name, ...
                             '_motion_profile.mat']);
        save(save_name, 'outlier');
        
        %% Create plot
        if design
            num_subplots = 4;
        else
            num_subplots = 3;
        end
        count = 1;
        fig = figure('Color', [1 1 1], 'PaperType', 'A4', 'PaperUnits', ...
                     'centimeters', 'PaperPosition', [0 0 15 20], ...
                     'InvertHardCopy', 'off', 'Visible', 'off');
        
        %% Task design if possible
        if design
            subplot(num_subplots, 1, count);
            
            % Create design for each condition
            for cond = 1:length(task_design.cond)
                for onset = 1:length(task_design.cond(cond).onset)
                    
                    % Get locations of the bars
                    to_plot = task_design.cond(cond).onset(onset)+1:...
                              task_design.cond(cond).onset(onset)+  ...
                              task_design.cond(cond).duration;
                          
                          % If more than 12 conditions are present, let
                          % MATLAB do the colour selection
                          if length(task_design.cond) > 12
                              h(cond) = bar(to_plot, ones(length(to_plot),1), ...
                                            1, 'EdgeAlpha', 0);
                          else
                              h(cond) = bar(to_plot, ones(length(to_plot),1), ...
                                            1, 'FaceColor', ...
                                            colour_scheme(cond, :), ...
                                            'EdgeAlpha', 0);
                          end
                    hold on
                end
            end
            
            % Axis customization
            xlim([0 num_time_points]);
            xticks(0:10:num_time_points);
            yticks([]);
            box off
            
            % Legend text
            text = cell(length(task_design.cond),1);
            for cond = 1:length(task_design.cond)
                text{cond} = task_design.cond(cond).name;
            end
            legend(h, text, 'Location', 'southoutside', 'FontName', fontname, ...
                   'Orientation', 'horizontal')
            count = count + 1;   
        end
        
        %% refRMS plot
        subplot(num_subplots, 1, count);
        plot(refRMS_data, 'Color', plot_colour, 'LineWidth', 1);
        hold on
        
        % Adding threshold line
        plot(repmat(outlier.refRMS.threshold, num_time_points, 1), ...
            'Color', threshold_colour, 'LineStyle', '--', 'LineWidth', 1);
        
        % Marking outliers
        plot(time_points(outlier.refRMS.outliers), ...
             refRMS_data(outlier.refRMS.outliers), ...
             'p', 'MarkerSize', 6, 'MarkerEdgeColor', outlier_colour)
        
        % Adding legend
        legend({'refRMS', ['threshold = ', num2str(outlier.refRMS.threshold)], ...
                'outliers'}, 'Location', 'southoutside', 'Orientation', 'horizontal', ...
                'FontName', fontname);
         
        % Axis customization
        xlim([1 num_time_points+1]);
        ax = gca;
        ax.XTick = 0:10:num_time_points;
        box off
        
        % Creating title
        num_lines = ceil(length(outlier.refRMS.outliers)/10);
        num_blank = length([list_subjs(sub).name, ' ', task_name, ' refRMS: ']);
        start_loc = 1;
        text = cell(num_lines,1);
        for line = 1:num_lines
            if line == num_lines
                text{line} = num2str((outlier.refRMS.outliers(start_loc:end))', '%03d, ');
            else
                text{line} = num2str((outlier.refRMS.outliers(start_loc:start_loc+9))', '%03d, ');
            end
            % Add blanks if necessary
            if line ~= 1
                text{line} = [blanks(num_blank), text{line}];
            end
            start_loc = start_loc + 10;
        end
        
        % Remove last character from the last line (extra comma)
        text{end}(end) = '';
        
        % Add subject name, task name, and refRMS in the first line
        text{1} = [list_subjs(sub).name, ' ', task_name, ' refRMS: ', text{1}];
        
        % Show title
        if num_lines == 1
            title(text, 'FontName', fontname, 'FontSize', fontsize);
        else
            t = title(text, 'FontName', fontname, 'FontSize', fontsize, ...
                      'HorizontalAlignment', 'left');
            t_loc = get(t, 'Position');
            set(t, 'Position', [0.8 t_loc(2) t_loc(3)]);
        end
        count = count + 1;
        
        %% DVARS plot
        subplot(num_subplots, 1, count);
        plot(dvars_data, 'Color', plot_colour, 'LineWidth', 1);
        hold on
        
        % Adding threshold line
        plot(repmat(outlier.dvars.threshold, num_time_points, 1), ...
            'Color', threshold_colour, 'LineStyle', '--', 'LineWidth', 1);
        
        % Marking outliers
        plot(time_points(outlier.dvars.outliers), ...
             dvars_data(outlier.dvars.outliers), ...
             'p', 'MarkerSize', 6, 'MarkerEdgeColor', outlier_colour)
        
        % Adding legend
        legend({'DVARS', ['threshold = ', num2str(outlier.dvars.threshold)], ...
                'outliers'}, 'Location', 'southoutside', 'Orientation', 'horizontal', ...
                'FontName', fontname);
            
        % Axis customization
        xlim([1 num_time_points+1]);
        ax = gca;
        ax.XTick = 0:10:num_time_points;
        box off
        
        % Creating title
        num_lines = ceil(length(outlier.dvars.outliers)/10);
        num_blank = length([list_subjs(sub).name, ' ', task_name, ' DVARS: ']);
        start_loc = 1;
        text = cell(num_lines,1);
        for line = 1:num_lines
            if line == num_lines
                text{line} = num2str((outlier.dvars.outliers(start_loc:end))', '%03d, ');
            else
                text{line} = num2str((outlier.dvars.outliers(start_loc:start_loc+9))', '%03d, ');
            end
            % Add blanks if necessary
            if line ~= 1
                text{line} = [blanks(num_blank), text{line}];
            end
            start_loc = start_loc + 10;
        end
        
        % Remove last character from the last line (extra comma)
        text{end}(end) = '';
        
        % Add subject name, task name, and DVARS in the first line
        text{1} = [list_subjs(sub).name, ' ', task_name, ' DVARS: ', text{1}];
        
        % Show title
        if num_lines == 1
            title(text, 'FontName', fontname, 'FontSize', fontsize);
        else
            t = title(text, 'FontName', fontname, 'FontSize', fontsize, ...
                      'HorizontalAlignment', 'left');
            t_loc = get(t, 'Position');
            set(t, 'Position', [0.8 t_loc(2) t_loc(3)]);
        end
        count = count + 1;
        
        %% FD plot
        subplot(num_subplots, 1, count);
        plot(FD_data, 'Color', plot_colour, 'LineWidth', 1);
        hold on
        
        % Adding threshold line
        plot(repmat(outlier.FD.threshold, num_time_points, 1), ...
            'Color', threshold_colour, 'LineStyle', '--', 'LineWidth', 1);
        
        % Marking outliers
        plot(time_points(outlier.FD.outliers), ...
             FD_data(outlier.FD.outliers), ...
             'p', 'MarkerSize', 6, 'MarkerEdgeColor', outlier_colour)
        
        % Adding legend
        legend({'FD', ['threshold = ', num2str(outlier.FD.threshold)], ...
                'outliers'}, 'Location', 'southoutside', 'Orientation', 'horizontal', ...
                'FontName', fontname);
            
        % Axis customization
        xlim([1 num_time_points+1]);
        ax = gca;
        ax.XTick = 0:10:num_time_points;
        box off
        
        % Creating title
        num_lines = ceil(length(outlier.FD.outliers)/10);
        num_blank = length([list_subjs(sub).name, ' ', task_name, ' FD: ']);
        start_loc = 1;
        text = cell(num_lines,1);
        for line = 1:num_lines
            if line == num_lines
                text{line} = num2str((outlier.FD.outliers(start_loc:end))', '%03d, ');
            else
                text{line} = num2str((outlier.FD.outliers(start_loc:start_loc+9))', '%03d, ');
            end
            % Add blanks if necessary
            if line ~= 1
                text{line} = [blanks(num_blank), text{line}];
            end
            start_loc = start_loc + 10;
        end
        
        % Remove last character from the last line (extra comma)
        text{end}(end) = '';
        
        % Add subject name, task name, and FD in the first line
        text{1} = [list_subjs(sub).name, ' ', task_name, ' FD: ', text{1}];
        
        % Show title
        if num_lines == 1
            title(text, 'FontName', fontname, 'FontSize', fontsize);
        else
            t = title(text, 'FontName', fontname, 'FontSize', fontsize, ...
                      'HorizontalAlignment', 'left');
            t_loc = get(t, 'Position');
            set(t, 'Position', [0.8 t_loc(2) t_loc(3)]);
        end
        
        % Save and close the figure
        save_name = fullfile(qc_dir, [list_subjs(sub).name, '_', ...
                             task_name, '_motion_profile.png']);
        print(fig, save_name, '-dpng', '-r600');
        close(fig);
    end
    
    % Clear some variables
    clear outlier save_name fig t t_loc text num_lines line num_blank ax ...
          count h cond onset to_plot
end

function threshold = quantile_iqr(data, num_time_points)
% Calculates the 75th percentile and the inter-quartile range and returns 
% the threshold used for outlier identification (Q3+1.5*IQR).
% Quantiles are calclated using the linear interpolation method described 
% in MATLAB documentation; assumes no NaN values

% Sort the data in ascending order and find quartiles
data_ascend = sort(data,1);

% Assign quartiles to each entry
qts = (1:num_time_points-0.5)/num_time_points;

% Working on 25th quartile
if isempty(nonzeros(qts==0.25))
    % Find points between which to interpolate
    loc = find((qts>=0.25),1);
    % Interpolate data
    Q1 = data_ascend(loc-1) + ((0.25-qts(loc-1))/(qts(loc)-qts(loc-1)))*(data_ascend(loc)-data_ascend(loc-1));
else
    Q1 = data_ascend(qts==0.25);
end

% Working on 75th quartile
if isempty(nonzeros(qts==0.75))
    % Find points between which to interpolate
    loc = find((qts>=0.75),1);
    % Interpolate data
    Q3 = data_ascend(loc-1) + ((0.75-qts(loc-1))/(qts(loc)-qts(loc-1)))*(data_ascend(loc)-data_ascend(loc-1));
else
    Q3 = data_ascend(qts==0.75);
end

% Calculate IQR
iqr = Q3-Q1;

% Threshold = Q3+1.5*IQR
threshold = Q3+1.5*iqr;