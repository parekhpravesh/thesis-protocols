function [echo_spacing, readout_time, encode_dir, slice_info, num_slices,   ...
          slice_order,  mb_factor, temporal_spacing, min_TR, slice_times] = ...
          extract_EPI_details(ExamCard, echo_spacing_method, readout_method)
% Function to return echo spacing, EPI readout time, and phase encoding 
% direction  given a Philips EPI ExamCard text file
%% Input:
% ExamCard:             text file having Philips EPI sequence ExamCard
% echo_spacing_method:  should be one of:
%                           * 'brainvoyager' or 'BV'
%                           * 'OSF'
% readout_method:       should be one of:
%                           * 'topup' or 'fsl'
%                           * 'fsl_alt' or 'fsl_forum'
%                           * 'BIDS'
% 
%% Outputs:
% echo_spacing:         echo spacing value in milliseconds
% readout_time:         EPI readout time calculated from echo_spacing
% encode_dir:           'AP', 'PA', or 'unknown'
% slice_info:           details of how slices were acquired
% num_slices:           number of slices
% slice_order:          vector of how slices were acquired
% mb_factor:            multiband factor (1 if non-multiband)
% temporal_spacing:     spacing of slices over time
% min_TR:               minimum TR for completion of one volume
% slice_times:          slice timings (in seconds)
% 
%% Notes:
% Given an ExamCard file, we extract the following values:
% EPI factor:           from "EPI factor"
% water-fat shift:      from "WFS (pix) / BW (Hz)"
% 
% Assumes field strength = 3T
% 
% From Ref 1:
% water-fat-shift (Hz) = fieldstrength (T) * water-fat difference (ppm) * resonance frequency (MHz/T)
% water-fat difference (ppm) = 3.35
% resonance frequency (MHz/T) = 42.576
% 
% For phase encoding direction, if the fat-shift is 'P', then it is assumed
% P --> A, otherwise A ---> P; assuming that other variants like L ---> R,
% etc are not present, though it is possible to code for these
% 
% slice_info of 'default' corresponds to interleaved (assuming foot to
% head) order on a Philips scanner
% 
% slice_times are computed as:
% 0:(min_TR/num_slices):(min_TR-(min_TR/num_slices))
% 
% Two methods for echo spacing calculation exist:
% a) 'brainvoyager' or 'BV' method
%    -----------------------------
%       echo spacing in msec = 1000 * (WFS/(water-fat shift (in Hz) * ETL))
%       where
%           ETL = EPI factor + 1
%           water-fat-shift (Hz) = fieldstrength (T) * water-fat difference (ppm) * resonance frequency (MHz/T)
%           water-fat difference (ppm) = 3.35 [2]
%           resonance frequency (MHz/T) = 42.576
%           effective echo spacing = echo spacing/acceleration
%       => effective echo spacing = (1000*(WFS/427.888*ETL))/acceleration
% 
% b) 'OSF' method
%    ------------
%       effective echo spacing = (((1000 * WFS)/(434.215 * (ETL+1))/acceleration)
% 
% Three methods exist for EPI readout calculation:
% a) 'topup'
%    -------
%       total readout time = echo spacing * (EPI factor - 1)
% 
% b) 'fsl_alt' or 'fsl_forum'
%    ------------------------
%       total readout time = echo spacing * EPI factor
% 
% c) 'BIDS'
%    ------
%       total readout time = effective echo spacing * (ReconMatrixPE - 1)
% 
% dcm2niix reports EPI factor as the ETL; this definition is used
% 
% ReconMatrixPE is derived from 'Reconstruction matrix' field from ExamCard
% 
%% Defaults:
% echo_spacing_method:  'brainvoyager'
% readout_method:       'topup'
% 
%% References:
% https://support.brainvoyager.com/brainvoyager/functional-analysis-preparation/29-pre-processing/78-epi-distortion-correction-echo-spacing-and-bandwidth
% https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=fsl;162ab1a3.1308
% https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=ind1308&L=FSL&P=R26762&1
% https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=fsl;11890734.1602
% https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=fsl;b40708d7.1902
% http://web.mit.edu/fsl_v5.0.10/fsl/doc/wiki/topup(2f)Faq.html
% https://osf.io/hks7x/
% https://in.mathworks.com/matlabcentral/answers/2015-find-index-of-cells-containing-my-string
% https://neurostars.org/t/consolidating-epi-echo-spacing-and-readout-time-for-philips-scanner/4406
% https://web.archive.org/web/20130420035502/www.spinozacentre.nl/wiki/index.php/NeuroWiki:Current_developments
% https://bids-specification.readthedocs.io/en/latest/04-modality-specific-files/01-magnetic-resonance-imaging-data.html

%% Author
% Parekh, Pravesh
% April 16, 2019
% MBIAL

%% Check inputs
% Check ExamCard
if ~exist('ExamCard', 'var') || isempty(ExamCard)
    error('ExamCard should be provided');
else
    if ~exist(ExamCard, 'file')
        error(['Unable to read: ', ExamCard]);
    end
end

% Check echo_spacing_method
if ~exist('echo_spacing_method', 'var') || isempty(echo_spacing_method)
    echo_spacing_method = 'brainvoyager';
else
    echo_spacing_method = lower(echo_spacing_method);
    if ~ismember(echo_spacing_method, {'brainvoyager', 'bv', 'osf'})
        error(['Unknown echo spacing method: ', echo_spacing_method]);
    end
end

% Check readout_method
if ~exist('readout_method', 'var') || isempty(readout_method)
    readout_method = 'topup';
