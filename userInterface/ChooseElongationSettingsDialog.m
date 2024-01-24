function varargout = ChooseElongationSettingsDialog(varargin)
% CHOOSEELONGATIONSETTINGSDIALOG MATLAB code for ChooseElongationSettingsDialog.fig
%      CHOOSEELONGATIONSETTINGSDIALOG, by itself, creates a new CHOOSEELONGATIONSETTINGSDIALOG or raises the existing
%      singleton*.
%
%      H = CHOOSEELONGATIONSETTINGSDIALOG returns the handle to a new CHOOSEELONGATIONSETTINGSDIALOG or the handle to
%      the existing singleton*.
%
%      CHOOSEELONGATIONSETTINGSDIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CHOOSEELONGATIONSETTINGSDIALOG.M with the given input arguments.
%
%      CHOOSEELONGATIONSETTINGSDIALOG('Property','Value',...) creates a new CHOOSEELONGATIONSETTINGSDIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ChooseElongationSettingsDialog_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ChooseElongationSettingsDialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ChooseElongationSettingsDialog

% Last Modified by GUIDE v2.5 22-Sep-2017 17:31:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ChooseElongationSettingsDialog_OpeningFcn, ...
                   'gui_OutputFcn',  @ChooseElongationSettingsDialog_OutputFcn, ...
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


% --- Executes just before ChooseElongationSettingsDialog is made visible.
function ChooseElongationSettingsDialog_OpeningFcn(hObject, eventdata, handles, varargin)%#ok
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ChooseElongationSettingsDialog (see VARARGIN)


% Choose default command line output for ChooseElongationSettingsDialog
handles.output = hObject;

if nargin == 4 && isa(varargin{1}, 'KymoRodData')
    app = varargin{1};
    setappdata(0, 'app', app);
 
else
    % if user come from ValidateSkeleton
    error('StartElongation should be called with an KymoRodData object');
end

app.logger.info('ChooseElongationSettingsDialog_OpeningFcn', ...
    'Open dialog "ChooseElongationSettingsDialog"');

% setup figure menu
gui = KymoRodGui.getInstance();
buildFigureMenu(gui, hObject, app);

% setup handles with application settings
updateWidgets(app, handles);

% enable button for next step
set(handles.validateSettingsButton, 'Enable', 'On')
set(handles.validateSettingsButton, 'String', 'Compute Elongations');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ChooseElongationSettingsDialog wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ChooseElongationSettingsDialog_OutputFcn(hObject, eventdata, handles) %#ok<INUSL>
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function updateWidgets(app, handles)
% setup handles with application settings

settings = app.settings;

% if image for displacement is grayscale or intensity, disable the widgets
% for choosing channel
img = getImageForDisplacement(app, 1);
if ndims(img) == 2 %#ok<ISMAT>
    set(handles.displacementChannelLabel,   'Enable', 'off');
    set(handles.displacementChannelPopupMenu, 'Enable', 'off');
else
    values = get(handles.displacementChannelPopupMenu, 'String');
    index = find(strcmp(cellstr(values), app.settings.displacementChannel));
    set(handles.displacementChannelPopupMenu, 'Value', index);
    set(handles.displacementChannelLabel,   'Enable', 'on');
    set(handles.displacementChannelPopupMenu, 'Enable', 'on');
end
 
set(handles.displacementStepEdit,       'String', num2str(settings.displacementStep));
set(handles.displacementStepEdit,       'String', num2str(settings.displacementStep));
set(handles.correlationWindowSize1Edit, 'String', num2str(settings.windowSize1));

% computation of elongation
set(handles.displacementSpatialSmoothingEdit,   'String', num2str(settings.displacementSpatialSmoothing));
set(handles.displacementValueSmoothingEdit,     'String', num2str(settings.displacementValueSmoothing));
set(handles.displacementResamplingDistanceEdit, 'String', num2str(settings.displacementResamplingDistance));
set(handles.correlationWindowSize2Edit, 'String', num2str(settings.windowSize2));


% --------------------------------------------------------------------
function mainFrameMenuItem_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to mainFrameMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

app = getappdata(0, 'app');
delete(gcf);
KymoRodMenuDialog(app);


function smoothingLengthEdit_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to smoothingLengthEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of smoothingLengthEdit as text
%        str2double(get(hObject,'String')) returns contents of smoothingLengthEdit as a double

str  = get(handles.smoothingLengthEdit, 'String');

