function MouseData = processMouseTrace(trace, varargin)
% function MouseData  = processMouseTrace(trace, [traceTiming],[plotResults],['EndPtCtrs', ctrs])
%
% DESCRIPTION:
% Function takes as input a 2-column vector of the X and Y coordinates of a
% mouse over time and outputs statistics related to the mouse trace in the
% structure MouseData. 
%
% The optional argument traceTiming gies the time (in
% secs) at which each X-Y coordinate pair was collected. If not specified,
% this defaults to an assumption that data is collected every 10ms.
%
% The argument plotResults can be supplied if a graph of the mouse trace
% and associated points of interest (see below) is desired.
% 
% The argument 'EndPtCtrs' can be used to specify the location of the
% center of each option, which, if provided, will be used to calculate the
% normalized angle deviance from a head-on trajectory (-1 = dead ahead to
% Left, +1 = dead ahead to Right). Otherwise, an approximation will be made
% using the final click location and its projection onto the non-chosen
% side
%
% OUTPUTS:
% normX, normY: normalized x and y coordinates, such that the mouse trace
% always starts at 0 and ends at 1
%
% normXSigned: normalized x coordinate ending either at 1 (right-hand side)
% or at -1 (left-hand side)
%
% normX100, normY100, normXSigned100: normalized x and y coordinates,
% stretched to always have a length of 100 time points
%
% currentDrx: variable which asks at each time point whether the mouse is
% heading toward the right or left object
%
% currentDrx100: toRight scaled to 100 time points
%
% normedTrajectory: similar to currentDrx, but scaled by angle of deviation
% between straight-line path to right or left object and current mouse
% angle (-1 is straight to left object, +1 is straight to right object)
%
% normedTrajectory100: normedTrajectory scaled to 100 time points
%
% RT: total time to respond, in secs
%
% firstDeviation: first time-point at which the mouse trajectory shows a
% reliable departure from the initial trajectory
%
% drxFirstDev: direction the mouse heads upon first showing departure from
% initial trajectory
%
% nChangeMind: number of times the mouse trajectory indicates a "change of
% mind"
%
% timeChangeMind: vector of time-points specifying time at which a "change
% of mind" occurred
% 
% xChangeMind, yChangeMind: coordinates for changes of mind
%
% peakAtChange: measure of how far toward the opposite side person got
% before changing mind
%
% maxVelocity: maximum mouse velocity
%
% firstMoveSpeed: average speed of the first mouse movement after choice initiation
%
% finalPauseBeforeClick: amount of time spent hovered over final choice option
% before click
%
% timeMaxVelocity: time-point of maximum velocity
% 
% timeFinalChoice: time at which the final movement toward a food (i.e. the
% movement that resulted in clicking the food) was initiated


%% Do format checking and correction for trace (must be N x 2 matrix)
[nRow nCol] = size(trace);

if nRow <= 1 || nCol <= 1
    error('Incorrect mouse trace format! Must have both X and Y coordinates.');
end

if nRow > 2 && nCol > 2
    error('Incorrect mouse trace format! Must have only X and Y coordinates.');
end

if nRow < nCol % transpose it
    trace = trace';
end

if isempty(varargin) || isempty(varargin{1})
    tracetime = [0:(size(trace,1) - 1)] * .01; % assumes mouse trace sample rate is 100Hz
else
    tracetime = varargin{1};
    if size(tracetime,1) < size(tracetime,2)
        tracetime = tracetime';
    end
end

if length(varargin) > 1
    plotResults = varargin{2};
else
    plotResults = 0;
end

% if ~isempty(strfind(varargin,'EndPtCtrs'))
%     EndPtCtrs = varargin{strfind(varargin,'EndPtCtrs') + 1};
% end

%% Calculate new mouse trace variables
x = trace(:,1);
y = trace(:,2);

normXSigned = (x - x(1))/abs(x(end) - x(1));
finalChoice = sign(normXSigned(end));
        
normX = (x - x(1))/(x(end) - x(1));
normY = (y - y(1))/(y(end) - y(1));

normX100 = interp1(1:length(normX),normX,linspace(1,length(normX),100))';
normXSigned100 = interp1(1:length(normXSigned),normXSigned,linspace(1,length(normXSigned),100))';
normY100 = interp1(1:length(normY),normY,linspace(1,length(normY),100))';

