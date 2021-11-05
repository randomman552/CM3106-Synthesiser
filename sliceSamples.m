function result = sliceSamples(sample, start, stop)
    % cutSamples(sample, start, stop)
    % Slice the given audio sample at the given points.
    % Required arguments:
    %   sample: The sampe to cut into
    %   start: The index to start at (must be greater than 1).
    %   stop: The index to stop at (must be greater than start).
    
    if start < 1
        error("Invalid arguments: Start must be greater than 1");
    end

    if stop < start
        error("Invalid arguments: Stop must be greater than start!");
    end

    mask = zeros(size(sample));
    mask(start:stop) = 1;
    result = sample .* mask;
end