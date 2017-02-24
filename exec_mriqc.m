function exec_mriqc
% Executes mriqc and writes the log to a text file
% Parekh, Pravesh
% February 14, 2017
% MBIAL

input_dir = '/run/media/MBIAL/MBIAL_STORAGE/Parekh/mriqc_dst_25Jan2017_BIDS/';
output_dir = '/run/media/MBIAL/MBIAL_STORAGE/Parekh/mriqc_dst_25Jan2017_BIDS_Output';
work_dir = '/run/media/MBIAL/MBIAL_STORAGE/Parekh/mriqc_dst_25Jan2017_BIDS_Work';
log_name = fullfile(output_dir, 'mriqc_log.txt');

system_string = ['"mriqc ', input_dir, ' ', output_dir, ...
    ' --verbose-reports --n_procs 30 participants -w ', work_dir, ' > ', ...
    log_name, '"'];

system(system_string);