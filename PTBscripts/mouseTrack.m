function [x, y, time] = mouseTrack(secs, endOnClick, PTBParams,varargin)

%--------------------------------------------------------------------------
% function [x, y, time] = mouseTrack(secs, endOnClick, PTBParams, [spotRectToEnd])
%
% Program tracks mouse displayed on screen w for secs seconds, until 
% mouse is clicked (if endOnClick == 1), or until mouse enters designated
% areas, specified in spotRectToEnd (N x 4 matrix specifying min x, min y,
% max x, max y for each of N spots capable of terminating mousetracking.
%
% Returns mouse x and y coordinates, sampled at twice the screen refresh 
% rate, as well as a time vector specifying time since beginning of  
% recording
%--------------------------------------------------------------------------

% 1. First, intialize variables

% Determine whether there is a correctly-specified request defining spots
% on which to determine mouse tracking
if ~isempty(varargin)
    spotRectToEnd = varargin{1};
    if size(spotRectToEnd,2) ~= 4 % CENDRI: complete check for numbers!!!
        error('Not a valid N x 4 matrix to define termination spots! Please check your coordinates')
    end
else
    spotRectToEnd = [];
end

if isempty(secs)
    secs = 30; % if no time is given, set for a really long time
end

% Vectors for storing mouse and timing info, created longer than we need
time = zeros(secs * 10000,1);
x = zeros(secs * 10000,1);
y = zeros(secs * 10000,1);

% 2. Record mouse position until designated stopping point
count = 1;
ShowCursor('Arrow');
timeStartedRecording = GetSecs;


while GetSecs - timeStartedRecording < secs
    time(count) = GetSecs - timeStartedRecording;
    [x(count),y(count), button] = GetMouse(PTBParams.win);
    if endOnClick && any(button)
        
        if ~isempty(spotRectToEnd) ... % check whether termination spot is specified
            && any(spotRectToEnd(:,1) <= x(count)) && any(spotRectToEnd(:,3) >= x(count))... check x pos
            && any(spotRectToEnd(:,2) <= y(count)) && any(spotRectToEnd(:,4) >= y(count)) % check y pos
            break;
        else % terminate on click regardless of where the mouse is
            if isempty(spotRectToEnd)
                break;
            end
        end
        
    end
    
    if ~isempty(spotRectToEnd) && ~endOnClick ... % check whether termination spot is specified w/o click required
            && any(spotRectToEnd(:,1) <= x(count)) && any(spotRectToEnd(:,3) >= x(count))... check x pos
            && any(spotRectToEnd(:,2) <= y(count)) && any(spotRectToEnd(:,4) >= y(count)) % check y pos
        break;
    end
    
    count = count + 1;
    % pause for 1 screen refresh (Mac OSX does not sample any faster,
    % apparently)
    WaitSecs(PTBParams.ifi); 
end

HideCursor;

% 3. Trim x, y, and time vectors to right length
x = x(time ~=0);
y = y(time ~=0);
time = time(time ~=0);

% 4. Correct y, which gets output in reverse from top of the screen
y = PTBParams.rect(4) - y;