%% Characteristics of mouse trace
RT = tracetime(end) - tracetime(1);

%% initial angle of mouse trajectory
opposite = normX;
hypotenuse = sqrt(normX.^2 + normY.^2);
angle = asin(opposite./hypotenuse); % insert rad2deg
initialAngle = mean(angle(2:6));


%% first reliable deviation from initial trajectory

% first check to see if there's a clear deceleration
velocityX = diff(normX);
velocitySignedX = diff(normXSigned);
accelerationX = diff(velocityX);

velocityY = diff(normY);
accelerationY = diff(velocityY);

velocity = sqrt(velocityX.^2 + velocityY.^2);
acceleration = diff(velocity); 
minRT = .150;
tempX = abs(diff(normX(tracetime >= minRT))); % change in X-position after first 150 ms.
indexX = 1:length(tempX);
indexDev = [];

while isempty(indexDev) && length(tempX) > 2
    % determine velocity above current pt
    abovePt = (tempX(2:end) - tempX(1)) > .0001;

    if any(abovePt)
        firstAbove = find(abovePt == 1, 1);
        firstNotAbove = find(abovePt == 0, 1);
        if isempty(firstNotAbove)
            firstNotAbove = length(abovePt);
        end
        
        if firstNotAbove > firstAbove && firstNotAbove > 3 % has peak and wide enough base (e.g. moving for long enough time)
            hump = tempX(1:firstNotAbove);
            [peak peakIndex] = max(hump);
            peak = peak - hump(1);
            if sum(hump) > .05 ... movement length is long enough
                && peak > .05 % acceleration suggests intentionality
                indexDev = indexX(1) + find(tracetime > minRT,1) - 1; % adjust for removal of first 100 ms.
            end
        end
        
        tempX(1:firstNotAbove) = [];
        indexX(1:(firstNotAbove)) = [];
    else
        tempX(1) = [];
        indexX(1) = [];
    end

end

if isempty(indexDev)
    if  tracetime(end) >= minRT
        indexDev = find(normX > .2 & tracetime >= minRT,1);
    else
        indexDev = 1;
    end
end
xFirstDev = normX(indexDev);
yFirstDev = normY(indexDev);
firstDeviation = tracetime(indexDev);
firstMoveTowardFinal = tracetime(find(sign(velocitySignedX(indexDev:end)) == sign(normXSigned(end)),1) + indexDev);

