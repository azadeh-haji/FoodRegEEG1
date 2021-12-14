function varargout = determineFood(varargin)
%
% Script for running a single subject through a ratings task, to collect measures of 
% subjective perceptions of health and taste for the self-other
% decision-making task
%
% Author: Cendri Hutcherson
% Last modified: Sept. 26, 2013

% try % for debugging purposes

%% --------------- START NEW DATAFILE FOR CURRENT SESSION --------------- %

if isempty(varargin)
    studyid = 'FoodReg1'; % change this for every study
    homepath = determinePath(studyid);
    addpath([homepath filesep 'PTBScripts'])

    PTBParams = InitPTB(homepath);
else
    PTBParams = varargin{1};
    PTBParams.inERP = 0;
    Data.subjid = PTBParams.subjid;
    Data.ssnid = 'FoodOutcome';
    Data.time = datestr(now);
 
    PTBParams.datafile = fullfile(PTBParams.homepath, 'SubjectData', ...
                         num2str(PTBParams.subjid), ['Data.' num2str(PTBParams.subjid) '.' Data.ssnid '.mat']);
    save(PTBParams.datafile, 'Data')
end

%% ----------------------- INITIALIZE VARIABLES ------------------------- %
imgpath = [PTBParams.homepath 'PTBscripts/'];

% load names of foods
choiceFile = fullfile(PTBParams.homepath,'SubjectData',num2str(PTBParams.subjid),...
    ['Data.', num2str(PTBParams.subjid), '.ChoiceTask.mat']);
ChoiceData = load(choiceFile);
ChoiceData = ChoiceData.Data;

fid = fopen(fullfile(PTBParams.homepath,'AvailableFoods.txt'));
temp = textscan(fid,'%s','HeaderLines',1,'Delimiter','\t');
availableFoods = temp{1};

availableTrials = [];
for i = 1:length(ChoiceData.Choice)
    if strcmp(ChoiceData.Choice{i},'right')
        chosenFood = ChoiceData.RightFood{i};
    else
        chosenFood = ChoiceData.LeftFood{i};
    end
    
    if any(strcmp(chosenFood,availableFoods))
        availableTrials = [availableTrials i];
    end
end
trialSelected = availableTrials(ceil(rand(1)*length(availableTrials)));
RightFood = ChoiceData.RightFood{trialSelected};
LeftFood = ChoiceData.LeftFood{trialSelected};

SessionStartTime = GetSecs();
logData(PTBParams.datafile,1,SessionStartTime);

showInstruction(22,PTBParams);
Screen(PTBParams.win,'FillRect',PTBParams.black);
Screen(PTBParams.win,'Flip');
WaitSecs(1);

DrawFormattedText(PTBParams.win,['Trial # selected: ' num2str(trialSelected)],...
    'center',.2*PTBParams.ctr(2),PTBParams.white);
TrialRevealed = Screen(PTBParams.win,'Flip',[],1);

[RFoodPic, RFoodSize] = makeTxtrFromImg(fullfile(PTBParams.homepath,'FoodPics',RightFood),...
    'BMP',PTBParams);
[LFoodPic, LFoodSize] = makeTxtrFromImg(fullfile(PTBParams.homepath,'FoodPics',LeftFood),...
    'BMP',PTBParams);

% Display foods
if strcmp(ChoiceData.Choice{trialSelected},'NULL')
    DrawFormattedText(PTBParams.win,['You chose between these foods, but did not respond in time.', ...
        'The highlighted food was selected at random for you to eat'],...
        'center',.4*PTBParams.ctr(2),PTBParams.white,40);
    if rand(1) > .5
        ChoiceData.Choice{trialSelected} = 'right';
    else
        ChoiceData.Choice{trialSelected} = 'right';
    end
else
    DrawFormattedText(PTBParams.win,['You chose between these foods, and selected the one that is highlighted. ', ...
        'This is the food you will eat.'],...
        'center',.4*PTBParams.ctr(2),PTBParams.white,40);
end
leftFoodPosition = findPicLoc(LFoodSize,[.3,.6],PTBParams,'ScreenPct',.3);
rightFoodPosition = findPicLoc(RFoodSize,[.7,.6],PTBParams,'ScreenPct',.3);

Screen('DrawTexture',PTBParams.win,RFoodPic,[],rightFoodPosition);
Screen('DrawTexture',PTBParams.win,LFoodPic,[],leftFoodPosition);

if strcmp(ChoiceData.Choice{trialSelected},'right')
    Screen('FrameRect',PTBParams.win,PTBParams.white,rightFoodPosition,6)
else
    Screen('FrameRect',PTBParams.win,PTBParams.white,leftFoodPosition,6)
end

FoodsOn = Screen(PTBParams.win,'Flip',TrialRevealed+1,1);

DrawFormattedText(PTBParams.win,['Please inform the experimenter that you '...
    'are finished with this portion of the experiment'],'center',PTBParams.ctr(2)*1.65,...
    PTBParams.white,40);
Screen(PTBParams.win,'Flip',FoodsOn+3,1);
collectResponse([],1,'c');
collectResponse([],1,'o');

SessionEndTime = datestr(now);
logData(PTBParams.datafile,1,SessionEndTime);

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

function path = determinePath(studyid)
	% determines path name, to enable some platform independence
	pathtofile = mfilename('fullpath');

	path = pathtofile(1:(regexp(pathtofile,studyid)+ length(studyid)));