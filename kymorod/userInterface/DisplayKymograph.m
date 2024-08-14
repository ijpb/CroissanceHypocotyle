function varargout = DisplayKymograph(varargin)
% DISPLAYKYMOGRAPH MATLAB code for DisplayKymograph.fig
%      DISPLAYKYMOGRAPH, by itself, creates a new DISPLAYKYMOGRAPH or raises the existing
%      singleton*.
%
%      H = DISPLAYKYMOGRAPH returns the handle to a new DISPLAYKYMOGRAPH or the handle to
%      the existing singleton*.
%
%      DISPLAYKYMOGRAPH('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DISPLAYKYMOGRAPH.M with the given input arguments.
%
%      DISPLAYKYMOGRAPH('Property','Value',...) creates a new DISPLAYKYMOGRAPH or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before DisplayKymograph_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to DisplayKymograph_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DisplayKymograph

% Last Modified by GUIDE v2.5 16-Mar-2018 16:04:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DisplayKymograph_OpeningFcn, ...
                   'gui_OutputFcn',  @DisplayKymograph_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before DisplayKymograph is made visible.
function DisplayKymograph_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to DisplayKymograph (see VARARGIN)

% Choose default command line output for DisplayKymograph
handles.output = hObject;

if nargin == 4 && isa(varargin{1}, 'KymoRodData')
    app = varargin{1};
    setappdata(0, 'app', app);
else
    error('Run DisplayKymograph using deprecated call');
end

% setup figure menu
gui = KymoRodGui.getInstance();
buildFigureMenu(gui, hObject, app);

% compute number of frames that can be displayed
nFrames = frameNumber(app);

% get index of current frame, eventually corrected by max frame number
frameIndex = app.currentFrameIndex;
frameIndex = min(frameIndex, nFrames);

% Display current image
% display grayscale image as RGB, to avoid colormap problems
axes(handles.imageAxes); hold on;
img = getImage(app, frameIndex);
if ndims(img) == 2 %#ok<ISMAT>
    img = repmat(img, [1 1 3]);
end
handles.imageHandle = imshow(img);

% setup slider for display of current frame
set(handles.currentFrameSlider, 'Min', 1, 'Max', nFrames, 'Value', frameIndex); 
sliderStep = min(max([1 10] ./ (nFrames - 1), 0.001), 1);
set(handles.currentFrameSlider, 'SliderStep', sliderStep); 

% get geometric data for annotations
contour = getSmoothedContour(app, frameIndex);
skeleton = getSkeleton(app, frameIndex).Coords;

% create handles for geometric annotations
handles.contourHandle   = drawContour(contour, 'r');
handles.skeletonHandle  = drawSkeleton(skeleton, 'b');
handles.colorSkelHandle = scatter(skeleton(:, 1), skeleton(:, 2), ...
    [], 'b', 'filled', 'Visible', 'off');
handles.imageMarker     = drawMarker(skeleton(1, :), ...
    'd', 'Color', 'k', 'LineWidth', 1, 'MarkerFaceColor', 'w');

% depending on which data have been processed, only some kymographs may be
% displayed.
typeList = {'radius', 'verticalAngle', 'curvature'};
if ~isempty(app.elongationKymograph)
    typeList = [typeList, {'elongation'}];
end
if ~isempty(app.intensityKymograph)
    typeList = [typeList, {'intensity'}];
end
set(handles.kymographTypePopup, 'String', char(typeList));

% update the widget for choosing the type of kymograph
index = find(strcmpi(app.kymographDisplayType, typeList));
if isempty(index)
    index = 1;
end
set(handles.kymographTypePopup, 'Value', index);

% compute display extent for elongation kymograph
img = getKymographMatrix(app);
minCaxis = min(img(:));
maxCaxis = max(img(:));

setappdata(0, 'minCaxis', minCaxis);
setappdata(0, 'maxCaxis', maxCaxis);

set(handles.slider1, 'Min', minCaxis);
set(handles.slider1, 'Max', maxCaxis);
set(handles.slider1, 'Value', minCaxis);

% display current kymograph
calib = app.analysis.InputImages.Calibration;
xdata = (0:(size(img, 2)-1)) * calib.TimeInterval;
ydata = 1:size(img, 1);
handles.kymographImage = imagesc(handles.kymographAxes, 'XData', xdata, 'YData', ydata, 'CData', img);
% add the function handle to capture mouse clicks
set(handles.kymographImage, 'buttondownfcn', {@kymographAxes_ButtonDownFcn, handles});

updateKymographDisplay(handles);
displayCurrentFrameIndex(handles);

handles.kymographMarker = [];

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes DisplayKymograph wait for user response (see UIRESUME)
% uiwait(handles.mainFigure);


% --- Outputs from this function are returned to the command line.
function varargout = DisplayKymograph_OutputFcn(hObject, eventdata, handles)%#ok<INUSL>
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function updateCurrentFrameDisplay(handles)
% refresh display of current frame: image, and eventually colored skeleton

% extract data for current frame
app = getappdata(0, 'app');
frameIndex = app.currentFrameIndex;

% create RGB image from app data
img = app.getImage(frameIndex);
if ndims(img) == 2 %#ok<ISMAT>
    img = repmat(img, [1 1 3]);
end

% extract geometric annotations
contour = getSmoothedContour(app, frameIndex);
skeleton = getSkeleton(app, frameIndex).Coords;

% update display
axes(handles.imageAxes);
set(handles.imageHandle, 'CData', img);
set(handles.contourHandle, 'XData', contour(:,1), 'YData', contour(:,2));
set(handles.skeletonHandle, 'XData', skeleton(:,1), 'YData', skeleton(:,2));


function displayCurrentFrameIndex(handles)
% Updates the content of the "currentFrameIndex" label
% Typically after slider update, or after click on kymograph

% get current frame index and number
app = getappdata(0, 'app');
frameIndex = app.currentFrameIndex;
nFrames = frameNumber(app);

% update label display
string = sprintf('Current Frame: %d / %d', frameIndex, nFrames);
set(handles.currentFrameLabel, 'String', string);


% --------------------------------------------------------------------
function mainMenuMenuItem_Callback(hObject, eventdata, handles) %#ok<INUSD>
% hObject    handle to mainMenuMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

app = getappdata(0, 'app');
delete(gcf);
KymoRodMenuDialog(app);


% --- Executes on slider movement.
function currentFrameSlider_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to currentFrameSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% compute new value for frame index
app = getappdata(0, 'app');
frameIndex = round(get(handles.currentFrameSlider, 'Value'));

app.currentFrameIndex = frameIndex;
setappdata(0, 'app', app);

displayCurrentFrameIndex(handles);

updateCurrentFrameDisplay(handles);
if strcmpi(get(handles.colorSkelHandle, 'Visible'), 'On')
    updateColoredSkeleton(handles);
end
updateCurvilinearMarker(handles);


% --- Executes during object creation, after setting all properties.
function currentFrameSlider_CreateFcn(hObject, eventdata, handles) %#ok<INUSD>
% hObject    handle to currentFrameSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in showColoredSkeletonCheckBox.
function showColoredSkeletonCheckBox_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to showColoredSkeletonCheckBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showColoredSkeletonCheckBox

if get(handles.showColoredSkeletonCheckBox, 'Value')
    updateColoredSkeleton(handles);
    set(handles.colorSkelHandle, 'Visible', 'On');
else
    set(handles.colorSkelHandle, 'Visible', 'Off');
end


% --- Executes on selection change in kymographTypePopup.
function kymographTypePopup_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to kymographTypePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns kymographTypePopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from kymographTypePopup
% To select the kymograph with a popupmenu

app = getappdata(0, 'app');

% get the type of kymograph currently displayed
typeList = get(handles.kymographTypePopup, 'String');
type = strtrim(typeList(get(handles.kymographTypePopup, 'Value'), :));
if iscell(type)
    type = type{1};
end
% Choose the kymograph to display
switch lower(type)
    case 'radius'
        app.kymographDisplayType = 'radius';
    case lower('verticalAngle')
        app.kymographDisplayType = 'verticalAngle';
    case 'curvature'
        app.kymographDisplayType = 'curvature';
    case 'elongation'
        app.kymographDisplayType = 'elongation';
    case 'intensity'
        app.kymographDisplayType = 'intensity';
end

% setup Widget for control of display range
kymo = getCurrentKymograph(app);
validateDisplayRange(kymo);
minCaxis = kymo.DisplayRange(1);
maxCaxis = kymo.DisplayRange(2);
set(handles.slider1, 'Min', minCaxis);
set(handles.slider1, 'Max', maxCaxis);
set(handles.slider1, 'Value', minCaxis);

updateKymographDisplay(handles);
updateCurvilinearMarker(handles);

if strcmpi(get(handles.colorSkelHandle, 'Visible'), 'On')
    updateColoredSkeleton(handles);
end

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function kymographTypePopup_CreateFcn(hObject, eventdata, handles) %#ok<*DEFNU,INUSD>
% hObject    handle to kymographTypePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function colormapPopup_CreateFcn(hObject, eventdata, handles)%#ok<INUSL>
% hObject    handle to colormapPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in colormapPopup.
function colormapPopup_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to colormapPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns colormapPopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from colormapPopup

updateKymographDisplay(handles);


function updateColoredSkeleton(handles)

app = getappdata(0, 'app');

% coordinates of current skeleton
frameIndex = app.currentFrameIndex;
skeleton = getSkeleton(app, frameIndex).Coords;
xdata = skeleton(:, 1);
ydata = skeleton(:, 2);

% get the type of kymograph currently displayed
typeList = get(handles.kymographTypePopup, 'String');
type = strtrim(typeList(get(handles.kymographTypePopup, 'Value'), :));
disp(type)

% Choose the information to display
switch lower(type)
    case 'radius'
        values = skeleton.Radiusses;
    case lower('verticalAngle')
        values = app.analysis.VerticalAngles{frameIndex};
    case 'curvature'
        values = skeleton.Curvatures;
    case 'elongation'
        % make sure frame index is valid for elongation data
        frameIndex = min(frameIndex, length(app.elongationList));
        skeleton = getSkeleton(app, frameIndex);
        
        % extract the values of elongation
        elg = app.analysis.Elongations{frameIndex};
        values = elg(:, 2);
        
        % need to re-compute x and y data, as they are computed on a pixel
        % approximation of the skeleton
        abscissa = app.analysis.AlignedAbscissas{frameIndex};
        inds = zeros(size(elg, 1), 1);
        for i = 1:length(inds)
            inds(i) = find(abscissa > elg(i,1), 1, 'first');
        end
        xdata = skeleton(inds, 1);
        ydata = skeleton(inds, 2);
    case 'intensity'
        % TODO...
        return;
end


% extract bounds
vmin = getappdata(0, 'minCaxis');
val = get(handles.slider1, 'Value');
vmax = getappdata(0, 'maxCaxis') - val;

% create 256-by-3 array of colors
cmap = jet(256);
inds = floor((values - vmin) * 255 / (vmax - vmin)) + 1;
inds = max(min(inds, 256), 1);
colors = cmap(inds, :);

if isfield(handles, 'colorSkelHandle')
    set(handles.colorSkelHandle, ...
        'XData', xdata, 'YData', ydata, 'CData', colors);
end


% --- Executes on mouse press over axes background.
function kymographAxes_ButtonDownFcn(hObject, eventdata, handles)%#ok<INUSL>
% hObject    handle to kymographAxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% To show a picture with contour and skeleton corresponding at kymograph
% clic

handles = guidata(hObject);

app = getappdata(0, 'app');
nPos = app.analysis.Parameters.KymographAbscissaSize;

% extract last clicked position, x = index of frame
pos = get(handles.kymographAxes, 'CurrentPoint');
posX = pos(1);
posY = pos(3);

% Display marker on kymograph image
if isempty(handles.kymographMarker)
    % create new marker
    axes(handles.kymographAxes); hold on;
    handles.kymographMarker = plot(posX, posY, ...
        'd', 'LineWidth', 1, 'color', 'k', 'MarkerFaceColor', 'w');
else
    % update position of current marker
    set(handles.kymographMarker, 'XData', posX, 'YData', posY);
end

% determine index of frame corresponding to clicked point
calib = app.analysis.InputImages.Calibration;
timeStep = calib.TimeInterval * app.indexStep;
frameIndex = round(posX / timeStep) + 1;
app.currentFrameIndex = frameIndex;

% extract data for current frame
img = app.getImage(frameIndex);
if ndims(img) == 2 %#ok<ISMAT>
    img = repmat(img, [1 1 3]);
end
contour = getSmoothedContour(app, frameIndex);
skeleton = getSkeleton(app, frameIndex).Coords;

% update display
axes(handles.imageAxes);
set(handles.imageHandle, 'CData', img);
set(handles.contourHandle, 'XData', contour(:,1), 'YData', contour(:,2));
set(handles.skeletonHandle, 'XData', skeleton(:,1), 'YData', skeleton(:,2));

% convert y-coordinate to curvilinear abscissa
Smax = app.analysis.AlignedAbscissas{end}(end);
Smin = 0;
Smarker = (posY - Smin) * (Smax - Smin) / nPos;

% convert absolute abscissa to relative abscissa
S = app.analysis.AlignedAbscissas{frameIndex};
relPos = (Smarker - min(S) ) / (max(S) - min(S));
relPos = min(max(relPos, 0), 1);
app.cursorRelativeAbscissa = relPos;

% identify skeleton point corresponding to marker
ind = find(Smarker <= S, 1, 'first');
ind = max(ind, 1);
if isempty(ind)
    ind = size(skeleton, 1);
end
set(handles.imageMarker, 'xdata', skeleton(ind, 1), 'ydata', skeleton(ind, 2));

% update display of frame info
setappdata(0, 'app', app);

if strcmpi(get(handles.colorSkelHandle, 'Visible'), 'On')
    updateColoredSkeleton(handles);
end   

updateCurvilinearMarker(handles);

updateCurrentFrameDisplay(handles);
displayCurrentFrameIndex(handles);
set(handles.currentFrameSlider, 'Value', frameIndex);

% Update handles structure
guidata(hObject, handles);


function updateCurvilinearMarker(handles)

app = getappdata(0, 'app');

% relative abscissa of cursor
relPos = app.cursorRelativeAbscissa;

% coordinates of current skeleton
frameIndex = app.currentFrameIndex;
skeleton = getSkeleton(app, frameIndex).Coords;

% curvilinear abscissa along current skeleton
S = app.analysis.AlignedAbscissas{frameIndex};

% compute absolute curvilinear absissa of marker
markerAbscissa = relPos * (max(S) - min(S)) + min(S);
    
% update position of curvilinear cursor on image display
if isfield(handles, 'imageMarker')
    % identify skeleton point corresponding to marker
    ind = find(markerAbscissa <= S, 1, 'first');
    ind = max(ind, 1);
    if isempty(ind)
        % test returns empty if all absissa are below marker, 
        % so we use last skeleton point
        ind = size(skeleton, 1);
    end
    set(handles.imageMarker, 'xdata', skeleton(ind, 1), 'ydata', skeleton(ind, 2));
end

% update position of marker on kymograph display
if isfield(handles, 'kymographMarker')
    % convert frame index to time position
    calib = app.analysis.InputImages.Calibration;
    posX = (frameIndex - 1) * calib.TimeInterval;
    
    % convert marker abscissa to position on kyomgraph Y axis
    nPos   = app.analysis.Parameters.KymographAbscissaSize;
    Smaxi = app.analysis.AlignedAbscissas{end}(end);
    Smini = app.analysis.AlignedAbscissas{end}(1);
    posY = (markerAbscissa - Smini) / (Smaxi - Smini) * nPos;
    posY = max(min(posY, nPos), 0);
    
    set(handles.kymographMarker, 'XData', posX, 'YData', posY);
    
    % check if marker should be displayed (for elongation kymographs, the
    % number of frames in kymograph is different from frame number in app)
    nFrameKymo = length(get(handles.kymographImage, 'XData'));
    if frameIndex <= nFrameKymo
        set(handles.kymographMarker, 'Visible', 'On');
    else
        set(handles.kymographMarker, 'Visible', 'Off');
    end
end


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

updateKymographDisplay(handles);
if strcmpi(get(handles.colorSkelHandle, 'Visible'), 'On')
    updateColoredSkeleton(handles);
end


% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)%#ok<INUSD>
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function updateKymographDisplay(handles)

