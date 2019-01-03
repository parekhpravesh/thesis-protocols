function get_qa_cat(xml_files, output_file)
% Function to read CAT report XML files and extract quality assurance
% measures, percentages, and grades into a csv file
%% Inputs:
% xml_files:        cell with full paths to XML files
%                   (rows are filenames)
% output_file:      filename to be used for saving results 
%                   (optionally with full path)
% 
%% Output:
% A csv file with the name specified in output_file or QA_CAT_<YYYYMMMDD> 
% is written either in the supplied directory or pwd containing filename, 
% quality measures for resolution, noise, and bias, weighted IQR, surface 
% euler number, and size of topology defects. MATLAB, SPM and CAT software 
% versions are also written out
% 
% CAT automatically saves the XML file as a mat file with the same filename
% 
%% Notes:
% The function uses cat_io_xml function to read the xml file into a MATLAB
% structure; the rest of the code relies on the grades and functions 
% marks2str, mark2rps, and mark2grad defined in cat_main.m file
% (lines 2051-2054; CAT 12.5 v1363)
% 
% These are also defined in cat_stat_marks and the XML file mentions
% cat_vol_qa functions for quality assurance
% 
% Resolution RMS:   RMS error of voxel size
% Noise NCR:        Noise to contrast ratio
% Bias ICR:         Inhomogeneity to contrast ratio
% 
% value:            The value passed to mark2rps
% rps:              Percentage rating points
% grade:            A+ to F
% 
%% Default:
% output_file:      QA_CAT_YYYYMMDD.csv in pwd
% 
%% Author(s):
% Parekh, Pravesh
% January 03, 2019
% MBIAL

%% Check inputs and assign defaults
% Check xml_files
if ~exist('xml_files', 'var') || isempty(xml_files)
    error('xml_files should be provided');
end

% Check output_file
if ~exist('output_file', 'var') || isempty(output_file)
    % Check if full path is present in the first xml file
    if isempty(fileparts(xml_files{1}))
        loc = pwd;
    else
        loc = fileparts(xml_files{1});
    end
    output_file = fullfile(loc, ['QA_CAT_', datestr(now, 'yyyymmmdd'), '.csv']);
end

%% Define functions
% These lines are taken from cat_main.m (lines 2051-2054; CAT 12.5 v1363)
grades      = {'A+','A','A-','B+','B','B-','C+','C','C-','D+','D','D-','E+','E','E-','F'};
mark2rps    = @(mark) min(100,max(0,105 - mark*10)) + isnan(mark).*mark;
mark2grad   = @(mark) grades{min(numel(grades),max(max(isnan(mark)*numel(grades),1),round((mark+2/3)*3-3)))};

%% Initialize
num_files = length(xml_files);

header = {'filename'; ...
          'resolution_RMS_value'; 'resolution_RMS_rps'; 'resolution_RMS_grade'; ...
          'noise_NCR_value';      'noise_NCR_rps';      'noise_NCR_grade';      ...
          'bias_ICR_value';       'bias_ICR_rps';       'bias_ICR_grade';       ...
          'weighted_IQR_value';   'weighted_IQR_rps';   'weighted_IQR_grade';   ...
          'surface_euler_num';    'size_topology_defects';                      ...
          'version_MATLAB';       'version_SPM';        'version_CAT'};
      
measures = cell(num_files, length(header));

%% Get values
for file = 1:num_files
    str  = cat_io_xml(xml_files{file});
    
    % Filename
    measures{file,1}  = xml_files{file};
    
    % Resolution
    measures{file,2}  = str.qualityratings.res_RMS;
    measures{file,3}  = mark2rps(str.qualityratings.res_RMS);
    measures{file,4}  = mark2grad(str.qualityratings.res_RMS);
    
    % Noise
    measures{file,5}  = str.qualityratings.NCR;
    measures{file,6}  = mark2rps(str.qualityratings.NCR);
    measures{file,7}  = mark2grad(str.qualityratings.NCR);
    
    % Bias
    measures{file,8}  = str.qualityratings.ICR;
    measures{file,9}  = mark2rps(str.qualityratings.ICR);
    measures{file,10} = mark2grad(str.qualityratings.ICR);
    
    % Weighted IQR
    measures{file,11} = str.qualityratings.IQR;
    measures{file,12} = mark2rps(str.qualityratings.IQR);
    measures{file,13} = mark2grad(str.qualityratings.IQR);
    
    try
        % Surface Euler number
        measures{file,14} = str.subjectmeasures.EC_abs;
        
        % Size of topology defects
        measures{file,15} = str.subjectmeasures.defect_size;
        
    catch
        % Surface Euler number
        measures{file,14} = NaN;
        
        % Size of topology defects
        measures{file,15} = NaN;
    end
    
    % MATLAB version
    measures{file,16} = num2str(str.software.version_matlab);
    
    % SPM version
    measures{file,17} = num2str(str.software.version_spm);
    
    % CAT version
    measures{file,18} = [num2str(str.software.version_cat), ' v', ...
                         num2str(str.software.revision_cat)];
                     
    % Clear up for the next file
    clear str
end

%% Convert to table and save as csv file
measures = cell2table(measures, 'VariableNames', header);
writetable(measures, output_file);