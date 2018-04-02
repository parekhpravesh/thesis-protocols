function nifti_to_bids(nifti_dir, bids_dir)
% Function to reorganize NIfTI directory to BIDS style
%% Input:
% nifti_dir:    full path to NIfTI directory
% bids_dir:     full path to location where bids_dir needs to be created
%
%% Output:
% bids_dir is created and files are copied and renamed to match BIDS
% specification v1.0.2; a summary file is written in bids_dir/summary named
% summary_nifti_to_bids_ddmmmyyyy.txt
%
%% Notes:
% All folders present in nifti_dir are assumed to be subject folders
%
% If a subject folder already exists in bids_dir, then that subject is
% skipped entirely
%
% Assumes nifti_dir structure:
%
% <nifti_dir>/
%
%   sub-<participant_label>/
%       <NIfTI and JSON files for this subject>
%   sub-<participant_label>/
%
%% Default:
% If bids_dir is not provided, it is created at one level above nifti_dir
%
%% Author(s):
% Parekh, Pravesh
% April 02, 2018
% MBIAL

%% Check input and create bids_dir if needed
if ~exist('nifti_dir', 'var')
    error('nifti_dir needs to be provided');
else
    if ~exist(nifti_dir, 'dir')
        error(['Cannot find nifti_dir: ', nifti_dir]);
    else
        if ~exist('bids_dir', 'var')
            % Go a level above nifti_dir and create bids_dir
            cd(nifti_dir);
            cd('..');
            bids_dir = fullfile(pwd, 'bids_dir');
            if ~exist('bids_dir', 'dir')
                mkdir('bids_dir');
            end
        else
            if ~exist(bids_dir, 'dir')
                error(['Cannot find bids_dir: ', bids_dir]);
            end
        end
    end
end

%% Create subject list
cd(nifti_dir);
list_subjs = dir;

% Remove any files that might have been listed
list_subjs(~[list_subjs.isdir]) = [];

% Convert to cell type and remove other structure fields
list_subjs = {list_subjs(:).name};

% Remove . and .. directories
list_subjs(ismember(list_subjs, {'.', '..'})) = [];

% Total number of subjects to work on
num_subjs = length(list_subjs);

%% Prepare summary file
% Create summary folder if it does not exist
if ~exist(fullfile(bids_dir, 'summary'), 'dir')
    mkdir(fullfile(bids_dir, 'summary'));
end

% Name summary file
summary_loc = fullfile(bids_dir, 'summary', ...
    ['summary_nifti_to_bids_', datestr(now, 'ddmmmyyyy'), '.txt']);

% Check if file exists; if yes, append; else create a new one
if exist(summary_loc, 'file')
    fid_summary = fopen(summary_loc, 'a');
else
    fid_summary = fopen(summary_loc, 'w');
end

% Save some information
fprintf(fid_summary, '%s\r\n', ['Date:         ', datestr(now, 'ddmmmyyyy')]);
fprintf(fid_summary, '%s\r\n', ['Time:         ', datestr(now, 'HH:MM:SS PM')]);
fprintf(fid_summary, '%s\r\n', ['nifti_dir:    ', nifti_dir]);
fprintf(fid_summary, '%s\r\n', ['bids_dir:     ', bids_dir]);

% Update summary with number of subjects
disp([num2str(num_subjs), ' subjects found']);
fprintf(fid_summary, '%s\r\n', [num2str(num_subjs), ' subjects found']);

