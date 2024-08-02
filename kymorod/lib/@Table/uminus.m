function res = uminus(this)
%UMINUS  Overload the uminus operator for Table objects
%
%   output = uminus(input)
%
%   Example
%   uminus
%
%   See also
%
%
% ------
% Author: David Legland
% e-mail: david.legland@grignon.inra.fr
% Created: 2012-02-19,    using Matlab 7.9.0.529 (R2009b)
% Copyright 2011 INRA - Cepia Software Platform.

newData = builtin('uminus', this.data);
res = Table.create(newData, 'parent', this);
