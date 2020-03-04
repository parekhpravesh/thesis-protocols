function compare_examcards_alt(source_examcard, target_examcard)
% Function to compare a set of examcards with a source examcard
% Designed for Philips Ingenia CX
%% Inputs:
% source_examcard:      full path to a text file having source exxamcard
%                       for a given sequence
% target_examcard:      full path to a text file or a list of text file
%                       (passed as a row of cell type) having examcards 
%                       which need to be compared for the given sequence 
% 
%% Output: 
% A csv file is written out in the present working directory comparing all
% the target examcards with the source examcard. The file is named as:
% compare_examcards_<DDMMMYYYY>.csv
% 
%% Notes:
% When comparing examcards, if the number of entires varies between source
% and destination examcard, a warning is generated
% 
%% Author(s):
% Parekh, Pravesh
% June 08, 2018
% MBIAL

%% Validate input
if ~exist('source_examcard', 'var')
    error('Source examcard should be provided');
else
    if ischar(source_examcard)
        % Convert to cell
        source_examcard = cellstr(source_examcard);
    end
    if ~exist(source_examcard{1}, 'file')
        error('Source examcard file not found');
    end
end

if ~exist('target_examcard', 'var')
    error('At least one target examcard should be provided');
else
    if ischar(target_examcard)
        % Convert to cell
        target_examcard = cellstr(target_examcard);
    end
end

num_target_cards = size(target_examcard, 1);

%% Read in source examcard
fid = fopen(source_examcard{1}, 'r');
source = textscan(fid, '%q%q', 'Delimiter', {' ='}, 'MultipleDelimsAsOne', true);
source = [source{1},source{2}];
fclose(fid);

% Replace all semicolons
source = regexprep(source, ';', '');

%% Initialize comparison variable
compare_fields      = cell(length(source), num_target_cards+1);
compare_fields(:,1) = source(:,1);

%% Get file names and create header for table
[~, source_filename, ~] = fileparts(source_examcard{1});
if isempty(source_filename)
    source_filename = source_examcard{1};
end
target_filename = cell(1,num_target_cards);

for files = 1:num_target_cards
    [~, target_filename{files}, ~] = fileparts(target_examcard{files});
    if isempty(target_filename{files})
        target_filename{files} = target_examcard{files};
    end
    target_filename{files} = regexprep(target_filename{files}, ' ', '_');
end

header_names = [{'Fieldnames'}, source_filename, target_filename(:)'];

%% Work on destination examcards and compare
for card = 1:num_target_cards
    % Read examcard
    fid = fopen(target_examcard{card}, 'r');
    target = textscan(fid, '%q%q', 'Delimiter', {' ='}, 'MultipleDelimsAsOne', true);
    target = [target{1},target{2}];
    fclose(fid);
    
    % Replace all semicolons
    target = regexprep(target, ';', '');
    
    % Scroll through the destination fields and find out if any field
    % unavailble in compare_fields is present
    for locs = 1:length(target)
        if isempty(nonzeros(strcmpi(target(locs,1), compare_fields(:,1))))
             % Grow compare_fields and source if new entries are found
             compare_fields(end+1,1) = target(locs,1);
             compare_fields(end,2)   = {'NA'};
             source(end+1,1)         = target(locs,1);
             source(end,2)           = {'NA'};
        end
    end

    % Loop over fields in compare_fields
    for fields = 1:length(compare_fields)
        % Add the particular field's value of source to compare_field
        compare_fields(fields,2) = source(fields,2);
        
        % Find the field in target
        loc = strcmpi(target(:,1), compare_fields(fields,1));
        loc = find(loc,1);
        
        % If not found, write NA and display warning
        if isempty(loc)
            compare_fields(fields,2+card) = {'NA'};
            warning(['Skipping some info for ', compare_fields{fields,1}, ...
                    ' for card: ', target_examcard{card}]);
        else
            % Add that value to compare_fields
            compare_fields(fields,2+card) = target(loc,2);
            
            % Remove that field and value from target
            target(loc,:) = [];
        end
    end
end

%% Convert to table
compare_fields = compare_fields';
header = compare_fields(1,:);
new_var_names = matlab.lang.makeValidName(header);
new_var_names = matlab.lang.makeUniqueStrings(new_var_names);
results = cell2table(compare_fields(2:end,:), 'VariableNames', new_var_names, 'RowNames', header_names(2:end));

%% Write out as csv
filename = fullfile(pwd, ['subjectwise_compare_examcards_', datestr(now, 'ddmmmyyyy'), '.xlsx']);
writetable(results, filename, 'WriteRowNames', true);