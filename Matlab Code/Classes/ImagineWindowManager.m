classdef (Sealed = true) ImagineWindowManager < handle
    
   % Responsible for rendering the main Imagine window and listening to
   % relevant classes for changes that should trigger rendering updates.
   
   % So it maintains the list of crop names and regime names in the
   % listboxes. It maintains the handles for all the axes elements, and
   % updates them accordingly. It's really a rendering class. It updates
   % visual elements. But it doesn't have callbacks going directly to it.
   % (Maybe a few functions to set it up, but then it's about listening in
   % order to keep it all up to date.) The callbacks on the buttons go to
   % the Imagine figure's m-file callbacks. They usually trigger data
   % changes (remove crop, add crop, etc).
   
   % One callback that should be in this class is the one that listens for
   % clicks on the main axis. It needs to update which year has been
   % clicked on and change the paddock axis etc.


   properties
    
       % We maintain a reference to the singleton objects 
       % imagineObject 
       % cropManager
       % regimeManager
       % for convenience
       imagineOb
       cropMgr
       regimeMgr
       climateMgr


              
       % We keep a list of Layouts which act a little like controls now.
       % Once initialised, the Layouts will resond to a button click and
       % will update as appropriate.
       layouts = Layout.empty(0, 0)
       
       % dividerLines is an array of handles to lines drawn between the
       % rows of layouts.
       dividerLines
       
       % An array of RegimeTimeline objects. There should always be as many
       % regimeTimelines as there are regimes.
       regimeTimelines
       
       % The user may click on a layout to 'select' it, such that more
       % detailed info for the layout of that year appears in the yearly
       % summary. This property maintains the record of the year that was
       % selected. It is one by default.
       selectedYear = 1;
              
       % Arrays to hold listeners. These are refreshed when the Imagine
       % Object is loaded.
       updateLayoutListeners = event.listener.empty(1,0);
       updateCropListListeners = event.listener.empty(1,0);
       updateRegimeListListeners = event.listener.empty(1,0);
       updatePaddockLayoutListeners = event.listener.empty(1,0);
       
   end

   properties (Access = private)
      privateSelectYearPatchHandle = 0;
   end
   
   properties (Dependent)
      % The selectYearPatchHandle is dependent because it should be created
      % if it doesn't exist, or referred to if it already exists.
      selectYearPatchHandle 
      
       % The handle to the main Imagine figure and the handles field for
       % the figure. The window's controls should be loaded from window and
       % saved back whenever they are needed in this code.
       window = handle.empty(0)
   end
   
   methods
      
       function yph = get.selectYearPatchHandle(iwm)
           if ishandle(iwm.privateSelectYearPatchHandle)
               % return the private handle if it exists
               yph = iwm.privateSelectYearPatchHandle;
           else
               % else create it and return it.
          %     iwm.privateSelectYearPatchHandle = patch(iwm.window, [6 6 64 64], [26 84 84 26], 'k', 'EdgeColor', [0.5 0.5 1], 'LineWidth', 1, 'FaceAlpha', 0.12, 'Visible', 'off');
               yph = iwm.privateSelectYearPatchHandle;
           end
       end
       
       % Allow the patch handle to be set.
       function set.selectYearPatchHandle(iwm, h)
          iwm.privateSelectYearPatchHandle = h; 
       end
       
   end
   
   % The private constructor and static getInstance methods are needed to
   % implement the singleton instance of an ImagineWindowManager.
   methods (Access = private)
      
       function iwm = ImagineWindowManager()
       end
       
       function imagineWindowManagerConstructor(iwm)
            iwm.refreshManagerPointers
       end
              
   end
   
   % Static getInstance method provides global access to the singleton
   % ImagineObject.
   methods (Static)
       
       function singleObj = getInstance
           persistent localObj
           if isempty(localObj) || ~isvalid(localObj)
               localObj = ImagineWindowManager;
               localObj.imagineWindowManagerConstructor;
           end
           singleObj = localObj;
       end

   end
    
   
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %
   % Ordinary methods start here.
   %
   methods
       
        % Fairly sure this is the only place we should ever call
        % ImagineWindow.
       function singleWindow = get.window(iwm)
          persistent localWindow
          if isempty(localWindow) || ~ishandle(localWindow) || localWindow == 0
              localWindow = ImagineWindow;
          end
          singleWindow = localWindow;
       end
       
        function refreshManagerPointers(iwm)
              iwm.imagineOb = ImagineObject.getInstance;          
              iwm.cropMgr = CropManager.getInstance;
              iwm.regimeMgr = RegimeManager.getInstance;
              iwm.climateMgr = ClimateManager.getInstance;
              
              if ishandle(iwm.window)
                  handles = guidata(iwm.window);
                  handles.cropMgr = CropManager.getInstance;
                  handles.iwm = ImagineWindowManager.getInstance;
                  handles.imagineOb = ImagineObject.getInstance;
                  handles.regimeMgr = RegimeManager.getInstance;
                  handles.climateMgr = ClimateManager.getInstance;

                  guidata(iwm.window, handles);
              end    
             
        end
       
        function updateRegimeList(iwm, src, evtData)
           % get the list of regimes from the regimeManager, then put it in the
           % listbox.
                      
           % Possible cases: added new, changed existing, or removed existing.
           handles = guidata(iwm.window);
           
           if isempty(evtData)
                % Then clear the list.
                set(handles.regimeListBox, 'String', {});
                return
           end
           
           set(handles.regimeListBox, 'String', {evtData.regimeDefinitionList.regimeLabel});
           
           if isempty(evtData.newName) 
                % If we removed a name, then make sure that the selection
                % isn't beyond the range of the list.
                if get(handles.regimeListBox, 'Value') > length(evtData.regimeDefinitionList)
                    set(handles.regimeListBox, 'Value', length(evtData.regimeDefinitionList));
                end
           else
               % If we editted or added a name, then this one should be
               % selected.
               set(handles.regimeListBox, 'Value', find(strcmp(evtData.newName, {evtData.regimeDefinitionList.regimeLabel}), 1));
           end 
       end % end updateRegimeList
       
       function updateCropList(iwm, src, evtData)
           % get the list of crops from the cropManager, then put it in the
           % listbox.
           
           % Possible cases: added new, changed existing, or removed existing.
           handles = guidata(iwm.window);
           set(handles.cropListBox, 'String', evtData.cropList);
           
           if isempty(evtData.newName) 
                % If we removed a name, then make sure that the selection
                % isn't beyond the range of the list.
                if get(handles.cropListBox, 'Value') > length(evtData.cropList)
                    set(handles.cropListBox, 'Value', length(evtData.cropList));
                end
           else
               % If we editted or added a name, then this one should be
               % selected.
               strcmp(evtData.newName, evtData.cropList)
    
               find(strcmp(evtData.newName, evtData.cropList), 1)
               set(handles.cropListBox, 'Value', find(strcmp(evtData.newName, evtData.cropList), 1));
           end 
       end % end updateCropList
       
       function updateCropColour(src, evtData)
           % Need to look up any graphics items that are using the crop's
           % colour and update them to the new colour.
       end
       
       
       function updateCropCategory(src, evtData)
        % This is not actually an event that should be listened for here.
        % Thats because crop category is not displayed in any way.
        % However, the regimeManager should care and check that the crop
        % category change has not stuffed up it's regimes. It may have and
        % a regime might go. However, until the regimeManager changes it's
        % regime the imagineWindowManager doesm't care. So it should be
        % listening to regime changes. Not crop category changes.
       end
          
       function updateTitle(iwm, type, path)
           
          if nargin == 3
              imroot = ImagineObject.imagineRoot;
               k = strfind(path, imroot);
               if ~isempty(k)
                   if k == 1
                      path = path(length(imroot)+1: end); 
                   end                   
               end
          end
           
           if strcmp(type, 'initialised')
               set(iwm.window, 'Name', 'Imagine Window');
           elseif strcmp(type, 'loaded')
               set(iwm.window, 'Name', ['Imagine Window - last loaded from: ', path]);
           elseif strcmp(type, 'saved')
               set(iwm.window, 'Name', ['Imagine Window - last saved to: ', path]);               
           else
               error('ImagineWindowManager.updateTitle called with unrecognized first parameter.');
           end
       end
       
              
       % This function sets up the controls in the window so they are
       % showing the right data.
       % It also sets up listeners to the cropMgr and the regimeMgr.
       function setupWindow(iwm)

          enableDisableFig(iwm.window, 'off');
         
          % Set up the Layouts
          iwm.initialiseLayouts;
          
          iwm.updateEverything;
          
          enableDisableFig(iwm.window, 'on');          
          
       end
       
       % The layouts and the paddock summary have the same set of event that should trigger updates.
       function addUpdateLayoutListeners(iwm)
          
           for i=1:length(iwm.updateLayoutListeners)
               delete(iwm.updateLayoutListeners(i));
           end
               
          iwm.updateLayoutListeners(1) = addlistener(iwm.cropMgr, 'CropEditted', @(src, evnt)updateLayouts(iwm));
          iwm.updateLayoutListeners(2) = addlistener(iwm.regimeMgr, 'RegimeAdded', @(src, evnt)updateLayouts(iwm));
          iwm.updateLayoutListeners(3) = addlistener(iwm.regimeMgr, 'RegimeEditted', @(src, evnt)updateLayouts(iwm));
          iwm.updateLayoutListeners(4) = addlistener(iwm.regimeMgr, 'RegimeRemoved', @(src, evnt)updateLayouts(iwm));
          
          iwm.updatePaddockLayoutListeners(1) = addlistener(iwm.cropMgr, 'CropEditted', @(src, evnt)setupYearlySummary(iwm));
          iwm.updatePaddockLayoutListeners(2) = addlistener(iwm.regimeMgr, 'RegimeAdded', @(src, evnt)setupYearlySummary(iwm));
          iwm.updatePaddockLayoutListeners(3) = addlistener(iwm.regimeMgr, 'RegimeEditted', @(src, evnt)setupYearlySummary(iwm));
          iwm.updatePaddockLayoutListeners(4) = addlistener(iwm.regimeMgr, 'RegimeRemoved', @(src, evnt)setupYearlySummary(iwm));
         
       end       
       
       function addUpdateCropListListeners(iwm)
          
           for i=1:length(iwm.updateCropListListeners)
               delete(iwm.updateCropListListeners(i));
           end
               
          iwm.updateCropListListeners(1) = addlistener(iwm.cropMgr, 'CropAdded', @(src, evnt)updateCropList(iwm, src, evnt));
          iwm.updateCropListListeners(2) = addlistener(iwm.cropMgr, 'CropEditted', @(src, evnt)updateCropList(iwm, src, evnt));
          iwm.updateCropListListeners(3) = addlistener(iwm.cropMgr, 'CropRemoved', @(src, evnt)updateCropList(iwm, src, evnt));
          
       end
       
       function addUpdateRegimeListListeners(iwm)
          
           for i=1:length(iwm.updateRegimeListListeners)
               delete(iwm.updateRegimeListListeners(i));
           end
               
          iwm.updateRegimeListListeners(1) = addlistener(iwm.regimeMgr, 'RegimeAdded', @(src, evnt)updateRegimeList(iwm, src, evnt));
          iwm.updateRegimeListListeners(2) = addlistener(iwm.regimeMgr, 'RegimeEditted', @(src, evnt)updateRegimeList(iwm, src, evnt));
          iwm.updateRegimeListListeners(3) = addlistener(iwm.regimeMgr, 'RegimeRemoved', @(src, evnt)updateRegimeList(iwm, src, evnt));
          
          iwm.updateRegimeListListeners(4) = addlistener(iwm.regimeMgr, 'RegimeAdded', @(src, evnt)addRegimeTimeline(iwm, src, evnt));
          iwm.updateRegimeListListeners(5) = addlistener(iwm.regimeMgr, 'RegimeEditted', @(src, evnt)updateRegimeTimeline(iwm, src, evnt));
          iwm.updateRegimeListListeners(6) = addlistener(iwm.regimeMgr, 'RegimeRemoved', @(src, evnt)removeRegimeTimeline(iwm, src, evnt));
        
       end
       
       function addRegimeTimeline(iwm, src, evnt)
           regDef = iwm.regimeMgr.getRegimeDefinition(evnt.newName);
           
           if ~isempty(regDef)
               handles = guidata(iwm.window);
                iwm.regimeTimelines(end + 1) = RegimeTimeline(evnt.newName, regDef.startYear, regDef.finalYear, regDef.timelineColour, regDef.type, handles.axes1);
           end
       end
       
       function updateRegimeTimeline(iwm, src, evnt)
           regDef = iwm.regimeMgr.getRegimeDefinition(evnt.previousName);
           ix = find(strcmp({iwm.regimeTimelines.regimeLabel}, evnt.previousName), 1, 'first');
           if isempty(ix)
               error('Could not find the regime to edit...')
           end
           iwm.regimeTimelines(ix).update(evnt.newName, regDef.startYear, regDef.finalYear, regDef.timelineColour);
       end
       
       function removeRegimeTimeline(iwm, src, evnt)
           ix = find(strcmp({iwm.regimeTimelines.regimeLabel}, evnt.previousName), 1, 'first');
           if isempty(ix)
               error('Could not find the regime to remove...')
           end
           iwm.regimeTimelines(ix).clearLines;
           iwm.regimeTimelines(ix).delete;           
           iwm.regimeTimelines = iwm.regimeTimelines([1:ix-1, ix+1:end]);           
       end

       % To be called when we load an ImagineObject, and the window is
       % already set up.
       function updateEverything(iwm)
                      
           % Set up the crops list...
           cropDefs = iwm.cropMgr.cropDefinitions;
           if ~isempty(cropDefs)
               evtData = CropListChangedEventData({cropDefs.name}, '', cropDefs(1).name);
               iwm.updateCropList([], evtData);
           else
               evtData = CropListChangedEventData({}, '', '');
               iwm.updateCropList([], evtData);
           end
          
           % Set up the regmimes list...
           regDefs = iwm.regimeMgr.regimeDefinitions;
           if ~isempty(regDefs)
              evtData = RegimeListChangedEventData(regDefs, '', regDefs(1).regimeLabel);
             iwm.updateRegimeList([], evtData);
           else
               iwm.updateRegimeList([], []);
           end
           
           % Set up the layouts
           iwm.updateLayouts;

           % Set up the yearly summary area
           iwm.setupYearlySummary;

           % Set up the rainfall axes
           iwm.drawClimateAxes(iwm.climateMgr.climateModel);
          
           % set up the regime timelines.
           for i = length(iwm.regimeTimelines):-1:1
              iwm.regimeTimelines(i).clearLines;               
           end
           
           iwm.regimeTimelines = RegimeTimeline.empty(1,0);
           
           regDefs = iwm.regimeMgr.regimeDefinitions;
           handles = guidata(iwm.window);
           for i = 1:length(regDefs)
              iwm.regimeTimelines(i) = RegimeTimeline(regDefs(i).regimeLabel, regDefs(i).startYear, regDefs(i).finalYear, ...
                                        regDefs(i).timelineColour, regDefs(i).type, handles.axes1);
           end
           
           iwm.addUpdateCropListListeners;
           iwm.addUpdateRegimeListListeners;
           iwm.addUpdateLayoutListeners;
           
       end
       
       % This function is called to create and set up the layouts in the
       % main axes. It is likely to be called only from the constructor.
       function initialiseLayouts(iwm)
                
           % Get and set the window's handles structure when required.
           % Use iwm.window as the figure handle.
           % This maintains the figure's handle structure. Handles to
           % graphics elements that are managed by the ImagineWindowManager
           % are store here as properties. So controls are found under
           % handles = guidata(iwm.window) and graphics elements are found
           % as properties of the iwm.
          % fig = iwm.window
           handles = guidata(iwm.window);
           
           % Clear the axes and make sure it is the current axes.        
           cla(handles.axes1);
           ax = handles.axes1;
           
           iwm.selectYearPatchHandle = patch([6 6 64 64], [26 84 84 26], 2*ones(1, 4), 'k', 'EdgeColor', [0.5 0.5 1], 'LineWidth', 1, 'FaceAlpha', 0.12, 'Visible', 'off', 'Parent', ax);
             for i = 1:5
                for j = 1:10  
                    
                    lo = Layout;
                    
                  %  vertices = [((j-1)*70 + [10 10 60 60]') (500-i*100 + [30 80 80 30]')];
                    lo.patchHandle = patch((j-1)*70 + [10 10 60 60], 500-i*100 + [30 80 80 30], ones(1, 4), 'w', 'ButtonDownFcn', @(src, event)layout_Callback(iwm, i, j), 'EdgeColor', 0.7*[1 1 1], 'Parent', ax); 
                    %lo.patchHandle = patch('Faces', faces, 'Vertices', vertices, 'FaceColor', 'w', 'ButtonDownFcn', {@layout_Callback, i,j}, 'EdgeColor', 0.7*[1 1 1]);          
                    lo.textHandle = text((j-1)*70 + 35, 500-i*100 + 90, num2str((i-1)*10 + j), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Parent', ax);
                    for k = 1:9
%                        lo.beltLines(k) = line((j-1)*70 + [15 55], 500-i*100 + [30+k*5, 30+k*5], 'Visible', 'off', 'ButtonDownFcn', @(src, event)layout_Callback(iwm, i, j)); 
                       lo.beltLines(k) = line((j-1)*70 + [15 55], 500-i*100 + [30+k*5, 30+k*5], [1.1 1.1], 'Visible', 'off', 'ButtonDownFcn', @(src, event)layout_Callback(iwm, i, j), 'Parent', ax); 
                    end
% 
%                    lo.borderLines(1) = line((j-1)*70 + [11 11], 500-i*100 + [35, 75], 'Visible', 'off', 'LineWidth', 1, 'ButtonDownFcn', @(src, event)layout_Callback(iwm, i, j));
%                    lo.borderLines(2) = line((j-1)*70 + [15 55], 500-i*100 + [79, 79], 'Visible', 'off', 'LineWidth', 1, 'ButtonDownFcn', @(src, event)layout_Callback(iwm, i, j));
%                    lo.borderLines(3) = line((j-1)*70 + [59 59], 500-i*100 + [75, 35], 'Visible', 'off', 'LineWidth', 1, 'ButtonDownFcn', @(src, event)layout_Callback(iwm, i, j));
%                    lo.borderLines(4) = line((j-1)*70 + [55 15], 500-i*100 + [31, 31], 'Visible', 'off', 'LineWidth', 1, 'ButtonDownFcn', @(src, event)layout_Callback(iwm, i, j));

                   lo.borderLines(1) = line((j-1)*70 + [11 11], 500-i*100 + [35, 75], [1.1 1.1], 'Visible', 'off', 'LineWidth', 1, 'ButtonDownFcn', @(src, event)layout_Callback(iwm, i, j), 'Parent', ax);
                   lo.borderLines(2) = line((j-1)*70 + [15 55], 500-i*100 + [79, 79], [1.1 1.1], 'Visible', 'off', 'LineWidth', 1, 'ButtonDownFcn', @(src, event)layout_Callback(iwm, i, j), 'Parent', ax);
                   lo.borderLines(3) = line((j-1)*70 + [59 59], 500-i*100 + [75, 35], [1.1 1.1], 'Visible', 'off', 'LineWidth', 1, 'ButtonDownFcn', @(src, event)layout_Callback(iwm, i, j), 'Parent', ax);
                   lo.borderLines(4) = line((j-1)*70 + [55 15], 500-i*100 + [31, 31], [1.1 1.1], 'Visible', 'off', 'LineWidth', 1, 'ButtonDownFcn', @(src, event)layout_Callback(iwm, i, j), 'Parent', ax);

                   lo.ax = ax;
                   
                   iwm.layouts(i,j) = lo;

                end
                if(i < 5)
                   iwm.dividerLines(i) = line([0, 700], [i * 100, i *100], [0.9 0.9], 'Color', 0.8*[1 1 1], 'Parent', ax);
                end
            end

            axis([0 700 0 500])
            axis off
       end

       % This function should be called whenever a change is made such that
       % the layouts should change. This will be when a Crop's colour changes,
       % or a Crop is removed or when a Regime is added, editted or removed. 
       %
       % This function assumes that the layouts have already been
       % initialised.
       function updateLayouts(iwm)
           
            % Set the white colour
            whiteColour = [1, 1, 1];

            handles = guidata(iwm.window);
            ax = handles.axes1;
            
            % For each year...
            for year = 1:50

                % Get the paddockSummary and the paddockLayout that comes
                % with it.
                ps = iwm.regimeMgr.getPaddockSummaryForYear(year);
                pl = ps.paddockLayout;
                
                % Set the layout indices.
                j = mod(year-1, 10) + 1;
                i = floor((year-1)/10) + 1;

                % Set the background colour
                if ~isempty(pl.backgroundColour)
                    iwm.layouts(i, j).setBackgroundColour(pl.backgroundColour);
                else
                    iwm.layouts(i, j).setBackgroundColour(whiteColour);
                end
                
                % If any of the foreground elements should be drawn, set
                % the foregroundColour.
                if ~isempty(pl.foregroundColour) && pl.shouldShowForegroundElements
                    iwm.layouts(i, j).setForegroundColour(pl.foregroundColour);
                end
                
                % Set the visibility of the foreground elements.
                if pl.shouldShowBelts
                    iwm.layouts(i, j).setBeltVisibility('on');
                else
                    iwm.layouts(i, j).setBeltVisibility('off');                    
                end
                
                if pl.shouldShowBorders
                    iwm.layouts(i, j).setBorderVisibility('on');
                else
                    iwm.layouts(i, j).setBorderVisibility('off');                    
                end                
                
                % ... If there are other foreground elements add them here.
                % eg woodlands and contours.              
            end           
            
            % Next implement the regime timelines.
            
       end
       
       % This function is used as the callback when a layout is clicked. It
       % moves the selectYearPatch and updates the yearly summary.
       function layout_Callback(iwm, i, j)
            
           % Hide the select patch, move it, then show it again.
           set(iwm.selectYearPatchHandle, 'Visible', 'off');
           set(iwm.selectYearPatchHandle, 'XData', (j-1)*70 + [6 6 64 64]);
           set(iwm.selectYearPatchHandle, 'YData', 500-i*100 + [26 84 84 26]);
           set(iwm.selectYearPatchHandle, 'Visible', 'on');

           % Set the summary year, then setup the yearly summary area.
           iwm.selectedYear = (i-1)*10 + j;           
           setupYearlySummary(iwm);
       end
       
       % This function sets up the yearlySummary axes to display data for
       % the selected year.
       function setupYearlySummary(iwm)
           
           handles = guidata(iwm.window);
           year = iwm.selectedYear;
           
           ps = iwm.regimeMgr.getPaddockSummaryForYear(year);
           
           % Set the labels...
           
           set(handles.yearLabel, 'String', num2str(year));
           
           if isempty(ps.primaryRegimeLabel)
               set(handles.primaryRegimeLabelLabel, 'String', 'None');
           else
               set(handles.primaryRegimeLabelLabel, 'String', ps.primaryRegimeLabel);
           end
           
           if isempty(ps.primaryCropName)
               set(handles.primaryCropLabel, 'String', 'None');
           else
               set(handles.primaryCropLabel, 'String', ps.primaryCropName);
           end
           
           if isempty(ps.companionCropName)
               set(handles.companionCropLabel, 'String', 'None');
           else
               set(handles.companionCropLabel, 'String', ps.companionCropName);
           end
           
           if isempty(ps.secondaryRegimeLabel)
               set(handles.secondaryRegimeLabelLabel, 'String', 'None');
           else
               set(handles.secondaryRegimeLabelLabel, 'String', ps.secondaryRegimeLabel);
           end
           
           if isempty(ps.secondaryCropName)
               set(handles.secondaryCropLabel, 'String', 'None');
           else
               set(handles.secondaryCropLabel, 'String', ps.secondaryCropName);
           end
           
           % Draw the paddock layout on axis3...
           
           % If there is a 
           % We use the function drawPaddockSummaryOnAxes, which is also
           % used in the belts and borders regime dialog. Need to create a
           % structure called beltS, which contains the data needed.
           
           beltS.useBelts = ps.paddockLayout.shouldShowBelts;
           beltS.useBorders = ps.paddockLayout.shouldShowBorders;

           if isfield(ps.paddockLayout.data, 'Belts_and_Borders')
              try                            
                  if(beltS.useBelts || beltS.useBorders)
                       beltS.exclusionZone = ps.paddockLayout.data.Belts_and_Borders.exclusionZone;
                       beltS.rowsPerBelt = ps.paddockLayout.data.Belts_and_Borders.rowsPerBelt;
                       beltS.rowSpacing = ps.paddockLayout.data.Belts_and_Borders.rowSpacing;
                       beltS.beltColour = ps.paddockLayout.foregroundColour;
                  end
                  
                  if(beltS.useBelts)
                      beltS.headland = ps.paddockLayout.data.Belts_and_Borders.headland;
                      beltS.beltNum = ps.paddockLayout.data.Belts_and_Borders.beltNum;
                  end

                  if(beltS.useBorders)
                      beltS.gapLengthAtCorners = ps.paddockLayout.data.Belts_and_Borders.gapLengthAtCorners;
                  end
                  
              catch e
                  print('Assigning paddock layout parameters from the Belts and Borders regime failed.');
              end
           end
           
           bgColour = ps.paddockLayout.backgroundColour;
           
           if isempty(bgColour)
              bgColour = [1 1 1]; 
           end
           drawPaddockSummaryOnAxes(handles.axes3, bgColour, iwm.imagineOb, beltS)
           
       end
       
       
       % Draw the rainfall graph
       function drawClimateAxes(iwm, climateModel)
           
           if ~isempty(climateModel)

              % Climate model should have a field 'drawFunction' which should itself take the
              % climateModel as an argument and an axis to draw it on. The axis
              % is provided by the ImagineWindowManager in this function.
              handles = guidata(iwm.window);
              climateModel.drawFunction(climateModel, handles.rainfallAxes);
           else
               handles = guidata(iwm.window);
               cla(handles.rainfallAxes);
           end
       end
      
       
   end
   
    
    
end