app = getappdata(0, 'app');

% retrieve kymograph data
kymo = getCurrentKymograph(app);
img = kymo.Data;

% also retrieve display range
validateDisplayRange(kymo);
minCaxis = kymo.DisplayRange(1);
maxCaxis = kymo.DisplayRange(2);

% display current kymograph
timeStep = app.analysis.InputImages.Calibration.TimeInterval;
xdata = (0:(size(img, 2)-1)) * timeStep;
ydata = 1:size(img, 1);
if isfield(handles, 'kymographImage')
    set(handles.kymographImage, 'xdata', xdata, 'ydata', ydata, 'cdata', img); 
else
    disp('create kymograph image again!');
    axes(handles.kymographAxes); cla;
    handles.kymographImage = imagesc(xdata, ydata, img);
end
xlim(handles.kymographAxes, ([0 size(img,2)] - .5) * timeStep);

% a value to adjust kymograph contrast
val = get(handles.slider1, 'Value');
  
% setup display
axes(handles.kymographAxes);
set(handles.kymographAxes, 'YDir', 'normal', 'YTick', []);
if minCaxis < maxCaxis - val
    clim(handles.kymographAxes, [minCaxis, maxCaxis - val]); 
end
colorbar(handles.kymographAxes);
cmapNames = get(handles.colormapPopup, 'String');
index = get(handles.colormapPopup, 'Value');
colorMapName = strtrim(cmapNames{index});
colormap(handles.kymographAxes, colorMapName);

