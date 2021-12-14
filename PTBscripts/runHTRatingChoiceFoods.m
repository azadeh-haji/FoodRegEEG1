function varargout = runHTRatingChoiceFoods(varargin)
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
    studyid = 'FoodRegEEG1'; % change this for every study
    homepath = determinePath(studyid);
    addpath([homepath filesep 'PTBScripts'])

    PTBParams = InitPTB(homepath);
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

% load names of foods
choiceFile = fullfile(PTBParams.homepath,'SubjectData',num2str(PTBParams.subjid),...
    ['Data.', num2str(PTBParams.subjid), '.ChoiceTask.mat']);
ChoiceData = load(choiceFile);
ChoiceData = ChoiceData.Data;
PTBParams.FoodNames = unique([ChoiceData.RightFood,ChoiceData.LeftFood]);
PTBParams.FoodNames = PTBParams.FoodNames(randperm(length(PTBParams.FoodNames)));
    

SessionStartTime = GetSecs();
logData(PTBParams.datafile,1,SessionStartTime);

ratingOrder = {'Health', 'Taste'};
ratingOrder = ratingOrder(randperm(length(ratingOrder)));

showInstruction(21,PTBParams)
            
trial = 1;

for r = 1:length(ratingOrder)
    switch ratingOrder{r}
        case 'Taste'
            insrx = 4;
            % load in pictures of taste rating keys
            [PTBParams.RateKeys PTBParams.RateKeysSize] = ...
                makeTxtrFromImg([imgpath 'TasteRatingKeys.png'], 'PNG', PTBParams);
            
        case 'Health'
            insrx = 5;
            % load in pictures of health rating keys
            [PTBParams.RateKeys PTBParams.RateKeysSize] = ...
                makeTxtrFromImg([imgpath 'HealthRatingKeys.png'], 'PNG', PTBParams);
    end
    
    showInstruction(insrx, PTBParams);
    
    for food = 1:3 %randperm(length(PTBParams.FoodNames))
        TrialData = getFoodRating(food, PTBParams);
        TrialData.Attribute = ratingOrder{r};
        logData(PTBParams.datafile, trial, TrialData)
        trial = trial + 1;
    end

end

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