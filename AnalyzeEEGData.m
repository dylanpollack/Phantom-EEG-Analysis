SAMPLING_RATE = 256; % Default sampling rate is 256 Hz.
TRIAL_LENGTH = 3;  % Default trial length is 2 seconds.
SPT = SAMPLING_RATE*TRIAL_LENGTH; % Number of samples collected per trial.

% Load the protocol file (.csv format) into a cell array. 
% Each cell corresponds to a column in the protocol file. 
% Only the first 7 columns, which contain information about
% the trial category, are recorded.
[protFile,protPath] = uigetfile('*.csv','Select the protocol file.');
fid = fopen(fullfile(protPath,protFile));
protocol = textscan(fid,'%*d %d %s %d %s %s %s %*[^\n]','HeaderLines',1,'Delimiter',',');
fclose(fid);

% Filter the protocol, removing practice and calibration trials.
protocol = filterProtocol(protocol);

% Number of trials in the experiment (excluding practice and calibration).
NUM_TRIALS = length(protocol{1});

% Prompt user to load EEG data (.mat format).
[eegFile, eegPath] = uigetfile('*.mat','Please select the EEG data to be analyzed.');
EEG = load(fullfile(eegPath,eegFile));

% Extract information about button presses from the digital EEG channel.
digitalChannel = EEG.EEG.data(61,:);
diffs = diff(digitalChannel); % Vector of changes in potential over time.
index = []; % Indices of button releases that precede trials.

% Indices of trials for which the button was released before
% the light came on.
glitch = [];

% Scan button press data to identify the indices
% marking the beginning of T1 trials.
for i = 1:length(diffs)
    
   % Detect each index at which the target light turns off;
   % this event occurs in the middle of any given trial.
   if diffs(i) == -16
       
      % Search backwards from the light-off index, until
      % a button release is detected. The last button release
      % during a trial will correspond to the start of that trial.
      for releaseIndex = i+50:-1:1
          
          % Button release is detected.
          if diffs(releaseIndex) == -64
              
             % Store index of button release.
             index = [index,releaseIndex]; 
             
             % Note any abnormalities in the button press data,
             % so that they can be plotted against Phantom data.
             if digitalChannel(releaseIndex) == 64
                glitch = [glitch,releaseIndex]; 
             end
             
             % Begin searching for the next light-off index.
             break
          end
      end
   end
end

% Delete the calibration trial.
% (Note: there should only be one calibration trial corresponding to
% the one target light.)
index = index(1:end-1);

% Remove practice trials. This line assumes that all T2 baseline
% trials precede T1 trials.
countT1 = sum(strcmp(protocol{4}, 't1'));
index = index(end-countT1+1:end);

% Buffer one trial's length to eliminate noisy button releases.
buffer = SPT;

% Scan button press data to identify the indices
% marking the beginning of T2 trials.
for i = index(1):-1:1
   
    % Button release is detected, and there are still baseline
    % trials left to be found.
    if diffs(i) == -64 && buffer <= 0 && length(index) < NUM_TRIALS

       % Store index of button release.
       index = [i,index];
       
       % Reset the buffer, so that clusters of button release
       % artifacts are ignored.
       buffer = SPT;
       
    end
    
    % Decrement buffer.
    % Any button releases that occur within the buffer time
    % cannot have been the start of a trial.
    buffer = buffer - 1;

end

% Create a cell array containing all relevant information for each
% individual trial. Data for each trial begins 2 seconds before
% the button was released and ends 3 seconds after the button was
% released.

for i = 1:NUM_TRIALS
    mTot{i}.trial = i;
    mTot{i}.block = protocol{1}(i);
    mTot{i}.location = protocol{4}{i};
    mTot{i}.type = protocol{6}{i};
    mTot{i}.time = -(2*SPT/3):(SPT-1);
    mTot{i}.data = EEG.EEG.data(:,(index(i)-2*SPT/3):(index(i)+SPT-1));
    mTot{i}.notes = [];
end

% Plot digital channel with circles marking the start of each trial.
hold on;
plot(digitalChannel);
plot(index,ones(1,length(index))*70,'or');

% DEBUG: Use this to quickly plot the first trial.
%        If the first trial matches the first T2 trial,
%        the correct number of trials was found.
% axis([index(1)-2*SPT index(2) -1 90]);
 
% Label each trial number.
% for k=1:length(index)
%     text(index(k)+30,80,num2str(k));
% end

% Save epoched trial data.
fileName = [eegFile(1:2),'_Phantom_mTot.mat'];
save(fullfile(protPath,fileName), 'mTot');