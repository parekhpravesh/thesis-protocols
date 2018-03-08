function dicom_to_nifti(in_dir, out_dir, dcm2niix_dir, log_dir, ...
                        extra_param, bids, gz, precise, outname)
% Convert DICOM to NIfTI format using dcm2niix
%% Inputs:
% Mandatory inputs:
% in_dir:       fullpath to directory having subject folders (see Notes)
% out_dir:      fullpath to directory where NIfTI data should be exported
% dcm2niix_dir: fullpath to directory where dcm2niix is present
% 
% Optional inputs:
% log_dir:      location to save conversion logs
%                   * fullpath to a directory where logs can be written
%                   * 'skip': no logs are written
%                   * '':     no logs are written
%                   * 'sub':  logs are written in subject NIfTI directory 
% extra_param:  any extra parameters for dcm2niix command 
%               (for example '-t y'); should be -flag y/n format
% bids:         whether BIDS style output is required (numeric)
%                   * 1
%                   * 0
% gz:           set to 1 if compressed NIfTI files are needed (numeric)
%                   * 1
%                   * 0
% precise:      whether to use Philips precise or display values (numeric)
%                   * 1 (uses Philips precise)
%                   * 0 (uses Display values)
% outname:      argument for -f part of the command which decides how
%               converted files are named
% 
%% Output:
% Passes each subject's directory to dcm2niix which is converted to NIfTI
% and output to out_dir. Subject folders are automatically created and a
% log of conversion is written to log_dir (sub-xxxx_dcm2niix_log.txt); a
% summary file is created in out_dir: summary_dicom_to_nifti_ddmmmyyyy.txt
%
%% Notes:
% Assumes the following folder structure:
% <in_dir>/
%   <sub-xxxx>/
%       DICOM/
%       DICOMDIR
%   <sub-xxxx>/
%       DICOM/
%       DICOMDIR
%
% Folder corresponding to each subject is automatically created in the
% out_dir, the naame is the same as the name in in_dir; if a particular
% subject's folder already exists in out_dir, that subject is skipped; this
% is useful if the same in_dir has to be repeatedily subjected to
% conversion (such as the case when new subjects are added) but existing
% data should not be touched
%
% A text file containing the log of conversion process is output to the
% appropriate folder (if a location or 'sub' was specified), the filename
% of the log file is sub-xxxx_log.txt; the first line of this log file is
% the actual command used to execute the code
%
%% Defaults:
% log_dir   = ''; (no logging)
% bids      = 1;
% gz        = 0;
% precise   = 0;
% outname   = %p;
%
%% Author(s)
% Parekh, Pravesh
% March 08, 2018
% MBIAL

%% Check inputs and assign defaults

% Check if in_dir is provided
if ~exist('in_dir', 'var')
    error('Input directory not provided');
else
    % Check if in_dir exists
    if ~exist(in_dir, 'dir')
        error([in_dir, ' not found']);
    end
end
    
% Check if out_dir is provided
if ~exist('out_dir', 'var')
    error('Output directory not provided');
else
    % Check if out_dir exists; if not, create it
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
end

% Check if dcm2niix_dir is provided
if ~exist('dcm2niix_dir', 'var')
    error('Path to dcm2niix not provided');
else
    % Check if dcm2niix_dir exists
    if ~exist(dcm2niix_dir, 'dir')
        error([dcm2nix_dir, ' not found']);
    end
end
    
% Check log_dir parameter
if ~exist('log_dir', 'var')
    log_dir = '';
    logging = 0;
else
    % Check specifics of log_dir input
    if isempty(log_dir)
        logging = 0;
    else
        if strcmpi(log_dir, 'skip')
            logging = 0;
        else
            if strcmpi(log_dir, 'sub')
                logging = 1;
            else
                logging = 1;
                % Check if log_dir exists; if not, create it
                if ~exist(log_dir, 'dir')
                    mkdir(log_dir);
                end
            end
        end
    end
end

% Check if any extra parameters are provided
if ~exist('extra_param', 'var')
    extra_param = '';
end

% Check if BIDS format is required
if ~exist('bids', 'var')
    bids = 1;
end

% Check if user wants gz files
if ~exist('gz', 'var')
    gz = 0;
end

% Check if Philips precise is explicitly passed
if ~exist('precise', 'var')
    precise = 0;
end

% Check if outname is provided
if ~exist('outname','var')
    outname = '%p';
end

% Convert binary variables to y and n (bids)
if bids
    bids = 'y';