app = getappdata(0, 'app');
app.logger.info('ChooseElongationSettingsDialog.m', ...
    ['Change value of smoothingLength to ' str]);

val  = str2double(str);
if isnan(val) || val < 0
    error('input ''%s'' must be a positive numeric value', str);
end

app.settings.curvatureSmoothingSize = val;

gui = KymoRodGui.getInstance();
gui.userPrefs.settings.curvatureSmoothingSize = val;

setProcessingStep(app, ProcessingStep.Skeleton);


% --- Executes during object creation, after setting all properties.
function smoothingLengthEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to smoothingLengthEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function pointNumberEdit_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to pointNumberEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pointNumberEdit as text
%        str2double(get(hObject,'String')) returns contents of pointNumberEdit as a double

str  = get(handles.pointNumberEdit, 'String');

app = getappdata(0, 'app');
app.logger.info('ChooseElongationSettingsDialog.m', ...
    ['Change value of finalResultLength to ' str]);

val  = str2double(str);
if isnan(val) || val < 0
    error('input ''%s'' must be a positive numeric value', str);
end

app.settings.finalResultLength = val;

gui = KymoRodGui.getInstance();
gui.userPrefs.settings.finalResultLength = val;

setProcessingStep(app, ProcessingStep.Skeleton);


% --- Executes during object creation, after setting all properties.
function pointNumberEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to pointNumberEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in displacementChannelPopupMenu.
function displacementChannelPopupMenu_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to displacementChannelPopupMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns displacementChannelPopupMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from displacementChannelPopupMenu

app = getappdata(0, 'app');
stringArray = get(handles.displacementChannelPopupMenu, 'String');
value = get(handles.displacementChannelPopupMenu, 'Value');
channelString = lower(char(strtrim(stringArray(value,:))));

app.logger.info(mfilename, ...
    ['Change image channel for displacement to: ' channelString]);

app.settings.displacementChannel = channelString;

gui = KymoRodGui.getInstance();
gui.userPrefs.settings.displacementChannel = channelString;

setProcessingStep(app, ProcessingStep.Skeleton);


