function E = computeDisplacement(skel1, skel2, S1, S2, img1, img2, ws, L)
% Compute displacement between two skeletons in pixel coordinates.
% 
%   E = computeDisplacement(SK1, SK2, S1, S2, IMG1, IMG2, WS, L)
%   (rewritten from function 'elong5')
%   Compute displacement between two frames, given skeleton in each frame
%   (in pixel coordinates), curvilinear abscissa for each skeleton,
%   reference image for each frame, size of correlation window, and
%   threshold on the maximal difference in curvilinear abscissa between the
%   two skeletons.
%   
%   Input arguments:
%   SK1: 	skeleton associated to first frame (in pixels)
%   SK2: 	skeleton associated to second frame (in pixels)
%   S1: 	curvilinear abscissa of first frame skeleton (in user unit)
%   S2: 	curvilinear abscissa of second frame skeleton (in user unit)
%   IMG1: 	image of the first frame
%   IMG2: 	image of the second frame
%   WS: 	size of the correlation window (in pixels)
%   L:      max difference in curvilinear abscissa (in user unit)
%
%   Output arguments:
%   E:      a N-by-2 array, containing for each vertex the curvilinear
%           abscissa and the displacement (difference in curvilinear
%           abscissa) 
%

% ------
% Author: Renaud Bastien
% e-mail: rbastien@seas.harvard.edu
% Created: 2012-03-03,    using Matlab 7.9.0.529 (R2009b)
% Copyright 2012 INRA - Cepia Software Platform.

%% 1. Snap skeleton points 

% identify in each image the pixels containing a portion of skeleton.
% S1px and S2px contain curvilinear abscissa for corresponding pixels.
[S1px, x1, y1] = snapCurveToPixels(S1, skel1);
[S2px, x2, y2] = snapCurveToPixels(S2, skel2);


%% 2. Clip skeleton points 

% process only skeleton points that are not too close from border
dim = size(img1);
inds = (x1 > ws) & (y1 > ws) & (x1 < dim(2)-ws) & (y1 < dim(1)-ws);
x1 = x1(inds);
y1 = y1(inds);
S1px = S1px(inds);

% process only skeleton points that are not too close from border
inds = (x2 > ws) & (x2 < dim(2)-ws) & (y2 > ws) & (y2 < dim(1)-ws);
x2 = x2(inds);
y2 = y2(inds);
S2px = S2px(inds);


%% 3. Particle Image Velocimetry

% allocate memory for result
E = zeros(length(x1), 2);

% counter for the number of computed correlations
a = 0;

% apply Particle Image Velocimetry on each point of the skeleton
for k = 1:length(x1)
	% image indices of current point
    i = y1(k);
    j = x1(k);
   
    % get small image around current point of first skeleton
    w1 = double(img1(i-ws:i+ws, j-ws:j+ws));
    
    % compute PIV only if variability in window is sufficient
    V = std2(w1);
    if V < .1
        warning(['KymoRod:' mfilename], ...
            'window around point (%d,%d) has not enough variability, try larger window size', j, i);
        continue;
    end
        
    % transform to vector, and remove mean
    w1 = w1(:) - mean(w1(:));
    
    % identify positions in second image with similar curvilinear abscissa
    inds = find( abs(S2px - S1px(k)) < L );

    % check degenerate cases
    if isempty(inds)
        error('Could not find enough points in second skeleton close to point (%d,%d), try larger limit in abscissa', j, i);
    end
    
    % initialize result of image to image correlation
    % first column contains difference in curvilinear coordinate
    % second column contains correlation coefficient
    resCorr = zeros(length(inds), 2);
    
    % iterate over pixels of second skeleton close enough from current pixel
    for l = 1:length(inds)
        % indices of positions in second image
        u = y2(inds(l));
        v = x2(inds(l));
        
        % get small image around current point in second skeleton
        w2 = double(img2(u-ws:u+ws, v-ws:v+ws));
        
        % transform to vector, and remove mean
        w2 = w2(:) - mean(w2(:));
             
        % compute displacement to current skeleton pixel of skel2, as the
        % difference between curvilinear abscissa
        resCorr(l, 1) = S2px(inds(l)) - S1px(k);
        
        % compute image correlation between the two thumbnails.
        resCorr(l, 2) = sum(w1 .* w2) / sqrt(sum(w1 .* w1) * sum(w2 .* w2));
    end
			
    % find the index of maximum correlation by sorting the resCorr array
    resCorr = sortrows(resCorr, 1);
    [corrMax, indMax] = max(resCorr(:, 2)); %#ok<ASGLU>
    
    % increment result array
    a = a + 1;
    E(a, 1) = S1px(k);
    E(a, 2) = resCorr(indMax,1);
end

% keep only relevant results, and sort them according to abscissa
E = E(1:a, :);
E = sortrows(E, 1);
