function [Resp, RT] = collectResponse(varargin)
% collectResponse.m
%j
% Author: Cendri Hutcherson
% Date: 1.27.09
%
% Description: Waits a specified amount of time for subject to respond,
% records response and RT.
%
% USAGE: collectResponse([waitTime],[moveOn],[allowedKeys],[KbDevice])
% 
% EXPLANATION: defaults to infinite waitTime, moving on as soon as any
% button is pressed [i.e. moveOn = 1], with any key press triggering the
% move.  If you wish the program to wait out the remainder of the waitTime
% even if a key has been pressed, use moveOn = 0.  If you wish the program
% to accept as input only certain keys, enter the allowed keys as a string
% (e.g. '12345' or 'bv')

% Set defaults
ListenTime = Inf;
moveOn = 1;
allowedKeys = [];
KbDevice = -1;

if length(varargin) >= 1
    ListenTime = varargin{1};
end

if isempty(ListenTime); ListenTime = Inf; end

if length(varargin) >= 2
    moveOn = varargin{2};
end

if isempty(moveOn); moveOn = 1; end

if length(varargin) >= 3
    allowedKeys = varargin{3};
end

if length(varargin) >= 4
    KbDevice = varargin{4};
end

if length(varargin) >= 5
    PTBParams = varargin{5};
end

if ListenTime == Inf && moveOn ~= 1
    error('Infinite loop: You asked me to wait forever, even AFTER the subject has responded!')
end

% Specifies how long to listen for subject's response
StartWaiting = GetSecs();
Resp = 'NULL';
RT = NaN;

while KbCheck(KbDevice)
end

if isempty(allowedKeys)
    while (GetSecs() - StartWaiting) < ListenTime
        [keyDown secs key] = KbCheck(KbDevice);
        if keyDown == 1
            Resp = KbName(find(key==1));
            RT = secs;
            break;
        end
    end
else
    while (GetSecs() - StartWaiting) < ListenTime
        [keyDown secs key] = KbCheck(KbDevice);
        GetMouse(); % needed to keep focus on PTB screen
        if keyDown == 1
            if ~iscell(KbName(find(key==1)))
                Resp = KbName(find(key==1));

                if any(strcmp(allowedKeys,Resp))
                    RT = secs;
                    if exist('PTBParams','var')
                        Resp = find(strcmp(Resp,PTBParams.KeyOrder) == 1);
                    
                        % if recording ERP, send trigger with appropriate tag
                        if PTBParams.inERP
                            TriggerValue = Resp+7;
                            err=DaqDOut(PTBParams.daq(1),0,PTBParams.stat{TriggerValue});
                            WaitSecs(PTBParams.pulse_duration);
                            err=DaqDOut(PTBParams.daq(1),0,0);
                        end
                    end
                    break;
                else
                    Resp = 'NULL';
                end
            end
        end
    end
end

if moveOn ~= 1
    while (GetSecs() - StartWaiting) < ListenTime
    end
end

    