else
    bids = 'n';
end

% Convert binary variables to y and n (gz)
if gz
    gz = 'y';
else
    gz = 'n';
end

% Convert binary variables to y and n (precise)
if precise
    precise = 'y';
else
    precise = 'n';
end

%% Create subject list
cd(in_dir);
list_subjs = dir('sub-*');
num_subjs  = length(list_subjs);
disp([num2str(num_subjs), ' subjects found']);

%% Prepare summary file
summary_loc = fullfile(out_dir, ['summary_dicom_to_nifti_', datestr(now, 'ddmmmyyyy'), '.txt']);
if exist(summary_loc, 'file')
    fid_summary = fopen(summary_loc, 'a');
else
    fid_summary = fopen(summary_loc, 'w');
end
fprintf(fid_summary, '%s\r\n', ['Date:         ', datestr(now, 'ddmmmyyyy')]);
fprintf(fid_summary, '%s\r\n', ['Time:         ', datestr(now, 'HH:MM:SS PM')]);
fprintf(fid_summary, '%s\r\n', ['in_dir:       ', in_dir]);
fprintf(fid_summary, '%s\r\n', ['out_dir:      ', out_dir]);
fprintf(fid_summary, '%s\r\n', ['dcm2niix_dir: ', dcm2niix_dir]);
fprintf(fid_summary, '%s\r\n', ['log_dir:      ', log_dir]);
fprintf(fid_summary, '%s\r\n', ['extra_param:  ', extra_param ]);
fprintf(fid_summary, '%s\r\n', ['BIDS:         ', bids]);
fprintf(fid_summary, '%s\r\n', ['Compressed:   ', gz]);
fprintf(fid_summary, '%s\r\n', ['Precise:      ', precise]);
fprintf(fid_summary, '%s\r\n', ['Outname:      ', outname]);
fprintf(fid_summary, '%s\r\n', [num2str(num_subjs), ' subjects found']);

%% Loop over each subject and convert
% Move to dcm2niix_dir
cd(dcm2niix_dir);

for subj = 1:num_subjs
    % Output path
    sub_out_dir = fullfile(out_dir, list_subjs(subj).name);
    
    % If output directory exists, skip the subject (lazy conversion)
    if exist(sub_out_dir, 'dir')
        disp([list_subjs(subj).name, '...skipped']);
        fprintf(fid_summary, '%s\r\n', [list_subjs(subj).name, '...skipped']);
        continue
    else
        % Create the framework of the command
        if isempty(extra_param)
            command_opts = ['-b ', bids, ' -z ', gz, ' -p ', precise, ' -f ', outname];
        else
            command_opts = ['-b ', bids, ' -z ', gz, ' -p ', precise, ' -f ', outname, ' ', extra_param];
        end

        % Create subject output directory
        mkdir(sub_out_dir);
        
        % Input path
        sub_in_dir   = fullfile(in_dir, list_subjs(subj).name);
        
        % Adding output directory and input directory to command
        command_out = [' -o ', sub_out_dir, ' ', sub_in_dir];
        
        % Check about log files and create path to log file
        if logging
            if strcmpi(log_dir, 'sub')
                sub_log_file = fullfile(out_dir, list_subjs(subj).name, ...
                               [list_subjs(subj).name, '_log.txt']);
            else
                sub_log_file = fullfile(log_dir, ...
                               [list_subjs(subj).name, '_log.txt']);
            end
            
            % Update command with logging path
            command_log = [' >> ', sub_log_file];
        end
        
        % Check OS and add execution method
        if isunix
            command = ['./dcm2niix ', command_opts, command_out, command_log];
        else
            command = ['dcm2niix.exe ', command_opts, command_out, command_log];
        end
        
        % If logging is enabled, write the command to the text file
        if logging
            fid = fopen(sub_log_file, 'w');
            fprintf(fid, '%s\r\n', command);
            fclose(fid);
        end
        
        % Execute the command
        status = system(command);
        
        % Display summary
        if status
            disp([list_subjs(subj).name, '...error']);
            fprintf(fid_summary, '%s\r\n', [list_subjs(subj).name, '...error']);
        else
            disp([list_subjs(subj).name, '...finished']);
            fprintf(fid_summary, '%s\r\n', [list_subjs(subj).name, '...finished']);
        end
    end
end
fclose(fid_summary);

% Return to output folder and tell user that conversion is over
cd(out_dir);
disp('Conversion completed!');