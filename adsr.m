function env = adsr(attack, decay, sustain, release, length, maxVol, minVol)
    % Creates an adsr envelope with the given parameters.
    % More details here: https://www.wikiaudio.org/adsr-envelope/
    % Arguments:
    %   attack: Normalised time of attack
    %   decay: Normalised time of decay
    %   sustain: Volume to sustain after decay
    %   release: Normalised time to release after sustain
    %   length: The length of envelope to produce
    %   maxVol: The maximum volume produced by the envelope
    %   minVol: The Minimum volume produced by the envelope

    % Argument validation
    if attack + decay + release > 1
        error("Sum of attack, decay, and release cannot be more than 1");
    end
    if nargin < 7
        minVol = 0;
        if nargin < 6
            maxVol = 1;
        end
    end
    if minVol > maxVol
        error("Minimum volume cannot be greater than maximum volume");
    end
    if minVol > 1 || minVol < 0 || maxVol > 1 || maxVol < 0
        error("Volume values must be between 0 and 1");
    end
    if sustain > 1 || sustain < 0
        error("Sustain must be between 0 and 1");
    end
    
    env = zeros(length, 1);
    
    % Create attack portion of envelope
    attackStart = 1;
    attackEnd = max(floor(attack * length), 1);
    if attackEnd > attackStart
        env(attackStart:attackEnd) = 0:1/(attackEnd-attackStart):1;
    end
    
    % Create decay portion of envelope
    decayEnd = attackEnd + floor(decay * length);
    if decay > 0
        if sustain == 1
            env(attackEnd:decayEnd) = 1;
        else
            env(attackEnd:decayEnd) = 1:-(1-sustain)/(decayEnd-attackEnd):sustain;
        end
    end
    
    % Create release portion of envelope
    release = release * length;
    releaseStart = length-release;
    if release ~= 0
        env(releaseStart:length) = sustain:-sustain/(length-releaseStart):0;
    end
    
    % Create sustain portion of envelope
    env(decayEnd:releaseStart) = sustain;

    % Apply min and max volume
    env = env * (maxVol - minVol);
    env = env + minVol;
end