% annotate
xlabel(sprintf('Time (%s)', app.settings.timeIntervalUnit));


% --- Executes on button press in saveAsPngButton.
function saveAsPngButton_Callback(hObject, eventdata, handles) %#ok<INUSD>
% hObject    handle to saveAsPngButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

gui = KymoRodGui.getInstance();
defaultPath = gui.userPrefs.lastSaveDir;

% open a dialog to select a PNG file
[fileName, pathName] = uiputfile({'*.png'}, ...
    'Save as PNG', defaultPath);

if fileName == 0
    return;
end
gui.userPrefs.lastSaveDir = pathName;

app = getappdata(0, 'app');

hf = figure; 
set(gca, 'fontsize', 14);
showCurrentKymograph(app);
print(hf, fullfile(pathName, fileName), '-dpng');
close(hf);


% --- Executes on button press in saveAsTiffButton.
function saveAsTiffButton_Callback(hObject, eventdata, handles) %#ok<INUSD>
% hObject    handle to saveAsTiffButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

gui = KymoRodGui.getInstance();
defaultPath = gui.userPrefs.lastSaveDir;

% To open the directory who the user want to save the data
[fileName, pathName] = uiputfile({'*.tif'}, ...
    'Save as TIFF', defaultPath);

if fileName == 0
    return;
