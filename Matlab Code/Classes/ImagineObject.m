% ImagineObject
%
% This class is a place to store references to the Manager objects in
% Imagine.
%
% It is a singleton object, and whenever the static method is called, it
% should return the ImagineObject. This makes it act like a global
% variable, but it's actually elegant.
classdef (Sealed = true) ImagineObject < handle
    
    properties (SetAccess = private)
       
        cropManager
        regimeManager
        climateManager
        imagineWindowManager
        simulationManager

        paddockWidth = 1000;
        paddockLength = 1000;
        paddockSpacing = 1000;
        simulationLength = 50;

    end
    
    properties (Transient = true)
        loadPath
        savePath    
    end
    
    % Private constructor
    methods (Access = private)
        function obj = ImagineObject
            
        end
        
        function imagineObjectConstructor(obj)
            initialiseImagine(obj)          
        end
                
    end
    
    methods
       
        function initialiseImagine(obj)
            pause(.1);
            delete(obj.cropManager);
            delete(obj.regimeManager);
            delete(obj.climateManager);
            delete(obj.imagineWindowManager); 
            
            obj.cropManager = CropManager.getInstance;
            obj.regimeManager = RegimeManager.getInstance;
            obj.climateManager = ClimateManager.getInstance;
            obj.imagineWindowManager = ImagineWindowManager.getInstance;
        %   window = ImagineWindow;
            obj.imagineWindowManager.setupWindow();
            obj.imagineWindowManager.updateTitle('initialised');
            obj.simulationManager = SimulationManager.getInstance;
            obj.simulationManager.refreshManagerPointers;
            obj.imagineWindowManager.refreshManagerPointers;
            
            obj.loadPath = '';
            obj.savePath = '';
        end
        
        function setPaddockSize(obj, width, length)
           obj.paddockWidth = width;
           obj.paddockLength = length;
        end
        
        function clearSimulations(obj)
           obj.simulationManager.simulations = Simulation.empty(1, 0); 
        end
        
    end
    
    % Static getInstance method provides global access to the singleton
    % ImagineObject.
    methods (Static)
        function singleObj = getInstance(loadedObj)
            persistent localObj
            % If an ImagineObject is passed in and is not the localObj,
            % then set it as the localObj.
            if nargin >= 1
                
                if isa(loadedObj, 'ImagineObject') && localObj ~= loadedObj
            %        disp('About to set Imob to loadedObj.');
                    
                    % Save the imagineWindowManger and the
                    % simulationManager.
                 %   iwm = localObj.imagineWindowManager;
                 %   sm =  localObj.simulationManager;
                    
                 %   localObj = loadedObj;

                 %   localObj.imagineWindowManager = iwm;
                 %   localObj.simulationManager = sm;
                    
             %       disp('Set Imob to loadedObj.');
                    localObj.cropManager = CropManager.getInstance(loadedObj.cropManager);
                    localObj.regimeManager = RegimeManager.getInstance(loadedObj.regimeManager);
                    localObj.climateManager = ClimateManager.getInstance(loadedObj.climateManager);
              %      disp('Set managers to loadedObj managers.');
                    
                    localObj.simulationManager.refreshManagerPointers;
                    localObj.imagineWindowManager.refreshManagerPointers;
                    localObj.imagineWindowManager.updateEverything;                    

                else
                    disp('Tried passing an object that''s not an ImagineObject to ImagineObject.getInstance.');
                end
            end
             
            if isempty(localObj) || ~isvalid(localObj)
                
                localObj = ImagineObject;
                localObj.imagineObjectConstructor;
            end
            singleObj = localObj;

        end
        

        % The loadObj methods uses the created, but not contructed
        % loadedObj as an argument the singleton ImagineObject absorb
        % function.
        function singletonObj = loadobj(loadedObj)
            singletonObj = ImagineObject.getInstance(loadedObj);          
        end 
        
        % Returns the ImagineMATLAB folder path.
        function thePath = imagineRoot
            fullPath = which('ImagineObject');
            k = strfind(fullPath, 'ImagineMATLAB');
            if isempty(k)
                thePath = '';
            else
                thePath = [fullPath(1:k(end)-1), 'ImagineMATLAB'];
            end
        end
        
    end
    
    methods
                

        
        % The absorb method grabs the manager objects
        % from the loaded object and puts them into the singleton
        % ImagineObject. The crop, regime and climate managers come from
        % the loaded object, but the imagineWindowManager is reconstructed
        % so that it refers to the new managers.
        %
        % absorb is called from the loadObj method and should be the only
        % place that a new ImagineObject can be created since the
        % constructor is private.
        % absorb fails if the newOb is not an ImagineObject.
        function absorb(singletonObj, newObj)
 %           disp('In ImagineObject.absorb');
            if singletonObj == newObj
                disp('Tried absorbing the ImagineObject into itself.');
                return
            end
            
            if isa(newObj, 'ImagineObject')

                tempCM = singletonObj.cropManager;
                tempRM = singletonObj.regimeManager;
                tempClM = singletonObj.climateManager;
                
                singletonObj.cropManager = newObj.cropManager;
                singletonObj.regimeManager = newObj.regimeManager;
                singletonObj.climateManager = newObj.climateManager;

                delete(tempCM);
                delete(tempRM);
                delete(tempClM);
                
                % Redo the window manager so that it refers to the new manager
                % objects.
                singletonObj.imagineWindowManager.refreshManagerPointers;
                singletonObj.imagineWindowManager.setupWindow(window);
            else
                disp('ImagineObject asked to absorb non-ImagineObject.');
                return
            end
        end
        
        % This function saves the ImagineObject to file.
        function wasSaved = save(singletonObj, path, file)
            
            wasSaved = false;
            
            filename = [path, file];
            save(filename, 'singletonObj');
            wasSaved = true;

            singletonObj.savePath = [path, file];
            singletonObj.imagineWindowManager.updateTitle('saved', singletonObj.savePath);

        end
        
        % This function loads the ImagineObject from file. note this is not
        % a static method. An instance of ImagineObject should exist
        % first.
        function newObj = load(singletonObj, path, file)
                        
            % Create this class that stores loaded QuantityCondition, which
            % can't really be properly constructed during the load process.
            % Once we've loaded, we'll update all the references that are
            % collected during the load process. This seemed like a less
            % intrusive way of solving the problem than added listeners and
            % so on.
            condUpdater = ConditionUpdater.getInstance;
            
            newObj = load([path, file]); %#ok<NASGU>
            newObj = ImagineObject.getInstance;
            newObj.loadPath = [path, file];
            % Need to do this indirectly with 'updateLoadedTitle' because newObj is not
            % singletonObj and so the private imagineWindowManager is inaccessible.
            newObj.updateLoadedTitle(newObj.loadPath);

            condUpdater.updateAllQuantityConditions();
            delete(condUpdater);
        end
        
        function updateLoadedTitle(singletonObj, path)
            singletonObj.imagineWindowManager.updateTitle('loaded', path);
        end
     
        function refreshWindow(singletonObj)
           singletonObj.imagineWindowManager.refreshManagerPointers; 
           singletonObj.imagineWindowManager.setupWindow(); 
        end
    end
    
end