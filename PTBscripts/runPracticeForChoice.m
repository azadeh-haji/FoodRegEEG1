function varargout = runPracticeForChoice(varargin)
%
% Script for running a single subject through instructions for the choice
% task, as well as practice trials
%
% Author: Cendri Hutcherson
% Last modified: Feb 15, 2016

try % for debugging purposes
    
    %% --------------- START NEW DATAFILE FOR CURRENT SESSION --------------- %
    studyid = 'FoodRegEEG1'; % change this for every study
    if isempty(varargin)
        homepath = determinePath(studyid);
        addpath([homepath filesep 'PTBScripts'])
        
        PTBParams = InitPTB(homepath,'DefaultSession','Practice');
    else
        PTBParams = varargin{1};
        PTBParams.inERP = 0;%???
        Data.subjid = PTBParams.subjid;
        Data.ssnid = 'Practice';
        Data.time = datestr(now);
        
        PTBParams.datafile = fullfile(PTBParams.homepath, 'SubjectData', ...
            num2str(PTBParams.subjid), ['Data.' num2str(PTBParams.subjid) '.' Data.ssnid '.mat']);
        save(PTBParams.datafile, 'Data')
    end
    
    datafile = PTBParams.datafile;
    
    %% ----------------------- INITIALIZE VARIABLES ------------------------- %
    SessionStartTime = GetSecs();
    logData(datafile,1,SessionStartTime);
    PTBParams.imgpath = fullfile(PTBParams.homepath,'PTBScripts');
    
    %% show Instructions before the practice
    insrx = 7;
    while insrx >= 7 && insrx <= 18
        if insrx == 7
            Resp = showInstruction(insrx,PTBParams,'RequiredKeys',{'RightArrow','right'});
            insrx = insrx + 1;
        else
            if insrx==13 && ~mod(PTBParams.subjid, 2)
                Resp = showInstruction(59,PTBParams,'RequiredKeys',{'RightArrow','LeftArrow','right','left'}); %for even number subjects
            else
                Resp = showInstruction(insrx,PTBParams,'RequiredKeys',{'RightArrow','LeftArrow','right','left'});
            end
            if strcmp(Resp,'LeftArrow') || isequal(Resp,'left')
                insrx = insrx - 1;
            else
                insrx = insrx + 1;
            end
        end
    end
    
    % Run 8 trials of the natural focus instructional condition with these
    % practice foods
    foodPathIndex = regexp(PTBParams.homepath,studyid);
    PTBParams.foodPath = fullfile(PTBParams.homepath(1:foodPathIndex - 1),'AllFoodPics');
    
    % load names of foods
    PTBParams.PracticeFoodNames = {'ClamJuice_3_0.25c.jpg','Cheerios_2_2T.jpg',...
        'IcebergLettuce_2_2leaves.jpg','Smarties_2_0.5box.jpg','Starburst_6_18pieces.jpg',...
        'TofuDessert_2_2Tbsp.jpg','BBQCrisps_2_5.jpg','BabyFoodSweetPotatos_2_2T.jpg'};
    
    %% run practice trials
    for trial = randperm(length(PTBParams.PracticeFoodNames))
        TrialData = runChoiceTrial(PTBParams.PracticeFoodNames{trial},0,'', PTBParams,0);
        switch TrialData.Choice
            case 2
                DrawFormattedText(PTBParams.win,'STRONG YES!', 'center',...
                    'center',PTBParams.white,40);
            case 1
                DrawFormattedText(PTBParams.win,'YES!', 'center',...
                    'center',PTBParams.white,40);
            case -1
                DrawFormattedText(PTBParams.win,'NO!', 'center',...
                    'center',PTBParams.white,40);
            case -2
                DrawFormattedText(PTBParams.win,'STRONG NO!', 'center',...
                    'center',PTBParams.white,40);
        end
        Screen('Flip',PTBParams.win);
        WaitSecs (2)
    end
    %% Show instructions on the regulation conditions
    while insrx >= 19 && insrx <= 27
        switch insrx
            case 15
                showInstruction(insrx,PTBParams,'RequiredKeys',{'RightArrow','right'});
                insrx = insrx + 1;
            otherwise
                Resp = showInstruction(insrx,PTBParams,'RequiredKeys',{'RightArrow','LeftArrow','right','left'});
                if strcmp(Resp,'LeftArrow') || isequal(Resp,'left')
                    insrx = insrx - 1;
                else
                    insrx = insrx + 1;
                end
        end
    end
    
    % %======================   RUN COMPREHENSION QUIZ   =======================%
    insrx = 28; % 
    showInstruction(insrx, PTBParams,'RequiredKeys',{'RightArrow','right'});
    insrx = insrx + 1;
    CorrectAnswers = [2, 3, 1, 3];
    for q = 1:length(CorrectAnswers)
        QuizResp = showInstruction(insrx, PTBParams, 'RequiredKeys',PTBParams.numKeys(1:3));
        QuizResp = QuizResp(1);
        logData(datafile, q, QuizResp)
        
        CorrectResponse = str2num(QuizResp) == CorrectAnswers(q);
        fprintf('Question %d: %d\n',q,CorrectResponse)
        
        if CorrectResponse
            showInstruction(insrx + 1, PTBParams,'RequiredKeys',{'RightArrow','right'});
        else
            showInstruction(insrx + 2, PTBParams,'RequiredKeys',{'RightArrow','right'});
        end
        
        logData(datafile, q, CorrectResponse);
        
        insrx = insrx + 3;
    end
    
    showInstruction(insrx, PTBParams,'RequiredKeys',{'RightArrow','right'});
    
    % show end-screen
    % showInstruction(36,PTBParams);
    
catch ME
    ME
    ME.stack.file
    ME.stack.line
    ME.stack.name
    Screen('CloseAll');
    ListenChar(1);
end



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