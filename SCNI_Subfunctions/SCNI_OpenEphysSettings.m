% SCNI_OpenEphysSettings.m



Params.OE.ZeroMQDir = '/home/lab/libzmq'; 
Params.OE.OEtoolsDir = '/projects/SCNI/plugin-GUI/Resources/Matlab/';
Params.OE.ToolsURL  = 'https://github.com/open-ephys/plugin-GUI/tree/master/Resources/Matlab';
if ~exist('zeroMQrr','file')
    Params.OE.ZeroMQfound = 0;
else
    Params.OE.ZeroMQfound = 1;
end
Params.OE.address   = '156.40.248.1';       % Open Ephys host PC IP address
Params.OE.protocol  = 'tcp';                % TCP/IP protocol
Params.OE.port      = '5556';               % Default Open Ephys port #
Params.OE.url       = sprintf('%s://%s:%s', Params.OE.protocol, Params.OE.address, Params.OE.port);

%zeroMQrr('Send', Params.OE.url , sprintf('Test message'));
zeroMQrr('Send', Params.OE.url , 'StartAcquisition');
WaitSecs(2);
zeroMQrr('Send', Params.OE.url , 'StartRecording 1 S:\TEST 20170711');
%[tmp] = zeroMQrr('GetResponses');
%zeroMQrr('CloseThread', Params.OE.url);

