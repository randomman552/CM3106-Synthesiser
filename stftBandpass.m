function filter = stftBandpass(s, freqStart, freqEnd, sampleStart, sampleEnd, stop)
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


    filter = zeros(size(s,1)/2, size(s, 2));

    % Generate cutoff points to generate the filter
    minX = max(floor(sampleStart * size(filter, 2)), 1);
    maxX = min(floor(sampleEnd * size(filter, 2)), size(filter, 2));
    minY = max(floor(freqStart * size(filter, 1)), 1);
    maxY = min(floor(freqEnd * size(filter, 1)), size(filter, 1));


    % Ensure values adhere to 1 indexing
    minY = max(minY, 1);
    minX = max(minX, 1);
    % Ensure cutoff max values are not above size of the array
    maxY = min(maxY, size(s, 1));
    maxX = min(maxX, size(s, 2));

    
    % Create the filter
    filter(minY:maxY, minX:maxX) = 1;


    % Invert if stop is true
    if stop
        filter = abs(filter - 1);
    end

    % Mirror filter to make it apply to whole stft
    filter = [filter(end:-1:1,:); filter];
end