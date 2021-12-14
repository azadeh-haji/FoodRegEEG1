function varargout = runChoiceTask(varargin)
%
% Script for running a single subject through a ratings task, to collect measures of
% subjective perceptions of health and taste for the self-other
% decision-making task
%
% Author: Cendri Hutcherson
% Last modified: Sept. 26, 2013

try % for debugging purposes
    
    %% --------------- START NEW DATAFILE FOR CURRENT SESSION --------------- %
    studyid = 'FoodRegEEG1'; % change this for every study
    homepath = determinePath(studyid);
    if isempty(varargin)
        addpath([homepath filesep 'PTBScripts'])
        PTBParams = InitPTB(homepath,'DefaultSession','ChoiceTask');
    else
        PTBParams = varargin{1};
%         PTBParams.inERP = 0;
        Data.subjid = PTBParams.subjid;
        Data.ssnid = 'ChoiceTask';
        Data.time = datestr(now);
        
        PTBParams.datafile = fullfile(PTBParams.homepath, 'SubjectData', ...
            num2str(PTBParams.subjid), ['Data.' num2str(PTBParams.subjid) '.' Data.ssnid '.mat']);
        save(PTBParams.datafile, 'Data')
    end
    
    %% ----------------------- INITIALIZE VARIABLES ------------------------- %
    PTBParams.imgpath = fullfile(PTBParams.homepath,'PTBScripts');
    foodPathIndex = regexp(PTBParams.homepath,studyid);
    PTBParams.foodPath = fullfile(PTBParams.homepath(1:foodPathIndex - 1),'AllFoodPics'); %PTBParams.foodPath = 'C:\Users\consensEEG\Documents\Azadeh\AllFoodPics';
    
    [PTBParams.AgreeKeys, PTBParams.AgreeKeysSize] =...
        makeTxtrFromImg(fullfile(PTBParams.imgpath, 'AgreeKeys.jpeg'), 'JPG', PTBParams);
    
    [PTBParams.NatInsrx, PTBParams.NatPicSize] = ...
        makeTxtrFromImg(fullfile(PTBParams.imgpath, 'NatInsrx.jpg'), 'JPG', PTBParams);
    
    [PTBParams.RegInsrx1, PTBParams.RegPicSize1] = ...
        makeTxtrFromImg(fullfile(PTBParams.imgpath, 'HealthInsrx.jpg'), 'JPG', PTBParams); % format is JPG for stupid reasons related to PPT. Stupid PPT!
    
    [PTBParams.RegInsrx2, PTBParams.RegPicSize2] = ...
        makeTxtrFromImg(fullfile(PTBParams.imgpath, 'DecreaseInsrx.jpg'), 'JPG', PTBParams);

    [PTBParams.Ready, PTBParams.ReadyPicSize] = ...
        makeTxtrFromImg(fullfile(PTBParams.imgpath, 'Ready.jpg'), 'JPG', PTBParams);
    
    subjRatingFile = fullfile(PTBParams.homepath,'SubjectData',num2str(PTBParams.subjid),...
        ['Data.', num2str(PTBParams.subjid), '.LikingRatings-Pre.mat']);
    % show ready slide
    Screen('DrawTexture',PTBParams.win,PTBParams.Ready,[],...
        findPicLoc(PTBParams.ReadyPicSize,[.5,.5],PTBParams,'ScreenPct',1));
    Screen('Flip',PTBParams.win);
    WaitSecs(3);
    
    %take the food items
    if exist(subjRatingFile,'file')
        RateData = load(subjRatingFile);
        RateData = RateData.Data;
        
        RateData.Resp = cell2mat(RateData.Resp);
        
        for i = 1:length(RateData.Food)
            FoodStem{i} = RateData.Food{i}(1:(regexp(RateData.Food{i},'_','once') - 1));
        end
        
        uniqueFoods = unique(FoodStem);
        aveRating = zeros(length(uniqueFoods),1);
        for f = 1:length(uniqueFoods)
            aveRating(f) = mean(RateData.Resp(searchcell(RateData.Food,uniqueFoods{f},'contains')));
        end
        % assign foods to 3 groups of roughly equally liked foods
        [sortedResp indexResp] = sort(aveRating);
        uniqueFoods = uniqueFoods(indexResp);
    else
        [num, text] = xlsread(fullfile(PTBParams.homepath, 'FoodsToUse.xlsx'));
        foodnames = text(1:end,1);
        foodnames(cellfun(@(x)~ischar(x),foodnames)) = [];
        foodnames = deblank(foodnames);
        FoodOrder = foodnames(randperm(length(foodnames)));
        RateData.Food = FoodOrder;
        for i = 1:length(foodnames)
            FoodStem{i} = foodnames{i}(1:(regexp(foodnames{i},'_','once') - 1));
        end
        
        uniqueFoods = unique(FoodStem);
        %     uniqueFoods = randperm(uniqueFoods); % why do we need this? Isnt it already randomized?
    end
    
    RegForFood = [];
    for block = 1:floor(length(indexResp)/3)
        RegForFood = [RegForFood, randperm(3)];
    end
    FoodOrderNat = [];
    FoodOrderReg1 = [];
    FoodOrderReg2 = [];
    for i = 1:length(RegForFood)
        switch RegForFood(i)
            case 1
                FoodOrderNat = [FoodOrderNat RateData.Food(searchcell(RateData.Food,uniqueFoods{i},'contains'))];
            case 2
                FoodOrderReg1 = [FoodOrderReg1 RateData.Food(searchcell(RateData.Food,uniqueFoods{i},'contains'))];
            otherwise
                FoodOrderReg2 = [FoodOrderReg2 RateData.Food(searchcell(RateData.Food,uniqueFoods{i},'contains'))];
        end
    end
    
    FoodOrderNat = FoodOrderNat(1:60); %60
    FoodOrderReg1 = FoodOrderReg1(1:60);%60
    FoodOrderReg2 = FoodOrderReg2(1:60);%60
    
    FoodOrderNat = [FoodOrderNat(randperm(length(FoodOrderNat))) FoodOrderNat(randperm(length(FoodOrderNat))) FoodOrderNat(randperm(length(FoodOrderNat)))];
    FoodOrderReg1 = [FoodOrderReg1(randperm(length(FoodOrderReg1))) FoodOrderReg1(randperm(length(FoodOrderReg1))) FoodOrderReg1(randperm(length(FoodOrderReg1)))];
    FoodOrderReg2 = [FoodOrderReg2(randperm(length(FoodOrderReg2))) FoodOrderReg2(randperm(length(FoodOrderReg2))) FoodOrderReg2(randperm(length(FoodOrderReg2)))];
    
    %create the jitters /could be consistent across subjects
    tr = 540; %540
    JitterAllTrials = 1 + rand(1,tr);
    JitterNat = JitterAllTrials(1:tr/3);
    JitterReg1 = JitterAllTrials(tr/3+1:2*tr/3);
    JitterReg2 = JitterAllTrials(2*tr/3+1:tr);
    
    SessionStartTime = GetSecs();
