classdef THSamplerEventData < event.EventData
    % Simple class for THSampler event data.
    properties
        T = 0.0;
        H = 0.0;
    end
    methods
        function self = THSamplerEventData(T,H)
            self.T = T;
            self.H = H;
        end
    end
end