end
gui.userPrefs.lastSaveDir = pathName;

app = getappdata(0, 'app');

hf = figure; 
set(gca, 'fontsize', 14);
showCurrentKymograph(app);
print(hf, fullfile(pathName, fileName), '-dtiff');
close(hf);


% --- Executes on button press in saveAllDataButton.
function saveAllDataButton_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to saveAllDataButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% disable save button to avoid multiple clicks
set(handles.saveAllDataButton, 'Enable', 'Off')
set(handles.saveAllDataButton, 'String', 'Wait please...')
pause(0.01);

gui = KymoRodGui.getInstance();
defaultPath = gui.userPrefs.lastSaveDir;

% To open the directory who the user want to save the data
[fileName, pathName] = uiputfile('*.mat', ...
    'Save Kymographs', defaultPath);

if pathName == 0
    return;
end
gui.userPrefs.lastSaveDir = pathName;

disp('Saving...');

% retrieve application data
app = getappdata(0, 'app');

% log the path of saving
app.logger.info('DisplayKymograph.m', ...
    ['Save kymograph data into folder: ' pathName]);

% filename of mat file
[emptyPath, baseName, ext] = fileparts(fileName); %#ok<ASGLU>
filePath = fullfile(pathName, [baseName '.mat']);

% save full application data as mat file, without image data
imgTemp = app.imageList;
app.imageList = {};
save(app, filePath);
app.imageList = imgTemp;

