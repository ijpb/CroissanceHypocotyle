function varargout = plotGroupErrorBars(data, group, varargin)
%PLOTGROUPERRORBARS  One-line description here, please.
%
%   output = plotGroupErrorBars(input)
%
%   Example
%   plotGroupErrorBars
%
%   See also
%
%
% ------
% Author: David Legland
% e-mail: david.legland@grignon.inra.fr
% Created: 2012-04-22,    using Matlab 7.9.0.529 (R2009b)
% Copyright 2012 INRA - Cepia Software Platform.

% extraction of groups indices and labels from input table
[groupIndices levelNames groupLabel] = parseGroupInfos(group);  %#ok<ASGLU,NASGU>
nLevels = length(levelNames);

% default error function is standard deviation
fun = @std;
if ~isempty(varargin) && isa(varargin{1}, 'function_handle')
    fun = varargin{1};
    varargin(1) = [];
end

% default drawing style of error bars
if isempty(varargin)
    varargin = {'.'};
end

% compute means of each group
means = groupStats(data, group, @mean);

% compute the error function of each group
errs = groupStats(data, group, fun);

% display the error bars
h = errorbar(1:nLevels, means, errs, varargin{:});

% decorate the graph
xlim([0 nLevels+1]);
set(gca, 'xtick', 1:nLevels);
set(gca, 'xtickLabel', levelNames);

if nargout > 0
    varargout = {h};
end
