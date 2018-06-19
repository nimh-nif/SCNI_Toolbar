

%========================= SCNI_StartOpenEphys.m ==========================
% A ZMQ client to test remote control of open-ephys GUI. Requries
% installation of Zero MQ library 3.2.x or higher, available here:
% https://github.com/open-ephys/plugin-GUI/tree/master/Resources/Matlab
%
% 06/26/2017 - Adapted from Open Ephys record_control_example_client.py by APM
%==========================================================================

function run_client()

    socket = [];

    % Basic start/stop commands
    start_cmd   = 'StartRecord';
    stop_cmd    = 'StopRecord';

    % Example settings
    rec_dir = os.path.join(os.getcwd(), 'Output_RecordControl');
    fprint('Saving data to: %s\n', rec_dir);

    % Some commands
    commands = {sprintf('%s RecDir=%s',start_cmd, rec_dir),...        
                start_cmd + ' PrependText=Session01 AppendText=Condition01',...
                start_cmd + ' PrependText=Session01 AppendText=Condition02',...
                start_cmd + ' PrependText=Session02 AppendText=Condition01',...
                start_cmd, ...
                start_cmd + ' CreateNewDir=1'};

    % Connect network handler
    ip      = '127.0.0.1';
    port    = 5556;
    timeout = 1;
    url     = sprintf('tcp://%s:%d', ip, port);

    
    with zmq.Context() as context:
        with context.socket(zmq.REQ) as socket:
            socket.RCVTIMEO = int(timeout * 1000);  % timeout in milliseconds
            socket.connect(url);

            % Finally, start data acquisition
            socket.send('StartAcquisition')
            answer = socket.recv();
            disp(answer)
            WaitSecs(5);

            for start_cmd = 1:numel(commands)

                for cmd = [start_cmd, stop_cmd]
                    socket.send(cmd)
                    answer = socket.recv();
                    disp(answer)

                    if strcmp('StartRecord', cmd)
                        % Record data for 5 seconds
                        WaitSecs(5);
                    else
                        % Stop for 1 second
                        WaitSecs(5);
                    end
                end
            end

            % Finally, stop data acquisition; it might be a good idea to 
            % wait a little bit until all data have been written to hard drive
            WaitSecs(0.5);
            socket.send('StopAcquisition');
            answer = socket.recv();
            disp(answer)

