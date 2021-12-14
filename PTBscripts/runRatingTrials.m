function runRatingTrials(varargin)
%
% Script for running a single subject through a ratings task, to collect measures of
% subjective perceptions of health and taste for the food choice
% decision-making task
%
% Author: Cendri Hutcherson
% Last modified: Sept. 26, 2013

try % for debugging purposes
    
    %% --------------- START NEW DATAFILE FOR CURRENT SESSION --------------- %
    
    studyid = 'FoodRegEEG1'; % change this for every study
    
    if isempty(varargin)
        homepath = determinePath(studyid);
        addpath([homepath filesep 'PTBScripts'])
        PTBParams = InitPTB(homepath,'DefaultSession','AttributeRatings-Pre');
    else
        PTBParams = varargin{1};
        PTBParams.inERP = 0;
        Data.subjid = PTBParams.subjid;
        Data.ssnid = 'AttributeRatings-Post';
        Data.time = datestr(now);
        
        PTBParams.datafile = fullfile(PTBParams.homepath, 'SubjectData', ...
            num2str(PTBParams.subjid), ['Data.' num2str(PTBParams.subjid) '.' Data.ssnid '.mat']);
        save(PTBParams.datafile, 'Data')
    end
    
    %% ----------------------- INITIALIZE VARIABLES ------------------------- %
    imgpath = [PTBParams.homepath 'PTBscripts/'];
    foodPathIndex = regexp(PTBParams.homepath,studyid);
    PTBParams.foodPath = fullfile(PTBParams.homepath(1:foodPathIndex - 1),'AllFoodPics');
    % load names of foods
    choiceFile = fullfile(PTBParams.homepath,'SubjectData',num2str(PTBParams.subjid),...
        ['Data.', num2str(PTBParams.subjid), '.ChoiceTask.mat']);
    ChoiceData = load(choiceFile);
    ChoiceData = ChoiceData.Data;
    ltemp = length(ChoiceData.FoodOrderNat{1})/3;
    for i=1:ltemp
        PTBParams.FoodNames{i} = ChoiceData.FoodOrderNat{1}{i};
        PTBParams.FoodNames{i+ltemp} = ChoiceData.FoodOrderReg1{1}{i};
        PTBParams.FoodNames{i+2*ltemp} = ChoiceData.FoodOrderReg2{1}{i};
    end
%     PTBParams.FoodNames = ChoiceData.FoodOnTrial;
    
    SessionStartTime = GetSecs();
    trial = 1;
    datafile = PTBParams.datafile;
    logData(datafile,trial,SessionStartTime); % AH: not sure if it appends fields to Data or else
    
    insrx = 44; 
    while insrx >=44 && insrx < 46
        if insrx == 44
            showInstruction(44,PTBParams,'RequiredKeys',{'RightArrow','right'});
            insrx = insrx + 1;
        else
            Resp = showInstruction(insrx,PTBParams,'RequiredKeys',{'RightArrow','LeftArrow','right','left'});
            if strcmp(Resp,'LeftArrow') || strcmp(Resp,'left')
                insrx = insrx - 1;
            else
                insrx = insrx + 1;
            end
        end
    end
    
    %counterbalance and corresponding to response keys
    if mod(PTBParams.subjid, 2)
        [PTBParams.RateKeys, PTBParams.RateKeysSize] =...
            makeTxtrFromImg([imgpath 'LikingRatingKeys_RL.png'], 'PNG', PTBParams);
    else
        [PTBParams.RateKeys, PTBParams.RateKeysSize] =...
            makeTxtrFromImg([imgpath 'LikingRatingKeys.png'], 'PNG', PTBParams);
    end
    
    trial = 1;
    for food = randperm(length(PTBParams.FoodNames)) %AH: why is this? Modify and test
        TrialData = getFoodRating(food, PTBParams);
        TrialData.Attribute = 'Liking';
        logData(PTBParams.datafile, trial, TrialData)
        trial = trial + 1;
    end
        
    ratingOrder = {'Health', 'Taste'};
    ratingOrder = ratingOrder(randperm(length(ratingOrder)));
      
    for r = 1:length(ratingOrder)
        switch ratingOrder{r}
            case 'Taste'
                insrx = 46;
                % load in pictures of taste rating keys
                %counterbalance and corresponding to response keys
                if mod(PTBParams.subjid, 2)
                    [PTBParams.RateKeys, PTBParams.RateKeysSize] =...
                        makeTxtrFromImg([imgpath 'TasteRatingKeys_RL.png'], 'PNG', PTBParams);
                else
                    [PTBParams.RateKeys, PTBParams.RateKeysSize] =...
                        makeTxtrFromImg([imgpath 'TasteRatingKeys.png'], 'PNG', PTBParams);
                end
                                
            case 'Health'
                insrx = 47;
                % load in pictures of health rating keys
                if mod(PTBParams.subjid, 2)
                    [PTBParams.RateKeys, PTBParams.RateKeysSize] =...
                        makeTxtrFromImg([imgpath 'HealthRatingKeys_RL.png'], 'PNG', PTBParams);
                else
                    [PTBParams.RateKeys, PTBParams.RateKeysSize] =...
                        makeTxtrFromImg([imgpath 'HealthRatingKeys.png'], 'PNG', PTBParams);
                end
        end
        
        showInstruction(insrx, PTBParams,'RequiredKeys',{'RightArrow','right'});
        
        for food = randperm(length(PTBParams.FoodNames))
            TrialData = getFoodRating(food, PTBParams);
            TrialData.Attribute = ratingOrder{r};
            logData(PTBParams.datafile, trial, TrialData)
            trial = trial + 1;
        end
        
    end
    
    SessionEndTime = datestr(now);
    trial = 1;
    datafile = PTBParams.datafile;
    logData(datafile,trial,SessionEndTime);
    
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
catch ME
    disp(getReport(ME))
    %     close_experiment
    sca
    keyboard
end

%-------------------------------------------------------------------------%

%=========================================================================%
%                   FUNCTIONS CALLED BY MAIN SCRIPT                       %
%=========================================================================%

function path = determinePath(studyid)
% determines path name, to enable some platform independence
pathtofile = mfilename('fullpath');

path = pathtofile(1:(regexp(pathtofile,studyid)+ length(studyid)));