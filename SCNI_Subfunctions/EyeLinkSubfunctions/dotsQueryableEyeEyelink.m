classdef dotsQueryableEyeEyelink < dotsQueryableEye
    % @class dotsQueryableEyeEyelink
    % Acquires and classifies Eyelink gaze and pupil size data.
    % @details
    % dotsQueryableEyeEyelink extends the dotsQueryableEye superclass to
    % acquire point of gaze and pupil size data using the Eyelink
    % toolbox, which is part of Psychtoolbox.
    % @details
    % dotsQueryableEyeEyelink is a usable class.  Use the newObject()
    % method of dotsTheQueryablesManager to create new objects.
    % @ingroup queryable
   
    properties
        % any function that returns the current time as a number
        % @details
        % Automatically opts in to share via dotsTheSwitchboard.
        clockFunction;
       
        % nx2 matrix of Eyelink frame timestamps and clockFunction
        % timestamps
        % @details
        % Each call to readRawData() adds a row to frameTimestamps.  The
        % first column contains the latest Eyelink timestamp returned from
        % Eyelink('GetQueuedData'), which is in ms on the Eyelink machine.
        % The second column contains a timestamp from clockFunction.
        % dotsQueryableEyeEyelink assumes that the Eyelink() and
        % clockFunction timestamps coincided.
        % @details
        % logAllData() adds the frameTimestamps matrix to topsDataLog.
        % flushData() clears frameTimestamps.
        frameTimestamps = [];
       
        % scale factor from Eyelink camera timestamp units to seconds
        eyelinkUnitsPerSecond = 1000;
       
        % name of file on the Eyelink machine to record data
        % @details
        % dotsTheMachineConfiguration could specify a filename.
        dataFile = 'snowdots.edf';
       
        % struct of info from EyelinkInitDefaults()
        el;
       
        % row from Eyelink('GetQueuedData') that contains x-position
        dataXRow = 14;

        % row from Eyelink('GetQueuedData') that contains y-position
        dataYRow = 16;

        % row from Eyelink('GetQueuedData') that contains pupil size
        dataPRow = 12;
    end
   
    methods
        % Acquire device-specific resources.
        % @details
        % Initializes the the Eyelink() mex function and starts recording
        % data, returns true if successful, otherwise returns false.
        function isOpen = openEyeTracker(self)
            dotsTheSwitchboard.sharePropertyOfObject( ...
                'clockFunction', self);
           
            self.el = EyelinkInitDefaults;
           
            self.closeEyeTracker;
            isOpen = false;
            if exist('Eyelink', 'file') > 0
                try
                    status = Eyelink('Initialize');
                    if status == 0
                        status = Eyelink('OpenFile', self.dataFile);
                        isOpen = status == 0;
                    end
                   
                catch err
                    isOpen = false;
                    warning(err.message);
                end
               
                if ~isOpen
                    Eyelink('CloseFile');
                    Eyelink('Shutdown');
                end
            end
        end
       
        % Release device-specific resources.
        % @details
        % Closes the Eyelink data file and connection.
        function closeEyeTracker(self)
            if self.isAvailable && Eyelink('IsConnected') ~= 0
                Eyelink('CloseFile');
                Eyelink('Shutdown');
            end
        end
       
        % Use the current drawing window for Eyelink calibration.
        % @details
        % Uses the current drawing window to set up inputRect and xyRect
        % and data dimensions for degrees of visual angle.  Passes the
        % current windowNumber to Eyelink for configuration and
        % calibration.
        function result = calibrateInWindow(self)
            result = -1;
            if dotsTheScreen.isWindowOrTexture(self.windowNumber)
               
                % Expect Eyelink to give pixels from top left
                %   get xyRect as degrees from center
                self.inputRect = self.windowRect;
                xyPix = [self.inputRect(1:2)-self.inputRect(3:4)/2, ...
                    self.inputRect(3:4)-self.inputRect(1:2)];
                scale = [1 1 1 -1]*self.pixelsPerDegree;
                self.xyRect = xyPix./scale;
                self.initializeDimensions;
               
                % Configure and calibrate Eyelink with window
                self.el = EyelinkInitDefaults(self.windowNumber);
                if self.isAvailable && Eyelink('IsConnected') ~= 0
                    commandwindow;
                    try
                        result = EyelinkDoTrackerSetup(self.el, 'c');
                    catch
                        result = -10;
                    end
                end
            end
        end
       
        % Start recording gaze.
        function startRecording(self)
            if self.isAvailable && Eyelink('IsConnected') ~= 0
                Eyelink('StartRecording');
            end
        end
       
        % Stop recording gaze.
        function stopRecording(self)
            if self.isAvailable && Eyelink('IsConnected') ~= 0
                Eyelink('StopRecording');
            end
        end
       
        % Is Eyelink recording gaze?
        function isRec = isRecording(self)
            isRec = self.isAvailable ...
                && Eyelink('IsConnected') ~= 0 ...
                && Eyelink('CheckRecording') == 0;
        end
       
        % Clear data from this object and the Eyelink() internal buffer.
        % @details
        % Extends the dotsQueryable flushData() method to also clear out
        % the Eyelink() internal data buffer and discard old frame
        % timestamps.
        function flushData(self)
            self.flushData@dotsQueryableEye;
            if self.isAvailable
                [data, events, isDrained] = Eyelink('GetQueuedData');
                while ~isDrained
                    [data, events, isDrained] = Eyelink('GetQueuedData');
                end
            end
            self.frameTimestamps = [];
        end
       
        % Add the allData and frameTimestamps to the topsDataLog.
        % @details
        % Extends the dotsQueryable logAllData() method to also log
        % frameTimestamps, using the group
        % name "@e class.frameTimestamps", where @e class is the object's
        % class name.
        function logAllData(self)
            self.logAllData@dotsQueryable;
            groupName = sprintf('%s.frameTimestamps', class(self));
            topsDataLog.logDataInGroup(self.frameTimestamps, groupName);
        end
       
        % Read raw data from the acquired eye tracker device.
        % @details
        % Reads out any queued data frames from Eyelink('GetQueuedData')
        % and reformats the data in the dotsQueryable style.
        % @details
        % Eyelink('GetQueuedData') reports data frames in a many-rowed
        % format described in Eyelink('GetQueuedData').  Only interested in
        % a few of those, here:
        %   - [xID, x, timestamp]
        %   - [yID, y, timestamp]
        %   - [pupilID, pupilSize, timestamp]
        %   .
        % where timestamp is derived from the Eyelink machine's milisecond
        % timestamps, eyelinkUnitsPerSecond, and the current time.
        % @details
        % Appends the latest frameNumber and the current time to
        % frameTimestamps.
        function data = readRawData(self)
            nowTime = feval(self.clockFunction);
            [eyelinkFrames, events, isDrained] = Eyelink('GetQueuedData');
           
            nData = 3*size(eyelinkFrames, 2);
            data = zeros(nData, 3);
            if nData > 0
                % frame numbers to local time values
                frameNumbers = eyelinkFrames(1,:);
                frameTimes = self.computeFrameTimes(frameNumbers, nowTime);
               
                % data to dotsQueryable format
                xIndexes = 1:3:nData;
                data(xIndexes,1) = self.xID;
                data(xIndexes,2) = eyelinkFrames(self.dataXRow,:);
                data(xIndexes,3) = frameTimes;
               
                yIndexes = 2:3:nData;
                data(yIndexes,1) = self.yID;
                data(yIndexes,2) = eyelinkFrames(self.dataYRow,:);
                data(yIndexes,3) = frameTimes;
               
                pIndexes = 3:3:nData;
                data(pIndexes,1) = self.pupilID;
                data(pIndexes,2) = eyelinkFrames(self.dataPRow,:);
                data(pIndexes,3) = frameTimes;
            end
        end
       
        function frameTimes = computeFrameTimes(self, frameNumbers, localTime)
            % save the raw last frame number with its local timestamp
            self.frameTimestamps(end+1,1:2) = ...
                [frameNumbers(end), localTime];
           
            % compute frame times with last frame defined as localTime
            frameNumbers = frameNumbers - frameNumbers(end);
            frameTimes = ...
                localTime + frameNumbers ./ self.eyelinkUnitsPerSecond;
        end
    end
end