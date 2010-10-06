classdef THListener < handle
    % Simple listener for temperature and humidity data. Sets the
    % temperatue and humidity text in GUI to which is is associated.
   properties
       hObject;
       handles;
   end
    methods
        function self = THListener(hObject,handles)
            self.hObject = hObject; % handle to associated figure
            self.handles = handles; % handles sructure for associated GUI
        end
        function eventHandler(self,~,eventData)
            % Handles samples acquired event from the THSampler class.
            T = eventData.T;
            H = eventData.H;
            
            % Set text stings for temperature and humidity data.
            TString = sprintf('Temperature: %1.2f', T);
            HString = sprintf('Humidity: %1.2f', H);
            set(self.handles.temperatureText,'String',TString);
            set(self.handles.humidityText,'String',HString);
            
            % Store lastest temperature and humidity data in GUI handles
            % structure.
            self.handles.T = T;
            self.handles.H = H;
            
            % Update Gui handles structure - required for handles.T and
            % handles.H to be set in main GUI.
            guidata(self.hObject, self.handles);
        end
    end
end