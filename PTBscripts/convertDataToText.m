function convertDataToText(varargin)

if ~isempty(varargin)
    showPlots = varargin{1};
else
    showPlots = 0;
end

subjects = [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 ...
            26 27 28 29 30 31 33 34 35 36 37 38 3940];
% processed subjects: 
% [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 ...
%  26 27 28 29 30 31 33 34 35 36 37 38 39 ]
% 26 - has weird looking motions
% 32 - weird motions - constantly going outside computer screen

dataPath = '~/Desktop/Dropbox/Projects/GVR-Mouse2/SubjectData/';

for s = 1:length(subjects)
    subjID = num2str(subjects(s));
    fprintf('Processing mouse data for subject %s...\n',subjID)
    
    %% Get trial data for each part
    clear Choice
    clear Choice1
    % process data for Part 1 (unregulated choice)
    load([dataPath subjID '/Data.' subjID '.ChoiceTask.mat'])
    
    if exist(fullfile(dataPath,subjID,'MouseChoice.mat'),'file')
        load(fullfile(dataPath,subjID,'MouseChoice.mat'))
    end
    
    if showPlots
        [w, rect] = Screen('OpenWindow',0, [], [1100,645,1440,900]); 
    end
    for t = 1:length(Data.Choice)
        clc;
        sprintf('Processing trial %d\n\n',t)
