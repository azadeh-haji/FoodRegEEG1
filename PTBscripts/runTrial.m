function TrialData = runTrial(RightFood, LeftFood, Instruction, PTBParams)

% Trial procedure for study GVR-Mouse2
% Trial structure:
%    1. Fixation (1 sec)
%    2. Presentation of two choices, with 3 seconds deliberation
%       to collect response from subject
%    3. Fixation (2 sec)
%    4. Display outcome (2 sec)
%
% Author: Cendri Hutcherson
% Date: 06/04/2012

ctr = PTBParams.ctr;
% Initialize variables for parameters that might not be reached if the
% participant takes too long to respond during the decision period
%TBC

%========================= 1. Load necessary images ======================%

% Draw blank screen
Screen('FillRect',PTBParams.win,PTBParams.black);
Screen(PTBParams.win,'Flip');

% load images to display Start, Reveal, and Choice Buttons
StartButton = PTBParams.StartButton;
StartButtonHighlighted = PTBParams.StartButtonHighlighted;

[RFoodPic, RFoodSize] = makeTxtrFromImg(fullfile(PTBParams.homepath,'FoodPics',RightFood),...
    'BMP',PTBParams);
[LFoodPic, LFoodSize] = makeTxtrFromImg(fullfile(PTBParams.homepath,'FoodPics',LeftFood),...
    'BMP',PTBParams);

%============  2. Display START button with a blank screen  ==============%

% Draw START button and instruction at bottom of the screen
StartButtonPosition = findPicLoc(PTBParams.StartPicSize, [.5, .875], PTBParams, ...
    'ScreenPct',.1);
Screen('DrawTexture',PTBParams.win,StartButton,[],StartButtonPosition);
DrawFormattedText(PTBParams.win, Instruction, ...
                  'center',StartButtonPosition(4) + 20, ...
                  PTBParams.white);

% Ensure criteria for beginning mouse parameters (start location, start
% velocity) are met before displaying proposal

TrialAborted = 1;

while TrialAborted
%     SetMouse(PTBParams.ctr(1),PTBParams.ctr(2));
    StartOn = Screen(PTBParams.win,'Flip',[],1);
    % Wait for participant to click on START button, then highlight it
    mouseTrack([], 1, PTBParams, StartButtonPosition);

    % Wait for participant to move the mouse above the top rim of the START 
    % button. If they have not moved it within 500 ms, restart the trial
    RegionAboveStartButton = [StartButtonPosition(1),0,...
                              StartButtonPosition(3), StartButtonPosition(2)];
    Screen('DrawTexture',PTBParams.win,StartButtonHighlighted,[],StartButtonPosition);
    StartClicked = Screen(PTBParams.win,'Flip',[],1);
    
    [t1, t2, time] = mouseTrack(.5, 0, PTBParams, RegionAboveStartButton);
    if time(end) > .49
        [t1, t2, TextBounds] = DrawFormattedText(PTBParams.win, ...
                            'TOO SLOW!\nSTART OVER.', 'center','center', PTBParams.white);
        TooSlowScreenOn = Screen(PTBParams.win,'Flip',[],1);
        Screen('FillRect', ...
               PTBParams.win, ...
               PTBParams.black, ...
               [ctr(1) - ceil(TextBounds(3)/2), ctr(2) - ceil(TextBounds(4)/2), ...
                ctr(1) + ceil(TextBounds(3)/2), ctr(2) + ceil(TextBounds(4)/2)]);
        Screen('DrawTexture', PTBParams.win, StartButton,[], StartButtonPosition);
        Screen(PTBParams.win,'Flip',TooSlowScreenOn + .5,1);

    else
        TrialAborted = 0;
    end
end

%============== 3. Present food pairs and collect response ===============%

% Display foods
leftFoodPosition = findPicLoc(LFoodSize,[.2,.2],PTBParams,'ScreenPct',.3);
rightFoodPosition = findPicLoc(RFoodSize,[.8,.2],PTBParams,'ScreenPct',.3);

Screen('DrawTexture',PTBParams.win,RFoodPic,[],rightFoodPosition);
Screen('DrawTexture',PTBParams.win,LFoodPic,[],leftFoodPosition);

FoodsOn = Screen(PTBParams.win,'Flip',[],1);


[ChoiceX,ChoiceY,ChoiceTime] = mouseTrack(4, 1, PTBParams, [rightFoodPosition; leftFoodPosition]);


%================= 4. Determine display for outcome period ===============%

% If participant doesn't respond within 4 seconds, remind them of the
% time limit
if ChoiceTime(end) >= (4 - PTBParams.ifi)
    Choice = 'NULL';
    ChoiceRT = NaN;
    Screen(PTBParams.win,'FillRect');
    ChoiceMade = GetSecs();
    DrawFormattedText(PTBParams.win, ['    TOO SLOW!\n\nIF THIS TRIAL IS DRAWN,' ... 
        'YOU WILL RECEIVE ONE OF THESE FOODS AT RANDOM.'], ...
                      'center','center', PTBParams.white,50);
    Screen(PTBParams.win,'Flip');
    WaitSecs(3);
else
    Choice = sign(ChoiceX(end) - ctr(1)); % Left Choice == -1, Right Choice == 1
    if Choice == -1
        Choice = 'left';  
        Screen('FrameRect',PTBParams.win,PTBParams.white,leftFoodPosition,6)
    else
        Choice = 'right';
        Screen('FrameRect',PTBParams.win,PTBParams.white,rightFoodPosition,6)
    end
    
    % Highlight the button they chose for 250 ms
    ChoiceMade = Screen(PTBParams.win,'Flip');    
    ChoiceRT = ChoiceTime(end);
    
    % display blank screen
    Screen(PTBParams.win,'Flip',ChoiceMade + .25);
    WaitSecs(.5);
end

TrialData.RightFood = RightFood;
TrialData.LeftFood = LeftFood;
TrialData.Choice = Choice;
TrialData.ChoiceRT  = ChoiceRT;
TrialData.ChoiceX = ChoiceX;
TrialData.ChoiceY = ChoiceY;
TrialData.ChoiceTime = ChoiceTime;
TrialData.Instruction = Instruction;
      
Screen('Close',[LFoodPic, RFoodPic]);
WaitSecs(1);
% Screen('Close');
    