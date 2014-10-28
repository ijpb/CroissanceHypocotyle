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

% Last Modified by GUIDE v2.5 28-Oct-2014 12:17:22

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

if nargin == 4 && isa(varargin{1}, 'HypoGrowthAppData')
    app = varargin{1};
    app.currentStep = 'kymograph';
    setappdata(0, 'app', app);
    
else
    error('Run DisplayKymograph using deprecated call');
end

% Display current image
CTVerif = app.contourList;
SKVerif = app.skeletonList;
axes(handles.imageAxes);
ind = app.currentFrameIndex;
imshow(app.imageList{ind});
hold on;
drawContour(CTVerif{ind}, 'r');
drawSkeleton(SKVerif{ind}, 'b');
colormap gray;
freezeColors;

% compute display extent for elongation kymograph
img = app.elongationImage;
minCaxis = min(img(:));
maxCaxis = max(img(:));

setappdata(0, 'minCaxis', minCaxis);
setappdata(0, 'maxCaxis', maxCaxis);

set(handles.slider1, 'Min', minCaxis);
set(handles.slider1, 'Max', maxCaxis);
set(handles.slider1, 'Value', minCaxis);

updateKymographDisplay(handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes DisplayKymograph wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = DisplayKymograph_OutputFcn(hObject, eventdata, handles)%#ok<INUSL>
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% --------------------------------------------------------------------
function mainMenuMenuItem_Callback(hObject, eventdata, handles) %#ok<INUSD>
% hObject    handle to mainMenuMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

app = getappdata(0, 'app');
delete(gcf);
HypoGrowthMenu(app);


% --- Executes on selection change in kymographTypePopup.
function kymographTypePopup_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to kymographTypePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns kymographTypePopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from kymographTypePopup
% To select the kymograph with a popupmenu

app = getappdata(0, 'app');

% Choose the kymograph to display
valPopUp = get(handles.kymographTypePopup, 'Value');
switch valPopUp
    case 1, img = app.elongationImage;
    case 2, img = app.radiusImage;
    case 3, img = app.curvatureImage;
    case 4, img = app.verticalAngleImage;
end
minCaxis = min(img(:));
maxCaxis = max(img(:));

setappdata(0, 'minCaxis', minCaxis);
setappdata(0, 'maxCaxis', maxCaxis);

set(handles.slider1, 'Min', minCaxis);
set(handles.slider1, 'Max', maxCaxis);
set(handles.slider1, 'Value', minCaxis);


updateKymographDisplay(handles);



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

% --- Executes on mouse press over axes background.
function kymographAxes_ButtonDownFcn(hObject, eventdata, handles)%#ok
% hObject    handle to kymographAxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% To show a picture with contour and skeleton corresponding at kymograph
% clic

handles = guidata(hObject);

app     = getappdata(0, 'app');
red     = app.imageList;
CTVerif = app.contourList;
SKVerif = app.skeletonList;
nx      = app.finalResultLength;

% extract last clicked position
pos = get(handles.kymographAxes, 'CurrentPoint');
posX = pos(1);
posY = pos(3);

% extract min/max values of axes
P = get(handles.kymographAxes, 'XLim');
min = P(1); 
max = P(2); 

% Take the value of pop up menu
valPopUp = get(handles.kymographTypePopup, 'Value'); 

if valPopUp == 1 % 1 for elongation
    if posX < min + 0.05 
        % Process the first image (not shown in kymograph)
        axes(handles.imageAxes);
        imshow(red{1});
        hold on;
        drawContour(CTVerif{1}, 'r');
        drawSkeleton(SKVerif{1}, 'b');

        colormap gray;
        freezeColors;
        nbPoints = length(SKVerif{1});
        ind = round((nbPoints * posY) / nx);
        drawMarker(SKVerif{1}(ind, :), 'd', 'Color', 'c', 'LineWidth', 3);
        
    elseif posX > max - 0.05 
        % Process the last image (not shown in kymograph)
        axes(handles.imageAxes);
        imshow(red{end});
        hold on;
        drawContour(CTVerif{end}, 'r');
        drawSkeleton(SKVerif{end}, 'b');
        colormap gray;
        freezeColors;
        nbPoints = length(SKVerif{end});
        ind = round((nbPoints * posY) / nx);
        drawMarker(SKVerif{end}(ind, :), 'd', 'Color', 'c', 'LineWidth', 3);
        
    else
        for i = (min - 0.5):(max - 0.5)
            % process all other image, shown in the kymograph
            if posX > i-0.5 && posX < i+0.5
                axes(handles.imageAxes);%#ok
                imshow(red{i+1});
                hold on;
                drawContour(CTVerif{i+1}, 'r');
                drawSkeleton(SKVerif{i+1}, 'b');

                colormap gray;
                freezeColors;
                nbPoints = length(SKVerif{i+1});
                ind = round((nbPoints * posY) / nx);
                drawMarker(SKVerif{i+1}(ind, :), 'd', 'Color', 'c', 'LineWidth', 3);
            end
        end
    end
end

% display angle, curvature or radius
if valPopUp == 2 || valPopUp == 3 || valPopUp == 4 
    for i = (min - 0.5):(max - 0.5)
        if posX > i-0.5 && posX < i+0.5
            axes(handles.imageAxes);%#ok
            imshow(red{i});
            hold on;
            drawContour(CTVerif{i}, 'r');
            drawSkeleton(SKVerif{i}, 'b');

            colormap gray;
            freezeColors;
            
            nbPoints = length(SKVerif{i});
            ind = round((nbPoints * posY) / nx);
            drawMarker(SKVerif{i}(ind, :), 'd', 'Color', 'c', 'LineWidth', 3);
        end
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

minCaxis = getappdata(0, 'minCaxis');
maxCaxis = getappdata(0, 'maxCaxis');

% a value to adjust kymograph contrast
val = get(handles.slider1, 'Value');
  
% Choose the kymograph to display
valPopUp = get(handles.kymographTypePopup, 'Value');
switch valPopUp
    case 1, img = app.elongationImage;
    case 2, img = app.radiusImage;
    case 3, img = app.curvatureImage;
    case 4, img = app.verticalAngleImage;
end

% display current kymograph
axes(handles.kymographAxes);
hImg = imagesc(img);

% setup display
set(gca, 'YDir', 'normal');
caxis([minCaxis, maxCaxis - val]); colorbar;
colormap jet;
freezeColors;

set(hImg, 'buttondownfcn', {@kymographAxes_ButtonDownFcn, handles});

% annotate
str = sprintf('one equals %d minutes', app.timeInterval);
xlabel(str);


% --- Executes on button press in saveAsPngButton.
function saveAsPngButton_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to saveAsPngButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    % open a dialog to select a PNG file
    [fileName, pathName] = uiputfile({'*.png'});
    
    % select current frame and convert to image
    f = getframe(handles.kymographAxes);
    im = frame2im(f);
    
    % save image into selected file
    imwrite(im, fullfile(pathName, fileName), 'png');
    
catch error %#ok
    warning('Select a folder to save picture please');
    return;
end


% --- Executes on button press in saveAsTiffButton.
function saveAsTiffButton_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to saveAsTiffButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    % open a dialog to select a PNG file
    [fileName, pathName] = uiputfile({'*.tif'});
    
    % select current frame and convert to image
    f = getframe(handles.kymographAxes);
    im = frame2im(f);
    
    % save image into selected file
    imwrite(im, fullfile(pathName, fileName), 'tif');

catch error%#ok
    warning('Select a folder to save picture please');
    return;
end

% --- Executes on button press in saveAllDataButton.
function saveAllDataButton_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to saveAllDataButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.saveAllDataButton, 'Enable', 'Off')
set(handles.saveAllDataButton, 'String', 'Wait please...')
pause(0.01);

