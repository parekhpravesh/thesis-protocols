function create_vdm(bids_dir)
% Function to create voxel displacement map calculated from phase and
% magnitude images acquired during fieldmap acquisition
%% Inputs:
% bids_dir:     fullpath to a BIDS directory having subject folders
%
%% Output:
% Apart from the vdm and other associated files, the batch is saved for
% each subject and an overall summary is written in the bids_dir named
% summary_create_vdm_ddmmmyyyy.txt
%
%% Notes:
% Assumes BIDS folder structure
%
% Assumes that data is in classic DICOM derived NIfTI which has been split
% into phase and magnitude images respectively (i.e. BIDS convention)
%
% Assumes that 'IntendedFor' entry is mentioned in the JSON file; this will
% be used for calculating EPI readout time and for specifying test EPI
% image for unwarping (this image should be present in the 'func' folder
%
%% Author(s)
% Parekh, Pravesh
% March 12, 2018
% MBIAL

%% Check if BIDS directory is provided and that it exists
if ~exist('bids_dir', 'var')
    error('Input BIDS directory not provided');
else
    if ~exist(bids_dir, 'dir')
        error(['Cannot locate BIDS directory: ', bids_dir]);
    end
end

%% Create subject list
cd(bids_dir);
list_subjs = dir('sub-*');
num_subjs  = length(list_subjs);
disp([num2str(num_subjs), ' subjects found']);

%% Prepare summary file
summary_loc = fullfile(bids_dir, ['summary_create_vdm_', datestr(now, 'ddmmmyyyy'), '.txt']);
if exist(summary_loc, 'file')
    fid_summary = fopen(summary_loc, 'a');
else
    fid_summary = fopen(summary_loc, 'w');
end
fprintf(fid_summary, '%s\r\n', ['Date:         ', datestr(now, 'ddmmmyyyy')]);
fprintf(fid_summary, '%s\r\n', ['Time:         ', datestr(now, 'HH:MM:SS PM')]);
fprintf(fid_summary, '%s\r\n', ['bids_dir:     ', bids_dir]);
fprintf(fid_summary, '%s\r\n', [num2str(num_subjs), ' subjects found']);

%% Get some defaults
spm_loc         = which('spm');
[spm_loc, ~]    = fileparts(spm_loc);
fmap_template   = fullfile(spm_loc, 'toolbox', 'FieldMap', 'T1w.nii');

%% Loop over subjects and create vdm batch
for subj = 1:num_subjs
    cd(fullfile(bids_dir, list_subjs(subj).name, 'fmap'));
    
    % Find fmap files
    list_files = dir('*.nii');
    
    % Parse list of fmaps and ensure all files are present
    list_base_names = cell(length(list_files), 1);
    
    % Create a list of base_names to work with
    for i = 1:length(list_files)
        [~,tmp] = fileparts(list_files(i).name);
        list_base_names{i} = regexprep(tmp, {'_phase1','_phase2','_magnitude1', '_magnitude2'}, '');
    end
    
    % Retain unique base_names
    list_base_names = unique(list_base_names);
    
    % Counter and location for base_names skipped
    skip_base_count = 0;
    skip_base_loc   = [];
    
    % Initialize a few list variables
    list_phase1_images = cell(length(list_base_names), 1);
    list_phase2_images = cell(length(list_base_names), 1);
    list_phase1_json   = cell(length(list_base_names), 1);
    list_phase2_json   = cell(length(list_base_names), 1);
    list_mag1_images   = cell(length(list_base_names), 1);
    list_mag2_images   = cell(length(list_base_names), 1);
    
    % Ensure that two phase and magnitude files are present for each
    % unique base name found above (JSON files for magnitude images are
    % not checked); also create list of phase and magnitude images
    for i = 1:length(list_base_names)
        
        if exist([list_base_names{i}, '_phase1.nii'],     'file') && ...
           exist([list_base_names{i}, '_phase2.nii'],     'file') && ...
           exist([list_base_names{i}, '_magnitude1.nii'], 'file') && ...
           exist([list_base_names{i}, '_magnitude2.nii'], 'file') && ...
           exist([list_base_names{i}, '_phase1.json'],    'file') && ...
           exist([list_base_names{i}, '_phase2.json'],    'file')
            
            list_phase1_images{i} = fullfile(bids_dir, ...
                                    list_subjs(subj).name, 'fmap', ...
                                    [list_base_names{i}, '_phase1.nii']);
            
            list_phase2_images{i} = fullfile(bids_dir, ...
                                    list_subjs(subj).name, 'fmap', ...
                                    [list_base_names{i}, '_phase2.nii']);
            
            list_phase1_json{i}   = fullfile(bids_dir, ...
                                    list_subjs(subj).name, 'fmap', ...
                                    [list_base_names{i}, '_phase1.json']);
            
            list_phase2_json{i}   = fullfile(bids_dir, ...
                                    list_subjs(subj).name, 'fmap', ...
                                    [list_base_names{i}, '_phase2.json']);
            
            list_mag1_images{i}   = fullfile(bids_dir, ...
                                    list_subjs(subj).name, 'fmap', ...
                                    [list_base_names{i}, '_magnitude1.nii']);
            
            list_mag2_images{i}   = fullfile(bids_dir, ...
                                    list_subjs(subj).name, 'fmap', ...
                                    [list_base_names{i}, '_magnitude2.nii']);
            
        else
            % Update summary and skip this particular base name
            disp([list_subjs(subj).name, '...incomplete set of files for ', ...
                list_base_names{i}, '...skipping']);
            fprintf(fid_summary, '%s', [list_subjs(subj).name, ...
                '...incomplete set of files for ', ...
                list_base_names{i}, '...skipping']);
            
            % Update counter and location of base name to skip
            skip_base_count = skip_base_count + 1;
            skip_base_loc(skip_base_count) = i;
            
            continue
        end
            
        % Add a new line if this is the only fieldmap, else put ...
        if length(list_base_names) == 1
            fprintf(fid_summary, '\r\n');
        else
            fprintf(fid_summary, '%s', '...');
        end
        
    end
    
    % Shrink the size of all list files if any base name was skipped
    if skip_base_count ~= 0
        list_phase1_images(skip_base_loc)   = [];
        list_phase2_images(skip_base_loc)   = [];
        list_phase1_json(skip_base_loc)     = [];
        list_phase2_json(skip_base_loc)     = [];
        list_mag1_images(skip_base_loc)     = [];
        list_mag2_images(skip_base_loc)     = [];
    end
    
    num_fmaps = length(list_phase1_images);
    
    % Update summary with number of fmaps found
    disp([list_subjs(subj).name,    '...', num2str(num_fmaps), ' fmaps found']);
    fprintf(fid_summary, '%s', [list_subjs(subj).name, '...', num2str(num_fmaps), ' fmaps found']);
    
    % Loop over number of fieldmaps and figure out details to create batch
    for fmap = 1:num_fmaps
        
        % Read JSON file and figure out shorter and longer echos
        fid_phase1  = fopen(list_phase1_json{fmap}, 'r');
        fid_phase2  = fopen(list_phase2_json{fmap}, 'r');
        data_phase1 = textscan(fid_phase1, '%s %s %s', 'Delimiter', '\t:');
        data_phase2 = textscan(fid_phase2, '%s %s %s', 'Delimiter', '\t:');
        
        % Locate EchoTime
        loc_e1	= strcmpi(data_phase1{1,2}, '"EchoTime"');
        loc_e2	= strcmpi(data_phase2{1,2}, '"EchoTime"');
        echo1	= data_phase1{1,3}{loc_e1};
        echo2   = data_phase2{1,3}{loc_e2};
        
        % Remove comma, convert to number, and change to ms
        echo1   = echo1(1:end-1);
        echo2   = echo2(1:end-1);
        echo1   = str2double(echo1)*1000;
        echo2   = str2double(echo2)*1000;
        
        % Figure out shorter and longer echos
        if echo1 > echo2
            swap = 1;
        else
            swap = 0;
        end
        
        % Create paths to magnitude and phase images
        if swap
            phase_short_nii = list_phase2_images{fmap}; 
            phase_long_nii  = list_phase1_images{fmap}; 
            mag_short_nii   = list_mag2_images{fmap};
            mag_long_nii    = list_mag1_images{fmap};
            echos           = [echo2 echo1];
        else
            phase_short_nii = list_phase1_images{fmap};
            phase_long_nii  = list_phase2_images{fmap};
            mag_short_nii   = list_mag1_images{fmap};
            mag_long_nii    = list_mag2_images{fmap};
            echos           = [echo1 echo2];
        end
        
        % Locate IntendedFor entry
        loc_intended_for    = strcmpi(data_phase1{1,2}, '"IntendedFor"');
        
        % Find number of IntendedFor entries
        for tmp = find(loc_intended_for):length(data_phase1{1,2})-1
            if isempty(data_phase1{1,2}{tmp+1})
                continue;
            else
                break;
            end
        end
        num_intended_for = tmp - find(loc_intended_for) + 1;
        
        % Update summary
        [~, tmp] = fileparts(phase_short_nii);
        tmp      = strrep(tmp, '_phase1', '');
        disp([list_subjs(subj).name, '...', tmp, '...', num2str(num_intended_for), ' intended usage found']);
        fprintf(fid_summary, '%s',  ['...', tmp, '...', num2str(num_intended_for), ' intended usage found']);
        
        % Create list of intended_for, task_names, and EPI readout times
        loc_intended_for = find(loc_intended_for):(find(loc_intended_for)+num_intended_for-1);
        intended_for     = cell(num_intended_for,  1);
        task_name        = cell(num_intended_for,  1);
        readout_time     = zeros(num_intended_for, 1);
        
        for i = 1:num_intended_for

            % Get name of IntendedFor and clean it
            tmp = data_phase1{1,3}{loc_intended_for(i)};
            tmp = regexprep(tmp, {'"', '[', ']', ','}, '');
            if ~isunix
                tmp = strrep(tmp, '/', '\');
            end
            
            % Get basename of the IntendedFor file
            [~, base_name]  = fileparts(tmp);
            
            % Go to func directory and read JSON file
            cd(fullfile(bids_dir, list_subjs(subj).name, 'func'));
            fid_func_json   = fopen([base_name, '.json'], 'r');
            data_func_json  = textscan(fid_func_json, '%s %s %s', 'Delimiter', '\t:');
            
            % Find PixelBandwidth and clean it
            px_bw_loc       = strcmpi(data_func_json{1,2}, '"PixelBandwidth"');
            px_bw           = data_func_json{1,3}{px_bw_loc};
            
            % Remove comma and convert to number
            px_bw           = px_bw(1:end-1);
            px_bw           = str2double(px_bw);
            
            % Find PhaseEncodingSteps and clean it
            encode_steps    = strcmpi(data_func_json{1,2}, '"PhaseEncodingSteps"');
            encode_steps    = data_func_json{1,3}{encode_steps};
            
            % Remove comma and convert to number
            encode_steps    = encode_steps(1:end-1);
            encode_steps    = str2double(encode_steps);
            
            % Figure out task_name
            [~, task]       = fileparts(tmp);
            begin_loc       = strfind(task, 'task-')+5;
            end_loc         = strfind(task, '_bold')-1;
            task            = task(begin_loc:end_loc);
            
            % Assign to variables (EPI readout time = encode_steps * 1/PixelBandwidth*1000)
            task_name{i}    = task;
            intended_for{i} = fullfile(bids_dir, list_subjs(subj).name, tmp);
            readout_time(i) = encode_steps * (1/px_bw*1000);
            
            % Close JSON file
            fclose(fid_func_json);
        end
        
        % Close open JSON files
        fclose(fid_phase1);
        fclose(fid_phase2);
        
        % Loop over num_intended_for and create batch
        for i = 1:num_intended_for
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.data.phasemag.shortphase             = {[phase_short_nii,  ',1']};
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.data.phasemag.shortmag               = {[mag_short_nii,    ',1']};
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.data.phasemag.longphase              = {[phase_long_nii,   ',1']};
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.data.phasemag.longmag                = {[mag_long_nii,     ',1']};
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.et              = echos;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.maskbrain       = 0;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.blipdir         = 1;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.tert            = readout_time(i);
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.epifm           = 0;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.ajm             = 0;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.method   = 'Mark3D';
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.fwhm     = 10;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.pad      = 0;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.ws       = 1;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.template = {fmap_template};
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.fwhm     = 5;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.nerode   = 2;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.ndilate  = 4;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.thresh   = 0.5;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.reg      = 0.02;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.session.epi                          = {[intended_for{i}, ',1']};
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.matchvdm                             = 1;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.sessname                             = 'session';
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.writeunwarped                        = 0;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.anat                                 = '';
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.matchanat                            = 0;
            
            % Save batch file
            [~, tmp] = fileparts(phase_short_nii);
            tmp      = strrep(tmp, '_phase1', '');
            save(fullfile(bids_dir, list_subjs(subj).name, 'fmap', ...
                ['batch_create_vdm_', task_name{i}, '_', tmp, '.mat']), 'matlabbatch');
            
            % Run batch
            spm_jobman('run', matlabbatch);
            
            % Add task name at the end of each created files
            [~, tmp1] = fileparts(phase_short_nii);
            [~, tmp2] = fileparts(phase_long_nii);
            
            % Adding task name to fpm file
            movefile(fullfile(bids_dir, list_subjs(subj).name, 'fmap', ...
                ['fpm_sc', tmp1, '.nii']), ...
                fullfile(bids_dir, list_subjs(subj).name, 'fmap', ...
                ['fpm_sc', tmp1, '_', task_name{i}, '.nii']));
            
            % Adding task name to sc file (short echo)
            movefile(fullfile(bids_dir, list_subjs(subj).name, 'fmap', ...
                ['sc', tmp1, '.nii']), ...
                fullfile(bids_dir, list_subjs(subj).name, 'fmap', ...
                ['sc', tmp1, '_', task_name{i}, '.nii']));
            
            % Adding task name to sc file (long echo)
            movefile(fullfile(bids_dir, list_subjs(subj).name, 'fmap', ...
                ['sc', tmp2, '.nii']), ...
                fullfile(bids_dir, list_subjs(subj).name, 'fmap', ...
                ['sc', tmp2, '_', task_name{i}, '.nii']));
            
            % Adding task name to vdm file
            movefile(fullfile(bids_dir, list_subjs(subj).name, 'fmap', ...
                ['vdm5_sc', tmp1, '.nii']), ...
                fullfile(bids_dir, list_subjs(subj).name, 'fmap', ...
                ['vdm5_sc', tmp1, '_', task_name{i}, '.nii']));
            
            clear matlabbatch
            
            % Update summary
            disp([list_subjs(subj).name, '...', tmp, '...', task_name{i}, '...done!']);
            fprintf(fid_summary, '%s',   '...', tmp, '...', task_name{i}, '...done!');
        end
    end
    
    % Update summary
    disp([list_subjs(subj).name,    '...done!']);
    fprintf(fid_summary, '%s\r\n',  '...done!');
end

% Close summary file
fclose(fid_summary);