currentAngle = zeros(length(normX) - 1,1);
for i = 1:length(normX) - 1
    opposite = normX(i + 1)  - normX(i);
    adjacent = normY(i + 1) - normY(i);
    hypotenuse = sqrt(opposite ^ 2 + adjacent ^ 2);
    currentAngle(i) = asin(opposite/hypotenuse); %rad2deg(
end
currentAngle(isnan(currentAngle)) = 0;

%% determine points where mouse trajectory indicates a change of mind
indexChange = [];
peakOfChange = [];

tempX = velocityX(abs(velocityX) > .01);
indexX = 1:length(velocityX);
indexX = indexX(abs(velocityX) > .01);

changeDirection = sign(tempX(1:end - 1)) ~= sign(tempX(2:end));
ptsPreChange = indexX(changeDirection);
ptsPostChange = indexX(find(changeDirection) + 1);
if ~isempty(ptsPreChange)
    for i = 1:length(ptsPreChange)
        indices = ptsPreChange(i):ptsPostChange(i);
        ptsOfChange(i) = indices(find(abs(velocityX(indices)) == min(abs(velocityX(indices))),1));
    end
else
    ptsOfChange = [];
end
ptsOfChange(ptsOfChange <= indexDev + 6) = []; % only accept changes of mind long enough after first deviation
ptsOfChange = [ptsOfChange, length(normX)];

pt = 1;
while length(ptsOfChange) > 1
    thisPt = ptsOfChange(pt);
    nextPt = ptsOfChange(pt + 1);
    durationOfChange = nextPt - thisPt;
    diffXOfChange = abs(normX(nextPt) - normX(thisPt));
    
    if durationOfChange > 6 ... meaningful duration moving in opp. direction
       && diffXOfChange > .1 ... meaningful movement toward other side
       && ~(normX(thisPt) > .85 && normX(nextPt) > .85) % exclude corrections trying to hit final target
    
        indexChange = [indexChange thisPt];
        peakOfChange = [peakOfChange normX(nextPt)];
        ptsOfChange(1) = [];
    else
        ptsOfChange(1:2) = [];
    end
    
    
end

nChangeMind = length(indexChange);
timeChangeMind = tracetime(indexChange);
xChangeMind = normX(indexChange);
yChangeMind = normY(indexChange);

if ~isempty(indexChange)
    drxFirstDev = sign(normXSigned(indexChange(1)) - normXSigned(indexDev));
else
    drxFirstDev = sign(normXSigned(end) - normXSigned(indexDev));
end

% calculate average speed of first movement post-choice initiation
endLastMove = find(abs(velocityX) > .01,1,'last');
if nChangeMind > 0
    firstMoveSpeed = mean(abs(velocityX(indexDev:indexChange(1))));
else
    firstMoveSpeed = mean(abs(velocityX(indexDev:endLastMove)));
end


% calculate current direction for each movement
currentDrx(1:indexDev - 1) = sign(normXSigned(indexDev) - normXSigned(1));
currentDrx(indexDev:length(normX)) = drxFirstDev;
if nChangeMind >= 1
    for cm = 1:nChangeMind
        currentDrx(indexChange(cm):end) = currentDrx(indexChange(cm) - 1) * -1;
    end
end

currentDrx100 = interp1(1:length(currentDrx),currentDrx,linspace(1,length(currentDrx),100))';

%% calculate normalized trajectory deviance
if ~exist('EndPtCtrs','var') % use normalized trajectory
    xDiff = diff(normXSigned);
    xDiff(abs(xDiff) < .0001) = 0;
    yDiff = diff(normY);
    yDiff(abs(yDiff) < .0001) = 0;
    currentAngle = acosd(xDiff./sqrt(xDiff.^2 + yDiff.^2));
    
%     % if participant does not move, fill in with previous angle
%     for i = find(isnan(currentAngle))'
%         if i > 1
%             currentAngle(i) = currentAngle(i - 1);
%         else
%             currentAngle(i) = 0;
%         end
%     end
    
%     currentAngle(yDiff < 0 & xDiff >= 0) = 0 - currentAngle(yDiff < 0 & xDiff >= 0);
%     currentAngle(yDiff < 0 & xDiff < 0) = 360 - currentAngle(yDiff < 0 & xDiff < 0);
    AngleToRight = acosd((1 - normXSigned)./sqrt((1 - normXSigned).^2 + (1 - normY).^2));
    AngleToLeft = acosd((-1 - normXSigned)./sqrt((-1 - normXSigned).^2 + (1 - normY).^2));
    
    AngleToRight(isnan(AngleToRight)) = 0;
    AngleToLeft(isnan(AngleToLeft)) = 180;
    
    AngleToRight = AngleToRight(1:end - 1);
    AngleToLeft = AngleToLeft(1:end - 1);
    
    AngleBisect = (AngleToRight + AngleToLeft)/2;
    
%     % replace points of no movement with indifference angle
    currentAngle(isnan(currentAngle)) = AngleBisect(isnan(currentAngle));
    
    AngleDiff = (AngleToRight - AngleToLeft)/2;
    normedTrajectory = (currentAngle - AngleBisect)./AngleDiff;
    normedTrajectory(end + 1) = normedTrajectory(end); % add in 1 extra pt at end
    % replace small corrective moves at end with direct trajectory leading up to
    % end
    nearTarget = normX(1:end - 1) > .85 & normX(2:end) > .85;
    indices = [fliplr(find(nearTarget)') 1];
    lastBeforeFinalMove = indices(find(diff(indices) ~= -1, 1, 'first'));
    normedTrajectory(lastBeforeFinalMove:end) = sign(normXSigned(lastBeforeFinalMove));

    % replace moves outside of -1 to 1 with -1 or 1
    
    for i = find(abs(normedTrajectory) > 1)'
        if i > 1
            normedTrajectory(i) = sign(normedTrajectory(i)); % -1 or 1
        else
            normedTrajectory(i) = AngleBisect(i);
        end
    end
    
    normedTrajectory100 = interp1(1:length(normedTrajectory),normedTrajectory,linspace(1,length(normedTrajectory),100))';
end

%% max velocity
[maxVelocity maxTime] = max(sqrt(diff(normX).^2 + diff(normY).^2));
timeMaxVelocity = tracetime(maxTime);

timeFinalChoice = max([firstDeviation, max(timeChangeMind)]);

finalPauseBeforeClick = tracetime(end) - tracetime(endLastMove);
%% curvature and maximum deviation from straight line
% rotate trace by 45 degrees
rotMat = [cos(1.75 * pi), -sin(1.75 * pi);sin(1.75 * pi), cos(1.75 * pi)];
rotCoords = rotMat * [normX100';normY100'];
% calculate area under the curve
AUCTotal = mean(rotCoords(2,:));
AUCToOther = mean(rotCoords(2,:).*(rotCoords(2,:) >= 0));
AUCToSelf = mean(rotCoords(2,:).*(rotCoords(2,:) < 0));
maxDev = rotCoords(2,find(abs(rotCoords(2,:)) == max(abs(rotCoords(2,:))),1));

%% Assign variables to output structure

varnames = {'RT','normX','normY','normXSigned','finalChoice','tracetime'...
            'normX100','normY100','normXSigned100', 'angle', 'initialAngle', ...
            'currentDrx','currentDrx100','normedTrajectory','normedTrajectory100'...
            'firstDeviation', 'indexDev', 'drxFirstDev','firstMoveTowardFinal', ...
            'nChangeMind','timeChangeMind', 'xChangeMind','yChangeMind', ...
            'peakOfChange', 'maxVelocity', 'timeMaxVelocity', 'firstMoveSpeed',...
            'timeFinalChoice', 'finalPauseBeforeClick', ...
            'AUCTotal','AUCToOther','AUCToSelf','maxDev'...
           };
MouseData = cell2struct(varnames,varnames,2);

for v = 1:length(varnames)
    MouseData.(varnames{v}) = eval(varnames{v});
end

% show characteristics of the mouse trace in a plot, if requested
if plotResults == 1
    nGraphs = 5;
    p = 1;
    h = subplot(nGraphs,1,p);
    plot(normX(currentDrx < 0),normY(currentDrx < 0), 'k', ...
         normX(currentDrx > 0),normY(currentDrx > 0), 'g')
    
    hold on;
    scatter(xFirstDev,yFirstDev,100,'b')
    if(nChangeMind > 0)
       scatter(xChangeMind,yChangeMind,100,'r') 
    end
    hold off;
    
    p = p + 1;
    subplot(nGraphs,1,p)
%     plot(normX)
%     hold on;
    plot(abs(diff(normX)))
    hold on;
    scatter(indexDev,abs(diff(normX([indexDev, indexDev + 1]))))
    hold off;
    
    p = p + 1;
    subplot(nGraphs,1,p)
    plot(velocity)
    hold on;
    plot(abs(diff(velocity)),'r')
    scatter(indexDev, abs(diff(velocity([indexDev, indexDev + 1]))))
    hold off;
    
    p = p + 1;
    subplot(nGraphs,1,p)
    plot(angle,'b')
    hold on;
    plot([0;diff(angle)],'r');
    hold off;
    
%     p = p + 1;
%     subplot(nGraphs,1,p)
%     plot(currentAngle,'b')
%     hold on;
%     plot(abs(diff(currentAngle)),'r')
%     hold off;

    p = p + 1;
    subplot(nGraphs,1,p)
%     plot(currentAngle,'b')
%     hold on;
    plot(currentAngle/180,'r')
    hold on;
    plot(normedTrajectory)
    hold off;
    
    input('Continue?')
end

% axes(h);
% 
% getPoints = input('See another point? <enter> = yes, 0 = no: ');
% if isempty(getPoints)
%     getPoints = 1;
% end
% 
% while getPoints
% [x, y] = ginput(1)
% 
% distanceToPoint = sqrt((normX - x).^2 + (normY - y).^2);
% [dist index] = min(distanceToPoint);
% 
% index
% 
% getPoints = input('See another point? <enter> = yes, 0 = no: ');
% if isempty(getPoints)
%     getPoints = 1;
% end
% end
% 

 