%% Work on individual subjects
for subj = 1:num_subjs
    
    % Update summary
    disp(['Working on: ', list_subjs{subj}]);
    fprintf(fid_summary, '\n%s\r\n', ['Working on: ', list_subjs{subj}]);
    
    % Check if sub- tag is necessary
    if strcmpi(list_subjs{subj}(1:4), 'sub-')
        subj_tag = list_subjs{subj};
    else
        subj_tag = ['sub-', list_subjs{subj}];
    end
    
    % Create full path to subject source directory
    subj_path = fullfile(nifti_dir, list_subjs{subj});
    
    % Check if folder already exists in bids_dir
    if exist(fullfile(bids_dir, subj_tag), 'dir')
        
        % Skip this subject; update summary and move on
        disp([list_subjs{subj}, ' folder exists in bids_dir; skipping']);
        fprintf(fid_summary, '\n%s\r\n', [list_subjs{subj}, ...
            ' folder exists in bids_dir; skipping']);
        continue
        
    else
        % Make subject folder in bids_dir
        mkdir(fullfile(bids_dir, subj_tag));
        
        cd(subj_path);
        
        % Get all NIfTI files present for the subject and convert to cell
        list_nii_files = dir('*.nii');
        list_nii_files = {list_nii_files(:).name};
        
        % Remove survey scan files if present
        list_nii_files(~cellfun(@isempty, regexpi(list_nii_files, 'survey')))   = [];
        
        % Remove ADC files if present
        list_nii_files(~cellfun(@isempty, regexpi(list_nii_files, 'ADC')))      = [];
        
        % Remove in-plane files if present
        list_nii_files(~cellfun(@isempty, regexpi(list_nii_files, 'inplane')))  = [];
        
        % Loop over all remaining images
        for file = 1:length(list_nii_files)
            %% Check if this file is potentially a T1w file
            if ~isempty(cell2mat(regexpi(list_nii_files(file), {'T1', 'MPR'})))
                
                % Create anat folder if needed
                if ~exist(fullfile(bids_dir, subj_tag, 'anat'), 'dir')
                    mkdir(fullfile(bids_dir, subj_tag, 'anat'));
                end
                
                % Create source and destination file
                source_file = fullfile(subj_path, list_nii_files{file});
                dest_file   = fullfile(bids_dir, subj_tag, ...
                    'anat', [subj_tag, '_T1w.nii']);
                
                % Check if destination file already exists
                if exist(dest_file, 'file')
                    
                    % Loop till a suitable new name can be generated
                    count = 1;
                    while 1
                        dest_file = fullfile(bids_dir, ...
                            subj_tag, 'anat', ...
                            [subj_tag, ...
                            '_T1w_', num2str(count), '.nii']);
                        
                        if ~exist(dest_file, 'file')
                            break
                        else
                            count = count + 1;
                        end
                    end
                end
                
                % Copy this file to bids_dir
                copyfile(source_file, dest_file);
                
                % Copy associated JSON file to bids_dir
                source_file = [strrep(source_file, '.nii', ''), '.json'];
                dest_file   = [strrep(dest_file,   '.nii', ''), '.json'];
                copyfile(source_file, dest_file);
                
            else
                %% Check if this file is potentially a DWI file
                if ~isempty(cell2mat(regexpi(list_nii_files(file), ...
                        {'dwi', 'dti', 'diff'})))
                    
                    % Create dwi folder if needed
                    if ~exist(fullfile(bids_dir, subj_tag, 'dwi'), 'dir')
                        mkdir(fullfile(bids_dir, subj_tag, 'dwi'));
                    end
                
                    % Create source file name
                    source_file = fullfile(subj_path, list_nii_files{file});
                    
                    % Check filename and find out the kind of dwi file
                    if ~isempty(regexpi(list_nii_files{file}, 'mb'))
                        token_out = 'mb';
                    else
                        if ~isempty(regexpi(list_nii_files{file}, 'rev|PA|_P'))
                            token_out = 'PA';
                        else
                            if ~isempty(regexpi(list_nii_files{file}, 'fwd|AP|_A'))
                                token_out = 'AP';
                            else
                                token_out = 'gen';
                            end
                        end
                    end
                    
                    % Create destination file name
                    dest_file = fullfile(bids_dir, subj_tag, ...
                        'dwi', [subj_tag, '_acq-', token_out,...
                        '_dwi.nii']);
                    
                    % Check if destination file already exists
                    if exist(dest_file, 'file')
                        
                        % Loop till a suitable new name can be generated
                        count = 1;
                        while 1
                            dest_file = fullfile(bids_dir, ...
                                subj_tag, 'dwi', ...
                                [subj_tag, ...
                                '_acq-', token_out, '_dwi_', ...
                                num2str(count), '.nii']);
                            
                            if ~exist(dest_file, 'file')
                                break
                            else
                                count = count + 1;
                            end
                        end
                    end
                    
                    % Copy this file to bids_dir
                    copyfile(source_file, dest_file);
                    
                    % Copy associated JSON file to bids_dir
                    source_file = [strrep(source_file, '.nii', ''), '.json'];
                    dest_file   = [strrep(dest_file,   '.nii', ''), '.json'];
                    copyfile(source_file, dest_file);
                    
                    % Copy associated bval file to bids_dir
                    source_file = [strrep(source_file, '.json', ''), '.bval'];
                    dest_file   = [strrep(dest_file,   '.json', ''), '.bval'];
                    copyfile(source_file, dest_file);
                    
                    % Copy associated bvec file to bids_dir
                    source_file = [strrep(source_file, '.bval', ''), '.bvec'];
                    dest_file   = [strrep(dest_file,   '.bval', ''), '.bvec'];
                    copyfile(source_file, dest_file);
                    
                else
                    %% Check if this file is potentially a fieldmap file
                    if ~isempty(cell2mat(regexpi(list_nii_files(file), 'fmap')))
                        
                        % Create fmap folder if needed
                        if ~exist(fullfile(bids_dir, subj_tag,...
                                'fmap'), 'dir')
                            mkdir(fullfile(bids_dir, subj_tag,...
                                'fmap'));
                        end
                        
                        % Create source file name
                        source_file = fullfile(subj_path, list_nii_files{file});
                        
                        % Check if task name is mentioned in file name
                        if ~isempty(cell2mat(regexpi(...
                                list_nii_files(file), 'vft')))
                            token_task = 'vftmodern';
                        else
                            if ~isempty(cell2mat(regexpi(...
                                    list_nii_files(file), 'pm')))
                                token_task = 'pm';
                            else
                                if ~isempty(cell2mat(regexpi(...
                                        list_nii_files(file), 'hamt')))
                                    token_task = 'hamths';
                                else
                                    if ~isempty(cell2mat(regexpi(...
                                            list_nii_files(file), 'hamtsz')))
                                        token_task = 'hamtsz';
                                    else
                                        if ~isempty(cell2mat(regexpi(...
                                                list_nii_files(file), 'rest|rsf')))
                                            token_task = 'rest';
                                        else
                                            token_task = 'gen';
                                        end
                                    end
                                end
                            end
                        end
                        
                        
                        % Decide if phase or magnitude
                        if ~isempty(cell2mat(regexpi(list_nii_files(file), 'ph')))
                            token_type = 'phase';
                        else
                            token_type = 'magnitude';
                        end
                        
                        % Decide first or second echo
                        if ~isempty(cell2mat(regexpi(list_nii_files(file), 'e1')))
                            token_echo = '1';
                        else
                            token_echo = '2';
                        end
                        
                        % Create destination name
                        dest_file = fullfile(bids_dir, subj_tag, ...
                            'fmap', [subj_tag, '_acq-', ... 
                            token_task, '_', token_type, token_echo, '.nii']);
                        
                        % Check if destination file already exists
                        if exist(dest_file, 'file')
                            
                            % Loop till a suitable new name can be generated
                            count = 1;
                            while 1
                                dest_file = fullfile(bids_dir, subj_tag, ...
                                    'fmap', [subj_tag, '_acq-', ...
                                    token_task, '_', token_type, token_echo, ...
                                    '_', num2str(count), '.nii']);
                                
                                if ~exist(dest_file, 'file')
                                    break
                                else
                                    count = count + 1;
                                end
                            end
                        end
                        
                        % Copy this file to bids_dir
                        copyfile(source_file, dest_file);
                        
                        % Copy associated JSON file to bids_dir
                        source_file = [strrep(source_file, '.nii', ''), '.json'];
                        dest_file   = [strrep(dest_file,   '.nii', ''), '.json'];
                        copyfile(source_file, dest_file);
                        
                    else
                        %% Check if this file is potentially an fMRI file
                        if ~isempty(cell2mat(regexpi(list_nii_files(file),...
                                'fmri|task|rsf|dmn|rest|vft|pm|hamt')))
                            
                            % Create func folder if needed
                            if ~exist(fullfile(bids_dir, subj_tag, 'func'), 'dir')
                                mkdir(fullfile(bids_dir, subj_tag, 'func'));
                            end
                            
                            % Create source file name
                            source_file = fullfile(subj_path, list_nii_files{file});
                            
                            % Get task name from file name
                            if ~isempty(cell2mat(regexpi(...
                                    list_nii_files(file), 'vft')))
                                token_task = 'vftmodern';
                            else
                                if ~isempty(cell2mat(regexpi(...
                                        list_nii_files(file), 'pm')))
                                    token_task = 'pm';
                                else
                                    if ~isempty(cell2mat(regexpi(...
                                        list_nii_files(file), 'hamt')))
                                        token_task = 'hamths';
                                    else
                                        if ~isempty(cell2mat(regexpi(...
                                                list_nii_files(file), 'hamtsz')))
                                            token_task = 'hamtsz';
                                        else
                                            if ~isempty(cell2mat(regexpi(...
                                                    list_nii_files(file), ...
                                                    'rest|rsf|dmn')))
                                                token_task = 'rest';
                                            else
                                                token_task = 'gen';
                                            end
                                        end
                                    end
                                end
                            end
                            
                            % Create destination name
                            dest_file = fullfile(bids_dir, subj_tag, ...
                                'func', [subj_tag, '_task-', ...
                                token_task, '_bold.nii']);
                            
                            % Check if destination file already exists
                            if exist(dest_file, 'file')
                                
                                % Loop till a suitable new name can be generated
                                count = 1;
                                while 1
                                    dest_file = fullfile(bids_dir, subj_tag, ...
                                        'func', [subj_tag, ...
                                        '_task-', token_task, '_bold_', ...
                                        num2str(count), '.nii']);
                                    
                                    if ~exist(dest_file, 'file')
                                        break
                                    else
                                        count = count + 1;
                                    end
                                end
                            end
                            
                            % Copy this file to bids_dir
                            copyfile(source_file, dest_file);
                            
                            % Copy associated JSON file to bids_dir
                            source_file = [strrep(source_file, '.nii', ''), '.json'];
                            dest_file   = [strrep(dest_file,   '.nii', ''), '.json'];
                            copyfile(source_file, dest_file);
                            
                        else
                            %% Unsure what to do
                            disp([list_nii_files{file}, ' : skipped']);
                            fprintf(fid_summary, '%s\r\n', ...
                                [list_nii_files{file}, ' : skipped']);
                            continue
                        end
                    end
                end
            end
                        
            % Create source and dest file names for writing summary
            source_file   = regexprep(list_nii_files{file}, ...
                {'.json', '.nii', '.bval', '.bvec'}, '');
            [~,dest_file] = fileparts(dest_file);
            dest_file     = regexprep(dest_file, ...
                {'.json', '.nii', '.bval', '.bvec'}, '');
            
            % Update summary
            disp([source_file, ' : ', dest_file]);
            fprintf(fid_summary, '%s\r\n', [source_file, ' : ', dest_file]);
        end
        
        % Update summary
        disp([list_subjs{subj}, '...done!']);
        fprintf(fid_summary, '%s\r\n', [list_subjs{subj}, '...done!']);
    end
end     

% Close summary file
fclose(fid_summary);