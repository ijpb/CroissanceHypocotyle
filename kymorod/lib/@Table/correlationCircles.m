function h = correlationCircles(this, varargin)
%CORRELATIONCIRCLES Represent correlation matrix using colored circles
%
%   output = correlationCircles(input)
%
%   Example
%     % Simple example on iris
%     tab = Table.read('fisherIris.txt');
%     correlationCircles(tab(:,1:4));
%
%     % Another example with more variables
%     load cities
%     tab = Table(ratings, cellstr(categories)', cellstr(names));
%     correlationCircles(tab)
%
%   See also
%   corrcoef
%
% ------
% Author: David Legland
% e-mail: david.legland@grignon.inra.fr
% Created: 2012-07-16,    using Matlab 7.9.0.529 (R2009b)
% Copyright 2012 INRA - Cepia Software Platform.

% number of variables
n = size(this, 2);
nRows = n;
nCols = n;

% compute the correlation matrix of input array
cc = corrcoef(this);

% initialize the colormap
cmap = jet(256);

% Create the main axis containing all small axes
cax = gca;
BigAx = newplot(cax);
fig = ancestor(BigAx, 'figure');
holdState = ishold(BigAx);
set(BigAx, ...
    'Visible', 'off', ...
    'xlim', [-1 1], ...
    'ylim', [-1 1], ...
    'DataAspectRatio', [1 1 1], ...
    'PlotBoxAspectRatio', [1 1 1], ...
    'color', 'none');

pos = get(BigAx, 'Position');

% size of sub-plots
width   = pos(3) / (nRows+1);
height  = pos(4) / (nCols+1);

% 2 percent space between axes
space = .02;
pos(1:2) = pos(1:2) + space * [width height];

BigAxHV = get(BigAx, 'HandleVisibility');
BigAxParent = get(BigAx, 'Parent');

% pre-compute data for drawing circles
t = linspace(0, 2*pi, 100)';
cx = cos(t);
cy = sin(t);

% iterate over all cells
for i = nRows:-1:1
    for j = nCols:-1:1
        
        % compute the position within the main figure
        axPos = [...
            pos(1) + (j-1+1) * width  ...
            pos(2) + (nRows-i-1) * height ...
            width * (1-space) ...
            height * (1-space)];
        
        % create the axes
        ax(i,j) = axes(...
            'Position', axPos, ...
            'HandleVisibility', BigAxHV, ...
            'parent', BigAxParent);
        
        % color and radius of current correlation circle
        indColor = min(floor((cc.data(i,j) + 1) * 128) + 1, 256);
        color = cmap(indColor, :);
        r = abs(cc.data(i, j));
        
        % fill a disc
        hh(i,j) = fill(cx*r, cy*r, color);

        % normalise the display of each axis
        set(ax(i,j), ...
            'xlim', [-1 1], ...
            'ylim', [-1 1], ...
            'DataAspectRatio', [1 1 1], ...
            'xgrid', 'off', ...
            'ygrid', 'off', ...
            'Visible', 'off');
    end
end


set(ax(:), 'xticklabel', '')
set(ax(:), 'yticklabel', '')
set(BigAx, ...
    'userdata', ax, ...
    'tag', 'PlotMatrixBigAx');
set(ax, 'tag', 'PlotMatrixCorrelationCirclesAx');

% Make BigAx the CurrentAxes
set(fig, 'CurrentAx', BigAx)
if ~holdState,
    set(fig, 'NextPlot', 'replace')
end

% Also set Title and X/YLabel visibility to 'on' and strings to empty
textHandles = [get(BigAx,'Title'); get(BigAx,'XLabel'); get(BigAx,'YLabel')]; 
set(textHandles, 'String', '', 'Visible', 'on')

% display labels on the left and on the top of the circle array
for i = 1:n
    set(ax(1,i), 'XAxisLocation', 'Top');
    xlabel(ax(1, i), this.colNames{i}, ...
        'Visible', 'On', ...
        'FontSize', 12, 'Rotation', 45, ...
        'VerticalAlignment', 'Middle', ...
        'HorizontalAlignment', 'Left');
    ylabel(ax(i, 1), this.colNames{i}, ...
        'Visible', 'On', ...
        'FontSize', 12, 'Rotation', 0, ...
        'VerticalAlignment', 'Middle', ...
        'HorizontalAlignment', 'Right');
end

% return handles if needed
if nargout ~= 0
    h = hh;
end