% retrieve application data
app     = getappdata(0, 'app');
ElgE1   = app.elongationImage;
CE1     = app.curvatureImage;
AE1     = app.verticalAngleImage;
RE1     = app.radiusImage;

% To open the directory who the user want to save the data
[fileName, pathName] = uiputfile('*.*', 'Create a directory to save your data');
nameDir = fullfile(pathName, fileName);

if pathName == 0
    warning('Select a file please');
    return;
end

disp('Saving...');

mkdir(nameDir);
fileName = 'data.mat';
nameData = fullfile(nameDir, fileName);

save(nameData, 'app');

n = length(app.imageList);

pathElongation = fullfile(nameDir, 'dataElongation.csv');
pathAngle = fullfile(nameDir, 'dataAngle.csv');
pathCurvature = fullfile(nameDir, 'dataCurvature.csv');
pathRadius = fullfile(nameDir, 'dataRadius.csv');

colNames = cell(n,1);
for i = 1 : n
    colNames{i} = sprintf('frame%03d', i);
end

colsElongation = cell(n-2, 1);
for i = 2 : n-1
    colsElongation{i - 1} = strcat('frame', num2str(i));
end

% Strtrim pour supprimer les espaces!
colNames = strtrim(colNames);
colsElongation = strtrim(colsElongation);


tabElongation = Table(ElgE1, 'colNames', colsElongation);
write(tabElongation, pathElongation);

tabAngle = Table(AE1, 'colNames', colNames);
write(tabAngle, pathAngle);

tabCurvature = Table(CE1, 'colNames', colNames);
write(tabCurvature, pathCurvature);

tabRadius = Table(RE1, 'colNames', colNames);
write(tabRadius, pathRadius);

disp('Saving done');
  
set(handles.saveAllDataButton, 'Enable', 'On')
set(handles.saveAllDataButton, 'String', 'Save all data')


% --- Executes on button press in backToElongationButton.
function backToElongationButton_Callback(hObject, eventdata, handles) %#ok<INUSD>
% hObject    handle to backToElongationButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

app = getappdata(0, 'app');
delete(gcf);
StartElongation(app);


% --- Executes on button press in computeComposedKymographButton.
function computeComposedKymographButton_Callback(hObject, eventdata, handles)%#ok<INUSD>
% hObject    handle to computeComposedKymographButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

app = getappdata(0, 'app');
delete(gcf);
StartComposedElongation(app);
