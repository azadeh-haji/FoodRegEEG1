function TrialData = runChoiceTrial(FoodOnTrial, jitter,Instruction, PTBParams, showRegRatings)
%function TrialData = runChoiceTrial(FoodOnTrial, MoneyOnTrial, PTBParams)
%
% Usage: takes a string identifying a food picture (just the name, not the
% full path, and a number identifying the monetary amount to offer,
% displays them to the participant, and collects a yes-no response to the
% choice-pair using the mouse to click on 'Yes' or 'No' buttons
%
% Trial structure:
%    1. Show the start button, and require the participant to click the
%    button to reveal the choice options
%    2. Present the proposal (one food-money pair) and collect yes-no
%    choice from particant using a mouse
%
% AH: Modified for EEG1 by Azadeh -- November 2017
try
    ctr = PTBParams.ctr;
    
    %========================= 1. Blank screen for amount of jitter  ========================%
    
    Screen('FillRect',PTBParams.win,PTBParams.black);%VERY VERY IMPORTANT
    Screen('Flip',PTBParams.win);
    WaitSecs(jitter);
    
    [PTBParams.FoodPic, PTBParams.FoodPicSize] = makeTxtrFromImg(fullfile(PTBParams.foodPath,FoodOnTrial),...
        'JPG',PTBParams);
    
    FoodPicPosition = findPicLoc(PTBParams.FoodPicSize, [.5, .5], PTBParams, 'ScreenPct', .2);
    
    % Prepare the fixation cross and surrounding color frame based on the instruction
    
    switch Instruction
        case 'Respond Naturally'
            [PTBParams.Cross, PTBParams.CrossSize] = ...
                makeTxtrFromImg(fullfile(PTBParams.imgpath, 'CrossGreen.png'), 'PNG', PTBParams);
            trigTemp = 'Nat';
        case 'Focus on Healthiness'
            [PTBParams.Cross, PTBParams.CrossSize] = ...
                makeTxtrFromImg(fullfile(PTBParams.imgpath, 'CrossRed.png'), 'PNG', PTBParams);
            trigTemp = 'Reg1';
        case 'Decrease Desire'
            [PTBParams.Cross, PTBParams.CrossSize] = ...
                makeTxtrFromImg(fullfile(PTBParams.imgpath, 'CrossYellow.png'), 'PNG', PTBParams);
            trigTemp = 'Reg2';
        otherwise
            [PTBParams.Cross, PTBParams.CrossSize] = ...
                makeTxtrFromImg(fullfile(PTBParams.imgpath, 'CrossWhite.png'), 'PNG', PTBParams);
            %                         trigTemp = 'None';
    end
    CrossPosition = findPicLoc(PTBParams.CrossSize, [.5, .5], PTBParams, 'ScreenPct', .05);
    
    %=========== 3. Present fixation cross =============%


    Screen('DrawTexture',PTBParams.win, PTBParams.Cross, [], CrossPosition);
%     Screen('DrawingFinished',PTBParams.win,1);
    if PTBParams.inERP && exist('trigTemp')
        trig = PTBParams.Trig.Cross.(trigTemp);
        [startSend endSend] = SendTrigger(PTBParams.daqSession,trig);
    else
        trig = NaN;
        startSend = NaN;
        endSend = NaN;
    end
    [VBLTimestamp CrossOn FlipCross] = Screen('Flip',PTBParams.win,[],1);
%     for i=1:29
%     % Flip to the screen
%         VBLTimestamp = Screen('Flip', PTBParams.win, VBLTimestamp +  0.5 * PTBParams.ifi);
%     end

%     if PTBParams.inERP && exist('trigTemp')
%         trig = PTBParams.Trig.Cross.(trigTemp);
%         [startSend endSend] = SendTrigger(PTBParams.daqSession,trig);
%     else
%         trig = NaN;
%         startSend = NaN;
%         endSend = NaN;
%     end
    Log = [CrossOn  FlipCross-VBLTimestamp startSend endSend trig];
    
    %     %redraw it 30 times the ifi
    %     for i=1:29
    %             Screen('DrawTexture',PTBParams.win, PTBParams.Cross, [], CrossPosition);
    %             Screen('DrawingFinished',PTBParams.win,1);
    %             Screen(PTBParams.win,'Flip',[],1);
    %     end
    
    %=========== 3. Present food  and collect response =============%
    % Screen('FillRect',PTBParams.win,[0,0,0],StartButtonPosition);
    %     Screen('DrawTexture',PTBParams.win, PTBParams.InstPic, [], InstPicPosition);
    Screen('DrawTexture',PTBParams.win, PTBParams.FoodPic, [], FoodPicPosition);
%     Screen('DrawingFinished',PTBParams.win,1);
    
    % WaitSecs(PTBParams.ifi*29);
    % Now that we've drawn the food and money, display them
    [VBLTimestamp FoodOn FlipFood] = Screen('Flip',PTBParams.win,CrossOn+PTBParams.ifi*29,1);%CrossOn+PTBParams.ifi*29
    if PTBParams.inERP && exist('trigTemp')
        trig = PTBParams.Trig.Food.(trigTemp);
        [startSend endSend] = SendTrigger(PTBParams.daqSession,trig);
    else
        trig = NaN;
        startSend = NaN;
        endSend = NaN;
    end
    Log = [Log;FoodOn FlipFood-VBLTimestamp startSend endSend trig];
    
    if ~PTBParams.bot
        key=0;
        %     stim_time = FoodOn;
        while key == 0
            [key, key_time, keyCode] = KbCheck;
            rt = key_time - FoodOn; %
            resp = KbName (find(keyCode,1,'first'));
            if key && ~ismember (resp, {'d','f','j','k'})
                key=0;
            end
            if rt > PTBParams.RT_deadline %deadline for response
                RTDeadline(PTBParams)
                resp = 'null';
                break
            end
        end
    else
        xx = {'d','f','j','k'};
        resp = xx{randperm(4,1)};
        rt = 1+rand;
        key_time = rt+FoodOn;
    end
    %     [resp, rt] = collectResponse(PTBParams.RT_deadline,[],PTBParams.KeyYesNo,PTBParams.KbDevice);%time deadline?
    % resp = PTBParams.KeyOrder{resp};%AH: counterbalance
    %     RT = RT - FoodOnTime;
    temp = [2 1 -1 -2]; % strong yes, yes, no, strong no
    [a ind] = ismember(resp,PTBParams.KeyYesNo);
    if a
        Choice = temp(ind);
    else
        Choice = NaN;
        rt = NaN;
        key_time = NaN;
    end
    if PTBParams.inERP && exist('trigTemp')
        if ~isnan(Choice)
            trig = PTBParams.Trig.Resp.(trigTemp)(ind);
            [startSend endSend] = SendTrigger(PTBParams.daqSession,trig);
        else
            trig = PTBParams.Trig.Resp.missed;
            [startSend endSend] = SendTrigger(PTBParams.daqSession,trig);
        end
    else
        trig = NaN;
        startSend = NaN;
        endSend = NaN;
    end
    Log = [Log;key_time  0 startSend endSend trig];
    
    TrialData.FoodOnTrial = FoodOnTrial;
    TrialData.InstructionOnTrial = Instruction;
    TrialData.Choice = Choice;
    TrialData.ChoiceRT = rt;
    TrialData.ChoiceTime = key_time;
    TrialData.Log = Log;
    TrialData.Jitter = jitter;
    
    % To avoid memory issues, we close the texture associated with the food
    % picture now that we are done using it
    Screen('Close',PTBParams.FoodPic);
    % WaitSecs(.5);
    
catch ME
    ME
    ME.stack.file
    ME.stack.line
    ME.stack.name
    Screen('CloseAll');
    ListenChar(1);
end