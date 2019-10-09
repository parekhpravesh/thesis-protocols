function sdata = mov_avg_smooth(data, span)
% Function to implement a moving average smoothing as defined in MATLAB
% Curve Fitting Toolbox smooth function
%% Inputs:
% data:     a column vector having data to be smoothed
% span:     number of data points to use for calculating moving average;
%           can be an integer or a value indicating the fraction of total
%           elements in vector to be used (see Notes)
%
%% Output:
% sdata:    a vector having smoothed data
% 
%% Notes:
% Attempts to mimic the functionality of smooth function from the Curve
% Fitting Toolbox.
% 
% When calculating fraction of number of data points, the resulting value
% is floored
% 
% If span is an odd number or that the fraction results in an odd number,
% span is reduced by 1 (but after floor)
% 
% If data contains NaN, those particular values are set to zero; sdata is
% calculated as the ratio of the following quantities:
%   numerator = mov_avg_smooth(data,span) where data contains zeros instead
%               of NaN values; and
%   denominator = mov_avg_smooth(double(~isnan(data)),span)
% Note that this set of results will only match with the output of smooth.m
% when 'moving' is specified during the call to smooth.m (otherwise MATLAB
% will smooth the data using Lowess method)
% 
% Behaviour might be different if there is repetition in the data (unsure)
% 
%% Default:
% span = 5
% 
%% References:
% Walter's suggestion for integer check rather than floor(x) == x
% https://www.mathworks.com/matlabcentral/answers/16390-integer-check
% 
% Documentation on smooth.m
% https://www.mathworks.com/help/curvefit/smooth.html
% 
% Implementation details on smooth.m
% https://in.mathworks.com/help/curvefit/smoothing-data.html
% 
%% Test case:
% rng(150, 'twister');
% data   = rand(1000,1);
% res    = zeros(1000,100);
% places = 16;
% 
% for spans = 1:100
%     % Round off to x decimal places to really compare
%     res(:,spans) = round(abs(mov_avg_smooth(data,spans) - smooth(data,spans)), places);
% end
% all_res = reshape(res, 1000*100, 1);
% disp(['Out of 1,00,000 values ', num2str(length(nonzeros(all_res))), ...
%       ' values are different between MATLAB and our implementation', ...
%       'at a precision of ', num2str(places), ' decimal places']);
% 
% Output:
% Out of 1,00,000 values 70082 values are different between MATLAB and our implementationat a precision of 16 decimal places
% Out of 1,00,000 values 226 values are different between MATLAB and our implementationat a precision of 15 decimal places
% Out of 1,00,000 values 0 values are different between MATLAB and our implementationat a precision of 14 decimal places
% 
%% Author(s):
% Parekh, Pravesh
% October 09, 2019
% MBIAL

%% Check inputs
if ~exist('data', 'var') || isempty(data)
    error('Please provide a vector to smooth');
else
    num_points = length(data);
end

if ~exist('span', 'var') || isempty(span)
    span = 5;
else
    % Validate span
    if mod(span,1)~=0 
        if span<0 || span>1
            error('Span should either be an integer or value between 0-1');
        else
            span = floor(num_points*span);
        end
    end
    
    % Ensure span is odd
    if mod(span,2)==0
        span = span - 1;
    end
end

%% Calculate moving average
sdata = zeros(num_points,1);

% Return original vector if span == 1
if span == 1
    sdata = data;
else
    % Special case if data contains NaN
    if ~isempty(find(isnan(data), 1))
        data2 = data;
        data2(isnan(data2)) = 0;
        numerator   = mov_avg_smooth(data2, span);
        denominator = mov_avg_smooth(double(~isnan(data)), span);
        sdata       = numerator./denominator;
    else
        num_neighbours = (span-1)/2;
        for tp = 1:num_points

            % All locations to pick from
            all_loc = tp+num_neighbours:-1:tp-num_neighbours;

            % Find entries to remove
            to_remove = length(nonzeros(all_loc>num_points | all_loc<=0));
            all_loc([1:to_remove length(all_loc):-1:length(all_loc)-to_remove+1]) = [];

            % Get mean
            sdata(tp) = mean(data(all_loc));
        end
    end
end