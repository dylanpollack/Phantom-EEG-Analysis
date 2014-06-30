function protocol = filterProtocol( protocol )
%Remove white space, practice, and calibration trials from the protocol.

numTrials = length(protocol{1});
ind = [];

% Trim white space.
protocol{2} = strtrim(protocol{2});
protocol{4} = strtrim(protocol{4});
protocol{5} = strtrim(protocol{5});
protocol{6} = strtrim(protocol{6});

% Note the indices of practice and calibration trials.
% Count number of T1 trials, for later use.
for i = 1:numTrials
    trialType = protocol{6}{i};
    if strcmp(trialType,'practice') || strcmp(trialType,'calibration')
        ind = [ind,i];
    end
end

% Remove practice and calibration trials from the protocol.
for i = 1:length(protocol)
    protocol{i}(ind) = [];
end
    
        
end