% save all informations of experiment, to retrieve them easily
filePath = fullfile(pathName, [baseName '-kymo.txt']);
write(app, filePath);

% save settings of experiment, to apply them to another experiment
filePath = fullfile(pathName, [baseName '-settings.txt']);
write(app.settings, filePath);

% initialize row names
nFrames = frameNumber(app);
rowNames = cell(nFrames, 1);
if isstruct(app.imageNameList)
	for i = 1:nFrames
		rowNames{i} = app.imageNameList(i).name;
	end
elseif iscell(app.imageNameList)
	for i = 1:nFrames
		rowNames{i} = app.imageNameList{i};
	end
else
	for i = 1:nFrames
		rowNames{i} = sprintf('frame%03d', i);
	end
end

% save individual image arrays
RE1     = app.radiusImage;
AE1     = app.verticalAngleImage;
CE1     = app.curvatureImage;
ElgE1   = app.elongationImage;

% initialize col names: a list of values
nPositions = app.settings.finalResultLength;
colNames = strtrim(cellstr(num2str((1:nPositions)', '%d'))');

% Save each data file as tab separated values
filePath = fullfile(pathName, [baseName '-radius.csv']);
writeTable(RE1', colNames, rowNames, filePath);

filePath = fullfile(pathName, [baseName '-angle.csv']);
writeTable(AE1', colNames, rowNames, filePath);

filePath = fullfile(pathName, [baseName '-curvature.csv']);
writeTable(CE1', colNames, rowNames, filePath);

filePath = fullfile(pathName, [baseName '-elongation.csv']);
rowNames2 = rowNames(1:end-app.settings.displacementStep);
writeTable(ElgE1', colNames, rowNames2, filePath);

disp('Saving done');

% re-enable save button
set(handles.saveAllDataButton, 'Enable', 'On')
set(handles.saveAllDataButton, 'String', 'Save all data')


% --- Executes on button press in backToElongationButton.
function backToElongationButton_Callback(hObject, eventdata, handles) %#ok<INUSD>
% hObject    handle to backToElongationButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

app = getappdata(0, 'app');
delete(gcf);
ChooseElongationSettingsDialog(app);


% --- Executes on button press in quitButton.
function quitButton_Callback(hObject, eventdata, handles) %#ok<INUSD>
% hObject    handle to quitButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

button = questdlg({'This will quit the program', 'Are you sure ?'}, ...
    'Quit Confirmation', ... 
    'Yes', 'No', 'No');

if strcmp(button, 'Yes')
    delete(gcf);
end



% --- Executes on button press in intensityKymographButton.
function intensityKymographButton_Callback(hObject, eventdata, handles)%#ok<INUSL>
% hObject    handle to intensityKymographButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

app = getappdata(0, 'app');
delete(gcf);
SelectIntensityImagesDialog(app);

