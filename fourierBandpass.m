function filter = fourierBandpass(N, lowFreq, highFreq, stop)
    % Generate a bandpass filter for use in fourier space
    % The filters created by this function are very basic at the moment
    % The filters feature no damping at either end (similar to top hat function)
    % Arguments:
    %   N: The length of the fourier transform to generate the filter for.
    %   lowFreq: Normalised frequency for lower band.
    %   highFreq: Normalised frequency for upper band.
    %   stop: Logical value, if provided will genreate a bandstop filter.
    
    if nargin < 4
        stop = false;
    end

    % Argument checking
    if nargin < 3
        error("Invaid arguments: N, lowFreq, and highFreq are required arguments!");
    end

    if lowFreq > highFreq
        error("Invalid arguments: lowFreq must be lower than highFreq");
    end

    if lowFreq < 0
        error("Invalid arguments: lowFreq must be >= 0")
    end

    if highFreq > 1
        error("Invalid arguments: highFreq must be <= 1")
    end

    % Initalise filter with all zeros
    filter = zeros(N, 1);

    % Calculate cutoff points
    lowCutoff = ceil(max(lowFreq * N, 1));
    highCutoff = floor(highFreq * N);

    % Set area within cutoff area to 1
    filter(lowCutoff:highCutoff) = 1;
    
    % Invert the filter if bandstop requested
    if stop
        mask = filter == 0;
        filter(mask) = 1;
        filter(~mask) = 0;
    end
end