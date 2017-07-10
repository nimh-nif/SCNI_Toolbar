% SCNI_OpenEphysSettings.m




Params.OE.ToolsURL = 'https://github.com/open-ephys/plugin-GUI/tree/master/Resources/Matlab';
if ~exist('zeroMQrr','file')
    Params.OE.ZeroMQfound = 0;
else
    Params.OE.ZeroMQfound = 1;
end
Params.OE.address   = '100.2.1.1';
Params.OE.protocol  = 'tcp';
Params.OE.port      = '5556';
Params.OE.url       = sprintf('%s://%s:%s', Params.OE.protocol, Params.OE.address, Params.OE.port);

zeroMQrr('Send', Params.OE.url , sprintf('Test message'));
[tmp] = zeroMQrr('GetResponses');
zeroMQrr('CloseThread',url);

