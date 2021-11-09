function result = stftBandpass(s, freqStart, freqEnd, sampleStart, sampleEnd, stop)
    % Creates and then applies a bandpass/stop filter to a stft.
    % Arguments:
    %   freqStart: Normalised frequency to start at
    %   freqEnd: Normalised frequency to end at
    %   sampleStart: Normalised sample to start at
    %   sampleEnd: Normalised sample to end at
    %   stop: Will invert the filter to create a bandstop filter if evaluates to true

    % If stop argument is not provided, give it a default value of false
    if nargin < 6
        stop = false;
    end

    % If freqStart is higher than freqEnd, switch the values
    if freqStart > freqEnd
        temp = freqStart;
        freqStart = freqEnd;
        freqEnd = temp;
    end

    % If sample start and end not provided, make the filter cover the whole sample
    if nargin < 5
        sampleStart = 0;
        sampleEnd = 1;
    end

    % If sampleStart is higher than sampleEnd, switch the values
    if sampleStart > sampleEnd
        temp = sampleStart;
        sampleStart = sampleEnd;
        sampleEnd = temp;
    end


    filter = zeros(size(s));
    % The midpoint in the frequency dimension is the zero point of the frequencies it represents
    mid = size(s, 1) / 2;


    % Convert normalised values to real values
    freqCutoffStart = floor(freqStart * mid);
    freqCutoffEnd = ceil(freqEnd * mid);
    timeCutoffStart = floor(sampleStart * size(s, 2));
    timeCutoffEnd = ceil(sampleEnd * size(s, 2));


    % Ensure values adhere to 1 indexing
    freqCutoffStart = max(freqCutoffStart, 1);
    timeCutoffStart = max(timeCutoffStart, 1);
    % Ensure cutoff max values are not above size of the array
    freqCutoffEnd = min(freqCutoffEnd, size(s, 1));
    timeCutoffEnd = min(timeCutoffEnd, size(s, 2));


    % Generate cutoff arrays to generate the filter
    freqCutoff1 = mid+freqCutoffStart:mid+freqCutoffEnd;
    freqCutoff2 = (mid-freqCutoffEnd)+1:(mid-freqCutoffStart)+1;
    timeCutoff = timeCutoffStart:timeCutoffEnd;
    
    % Create the filter
    filter(freqCutoff1, timeCutoff) = 1;
    filter(freqCutoff2, timeCutoff) = 1;

    % Invert if stop is true
    if stop
        filter = abs(filter - 1);
    end
    
    % Apply the filter and return the result
    result = s .* filter;
end