% --- Executes during object creation, after setting all properties.
function displacementChannelPopupMenu_CreateFcn(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to displacementChannelPopupMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function displacementStepEdit_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to displacementStepEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of displacementStepEdit as text
%        str2double(get(hObject,'String')) returns contents of displacementStepEdit as a double

str  = get(handles.displacementStepEdit, 'String');
app = getappdata(0, 'app');
app.logger.info('ChooseElongationSettingsDialog.m', ...
    ['Change value of displacement step to ' str]);

val  = str2double(str);
if isnan(val) || val < 0
    error('input ''%s'' must be a positive numeric value', str);
end

app.settings.displacementStep = val;

gui = KymoRodGui.getInstance();
gui.userPrefs.settings.displacementStep = val;

setProcessingStep(app, ProcessingStep.Skeleton);


% --- Executes during object creation, after setting all properties.
function displacementStepEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to displacementStepEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end



function correlationWindowSize1Edit_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to correlationWindowSize1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of correlationWindowSize1Edit as text
%        str2double(get(hObject,'String')) returns contents of correlationWindowSize1Edit as a double

str  = get(handles.correlationWindowSize1Edit, 'String');

app = getappdata(0, 'app');
app.logger.info('ChooseElongationSettingsDialog.m', ...
    ['Change value of windowSize1 to ' str]);

val  = str2double(str);
if isnan(val) || val < 0
    error('input ''%s'' must be a positive numeric value', str);
end

app.settings.windowSize1 = val;

gui = KymoRodGui.getInstance();
gui.userPrefs.settings.windowSize1 = val;

setProcessingStep(app, ProcessingStep.Skeleton);


% --- Executes during object creation, after setting all properties.
function correlationWindowSize1Edit_CreateFcn(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to correlationWindowSize1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function displacementSpatialSmoothingEdit_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to displacementSpatialSmoothingEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of displacementSpatialSmoothingEdit as text
%        str2double(get(hObject,'String')) returns contents of displacementSpatialSmoothingEdit as a double


str  = get(handles.displacementSpatialSmoothingEdit, 'String');

app = getappdata(0, 'app');
app.logger.info('ChooseElongationSettingsDialog.m', ...
    ['Change value of displacementSpatialSmoothing to ' str]);

val  = str2double(str);
if isnan(val) || val < 0
    error('input ''%s'' must be a positive numeric value', str);
end

app.settings.displacementSpatialSmoothing = val;

gui = KymoRodGui.getInstance();
gui.userPrefs.settings.displacementSpatialSmoothing = val;

setProcessingStep(app, ProcessingStep.Skeleton);


% --- Executes during object creation, after setting all properties.
function displacementSpatialSmoothingEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to displacementSpatialSmoothingEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function displacementValueSmoothingEdit_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to displacementValueSmoothingEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of displacementValueSmoothingEdit as text
%        str2double(get(hObject,'String')) returns contents of displacementValueSmoothingEdit as a double

str  = get(handles.displacementValueSmoothingEdit, 'String');

app = getappdata(0, 'app');
app.logger.info('ChooseElongationSettingsDialog.m', ...
    ['Change value of displacementValueSmoothing to ' str]);

val  = str2double(str);
if isnan(val) || val < 0
    error('input ''%s'' must be a positive numeric value', str);
end

app.settings.displacementValueSmoothing = val;

gui = KymoRodGui.getInstance();
gui.userPrefs.settings.displacementValueSmoothing = val;

setProcessingStep(app, ProcessingStep.Skeleton);


% --- Executes during object creation, after setting all properties.
function displacementValueSmoothingEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to displacementValueSmoothingEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function displacementResamplingDistanceEdit_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to displacementResamplingDistanceEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of displacementResamplingDistanceEdit as text
%        str2double(get(hObject,'String')) returns contents of displacementResamplingDistanceEdit as a double

str  = get(handles.displacementResamplingDistanceEdit, 'String');

app = getappdata(0, 'app');
app.logger.info('ChooseElongationSettingsDialog.m', ...
    ['Change value of displacementSamplingDistance to ' str]);

val  = str2double(str);
if isnan(val) || val < 0
    error('input ''%s'' must be a positive numeric value', str);
end

app.settings.displacementResamplingDistance = val;

gui = KymoRodGui.getInstance();
gui.userPrefs.settings.displacementResamplingDistance = val;

setProcessingStep(app, ProcessingStep.Skeleton);


% --- Executes during object creation, after setting all properties.
function displacementResamplingDistanceEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to displacementResamplingDistanceEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function correlationWindowSize2Edit_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to correlationWindowSize2Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of correlationWindowSize2Edit as text
%        str2double(get(hObject,'String')) returns contents of correlationWindowSize2Edit as a double

str  = get(handles.correlationWindowSize2Edit, 'String');

app = getappdata(0, 'app');
app.logger.info('ChooseElongationSettingsDialog.m', ...
    ['Change value of windowSize2 to ' str]);

val  = str2double(str);
if isnan(val) || val < 0
    error('input ''%s'' must be a positive numeric value', str);
end

app.settings.windowSize2 = val;

gui = KymoRodGui.getInstance();
gui.userPrefs.settings.windowSize2 = val;

setProcessingStep(app, ProcessingStep.Skeleton);


% --- Executes during object creation, after setting all properties.
function correlationWindowSize2Edit_CreateFcn(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to correlationWindowSize2Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in defaultSettingsButton.
function defaultSettingsButton_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to defaultSettingsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get settings object of app
app = getappdata(0, 'app');
app.logger.info('ChooseElongationSettingsDialog.m', ...
    'Choose default settings');

% Reset to default parameters
settings = app.settings;
settings.curvatureSmoothingSize = 10;
settings.finalResultLength = 500;
settings.windowSize1 = 5;
settings.windowSize2 = 30;
settings.displacementStep = 2;

% update processing step
setProcessingStep(app, ProcessingStep.Skeleton);

% refresh display
updateWidgets(app, handles);


% --- Executes on button press in backToSkeletonButton.
function backToSkeletonButton_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to backToSkeletonButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

app = getappdata(0, 'app');
delete(gcf);
ValidateSkeletonDialog(app);


% --- Executes on button press in validateSettingsButton.
function validateSettingsButton_Callback(hObject, eventdata, handles)%#ok
% hObject    handle to validateSettingsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% To start the programm
set(handles.validateSettingsButton, 'Enable', 'Off')
set(handles.validateSettingsButton, 'String', 'Wait please...')
pause(0.01);

% get global data
app = getappdata(0, 'app');

tic;
computeCurvaturesDisplacementAndElongation(app);
dt = toc;
disp(sprintf('Computation of elongation took %f mn', dt / 60)); %#ok<DSPS>

setProcessingStep(app, ProcessingStep.Kymograph);

delete(gcf);

disp('Display Kymographs');
DisplayKymograph(app);


