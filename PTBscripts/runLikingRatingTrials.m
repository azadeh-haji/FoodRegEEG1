function runLikingRatingTrials(varargin)
%
% Script for running a single subject through a ratings task, to collect measures of 
% subjective perceptions of health and taste for the food choice
% decision-making task
%
% Author: Cendri Hutcherson
% Last modified: Sept. 26, 2013

% try % for debugging purposes

%% --------------- START NEW DATAFILE FOR CURRENT SESSION --------------- %

studyid = 'FoodRegEEG1'; % change this for every study

if isempty(varargin)
    homepath = determinePath(studyid);
    addpath([homepath filesep 'PTBScripts'])
    PTBParams = InitPTB(homepath,'DefaultSession','LikingRatings-Pre');
else
    PTBParams = varargin{1};
    PTBParams.inERP = 0;
    Data.subjid = PTBParams.subjid;
    Data.ssnid = 'LikingRatings-Pre';
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
PTBParams.nFoods = 30;
[num, text] = xlsread(fullfile(PTBParams.homepath, 'FoodsToUse.xlsx'));
foodnames = text(1:end,1);
foodnames(cellfun(@(x)~ischar(x),foodnames)) = [];
foodnames = deblank(foodnames);
PTBParams.FoodNames = foodnames;

SessionStartTime = GetSecs();
trial = 1;
datafile = PTBParams.datafile;
logData(datafile,trial,SessionStartTime);

insrx = 3;
while insrx >=3 && insrx < 5
    if insrx == 3
        showInstruction(3,PTBParams,'RequiredKeys',{'RightArrow','right'});
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
    [PTBParams.RateKeys, PTBParams.RateKeysSize] = makeTxtrFromImg([imgpath 'LikingRatingKeys_RL.png'], 'PNG', PTBParams);
else
    [PTBParams.RateKeys, PTBParams.RateKeysSize] = makeTxtrFromImg([imgpath 'LikingRatingKeys.png'], 'PNG', PTBParams);
end
trial = 1;
for food = randperm(length(PTBParams.FoodNames))
    TrialData = getFoodRating(food, PTBParams);
    TrialData.Attribute = 'Liking';
    logData(PTBParams.datafile, trial, TrialData)
    trial = trial + 1;
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

%-------------------------------------------------------------------------%

%=========================================================================%
%                   FUNCTIONS CALLED BY MAIN SCRIPT                       %
%=========================================================================%

function path = determinePath(studyid)
	% determines path name, to enable some platform independence
	pathtofile = mfilename('fullpath');

	path = pathtofile(1:(regexp(pathtofile,studyid)+ length(studyid)));