%     Log = [SessionStartTime 0 0 0]; 
    PTBParams.RT_deadline = 4; %response deadline
    datafile = PTBParams.datafile;
    logData(datafile,1,SessionStartTime);
    
    % determine pseudorandom order of blocks (no more than 2 reps of any given
    % block type)
    BlockOrder = [];
    %Cendri did it for 21 blocks of each 10 trials
    numb = 12;%12; %12 blocks for each instruction--> 36 blocks
    numt = 15;%15;
    for block = 1:numb % for debug
        BlockOrder = [BlockOrder, randperm(3)];
    end
    
%     datafile = PTBParams.datafile;
    logData(datafile,1,FoodOrderNat,FoodOrderReg1, FoodOrderReg2, BlockOrder,JitterNat,JitterReg1,JitterReg2,BlockOrder);
    
    %start saving EEG data
    if PTBParams.inERP
        [startSend, endSend] = SendTrigger(PTBParams.daqSession, PTBParams.Trig.Start);
    end
    WaitSecs(2);
    trial = 0;
    brk = 0;
    for block = 1:length(BlockOrder) %
        switch BlockOrder(block)
            case 1
                InsrxPic = PTBParams.NatInsrx;
                InsrxSize = PTBParams.NatPicSize;
                Food = FoodOrderNat(1:numt);
    
                FoodOrderNat(1:numt) = [];
                Jitter = JitterNat(1:numt);
                JitterNat(1:numt) = [];
                trig = PTBParams.Trig.Inst.Nat;
                Insrx = 'Respond Naturally';
            case 2
                InsrxPic = PTBParams.RegInsrx1;
                InsrxSize = PTBParams.RegPicSize1;
                Food = FoodOrderReg1(1:numt);
                FoodOrderReg1(1:numt) = [];
                Jitter = JitterReg1(1:numt);
                JitterReg1(1:numt) = [];
                trig = PTBParams.Trig.Inst.Reg1;
                Insrx = 'Focus on Healthiness';
            otherwise
                InsrxPic = PTBParams.RegInsrx2;
                InsrxSize = PTBParams.RegPicSize2;
                Food = FoodOrderReg2(1:numt);
                FoodOrderReg2(1:numt) = [];
                Jitter = JitterReg2(1:numt);
                JitterReg2(1:numt) = [];
                trig = PTBParams.Trig.Inst.Reg2;
                Insrx = 'Decrease Desire';
        end
        %show task instruction
        Screen('DrawTexture',PTBParams.win,InsrxPic,[],...
            findPicLoc(InsrxSize,[.5,.5],PTBParams,'ScreenPct',1));
        [VBLTimestamp,InstOn,FlipTimestamp]=Screen('Flip',PTBParams.win);
        if PTBParams.inERP
            [startSend, endSend] = SendTrigger(PTBParams.daqSession, trig);
        else
            startSend = NaN;
            endSend   = NaN;
            trig = NaN;
        end
        InstLog = [InstOn  startSend endSend trig];
        logData(datafile,block,InstLog);

        WaitSecs(5);
        
        % select two trials to assess want-to and have-to motivation
        whtrials = randperm(numt);
        whtrials = whtrials(1:2);
        
        for t = 1:numt
            trial = trial + 1;
            if any(t == whtrials)
                showRegRatings = 0; % AH: for debugging i set it to zero so that it doesnt ask the questions. otherwise it has to be 1
            else
                showRegRatings = 0;
            end
            TrialData = runChoiceTrial(Food{t},Jitter(t),Insrx,PTBParams,showRegRatings);
            logData(datafile,trial,TrialData);
            %             WaitSecs(.2)
        end
        
        if ~PTBParams.bot% give participants a break every 3 blocks
            if mod(block,3) == 0 && block < 35
                Screen('FillRect',PTBParams.win,PTBParams.black);
                DrawFormattedText(PTBParams.win,['You may now take a break.\n'...
                    'Whenever you are ready to continue, press any key.'], 'center',...
                    'center',PTBParams.white,40);
                [VBLTimestamp,BrkOn,FlipTimestamp] = Screen('Flip',PTBParams.win);
                if PTBParams.inERP
                    [startSend, endSend] = SendTrigger(PTBParams.daqSession, PTBParams.Trig.Break);
                else
                    startSend = NaN;
                    endSend   = NaN;
