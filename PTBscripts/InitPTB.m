function PTBParams = InitPTB(homepath,varargin)
% function [subjid ssnid datafile PTBParams] = InitPTB(homepath,['DefaultSession',ssnid])
%
% Function for initializing parameters at the beginning of a session
%
% homepath: Path name to scripts directory for the study
%
% Author: Cendri Hutcherson
% Last Modified: 2-16-2016
% Modified by Azadeh November 2017

%% housecleaning before the guests arrive
cd(homepath);
close all; Screen('CloseAll');
homepath = [pwd '\'];

%% Get Subject Info
% Check to make sure aren't about to overwrite duplicate session!
checksubjid = 1;
while checksubjid == 1
    subjid      = input('Subject number:  ', 's');
    ssnid       = input('Session number:  ', 's');
    
    % Set defaults for subject number and session
    if isempty(subjid)
        subjid = '999';
    end
    
    if isempty(ssnid)
        if isempty(LikingRatings) || ~any(strcmp(varargin,'DefaultSession'))
            ssnid = '1';
        else
            ind = find(strcmp(varargin,'DefaultSession'));
            ssnid = varargin{ind + 1};
        end
    end
    fprintf('\nSaving datafile as Data.%s.%s.mat\n\n',subjid,ssnid)
    
    if exist([homepath 'SubjectData/' subjid '/Data.' subjid '.' ssnid '.mat'],'file') == 2
        cont = input('WARNING: Datafile already exists!  Overwrite? (y/n)  ','s');
        if cont == 'y'
            checksubjid = 0;
        else
            checksubjid = 1;
        end
    else
        checksubjid = 0;
    end
end

% create name of datafile where data will be stored
if ~exist([homepath 'SubjectData/' subjid],'dir')
    mkdir([homepath 'SubjectData/' subjid]);
end


Data.subjid = subjid;
Data.ssnid = ssnid;
Data.time = datestr(now);

datafile = fullfile(homepath, 'SubjectData', subjid, ['Data.' subjid '.' ssnid '.mat']);
save(datafile,'Data');

%% bot mode is used to simulte responses for timing tests
PTBParams.bot = 0; %1: bot is on 0: bot is off % hardcoded for tests
%% Initialize parameters for fMRI
inMRI = 0;%input('Run the study using MRI? 0 = no (default), 1 = yes: '); AH: stopped asking
if isempty(inMRI)
    inMRI = 0;
end
PTBParams.inMRI = inMRI;

% get TR duration
if inMRI
    PTBParams.TR = input('Length of TR (in secs, default = 2.75): ');
else
    PTBParams.TR = 2.5;
end

if isempty(PTBParams.TR)
    PTBParams.TR = 2.5;
end

%% Initialize parameters for EEG if necessary

inERP = input('Run the study using EEG? 0 = no (default), 1 = yes: ');

if isempty(inERP)
    inERP = 0;
end

PTBParams.inERP = inERP;
PTBParams.KbDevice = -1;

%---- define triggers -----
Trig.Start                   = 198; %BioSemi starts recording
Trig.Stop                    = 199; %BioSemi stops recording
Trig.Inst.Nat                = 201; %respond naturally
Trig.Inst.Reg1               = 202; %focus on health
Trig.Inst.Reg2               = 203; %decrease desire

Trig.Cross.Nat                = 204;% Strong Yes, Yes, No, Strong No
Trig.Cross.Reg1               = 205;% Strong Yes, Yes, No, Strong No
Trig.Cross.Reg2               = 206;% Strong Yes, Yes, No, Strong No

Trig.Food.Nat                 = 101; % Any food
Trig.Food.Reg1                = 102; % Any food
Trig.Food.Reg2                = 103; % Any food

% Trig.Rating                  = 101:106; % determine based on subject's response;This is for all rating responses including hunger

Trig.Resp.Nat                = [110 111 112 113];% Strong Yes, Yes, No, Strong No
Trig.Resp.Reg1               = [114 115 116 117];% Strong Yes, Yes, No, Strong No
Trig.Resp.Reg2               = [118 119 120 121];% Strong Yes, Yes, No, Strong No
Trig.Resp.missed             = 125;
Trig.Break                   = 126; %BioSemi starts recording

% --------these lines are specific to the BioSemi trigger box------
addpath('C:\toolbox\TriggerFunctions');
if PTBParams.inERP
    [PTBParams.daqSession] = TriggerInit(1); % this initiates triggering (opens a port and creates a session on the daq
else
    disp('No triggers requested')
end
%------------------------
PTBParams.Trig = Trig;

%% Initialize PsychToolbox Parameters and save in PTBParams struct

AssertOpenGL;
ListenChar(2); % don't print keypresses to screen
% ListenChar
Screen('Preference', 'SkipSyncTests', 0); % use 1 if VBL fails
Screen('Preference', 'VisualDebugLevel',3);

% HideCursor;
screenNum = 0;
PsychDefaultSetup(1);

if str2double(subjid) > 900
    %     use next line if want to run in partial screen mode
    [w, rect] = Screen('OpenWindow',screenNum, [], [0 0 800 600]);
else
    [w, rect] = Screen('OpenWindow',screenNum);
end
ctr = [rect(3)/2, rect(4)/2];
white=WhiteIndex(w);
black=BlackIndex(w);
gray = (WhiteIndex(w) + BlackIndex(w))/2;
ifi = Screen('GetFlipInterval', w);

PTBParams.win = w;
PTBParams.rect = rect;
PTBParams.ctr = ctr;
PTBParams.white = white;
PTBParams.black = black;
PTBParams.gray = gray;
PTBParams.ifi = ifi;
PTBParams.datafile = datafile;
PTBParams.homepath = homepath;
PTBParams.subjid = str2double(subjid);
PTBParams.ssnid = ssnid;
PTBParams.numKeys = {'1!' '2@' '3#' '4$' '5%' '6^' '7&' '8*' '9(' '0)'};
PTBParams.RT_deadline = Inf;
PTBParams.Missed_msg = 'Please respond faster!';

% set response key mapping
if mod(PTBParams.subjid, 2) % ODD subject numbers
    PTBParams.KeyYesNo = {'d','f','j','k'}; % Strong Yes, Yes, No, Strong No
    PTBParams.KeyOrder = {6 5 4 3 2 1};
else % EVEN subject numbers
    PTBParams.KeyYesNo = {'k','j','f','d'}; % Strong Yes, Yes, No, Strong No
    PTBParams.KeyOrder = {1 2 3 4 5 6};
end
% AH: keys must be consistent for one subject. If left is more Yes,
% then 1 should correspond to Strongly Like, etc

% save PTBParams structure
datafile = fullfile(homepath, 'SubjectData', subjid, ['PTBParams.' PTBParams.ssnid '.mat']);
save(datafile,'PTBParams');
Screen(w,'TextSize',round(.1*ctr(2)));
Screen('TextFont',w,'Helvetica');
Screen('FillRect',w,black);

% WaitSecs(.5);
%% Seed random number generator
%(note that different versions of Matlab allow/deprecate different random
% number generators, so I've incorporated some flexibility here

[v d] = version; % get Matlab version
if datenum(d) > datenum('April 8, 2011') % compare to first release of rng
    rng('shuffle')
else
    rand('twister',sum(100*clock));
end