else
    readout_method = lower(readout_method);
    if ~ismember(readout_method, {'topup', 'fsl', 'fsl_alt', 'fsl_forum', 'bids'})
        error(['Unknown readout_method: ', readout_method]);
    end
end

%% Read ExamCard file
fid  = fopen(ExamCard, 'r');
data = textscan(fid, '%s %s', 'Delimiter', '=');

%% Find EPI factor
epi_factor_loc  = strfind(data{1,1}, 'EPI factor');
epi_factor_loc  = ~(cellfun('isempty', epi_factor_loc));
epi_factor      = str2double(strrep(data{1,2}{epi_factor_loc}, ';', ''));

%% Find water-fat shift value in pixels
wfs_loc         = strfind(data{1,1}, 'WFS (pix) / BW (Hz)');
wfs_loc         = ~(cellfun('isempty', wfs_loc));
temp            = strsplit(data{1,2}{wfs_loc}, '/');
wfs_value       = str2double(regexprep(temp{1}, {' ', '"'}, ''));

%% Find fat-shift direction
fat_shift_loc   = strfind(data{1,1}, 'fat shift direction');
fat_shift_loc   = ~(cellfun('isempty', fat_shift_loc));
encode_dir      = regexprep(data{1,2}{fat_shift_loc}, {'"', ';'}, '');

if strcmpi(encode_dir, 'P')
    encode_dir = 'PA';
else
    if strcmpi(encode_dir, 'A')
        encode_dir = 'AP';
    else
        encode_dir = 'Unknown';
    end
end

%% Slicing information
slice_loc      = strfind(data{1,1}, 'Slice scan order');
slice_loc      = ~(cellfun('isempty', slice_loc));
slice_info     = regexprep(data{1,2}{slice_loc}, {'"', ';'}, '');

%% Number of slices
num_slice_loc  = strfind(data{1,1}, 'slices');
num_slice_loc  = ~(cellfun('isempty', num_slice_loc));
num_slices     = str2double(strrep(data{1,2}{num_slice_loc}, ';', ''));

%% Create slice order
switch(slice_info)
    case 'default'
        slice_order = [1:2:num_slices 2:2:num_slices];
      
    case 'ascend'
        slice_order = 1:num_slices;
        
    case 'descend'
        slice_order = num_slices:-1:1;
        
    case 'interleaved'
        num = ceil(sqrt(num_slices));
        slice_order = [1:num:num_slices 2:num:num_slices];
        
    case 'FH'
        slice_order = 1:num_slices;
        
    case 'HF'
        slice_order = num_slices:-1:1;
end

%% Temporal spacing
temp_spacing_loc    = strfind(data{1,1}, 'Temporal slice spacing');
temp_spacing_loc    = ~(cellfun('isempty', temp_spacing_loc));
temporal_spacing    = regexprep(data{1,2}{temp_spacing_loc}, {'"', ';'}, '');

%% Minimum TR
min_TR_loc          = strfind(data{1,1}, 'Min. TR/TE (ms)');
min_TR_loc          = ~(cellfun('isempty', min_TR_loc));
temp                = strsplit(data{1,2}{min_TR_loc}, '/');
min_TR              = str2double(regexprep(temp{1}, {' ', '"'}, ''));

%% Compute slice times
slice_times         = (0:(min_TR/num_slices):(min_TR-(min_TR/num_slices)))./1000;

%% Get MB-factor
mb_fac_loc          = strfind(data{1,1}, 'MB SENSE');
mb_fac_loc          = ~(cellfun('isempty', mb_fac_loc));
mb_factor           = regexprep(data{1,2}{mb_fac_loc}, {'"', ';'}, '');
if strcmpi(mb_factor, 'No')
    mb_factor = 1;
else
    mb_fac_loc      = strfind(data{1,1}, 'MB Factor');
    mb_fac_loc      = ~(cellfun('isempty', mb_fac_loc));
    mb_factor       = str2double(strrep(data{1,2}{mb_fac_loc}, ';', ''));
end

%% Work out SENSE factor
sense_loc           = regexp(data{1,1}, '^SENSE');
sense_loc           = ~(cellfun('isempty', sense_loc));
sense               = regexprep(data{1,2}{sense_loc}, {';', '"'}, '');

if strcmpi(sense, 'yes')
    acceleration    = str2double(strrep(data{1,2}{find(sense_loc)+1}, ';', ''));
else
    acceleration    = 1;
end

%% Reconstruction matrix
recon_loc          = strfind(data{1,1}, 'Reconstruction matrix');
recon_loc          = ~(cellfun('isempty', recon_loc));
reconstruction_mat = str2double(strrep(data{1,2}{recon_loc}, ';', ''));

%% Other variables
wfs_hz          = 3 * 3.35 * 42.576;
echo_train_len  = epi_factor;

%% Echo spacing
if strcmpi(echo_spacing_method, 'brainvoyager') || strcmpi(echo_spacing_method, 'bv')
    % Brainvoyager method
    echo_spacing    = ((1000 * wfs_value)/(wfs_hz * echo_train_len)/acceleration);
else
    % OSF method
    echo_spacing    = (1000*(wfs_value/(434.215*(echo_train_len+1)))/acceleration);
end

%% Readout time
% Topup method
if strcmpi(readout_method, 'topup') || strcmpi(readout_method, 'fsl')
    readout_time    = (echo_spacing * (epi_factor - 1))/1000;
else
    % FSL forum post method
    if strcmpi(readout_method, 'fsl_alt') || strcmpi(readout_method, 'fsl_forum')
        readout_time = (echo_spacing * epi_factor)/1000;
    else
        % BIDS method
        readout_time = (echo_spacing * (reconstruction_mat - 1))/1000;
    end
end