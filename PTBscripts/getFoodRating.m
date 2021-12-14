function TrialData = getFoodRating(foodnum, PTBParams)
% function TrialData = getFoodRating(foodnum, PTBParams)
%
% foodnum = specifies which food to display
% PTBParams = structure specifying various study parameters
%

%% 1. DISPLAY TRIAL TYPE FOR 500 ms + jittered fixation
Screen('DrawDots',PTBParams.win, [0;0], 10, [255,255,255]', PTBParams.ctr, 1);
TrialStartTime = Screen(PTBParams.win, 'Flip');
%% 2. DISPLAY FOOD FOR UP TO 4 SECONDS

% load food picture for trial
Food = PTBParams.FoodNames{foodnum};
[FoodTexture, FoodSize] = makeTxtrFromImg(fullfile(PTBParams.foodPath,Food),'JPG', PTBParams);

picLoc = findPicLoc(FoodSize,[.5,.45],PTBParams,'ScreenPct',.45);
Screen('DrawTexture', PTBParams.win, FoodTexture,[],picLoc);
picLoc = findPicLoc(PTBParams.RateKeysSize,[.5,.85],PTBParams,'ScreenPct',.25);
Screen('DrawTexture', PTBParams.win, PTBParams.RateKeys,[],picLoc);

FoodOnTime = Screen(PTBParams.win,'Flip',TrialStartTime + .2); % so 250 ms, not 500 ms and no jitter

if ~PTBParams.bot
    [Resp, RT] = collectResponse([],[],PTBParams.numKeys(1:6),PTBParams.KbDevice);%time deadline?
    Resp = str2double(Resp(1));
    Resp = PTBParams.KeyOrder{Resp};%AH: counterbalance
    RT = RT - FoodOnTime;
else
    Resp = randperm(6,1);
    RT = 1 + rand;
end


%% 3. DISPLAY FIXATION

Screen('DrawDots',PTBParams.win, [0;0], 10, [255,255,255]', PTBParams.ctr, 1);
FixationOnTime = Screen(PTBParams.win, 'Flip');

WaitSecs(.02);


%% 4. ADD TRIAL DATA TO STRUCTURE FOR OUTPUT

TrialData.Food = Food;
TrialData.Resp = Resp;
TrialData.RT = RT;
TrialData.TrialStartTime = TrialStartTime;
TrialData.FoodOnTime = FoodOnTime;

%% 5. CLEAN UP
Screen('Close',FoodTexture);

