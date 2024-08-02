function res = cellstr(this)
%CELLSTR  Convert data table into cell array of strings
%
%   C = cellstr(TAB)
%   Converts the data table TAB into a cell array of strings. The resulting
%   array has the same size as the original table.
%
%   Example
%     % convert iris table
%     iris = Table.read('fisherIris.txt');
%     cellstr(iris(1:4, :))
%     ans =
%         '5.1'    '3.5'    '1.4'    '0.2'    'Setosa'
%         '4.9'    '3'      '1.4'    '0.2'    'Setosa'
%         '4.7'    '3.2'    '1.3'    '0.2'    'Setosa'
%         '4.6'    '3.1'    '1.5'    '0.2'    'Setosa'
%
%   See also
%   disp
%
% ------
% Author: David Legland
% e-mail: david.legland@grignon.inra.fr
% Created: 2012-04-20,    using Matlab 7.9.0.529 (R2009b)
% Copyright 2012 INRA - Cepia Software Platform.

dim = size(this);
res = cell(dim);

% iterate over columns
for c = 1:dim(2)
    if isFactor(this, c)
        % create a column containing level names
        levels = this.levels{c};
        res(:, c) = levels(this.data(:, c));
    else
        % simply convert numeric values
        res(:, c) = strtrim(cellstr(num2str(this.data(:, c))));
    end
    
end