%         input(['View trial ' num2str(t)])
        Choice1(t) = processMouseTrace_fromDVNR([Data.ChoiceX{t},Data.ChoiceY{t}],Data.ChoiceTime{t},0);
        save(fullfile(dataPath,subjID,'MouseChoice.mat'),'Choice');
    end 
    
    % load pre-task rating data
    PreRating = load([dataPath subjID '/Data.' subjID '.AttributeRatings-Pre.mat']);
    PostRating = load([dataPath subjID '/Data.' subjID '.AttributeRatings-Post.mat']);
    % load mouse data

    %% Print mouse trace trial data to .txt file
    
    % delete file if it already exists (avoids appending each time this is
    % run)
    if exist([dataPath subjID '/MouseTracePerChoice2_' subjID '.txt'],'file')
        delete([dataPath subjID '/MouseTracePerChoice2_' subjID '.txt'])
    end
    
    fid = fopen([dataPath subjID '/MouseTracePerChoice2_' subjID '.txt'],'a');
    
    fprintf(fid, ['Subject\tTrial\t' ...
                  'TimePt\tTime\tChoiceX\tChoiceSignedX\tChoiceY\tDrx\tTrajectory\n']);
    
    % print info for choice task
    for trial = 1:length(Choice) % for each trial
        for m = 1:length(Choice(trial).normX) % for each mouse sample
            fprintf(fid, '%s\t%d\t',subjID, trial);
            
            fprintf(fid, '%d\t%.3f\t%.4f\t%.4f\t%.4f\t%d\n', ...
                    m,Choice(trial).tracetime(m),Choice(trial).normX(m),...
                    Choice(trial).normXSigned(m), Choice(trial).normY(m),...
                    Choice(trial).currentDrx(m));%, Choice(trial);
        end

    end
    
    
    
    fclose(fid);
    
    %% Print mouse trace trial data interpolated to 100 pts to .txt file
    
    % delete file if it already exists (avoids appending each time this is
    % run)
    if exist([dataPath subjID '/MouseTrace100PerChoice_' subjID '.txt'],'file')
        delete([dataPath subjID '/MouseTrace100PerChoice_' subjID '.txt'])
    end
    
    fid = fopen([dataPath subjID '/MouseTrace100PerChoice_' subjID '.txt'],'a');
    
    fprintf(fid, ['Subject\tTrial\t' ...
                  'TimePt\tChoiceX\tChoiceSignedX\tChoiceY\tDrx\n']);
    
    % print info for choice task
    for trial = 1:length(Choice) % for each trial
        for m = 1:length(Choice(trial).normX100) % for each mouse sample
            fprintf(fid, '%s\t%d\t',subjID, trial);
            fprintf(fid, '%d\t%.4f\t%.4f\t%.4f\t%d\n', ...
                    m,Choice(trial).normX100(m),Choice(trial).normXSigned100(m),...
                    Choice(trial).normY100(m),Choice(trial).currentDrx100(m));
        end

    end
    
    
    
    fclose(fid);
    
    %% Print trial-by-trial variables to separate .txt file
   
    fprintf('Processing trial data for subject %s...\n',subjID)
    
    % delete file if it already exists (avoids appending each time this is
    % run)
    if exist([dataPath subjID '/ChoiceData_' subjID '.txt'],'file')
        delete([dataPath subjID '/ChoiceData_' subjID '.txt'])
    end
    
    fid = fopen([dataPath subjID '/ChoiceData_' subjID '.txt'],'a');
    
    headers = {'Subject','Trial','Instruction','Health1Right','Taste1Right', ...
            'Health1Left','Taste1Left','Health2Right','Taste2Right', ...
            'Health2Left','Taste2Left','ChoseRight','ChoiceRT','FirstDevTimeChoice',...    
            'InitAngleChoice','NumChangeMindChoice','FinalDevTimeChoice','MaxVelocityChoice',...
            'DrxFirstDevChoice','TotalAUCChoice','AUCtoNonChosenChoice',...
            'AUCtoChosenChoice','MaxDevChoice','Health1Right_RT','Taste1Right_RT',...
            'Health1Left_RT','Taste1Left_RT','Health2Right_RT','Taste2Right_RT', ...
            'Health2Left_RT','Taste2Left_RT'};
    % print vars at top of file
    for h = 1:length(headers) - 1
        fprintf(fid,'%s\t',headers{h});
    end
    
    fprintf(fid,'%s\n',headers{end});
    
    % print info 
    colVars = {'Data.subjid','t','Data.Instruction{t}',...
               'HealthPreR','TastePreR','HealthPreL','TastePreL',...
               'HealthPostR','TastePostR','HealthPostL','TastePostL',...
               'strcmp(Data.Choice{t},''right'')','Data.ChoiceRT{t}',...
               'Choice(t).firstDeviation','Choice(t).initialAngle','Choice(t).nChangeMind',...
               'Choice(t).timeFinalChoice','Choice(t).maxVelocity',...
               'Choice(t).drxFirstDev','Choice(t).AUCTotal',...
               'Choice(t).AUCToNonChosen','Choice(t).AUCToChosen','Choice(t).maxDev',...
               'HealthPreR_RT','TastePreR_RT','HealthPreL_RT','TastePreL_RT',...
               'HealthPostR_RT','TastePostR_RT','HealthPostL_RT','TastePostL_RT',...
               };
    
    for t = 1:length(Data.Choice) % for each trial
        HealthPreR = PreRating.Data.Resp{strcmp(PreRating.Data.Attribute,'Health') ...
            & strcmp(PreRating.Data.Food,Data.RightFood{t})};
        HealthPreL = PreRating.Data.Resp{strcmp(PreRating.Data.Attribute,'Health') ...
            & strcmp(PreRating.Data.Food,Data.LeftFood{t})};
        TastePreR = PreRating.Data.Resp{strcmp(PreRating.Data.Attribute,'Taste') ...
            & strcmp(PreRating.Data.Food,Data.RightFood{t})};
        TastePreL = PreRating.Data.Resp{strcmp(PreRating.Data.Attribute,'Taste') ...
            & strcmp(PreRating.Data.Food,Data.LeftFood{t})};
        HealthPostR = PostRating.Data.Resp{strcmp(PostRating.Data.Attribute,'Health') ...
            & strcmp(PostRating.Data.Food,Data.RightFood{t})};
        HealthPostL = PostRating.Data.Resp{strcmp(PostRating.Data.Attribute,'Health') ...
            & strcmp(PostRating.Data.Food,Data.LeftFood{t})};
        TastePostR = PostRating.Data.Resp{strcmp(PostRating.Data.Attribute,'Taste') ...
            & strcmp(PostRating.Data.Food,Data.RightFood{t})};
        TastePostL = PostRating.Data.Resp{strcmp(PostRating.Data.Attribute,'Taste') ...
            & strcmp(PostRating.Data.Food,Data.LeftFood{t})};
        
        HealthPreR_RT = PreRating.Data.RT{strcmp(PreRating.Data.Attribute,'Health') ...
            & strcmp(PreRating.Data.Food,Data.RightFood{t})};
        HealthPreL_RT = PreRating.Data.RT{strcmp(PreRating.Data.Attribute,'Health') ...
            & strcmp(PreRating.Data.Food,Data.LeftFood{t})};
        TastePreR_RT = PreRating.Data.RT{strcmp(PreRating.Data.Attribute,'Taste') ...
            & strcmp(PreRating.Data.Food,Data.RightFood{t})};
        TastePreL_RT = PreRating.Data.RT{strcmp(PreRating.Data.Attribute,'Taste') ...
            & strcmp(PreRating.Data.Food,Data.LeftFood{t})};
        HealthPostR_RT = PostRating.Data.RT{strcmp(PostRating.Data.Attribute,'Health') ...
            & strcmp(PostRating.Data.Food,Data.RightFood{t})};
        HealthPostL_RT = PostRating.Data.RT{strcmp(PostRating.Data.Attribute,'Health') ...
            & strcmp(PostRating.Data.Food,Data.LeftFood{t})};
        TastePostR_RT = PostRating.Data.RT{strcmp(PostRating.Data.Attribute,'Taste') ...
            & strcmp(PostRating.Data.Food,Data.RightFood{t})};
        TastePostL_RT = PostRating.Data.RT{strcmp(PostRating.Data.Attribute,'Taste') ...
            & strcmp(PostRating.Data.Food,Data.LeftFood{t})};
        
        for c = 1:length(colVars) - 1
            eval(['v = ' colVars{c} ';']);
            printvar(v,fid,'\t');
        end
        eval(['v = ' colVars{c + 1} ';']);
        printvar(v,fid,'\n');

    end
    
    
