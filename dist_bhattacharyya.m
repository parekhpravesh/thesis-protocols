function d = dist_bhattacharyya(mat1, mat2)
% Function to calculate Bhattacharyya distance given two matrices
%% Inputs:
% mat1:         vector or matrix 1 (assuming variables are columns)
% mat2:         vector or matrix 2 (assuming variables are columns)
% 
%% Output:
% Bhattacharyya distance d is returned
% 
%% Notes:
% For each matrix, the means (mu1 and mu2) and covariances (cov1, cov2) are
% calculated; overall covariance is the average of cov1 and cov2:
% C = (cov1+cov2)/2;
% The first term of the Bhattacharyya distance is calculated as:
% 1/8 * (mu1-mu2) * inv(C) * (mu1-mu2)
% The second term of the Bhattacharyya distance is calculated as:
% 1/2 * log(det(C)/(sqrt(det(cov1)*det(cov2)))
% Therefore, the Bhattacharyya distance is the sum of term1 and term2
% 
%% Reference:
% https://en.wikipedia.org/wiki/Bhattacharyya_distance
% 
%% Author(s):
% Parekh, Pravesh
% December 16, 2019
% MBIAL

%% Check inputs
if ~exist('mat1', 'var') || isempty(mat1)
    error('Please input first vector/matrix');
else
    num_var_1 = size(mat1,2);
end

if ~exist('mat2', 'var') || isempty(mat2)
    error('Please input second vector/matrix');
else
    num_var_2 = size(mat2,2);
end

% Check and ensure that the number of variables are the same
if num_var_1 ~= num_var_2
    error('Both matrices should have the same number of variables');
end

%% Calculate preliminary variables
mu1         = mean(mat1);
mu2         = mean(mat2);
diff_mean   = mu1 - mu2;
cov1        = cov(mat1);
cov2        = cov(mat2);
C           = (cov1+cov2)/2;

%% Calculate term 1
term1 = 1/8 * diff_mean * (C \ diff_mean');

%% Calculate term 2
term2 = 1/2 * log(det(C)/sqrt(det(cov1)*det(cov2)));

%% Return Bhattacharyya distance
d = term1 + term2;