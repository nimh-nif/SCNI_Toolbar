function SCNI_OpenEphysSettings()

% SCNI_OpenEphysSettings.m

Record = 1;

Params.OE.ZeroMQDir     = '/home/lab/libzmq'; 
Params.OE.OEtoolsDir    = '/projects/SCNI/plugin-GUI/Resources/Matlab/';
Params.OE.ToolsURL      = 'https://github.com/open-ephys/plugin-GUI/tree/master/Resources/Matlab';
if ~exist('zeroMQrr','file')
    Params.OE.ZeroMQfound = 0;
else
    Params.OE.ZeroMQfound = 1;
end
Params.OE.address   = '156.40.249.112';         % Open Ephys host PC IP address
Params.OE.protocol  = 'tcp';                    % TCP/IP protocol
Params.OE.port      = '5556';                   % Default Open Ephys port #
Params.OE.url       = sprintf('%s://%s:%s', Params.OE.protocol, Params.OE.address, Params.OE.port);
Params.OE.handle    = zeroMQwrapper('StartConnectThread',Params.OE.url);


%================= Start
if Record == 0
    fprintf('Starting acquisition...\n');
    zeroMQwrapper('Send', Params.OE.handle, 'StartAcquisition');
elseif Record == 1
    fprintf('Starting recording...\n');
    zeroMQwrapper('Send', Params.OE.handle, 'StartAcquisition');
    zeroMQwrapper('Send', Params.OE.handle, 'StartRecord');
%     zeroMQwrapper('Send', Params.OE.handle , 'StartRecord CreateNewDir=1 RecDir=E:\OpenEphys\ PrependText=TEST_');
end

%================= Send message
WaitSecs(5);
% [tmp] = zeroMQwrapper('GetResponses')
zeroMQwrapper('Send', Params.OE.handle , 'Test message 1');
WaitSecs(1);

WaitSecs(1);
zeroMQwrapper('Send', Params.OE.handle , sprintf('Test message 2'));
WaitSecs(5);

%================= Stop
if Record == 0
    fprintf('Stopping acquisition...\n');
    zeroMQwrapper('Send', Params.OE.handle , 'StopAcquisition');
elseif Record == 1
    fprintf('Stopping recording...\n');
    zeroMQwrapper('Send', Params.OE.handle , 'StopRecord');
    WaitSecs(5);
% 	zeroMQwrapper('Send', Params.OE.handle , 'StopAcquisition');
end
zeroMQwrapper('CloseThread', Params.OE.handle);
clear all