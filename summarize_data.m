function stats = summarize_data(data, variable_names, precision, write_txt, display_plots, write_plots)
% Function to calculate summary statistics of variables; additionally
% allows saving summary statistics as a csv file; plotting and saving of
% the plots is an added functionality
% Parekh, Pravesh
% MBIAL
% January 26, 2018

% Quantiles are calculated by linear interpolation as explained in MATLAB
% documentation

% Parse inputs
if nargin < 1
    error('Not enough arguments');
else
    if ~exist('data', 'var')
        error('Data for calculating statistics not provided');
    else
        % Number of variables = number of columns of data
        num_vars = size(data,2);
        
        if ~exist('variable_names', 'var') || isempty(variable_names)
            variable_names = strcat({'var'}, strtrim(num2str((1:num_vars)')));
        end
        if ~exist('precision', 'var')
            precision = 2;
        end
        if ~exist('write_txt', 'var')
            write_txt = 0;
        end
        if ~exist('display_plots', 'var')
            display_plots = 0;
        end
        if ~exist('write_plots', 'var')
            write_plots = 0;
        end
    end
end

% Check if NaN exists in any of the columns of data; if yes, display
% warning to the user
nan_chk = find(sum(isnan(data(:,:)),1));
if ~isempty(nan_chk)
    warning([strjoin(variable_names(nan_chk), ', '), ' contain NaN values']);
end

% Sort the data in ascending order and find quartiles
data_ascend     = sort(data,1);
Q1              = zeros(1,num_vars);
Q3              = zeros(1,num_vars);
col_counts      = sum(~isnan(data),1);

for vari = 1:num_vars
    % Assign quartiles to each entry of a variable
    qts = ((1:col_counts(vari))-0.5)/col_counts(vari);
    % Get rid of NaNs in the data
    tmp_data = data_ascend(~isnan(data_ascend(:,vari)),vari);
    
    % Working on 25th quartile
    if isempty(nonzeros(qts==0.25))
        % Find points between which to interpolate
        loc = find((qts>=0.25),1);
        % Interpolate data
        Q1(vari) = tmp_data(loc-1) + ((0.25-qts(loc-1))/(qts(loc)-qts(loc-1)))*(tmp_data(loc)-tmp_data(loc-1));
    else
        Q1(vari) = tmp_data(qts==0.25);
    end
    
    % Working on 75th quartile
    if isempty(nonzeros(qts==0.75))
        % Find points between which to interpolate
        loc = find((qts>=0.75),1);
        % Interpolate data
        Q3(vari) = tmp_data(loc-1) + ((0.75-qts(loc-1))/(qts(loc)-qts(loc-1)))*(tmp_data(loc)-tmp_data(loc-1));
    else
        Q3(vari) = tmp_data(qts==0.75);
    end
    clear tmp_data
end
clear vari

outliers     = data < Q1-(1.5*(Q3-Q1)) | data > Q3+(1.5*(Q3-Q1));
[r,k]        = find(outliers);
fmt_outliers = cell(1,num_vars);
for vari = 1:num_vars
    if ~isempty(r(k==vari))
        fmt_outliers{vari} = num2str(r(k==vari)');
    else
        fmt_outliers{vari} = 'None';
    end
end
clear vari

% Populate the stats structure
stats.rawdata                   = data;
stats.count                     = col_counts;
stats.num_NaN                   = sum(isnan(data),1);
stats.total_count               = sum(stats.count + stats.num_NaN,1);
stats.mean                      = mean(data, 1, 'omitnan');
stats.median                    = median(data, 1, 'omitnan');
[stats.mode, stats.mode_count]  = mode(data, 1);
stats.min                       = min(data, [], 'omitnan');
stats.max                       = max(data, [], 'omitnan');
stats.range                     = stats.max - stats.min;
stats.variance                  = var(data, 0, 1, 'omitnan');
stats.standard_deviation        = std(data, 0, 1, 'omitnan');
stats.quantile25th              = Q1;
stats.quantile75th              = Q3;
stats.IQR                       = Q3-Q1;
stats.num_outliers_IQR          = sum(outliers,1);
stats.loc_outliers_IQR          = fmt_outliers;

% Names of all stats fields
stats.names = {'count', 'num_NaN', 'total_count', 'mean', 'median', ...
    'mode', 'mode_count', 'min', 'max', 'range', 'variance', 'standard_deviation', ...
    'quantile25th', 'quantile75th', 'IQR', 'num_outliers_IQR', 'loc_outliers_IQR'};

% Spacing from left
[v,~] = max(cellfun('length', stats.names));
left_spacing = v+5;
left_spaces = repmat(' ', 1, left_spacing);

% Largest number in the data or longest variable name decides column spacing
vari_len = cellfun('length', variable_names);
[v,~] = max(vari_len);
col_spacing = max(length(num2str(max(data(:)))),v)+5;

% Create and display header line
header_line = '';
% Handle case of only one variable
if num_vars > 1
    for vari = 1:num_vars-1
        header_line = [header_line, variable_names{vari}, repmat(' ',1,col_spacing-vari_len(vari))];
    end
header_line = ['Statistics', repmat(' ',1,left_spacing-length('Statistics')), header_line, variable_names{vari+1}];
else
    header_line = ['Statistics', repmat(' ',1,left_spacing-length('Statistics')), header_line, variable_names{1}];
end
disp(header_line);

% Create and display dashes underneath header line
tmp = '';
% Handle case of only one variable
if num_vars > 1
    for vari = 1:num_vars-1
        tmp = [tmp, repmat('-',1,vari_len(vari)), repmat(' ',1,col_spacing-vari_len(vari))];
    end
    tmp = [tmp, repmat('-',1,vari_len(vari+1))];
else
    tmp = [tmp, repmat('-',1,vari_len(1))];
end
dashes = [repmat('-',1,length('Statistics')), repmat(' ',1,left_spacing-length('Statistics')), tmp];
disp(dashes);

% Display results
for st = 1:size(stats.names,2)-1
    to_disp_inner = '';
    tmp_arr = stats.(stats.names{st});
    % Handle case of only one variable
    if num_vars > 1
        for vari = 1:num_vars-1
            tmp = num2str(tmp_arr(vari),['%.', num2str(precision), 'f']);
            to_disp_inner = [to_disp_inner, tmp, repmat(' ',1,col_spacing-length(tmp))];
        end
        to_disp_inner = [to_disp_inner, num2str(tmp_arr(vari+1),['%.', num2str(precision), 'f'])];
    else
        to_disp_inner = [to_disp_inner, num2str(tmp_arr(1),['%.', num2str(precision), 'f'])];
    end
    to_disp = [stats.names{st}, ':', repmat(' ',1,(length(left_spaces)-length(stats.names{st})-1)), to_disp_inner];
    disp(to_disp);
end

% Write results in a tab delimited file if the user wants
if write_txt
    save_dir = '';
    while(isempty(save_dir))
        try
            prompt = ['Saving csv file at: ', strrep(pwd, filesep, [filesep, filesep]), ' Continue [Y/N/C] '];
            reply  = input(prompt, 's');
                if strcmpi(reply, 'n')
                    save_dir = uigetdir(pwd, 'Select directory to save results');
                    if save_dir == 0
                        save_dir = '';
                    end
                else
                    if strcmpi(reply, 'y')
                        save_dir = pwd;
                    else
                        if strcmpi(reply, 'c')
                            break
                        end
                    end
                end
        catch
        end
    end
    if ~isempty(save_dir)
        fid = fopen(fullfile(save_dir, 'summary_stats.txt'), 'w');
        % Print header
        fprintf(fid, '\t');
        % Handle case of only one variable
        if num_vars > 1
            for vari = 1:num_vars-1
                fprintf(fid, '%s\t', variable_names{vari});
            end
            fprintf(fid, '%s\r\n', variable_names{vari+1});
        else
            fprintf(fid, '%s\r\n', variable_names{1});
        end
        
        % Print measure name and stats
        for st = 1:size(stats.names,2)-1
            fprintf(fid, '%s\t', stats.names{st});
            tmp_arr = stats.(stats.names{st});
            % Handle case of only one variable
            if num_vars > 1
                for vari = 1:num_vars-1
                    fprintf(fid, ['%.', num2str(precision), 'f\t'], tmp_arr(vari));
                end
                fprintf(fid, ['%.', num2str(precision), 'f\r\n'], tmp_arr(vari+1));
            else
                fprintf(fid, ['%.', num2str(precision), 'f\r\n'], tmp_arr(1));
            end
        end
        fprintf(fid, '%s\t', stats.names{st+1});
        % Handle case of only one variable
        if num_vars > 1
            for vari = 1:num_vars-1
                fprintf(fid, '%s\t', stats.loc_outliers_IQR{vari});
            end
            fprintf(fid, '%s', stats.loc_outliers_IQR{vari+1});
        else
            fprintf(fid, '%s', stats.loc_outliers_IQR{1});
        end
        fclose(fid);
    end
end