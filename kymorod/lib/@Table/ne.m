function res = ne(this, that)
%NE  Overload the ne operator for Table objects
%
%   output = ne(input)
%
%   Example
%   ne
%
%   See also
%
%
% ------
% Author: David Legland
% e-mail: david.legland@grignon.inra.fr
% Created: 2011-08-02,    using Matlab 7.9.0.529 (R2009b)
% Copyright 2011 INRA - Cepia Software Platform.

[dat1 dat2 parent names1 names2] = parseInputCouple(this, that, inputname(1), inputname(2));

if ~hasFactors(parent)
    % compute new data with numeric data
    newData = bsxfun(@ne, dat1, dat2);
    
else
    % Case of factor data table
    if size(parent, 2) > 1
        error('Table:eq:FactorColumnForbidden', ...
            'If table is factor, it should have only one column');
    end
    
    % extract factor level for each row
    levels = parent.levels{1};
    levels = levels(dat1);
    
    % compare factor levels with second argument
    if ischar(dat2)
        newData = ~strcmp(levels, dat2);
    else
        newData = bsxfun(@ne, levels, dat2);
    end
end

newColNames = strcat(names1, '~=', names2);

% create result array
res = Table.create(newData, ...
    'parent', parent, ...
    'colNames', newColNames);
