% Prompt user to load mTot file (.mat format).
[mTotFile, mTotPath] = uigetfile('*.mat','Please select the EEG data to be analyzed.');
mTot = load(fullfile(mTotPath,mTotFile));
mTot = mTot.mTot;

% Initialize arrays that will contain trials for each condition.
baselineT1 = [];
baselineT2 = [];
catchTrials = [];
adaptationTrials = [];

% Search through mTot, adding files from each condition into
% their respective arrays.
for i = 1:numel(mTot)
    
    data = mTot{i}.data;
    
    if strcmp(mTot{i}.type, 'baseline')
       
        if strcmp(mTot{i}.location, 't1')
            baselineT1 = cat(3, baselineT1, data);
        else
            baselineT2 = cat(3, baselineT2, data);
        end
    
    elseif strcmp(mTot{i}.type, 'catch')
        catchTrials = cat(3, catchTrials, data);
        
        % Adaptation trials that occur directly before the catch.
        adaptationTrials = cat(3, adaptationTrials, mTot{i-1}.data);
    end
end

NUM_CHANNELS = length(meanCatch(:,1)); % Number of channels
TIME = mTot{1}.time; % Time span of each trial

% Average levels for each trial, used to account for drift.
T1TrialMeans = repmat(mean(baselineT1,2),1,size(baselineT1,2));
T2TrialMeans = repmat(mean(baselineT2,2),1,size(baselineT2,2));
catchTrialMeans = repmat(mean(catchTrials,2),1,size(catchTrials,2));
adaptationTrialMeans = repmat(mean(adaptationTrials,2),1,size(adaptationTrials,2));

% Average across all trials in a condition for each electrode.
meanT1 = mean(baselineT1-T1TrialMeans, 3);
meanT2 = mean(baselineT2-T2TrialMeans, 3);
meanCatch = mean(catchTrials-catchTrialMeans,3);
meanAdaptation = mean(adaptationTrials-adaptationTrialMeans,3);

% Initialize figure.
screen = get(0,'ScreenSize'); % left, bottom, width, height
figure('position',[1 screen(4)/100 screen(3)/0.5 screen(4)]);

% Create a subplot for each electrode.
for i = 1:NUM_CHANNELS-1
    
    subplot(10,6,i);
    hold on;
    plot(TIME, meanCatch(i,:));
    plot(TIME, meanT1(i,:), 'r');
    axis([TIME(1) TIME(end) -100 100])
    sub_pos = get(gca,'position'); % get subplot axis position
    set(gca,'position',sub_pos.*[1 1 1.2 1.2]); % stretch its width and height
    
end