%% Process rating data independently
    fprintf('Processing ratings data for subject %s...\n',subjID)
    if exist([dataPath subjID '/RatingDataForGLM_' subjID '.txt'],'file')
        delete([dataPath subjID '/RatingDataForGLM_' subjID '.txt'])
    end


    fid = fopen([dataPath subjID '/RatingDataForGLM_' subjID '.txt'],'a');

    headers = {'Subject','Session','Block','Trial','Attribute','Food','Rating','RT'};
    % print vars at top of file
    for h = 1:length(headers) - 1
        fprintf(fid,'%s\t',headers{h});
    end

    fprintf(fid,'%s\n',headers{end});

    colVars = {'PreRating.Data.subjid','Session','Block'...
        't','PreRating.Data.Attribute{t}','PreRating.Data.Food{t}',...
        'PreRating.Data.Resp{t}','PreRating.Data.RT{t}',};

    for t = 1:length(PreRating.Data.Food)
        Session = 1;
        if strcmp(PreRating.Data.Attribute{t},PreRating.Data.Attribute{1})
            Block = 1;
        else
            Block = 2;
        end

        for c = 1:length(colVars) - 1
                eval(['v = ' colVars{c} ';']);
                printvar(v,fid,'\t');
        end
        eval(['v = ' colVars{c + 1} ';']);
        printvar(v,fid,'\n');
    end
    
    colVars = {'PreRating.Data.subjid','Session','Block'...
        't','PostRating.Data.Attribute{t}','PostRating.Data.Food{t}',...
        'PostRating.Data.Resp{t}','PostRating.Data.RT{t}',};

    for t = 1:length(PostRating.Data.Food)
        Session = 2;
        if strcmp(PostRating.Data.Attribute{t},PostRating.Data.Attribute{1})
            Block = 1;
        else
            Block = 2;
        end

        for c = 1:length(colVars) - 1
                eval(['v = ' colVars{c} ';']);
                printvar(v,fid,'\t');
        end
        eval(['v = ' colVars{c + 1} ';']);
        printvar(v,fid,'\n');
    end
    
    fclose(fid);
    
end

function printvar(var,fid,endCap)
    if isempty(var) || any(isnan(var))
        var = 'NA';
    end
    varInfo = whos('var');
    
    switch varInfo.class
        case 'char'
            fprintf(fid,['%s' endCap],var);
        case 'logical'
            fprintf(fid,['%d' endCap],var);
        otherwise
            fprintf(fid,['%.4f' endCap],var);
    end
    