%                     trig = PTBParams.Trig.Break;
                end
                brk = brk+1;
                BrkLog = [BrkOn  startSend endSend PTBParams.Trig.Break];
                logData(datafile,brk,BrkLog);
                
                collectResponse;
                Screen('DrawTexture',PTBParams.win,PTBParams.Ready,[],...
                    findPicLoc(PTBParams.ReadyPicSize,[.5,.5],PTBParams,'ScreenPct',1));
                Screen('Flip',PTBParams.win);
                WaitSecs(3);              
            end
        end
        WaitSecs(.5)
    end
    
    %stop saving the EEG data
    WaitSecs(4);
    if PTBParams.inERP
        [startSend, endSend] = SendTrigger(PTBParams.daqSession, PTBParams.Trig.Stop);
    end

    SessionEndTime = datestr(now);
    logData(datafile,1,SessionEndTime);
    
    % show end-screen
    % showInstruction(36,PTBParams);
    
    % catch ME
    %     ME
    %     ME.stack.file
    %     ME.stack.line
    %     ME.stack.name
    %     Screen('CloseAll');
    %     ListenChar(1);
    % end
    
    
    
    %% ------------------------  CLEAN-UP AND END  -------------------------- %
    
    if isempty(varargin)
        close all; Screen('CloseAll'); ListenChar(1);
    end
    
    %-------------------------------------------------------------------------%
    
    %=========================================================================%
    %                   FUNCTIONS CALLED BY MAIN SCRIPT                       %
    %=========================================================================%
catch ME
    disp(getReport(ME))
    %     close_experiment
    sca
    keyboard
end

function path = determinePath(studyid)
% determines path name, to enable some platform independence
pathtofile = mfilename('fullpath');

path = pathtofile(1:(regexp(pathtofile,studyid)+ length(studyid)));
