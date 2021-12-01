classdef Synthesiser < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        FileMenu                      matlab.ui.container.Menu
        ImportMenu                    matlab.ui.container.Menu
        ExportMenu                    matlab.ui.container.Menu
        ClearMenu                     matlab.ui.container.Menu
        EditMenu                      matlab.ui.container.Menu
        ClearSpectrogramMenu          matlab.ui.container.Menu
        PlaybackMenu                  matlab.ui.container.Menu
        PlayMenu                      matlab.ui.container.Menu
        StopMenu                      matlab.ui.container.Menu
        GridLayout                    matlab.ui.container.GridLayout
        GridLayout4                   matlab.ui.container.GridLayout
        PlayButton                    matlab.ui.control.Button
        StopButton                    matlab.ui.control.Button
        TabGroup2                     matlab.ui.container.TabGroup
        PlaybackTab                   matlab.ui.container.Tab
        GridLayout2                   matlab.ui.container.GridLayout
        PlaybackResetButton           matlab.ui.control.Button
        PostAmpKnob                   matlab.ui.control.Knob
        PostAmpKnobLabel              matlab.ui.control.Label
        TempoKnob                     matlab.ui.control.Knob
        TempoKnobLabel                matlab.ui.control.Label
        PitchKnob                     matlab.ui.control.Knob
        PitchKnobLabel                matlab.ui.control.Label
        ConvolutionTab                matlab.ui.container.Tab
        GridLayout3                   matlab.ui.container.GridLayout
        LoadSampleButton              matlab.ui.control.Button
        ClearSampleButton             matlab.ui.control.Button
        EnableConvolutionButton       matlab.ui.control.StateButton
        ConvolutionWaveformAxes       matlab.ui.control.UIAxes
        VolumeShapingTab              matlab.ui.container.Tab
        GridLayout5                   matlab.ui.container.GridLayout
        EnvelopeResetButton           matlab.ui.control.Button
        EnvelopeMinVolumeSpinner      matlab.ui.control.Spinner
        MinVolumeSpinnerLabel         matlab.ui.control.Label
        EnvelopeMaxVolumeSpinner      matlab.ui.control.Spinner
        MaxVolumeSpinnerLabel         matlab.ui.control.Label
        EnvelopeReleaseSpinner        matlab.ui.control.Spinner
        ReleaseSpinnerLabel           matlab.ui.control.Label
        EnvelopeSustainSpinner        matlab.ui.control.Spinner
        SustainSpinnerLabel           matlab.ui.control.Label
        EnvelopeDecaySpinner          matlab.ui.control.Spinner
        DecaySpinnerLabel             matlab.ui.control.Label
        EnvelopeAttackSpinner         matlab.ui.control.Spinner
        AttackSpinnerLabel            matlab.ui.control.Label
        EnvelopeEnableButton          matlab.ui.control.StateButton
        VolumeShapingAxes             matlab.ui.control.UIAxes
        EqualiserTab                  matlab.ui.container.Tab
        EqualiserGridLayout           matlab.ui.container.GridLayout
        EqualiserResetButton          matlab.ui.control.Button
        EqSlider16k                   matlab.ui.control.Slider
        Label_10                      matlab.ui.control.Label
        EqSlider8k                    matlab.ui.control.Slider
        Label_9                       matlab.ui.control.Label
        EqSlider4k                    matlab.ui.control.Slider
        Label_8                       matlab.ui.control.Label
        EqSlider2k                    matlab.ui.control.Slider
        Label_7                       matlab.ui.control.Label
        EqSlider1k                    matlab.ui.control.Slider
        Label_6                       matlab.ui.control.Label
        EqSlider512                   matlab.ui.control.Slider
        Label_5                       matlab.ui.control.Label
        EqSlider256                   matlab.ui.control.Slider
        Label_4                       matlab.ui.control.Label
        EqSlider128                   matlab.ui.control.Slider
        Label_3                       matlab.ui.control.Label
        EqSlider64                    matlab.ui.control.Slider
        Label_2                       matlab.ui.control.Label
        EqSlider32                    matlab.ui.control.Slider
        Label                         matlab.ui.control.Label
        TabGroup                      matlab.ui.container.TabGroup
        SpectrogramTab                matlab.ui.container.Tab
        SpectrogramContainer          matlab.ui.container.GridLayout
        SpectrogramAxes               matlab.ui.control.UIAxes
        MagnitudeTab                  matlab.ui.container.Tab
        MagnitudeContainer            matlab.ui.container.GridLayout
        MagnitudeAxes                 matlab.ui.control.UIAxes
        WaveformTab                   matlab.ui.container.Tab
        WaveformContainer             matlab.ui.container.GridLayout
        WaveformAxes                  matlab.ui.control.UIAxes
        SpectrogramContextMenu        matlab.ui.container.ContextMenu
        SpectrogramContextMenuClear   matlab.ui.container.Menu
        SpectrogramContextMenuReDraw  matlab.ui.container.Menu
        GraphContextMenu              matlab.ui.container.ContextMenu
        GraphContextMenuReDraw        matlab.ui.container.Menu
    end

    
    properties (Access = private)
        sample % The sample loaded from file for the synthesiser.
        sampleFft % The fourier transform of the loaded sample.
        sampleStft % The stft of the loaded sample
        sampleRate % The sample rate of the currently loaded audio sample.
        sampleName = "None" % The name of the file being used as a sample.
        sampleSpectrogram % The spectrogram image of the imported sample.

        convSample % The sample loaded for convolution
        convSampleRate % The sample rate of the convolution sample
        convSampleName = "None" % Name of the convolution sample file

        resultantAudio = [] % The audio sample produced by app.processAudio (cache)
     
        audioPlayer % The current audio player object in use.

        focusedGraph = "spectrogram" % The currently focused plot. This is the plot that will be updated when the data is changed.
        
        shapePoint1 % The first point of the shape currently being drawn.
        shapes % Array of subtractive shapes drawn on the spectrogram.
        shapeColor = "white" % The color of the shapes when drawn on the spectrogram.

        eqBands = [
            [32,0]
            [64,0]
            [128,0]
            [256,0]
            [512,0]
            [1024,0]
            [2048,0]
            [4096,0]
            [8192,0]
            [16384,0]
        ] % Matrix of equaliser settings. Each vector contained specifies a frequency and an attenuation amount.

        pitch = 1 % The pitch shift to apply
        tempo = 1 % The tempo shift to apply
        postAmp = 1 % The post amplification to apply after all effects are applied
        applyConv = true % Whether to apply convolution or not
        
        envelopeEnable = true;
        envelopeAttack = 0;
        envelopeDecay = 0;
        envelopeSustain = 1;
        envelopeRelease = 0;
        envelopeMaxVol = 1;
        envelopeMinVol = 0;
    end
    
    methods (Access = private)
        % --== Audio file interaction methods ==-- %
        % Method to import an audio sample
        function [y, Fs, file] = importAudio(~)
            [file, path] = uigetfile( ...
                    ["*.mp3;*.flac;*.m4a;*.mp4;*.oga;*.ogg;*.wav", ...
                    "Audio Files"] ...
            );

            y = [];
            Fs = 0;
            
            % Check user selected a path/file
            if path ~= 0
                % Load the audio
                fullPath = append(path, file);
                [y, Fs] = audioread(fullPath);
                
                % Convert to mono by averaging both channels
                if size(y, 2) > 1
                    y = (y(:, 1) + y(:, 2)) / 2;
                end
            end
        end
        
        % Import audio sample and place it into app.sample variables
        function [y, Fs] = importAudioSample(app)
            [y, Fs, file] = app.importAudio();
            
            if isempty(y)
                return;
            end

            app.sample = y;
            app.sampleRate = Fs;
            app.sampleName = file;
            app.sampleFft = fft(app.sample);
            app.sampleStft = stft(app.sample);
            [app.sampleSpectrogram, ~, ~] = spectrogram(app.sample, 100);
            
            % Update audio
            app.processAudio();
        end
        
        % Import audio sample and place it into convolution variables
        function [y, Fs] = importConvSample(app)
            [y, Fs, file] = app.importAudio();

            if isempty(y)
                return;
            end

            app.convSample = y;
            app.convSampleRate = Fs;
            app.convSampleName = file;
            
            app.plotConvGraphs();

            % Update audio
            app.processAudio();
        end
        
        % Method to export the audio resulting from the synthesiser changes
        function fullPath = exportAudio(app)
            [file, path] = uiputfile(["*.flac;*.oga;*.ogg;*.wav", "Audio files"]);

            if path ~= 0
                fullPath = append(path, file);
                audiowrite(fullPath, app.processAudio, app.sampleRate);
            end
        end
        
        % Method to clear the current audio sample from storage
        function clearAudio(app)
            app.sample = [];
            app.sampleFft = [];
            app.sampleStft = [];
            app.sampleSpectrogram = [];
            app.sampleRate = 0;
            app.sampleName = "None";

            app.audioPlayer = {};

            % Update audio
            app.processAudio();
        end

        % Method to clear the current convolution audio sample
        function clearConvSample(app)
            app.convSample = [];
            app.convSampleRate = 0;
            app.convSampleName = "None";

            app.clearConvGraphs();
            app.plotConvGraphs();
            
            % Update audio
            app.processAudio();
        end
        

        % --== Plotting methods ==-- %
        % Method to plot the spectrogram and assocated shapes
        function plotSpectrogram(app)
            axes = app.SpectrogramAxes;
            title(axes, "Spectrogram - " + app.sampleName);

            if app.focusedGraph == "spectrogram" && ~isempty(app.sample)
                N = length(app.resultantAudio);
                Fs = app.sampleRate;
                S = app.sampleSpectrogram;
                
                % Array of timestamps for each sample
                time = (0:N-1)/Fs;
    
                cla(axes);
    
                imagesc(axes, [0, max(time)], [0, 1], log(abs(S)), "HitTest", "off");
                set(axes, "YDir", "normal")
                xlim(axes, [0, max(time)]);
                ylim(axes, [0, 1]);
    
                % Plot shapes
                hold(axes, "on");
                for i = 1:size(app.shapes, 1)
                    points = app.shapes(i, :);
                    pgon = polyshape(points(1:2:end), points(2:2:end));
                    
                    plot( ...
                        axes, pgon, ...
                        "FaceColor", app.shapeColor, ...
                        "LineStyle", "none", ...
                        "FaceAlpha", 0.5, ...
                        "EdgeAlpha", 1, ...
                        "HitTest", "off" ...
                    );
    
                end
                hold(axes, "off");
            end
        end
        
        % Method to plot the waveform
        function plotWaveform(app)
            axes = app.WaveformAxes;
            title(axes, "Waveform - " + app.sampleName);

            % Function to plot original value
            function plotOriginal()
                plot(axes, time, y, ...
                    "Color", "#0072BD", ...
                    "HitTest", "off" ...
                );
            end

            % Function to plot processed value
            function plotAltered()
                plot(axes, time2, y2, ...
                    "Color", "#77AC30", ...
                    "HitTest", "off" ...
                );
            end

            if app.focusedGraph == "waveform" && ~isempty(app.sample)
                % Get data from before and after transforming
                y = app.sample;
                y2 = app.resultantAudio;
                N = length(y);
                N2 = length(y2);
                Fs = app.sampleRate;
                
                % Array of timestamps for each sample
                time = (0:N-1)/Fs;
                time2 = (0:N2-1)/Fs;

                % Prepare axes
                cla(axes);
                hold(axes, "on");
                
                % Ensure the sample with the highest peak is drawn behind
                % This makes the grpah easier to read.
                if max(y) > max(y2)
                    plotOriginal();
                    plotAltered();
                    legend(axes, "Original", "Altered");
                else
                    plotAltered();
                    plotOriginal();
                    legend(axes, "Altered", "Original");
                end
                

                hold(axes, "off");

                xlim(axes, [0, max([time, time2])]);
                ylim(axes, [-1, 1]);
            end
        end
        
        % Method to plot the magnitude spectrum
        function plotMagnitude(app)
            axes = app.MagnitudeAxes;
            title(axes, "Magnitude Spectrum - " + app.sampleName);
            
            % Function to plot the original magnitude spectrum
            function plotOriginal()
                plot(axes, freqs, shifted, ...
                    "Color", "#0072BD", ...
                    "HitTest", "off" ...
                );
            end
            
            % Function to plot the altered magnitude spectrum
            function plotAltered()
                % Plot processed value
                plot(axes, freqs2, shifted2, ...
                    "Color", "#77AC30", ...
                    "HitTest", "off" ...
                );
            end
            
            if app.focusedGraph == "magnitude" && ~isempty(app.sample)
                % Get data from before and after transforming
                y = app.sample;
                y2 = app.resultantAudio;
                N = length(y);
                N2 = length(y2);
                Fs = app.sampleRate;
                
                cla(axes);

                shifted = fftshift(abs(app.sampleFft/N));
                shifted2 = fftshift(abs(fft(y2)/N));
                freqs = ((-N/2:N/2-1)/N)*Fs;
                freqs2 = ((-N2/2:N2/2-1)/N2)*Fs;

                hold(axes, "on");

                % Ensure the sample with the highest peak is drawn behind
                % This makes the grpah easier to read.
                if max(y) > max(y2)
                    plotOriginal();
                    plotAltered();
                    legend(axes, "Original", "Altered");
                else
                    plotAltered();
                    plotOriginal();
                    legend(axes, "Altered", "Original");
                end
                   
                hold(axes, "off");

                xlim(axes, [min(freqs), max(freqs)]);
            end
        end

        % Method to plot the currently focussed graph
        function plotGraphs(app)
            app.plotSpectrogram();
            app.plotWaveform();
            app.plotMagnitude();
        end

        % Method to clear all graphs
        function clearGraphs(app)
            cla(app.SpectrogramAxes);
            cla(app.MagnitudeAxes);
            cla(app.WaveformAxes);
        end

        
        % --== Convolution plotting methods ==-- %
        % Method to plot the convolution waveform
        function plotConvWaveform(app)
            axes = app.ConvolutionWaveformAxes;
            title(axes, "Waveform - " + app.convSampleName);

            if ~isempty(app.convSample)
                y = app.convSample;
                Fs = app.convSampleRate;
                N = length(y);
                time = (0:N-1)/Fs;
    
                cla(axes);
                plot(axes, time, y);
                ylim(axes, [-1, 1]);
                xlim(axes, [0, max(time)]);
            end
        end
        
        % Method to plot convolution graphs
        function plotConvGraphs(app)
            app.plotConvWaveform();
        end

        % Method to clear convolution graphs
        function clearConvGraphs(app)
            cla(app.ConvolutionWaveformAxes);
        end


        % --== Envelope plotting methods ==-- %
        function plotEnvelope(app)
            axes = app.VolumeShapingAxes;
            if ~isempty(app.resultantAudio)
                dur = length(app.resultantAudio)/app.sampleRate;
            else
                dur = 1;
            end

            attack = app.envelopeAttack;
            decay = app.envelopeDecay;
            sustain = app.envelopeSustain;
            release = app.envelopeRelease;
            maxVol = app.envelopeMaxVol;
            minVol = app.envelopeMinVol;
            
            % Create a small envelope to display to the user
            y = adsr(attack, decay, sustain, release, 1000, maxVol, minVol);
            x = (0:1/999:1) * dur;

            plot(axes, x, y);
            xlim(axes, [0, dur]);
            ylim(axes, [0, 1]);
        end


        % --== Audio playback methods ==-- %
        % Play the current audio generated by app.processAudio
        % If app.audioPlayer is defined, will resume playback
        function playAudio(app)
            % Create a new audio player if one is not already assigned.
            if isempty(app.audioPlayer)
                if isempty(app.resultantAudio)
                    app.processAudio();
                end

                % Create audio player
                y = app.resultantAudio;
                Fs = app.sampleRate;
                if ~isempty(y)
                    app.audioPlayer = audioplayer(y, Fs);
                    app.audioPlayer.StopFcn = @(~, ~) app.stopAudio();
                end
            end

            if ~isempty(app.audioPlayer)
                resume(app.audioPlayer);
            end
        end
        
        % Stop the currently playing audio
        function stopAudio(app)
            if ~isempty(app.audioPlayer)
                stop(app.audioPlayer);
                app.audioPlayer = {};
            end
        end
        

        % --== Audio processing methods ==-- %
        % Process the audio according to the applications state
        function results = processAudio(app)
            if isempty(app.sampleStft)
                return;
            end
            
            % Invalidate the cache
            app.resultantAudio = [];

            y = app.sample;

            % Apply convolution
            y = app.processAudioConvolution(y);

            % Apply tempo and pitch transformations
            y = app.processAudioPitchTempo(y);

            % Apply envelope
            y = app.processAudioEnvelope(y);

            % Apply equalisation
            app.resultantAudio = y;
            [app.sampleSpectrogram, ~, ~] = spectrogram(y, 100);
            yStft = stft(y);
            yStft = app.processAudioGraphical(yStft);
            yStft = app.processAudioEqualiser(yStft);
            y = real(istft(yStft));
           
            % Finally, apply post amplification
            results = y .* app.postAmp;

            % Store the results in a cache
            app.resultantAudio = results;

            % Update the plots
            app.plotGraphs();
        end
        
        % Process audio using the global equaliser settings
        function yStft = processAudioEqualiser(app, yStft)
            for i = 1:size(app.eqBands,1)
                % For each band in the equaliser
                nyquist = app.sampleRate/2;
                targetFreq = app.eqBands(i, 1);
                attenuation = app.eqBands(i, 2);

                % Get frequencies of the band below and above this one
                lowFreq = app.eqBands(max(i - 1, 1), 1);
                highFreq = app.eqBands(min(i + 1, size(app.eqBands, 1)), 1);

                % Calculate bounds for this frequency band such that no two bands intersect each other
                lowerBound = ((lowFreq + targetFreq) / 2) / nyquist;
                upperBound = ((highFreq + targetFreq) / 2) / nyquist;

                % Set lower bound to 0 if low freq and target freq are identical
                if lowFreq == targetFreq
                    lowerBound = 0;
                end

                % Set upper bound to 1 if high freq and target freq are identical
                if highFreq == targetFreq
                    upperBound = 1;
                end
                
                % Generate each filter
                filter = stftBandpass(yStft, lowerBound, upperBound);
                % Divide by nyquist frequency to normalise bounds
                % We can't multiply by -1 here as it messes up the complex numbers in the fourier transform
                filtered = (yStft .* filter) * abs(attenuation);
                
                if attenuation < 0
                    yStft = yStft - filtered;
                else
                    yStft = yStft + filtered;
                end
            end
        end
        
        % Process audio according to the shapes drawn on the spectrogram.
        function yStft = processAudioGraphical(app, yStft)
            % Dont proceed if no shapes are defined
            if size(app.shapes, 1) < 1
                return
            end
            
            dur = length(app.resultantAudio)/app.sampleRate;
            filter = ones(size(yStft));
            
            % Generate mask to apply to the stft
            for i = 1:size(app.shapes, 1)
                shape = app.shapes(i, :);
                
                % As all shapes are rectangles, generating the filter is
                % fairly trivial.
                % Calculate normalised shape vertex positions
                minX = min(shape(1:2:end))/dur;
                maxX = max(shape(1:2:end))/dur;
                minY = min(shape(2:2:end));
                maxY = max(shape(2:2:end));
                
                % Create a new filter for the given shape and apply it to
                % the existing filter
                filter = filter - stftBandpass(yStft, minY, maxY, minX, maxX);
            end
            % Ensure attenuation is not greater than 1 for created filter
            filter(filter < 1) = 0;

            % Mirror filter to make it apply to whole stft
            yStft = yStft .* filter;
        end

        % Process tempo & pitch according to app.pitch and app.tempo
        % Called after processing the equaliser and graphical spectrogram
        function y = processAudioPitchTempo(app, y)
            if app.tempo ~= 1 || app.pitch ~= 1
                pitch = app.pitch;
                tempo = app.tempo;
                
                % Apply tempo changes (including pitch changes)
                y = pvoc(y, ((2/pitch)/(2*pitch)) * tempo);

                % Resample to apply pitch
                % y = resample(y, round(2/pitch), round(2*pitch));
                y = y(1:(2*pitch)/(2/pitch):end);
            end
        end
      
        % Process convolution step
        function y = processAudioConvolution(app, y)
            if ~isempty(app.sample) && app.applyConv && ~isempty(app.convSample)
                y = conv(app.convSample, y);
                y = y ./ max(y);
            end
        end
        
        % Process volume shaping step (envelope)
        function y = processAudioEnvelope(app, y)
            if app.envelopeEnable
                attack = app.envelopeAttack;
                decay = app.envelopeDecay;
                sustain = app.envelopeSustain;
                release = app.envelopeRelease;
                maxVol = app.envelopeMaxVol;
                minVol = app.envelopeMinVol;
                try
                    envelope = adsr(attack, decay, sustain, release, length(y), maxVol, minVol);
                    y = y .*envelope;
                catch

                end
            end
        end


        % --== Shape interaction methods ==-- %
        % Shapes are used to define what part of the spectrum to subtract
        % from the rest
        function addShape(app, points)
            % Initalise the array if it is empty
            if isempty(app.shapes)
                app.shapes = [];
            end
            
            % Add shape to the shapes array
            app.shapes = [app.shapes; points];
            
            % Update audio
            app.processAudio();
        end
       
        % Delete all currently stored shapes
        function clearShapes(app)
            app.shapes = [];
            app.shapePoint1 = [];

            % Update audio
            app.processAudio();
        end

        
        % --== Global equaliser interaction methods ==-- %
        % Set the global eq bands scalars
        % Takes an index of the band and the scalar to multiply by as
        % arguments
        function setEqBand(app, idx, scalar)
            app.eqBands(idx, 2) = scalar;
            % Clear the audio player whenver we edit eq bands
            app.audioPlayer = {};

            % Update audio
            app.processAudio();
        end
        
        % Reset eqSettings to default values
        function resetEqBands(app)
            app.audioPlayer = {};
            
            app.eqBands = [
                [32,0]
                [64,0]
                [128,0]
                [256,0]
                [512,0]
                [1024,0]
                [2048,0]
                [4096,0]
                [8192,0]
                [16384,0]
            ];
            
            % Reset slider values as well
            app.EqSlider32.Value = 0;
            app.EqSlider64.Value = 0;
            app.EqSlider128.Value = 0;
            app.EqSlider256.Value = 0;
            app.EqSlider512.Value = 0;
            app.EqSlider1k.Value = 0;
            app.EqSlider2k.Value = 0;
            app.EqSlider4k.Value = 0;
            app.EqSlider8k.Value = 0;
            app.EqSlider16k.Value = 0;

            % Update audio
            app.processAudio();
        end
    
    
        % --== Playback settings ==-- %
        % Method for setting post amp volume
        function setPostAmp(app, val)
            app.postAmp = val;

            % Update audio
            app.processAudio();
        end

        % Method for setting pitch value
        function setPitch(app, val)
            app.pitch = val;
            
            % Update audio
            app.processAudio();
        end

        % Method for setting tempo value
        function setTempo(app, val)
            app.tempo = val;

            % Update audio
            app.processAudio();
        end
        
        % Method for changing whether to apply convolution or not
        function setApplyConv(app, val)
            app.applyConv = val;

            % Update audio
            app.processAudio();
        end
    
    
        % --== Envelope interaction methods == -- %
        % Method to set the attack for the volume envelope
        function setEnvelopeAttack(app, val)
            old = app.envelopeAttack;
            app.envelopeAttack = val;
            app.EnvelopeAttackSpinner.Value = val;
            
            % If value change creates an error, set the value to old value
            try
                app.plotEnvelope();
                app.processAudio();
            catch e
                errordlg(e.message, "Envelope generation failed");
                app.setEnvelopeAttack(old);
            end
        end
        
        % Method to set the decay for the volume envelope
        function setEnvelopeDecay(app, val)
            old = app.envelopeDecay;
            app.envelopeDecay = val;
            app.EnvelopeDecaySpinner.Value = val;
            
            % If value change creates an error, set the value to old value
            try
                app.plotEnvelope();
                app.processAudio();
            catch e
                errordlg(e.message, "Envelope generation failed");
                app.setEnvelopeDecay(old);
            end
        end
        
        % Method to set the release for the volume envelope
        function setEnvelopeRelease(app, val)
            old = app.envelopeRelease;
            app.envelopeRelease = val;
            app.EnvelopeReleaseSpinner.Value = val;
            
            % If value change creates an error, set the value to old value
            try
                app.plotEnvelope();
                app.processAudio();
            catch e
                errordlg(e.message, "Envelope generation failed");
                app.setEnvelopeRelease(old);
            end
        end
        
        % Method to set the sustain for the volume envelope
        function setEnvelopeSustain(app, val)
            app.envelopeSustain = val;
            app.EnvelopeSustainSpinner.Value = val;
            app.plotEnvelope();
            app.processAudio();
        end
        
        % Method to set the max volume for the volume envelope
        function setEnvelopeMaxVol(app, val)
            app.envelopeMaxVol = val;

            app.EnvelopeMaxVolumeSpinner.Value = val;
            app.EnvelopeMinVolumeSpinner.Limits = [0, val];

            app.plotEnvelope();
            app.processAudio();
        end
        
        % Method to set the min volume for the volume envelope
        function setEnvelopeMinVol(app, val)
            app.envelopeMinVol = val;

            app.EnvelopeMinVolumeSpinner.Value = val;
            app.EnvelopeMaxVolumeSpinner.Limits = [val, 1];

            app.plotEnvelope();
            app.processAudio();
        end
        
        % Method to enable or disable the volume envelope
        function setEnvelopeEnable(app, val)
            app.envelopeEnable = val;
            app.EnvelopeEnableButton.Value = val;
            app.processAudio();
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Setup spectrogram axes for callback integration
            disableDefaultInteractivity(app.SpectrogramAxes)

            % Setup waveform axes
            disableDefaultInteractivity(app.WaveformAxes);

            % Setup magnitude axes
            disableDefaultInteractivity(app.MagnitudeAxes);

            % Setup convolution waveform axes
            disableDefaultInteractivity(app.ConvolutionWaveformAxes);
            
            % Setup volume shaping axes
            disableDefaultInteractivity(app.VolumeShapingAxes);
            app.plotEnvelope();
        end

        % Menu selected function: ImportMenu
        function ImportMenuSelected(app, event)
            app.importAudioSample();
            app.plotGraphs();
        end

        % Menu selected function: ExportMenu
        function ExportMenuSelected(app, event)
            app.exportAudio();
        end

        % Menu selected function: ClearMenu
        function ClearMenuSelected(app, event)
            app.clearAudio();
            app.clearGraphs();
        end

        % Menu selected function: PlayMenu
        function PlayMenuSelected(app, event)
            app.playAudio();
        end

        % Callback function
        function PauseMenuSelected(app, event)
            app.pauseAudio();
        end

        % Menu selected function: StopMenu
        function StopMenuSelected(app, event)
            app.stopAudio();
        end

        % Button down function: SpectrogramAxes
        function SpectrogramAxesButtonDown(app, event)
            if event.Button == 1
                % If app.shapePoint1 is not empty, we begin a new shape
                if isempty(app.shapePoint1)
                    app.shapePoint1 = event.IntersectionPoint(1:2);
                else
                    % Generate rectangle edges
                    point1 = app.shapePoint1;
                    point2 = event.IntersectionPoint(1:2);
                    points = [
                        point1(1), point1(2)...
                        point1(1), point2(2)...
                        point2(1), point2(2)...
                        point2(1), point1(2)...
                    ];
                    app.addShape(points);
                    app.shapePoint1 = [];
                end
            end
        end

        % Value changed function: EqSlider32
        function EqSlider32ValueChanged(app, event)
            value = app.EqSlider32.Value;
            app.setEqBand(1, value);
        end

        % Value changed function: EqSlider64
        function EqSlider64ValueChanged(app, event)
            value = app.EqSlider64.Value;
            app.setEqBand(2, value);
        end

        % Value changed function: EqSlider128
        function EqSlider128ValueChanged(app, event)
            value = app.EqSlider128.Value;
            app.setEqBand(3, value);
        end

        % Value changed function: EqSlider256
        function EqSlider256ValueChanged(app, event)
            value = app.EqSlider256.Value;
            app.setEqBand(4, value);
        end

        % Value changed function: EqSlider512
        function EqSlider512ValueChanged(app, event)
            value = app.EqSlider512.Value;
            app.setEqBand(5, value);
        end

        % Value changed function: EqSlider1k
        function EqSlider1kValueChanged(app, event)
            value = app.EqSlider1k.Value;
            app.setEqBand(6, value);
        end

        % Value changed function: EqSlider2k
        function EqSlider2kValueChanged(app, event)
            value = app.EqSlider2k.Value;
            app.setEqBand(7, value);
        end

        % Value changed function: EqSlider4k
        function EqSlider4kValueChanged(app, event)
            value = app.EqSlider4k.Value;
            app.setEqBand(8, value);
        end

        % Value changed function: EqSlider8k
        function EqSlider8kValueChanged(app, event)
            value = app.EqSlider8k.Value;
            app.setEqBand(9, value);
        end

        % Value changed function: EqSlider16k
        function EqSlider16kValueChanged(app, event)
            value = app.EqSlider16k.Value;
            app.setEqBand(10, value);
        end

        % Button pushed function: EqualiserResetButton
        function EqualiserResetButtonPushed(app, event)
            app.resetEqBands();
        end

        % Button pushed function: PlayButton
        function PlayButtonPushed(app, event)
            app.playAudio();
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            app.stopAudio();
        end

        % Button pushed function: PlaybackResetButton
        function PlaybackResetButtonPushed(app, event)
            app.setPitch(1);
            app.setTempo(1);
            app.setPostAmp(1);

            app.PitchKnob.Value = app.pitch;
            app.TempoKnob.Value = app.tempo;
            app.PostAmpKnob.Value = app.postAmp;

            % Draw graphs as audio sample has changed
            app.plotGraphs();
        end

        % Value changed function: PitchKnob
        function PitchKnobValueChanged(app, event)
            value = app.PitchKnob.Value;
            app.setPitch(value);
        end

        % Value changed function: TempoKnob
        function TempoKnobValueChanged(app, event)
            value = app.TempoKnob.Value;
            app.setTempo(value);
        end

        % Value changed function: PostAmpKnob
        function PostAmpKnobValueChanged(app, event)
            value = app.PostAmpKnob.Value;
            app.setPostAmp(value);
        end

        % Menu selected function: ClearSpectrogramMenu
        function ClearSpectrogramMenuSelected(app, event)
            app.clearShapes();
        end

        % Button down function: SpectrogramTab
        function SpectrogramTabButtonDown(app, event)
            app.focusedGraph = "spectrogram";
            app.plotSpectrogram();
        end

        % Button down function: MagnitudeTab
        function MagnitudeTabButtonDown(app, event)
            app.focusedGraph = "magnitude";
            app.plotMagnitude();
        end

        % Button down function: WaveformTab
        function WaveformTabButtonDown(app, event)
            app.focusedGraph = "waveform";
            app.plotWaveform();
        end

        % Menu selected function: SpectrogramContextMenuClear
        function SpectrogramContextMenuClearSelected(app, event)
            app.clearShapes();
        end

        % Menu selected function: SpectrogramContextMenuReDraw
        function SpectrogramContextMenuReDrawSelected(app, event)
            app.plotGraphs();
        end

        % Menu selected function: GraphContextMenuReDraw
        function GraphContextMenuReDrawSelected(app, event)
            app.plotGraphs();
        end

        % Button pushed function: LoadSampleButton
        function LoadSampleButtonPushed(app, event)
            app.importConvSample();
            app.plotGraphs();
        end

        % Button pushed function: ClearSampleButton
        function ClearSampleButtonPushed(app, event)
            app.clearConvSample();
        end

        % Value changed function: EnableConvolutionButton
        function EnableConvolutionButtonValueChanged(app, event)
            value = app.EnableConvolutionButton.Value;
            app.setApplyConv(value);
        end

        % Value changed function: EnvelopeAttackSpinner
        function EnvelopeAttackSpinnerValueChanged(app, event)
            value = app.EnvelopeAttackSpinner.Value;
            app.setEnvelopeAttack(value);
        end

        % Value changed function: EnvelopeDecaySpinner
        function EnvelopeDecaySpinnerValueChanged(app, event)
            value = app.EnvelopeDecaySpinner.Value;
            app.setEnvelopeDecay(value);
        end

        % Value changed function: EnvelopeSustainSpinner
        function EnvelopeSustainSpinnerValueChanged(app, event)
            value = app.EnvelopeSustainSpinner.Value;
            app.setEnvelopeSustain(value);
        end

        % Value changed function: EnvelopeReleaseSpinner
        function EnvelopeReleaseSpinnerValueChanged(app, event)
            value = app.EnvelopeReleaseSpinner.Value;
            app.setEnvelopeRelease(value);
        end

        % Value changed function: EnvelopeMaxVolumeSpinner
        function EnvelopeMaxVolumeSpinnerValueChanged(app, event)
            value = app.EnvelopeMaxVolumeSpinner.Value;
            app.setEnvelopeMaxVol(value);
        end

        % Value changed function: EnvelopeMinVolumeSpinner
        function EnvelopeMinVolumeSpinnerValueChanged(app, event)
            value = app.EnvelopeMinVolumeSpinner.Value;
            app.setEnvelopeMinVol(value);
        end

        % Value changed function: EnvelopeEnableButton
        function EnvelopeEnableButtonValueChanged(app, event)
            value = app.EnvelopeEnableButton.Value;
            app.setEnvelopeEnable(value);
        end

        % Button pushed function: EnvelopeResetButton
        function EnvelopeResetButtonPushed(app, event)
            app.setEnvelopeAttack(0);
            app.setEnvelopeDecay(0);
            app.setEnvelopeSustain(1);
            app.setEnvelopeRelease(0);
            app.setEnvelopeMaxVol(1);
            app.setEnvelopeMinVol(0);
            app.setEnvelopeEnable(true);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1150 815];
            app.UIFigure.Name = 'MATLAB App';

            % Create FileMenu
            app.FileMenu = uimenu(app.UIFigure);
            app.FileMenu.Text = 'File';

            % Create ImportMenu
            app.ImportMenu = uimenu(app.FileMenu);
            app.ImportMenu.MenuSelectedFcn = createCallbackFcn(app, @ImportMenuSelected, true);
            app.ImportMenu.Separator = 'on';
            app.ImportMenu.Accelerator = 'o';
            app.ImportMenu.Text = 'Import';

            % Create ExportMenu
            app.ExportMenu = uimenu(app.FileMenu);
            app.ExportMenu.MenuSelectedFcn = createCallbackFcn(app, @ExportMenuSelected, true);
            app.ExportMenu.Accelerator = 's';
            app.ExportMenu.Text = 'Export';

            % Create ClearMenu
            app.ClearMenu = uimenu(app.FileMenu);
            app.ClearMenu.MenuSelectedFcn = createCallbackFcn(app, @ClearMenuSelected, true);
            app.ClearMenu.Separator = 'on';
            app.ClearMenu.Accelerator = 'c';
            app.ClearMenu.Text = 'Clear';

            % Create EditMenu
            app.EditMenu = uimenu(app.UIFigure);
            app.EditMenu.Text = 'Edit';

            % Create ClearSpectrogramMenu
            app.ClearSpectrogramMenu = uimenu(app.EditMenu);
            app.ClearSpectrogramMenu.MenuSelectedFcn = createCallbackFcn(app, @ClearSpectrogramMenuSelected, true);
            app.ClearSpectrogramMenu.Text = 'Clear Spectrogram';

            % Create PlaybackMenu
            app.PlaybackMenu = uimenu(app.UIFigure);
            app.PlaybackMenu.Text = 'Playback';

            % Create PlayMenu
            app.PlayMenu = uimenu(app.PlaybackMenu);
            app.PlayMenu.MenuSelectedFcn = createCallbackFcn(app, @PlayMenuSelected, true);
            app.PlayMenu.Accelerator = 'e';
            app.PlayMenu.Text = 'Play';

            % Create StopMenu
            app.StopMenu = uimenu(app.PlaybackMenu);
            app.StopMenu.MenuSelectedFcn = createCallbackFcn(app, @StopMenuSelected, true);
            app.StopMenu.Accelerator = 'r';
            app.StopMenu.Text = 'Stop';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'9x', '1x'};
            app.GridLayout.RowHeight = {'5x', '4x'};
            app.GridLayout.ColumnSpacing = 5;
            app.GridLayout.RowSpacing = 5;

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = [1 2];

            % Create SpectrogramTab
            app.SpectrogramTab = uitab(app.TabGroup);
            app.SpectrogramTab.Title = 'Spectrogram';
            app.SpectrogramTab.ButtonDownFcn = createCallbackFcn(app, @SpectrogramTabButtonDown, true);

            % Create SpectrogramContainer
            app.SpectrogramContainer = uigridlayout(app.SpectrogramTab);
            app.SpectrogramContainer.ColumnWidth = {'1x'};
            app.SpectrogramContainer.RowHeight = {'1x'};
            app.SpectrogramContainer.Padding = [0 0 0 0];

            % Create SpectrogramAxes
            app.SpectrogramAxes = uiaxes(app.SpectrogramContainer);
            title(app.SpectrogramAxes, 'Spectrogram - None')
            xlabel(app.SpectrogramAxes, 'Time (s)')
            ylabel(app.SpectrogramAxes, 'Normalised Frequency')
            app.SpectrogramAxes.Toolbar.Visible = 'off';
            app.SpectrogramAxes.Layout.Row = 1;
            app.SpectrogramAxes.Layout.Column = 1;
            app.SpectrogramAxes.ButtonDownFcn = createCallbackFcn(app, @SpectrogramAxesButtonDown, true);

            % Create MagnitudeTab
            app.MagnitudeTab = uitab(app.TabGroup);
            app.MagnitudeTab.Title = 'Magnitude';
            app.MagnitudeTab.ButtonDownFcn = createCallbackFcn(app, @MagnitudeTabButtonDown, true);

            % Create MagnitudeContainer
            app.MagnitudeContainer = uigridlayout(app.MagnitudeTab);
            app.MagnitudeContainer.ColumnWidth = {'1x'};
            app.MagnitudeContainer.RowHeight = {'1x'};
            app.MagnitudeContainer.Padding = [0 0 0 0];

            % Create MagnitudeAxes
            app.MagnitudeAxes = uiaxes(app.MagnitudeContainer);
            title(app.MagnitudeAxes, 'Magnitude Spectrum - None')
            xlabel(app.MagnitudeAxes, 'Frequency (Hz)')
            ylabel(app.MagnitudeAxes, 'Magnitude')
            zlabel(app.MagnitudeAxes, 'Z')
            app.MagnitudeAxes.Layout.Row = 1;
            app.MagnitudeAxes.Layout.Column = 1;

            % Create WaveformTab
            app.WaveformTab = uitab(app.TabGroup);
            app.WaveformTab.Title = 'Waveform';
            app.WaveformTab.ButtonDownFcn = createCallbackFcn(app, @WaveformTabButtonDown, true);

            % Create WaveformContainer
            app.WaveformContainer = uigridlayout(app.WaveformTab);
            app.WaveformContainer.ColumnWidth = {'1x'};
            app.WaveformContainer.RowHeight = {'1x'};
            app.WaveformContainer.Padding = [0 0 0 0];

            % Create WaveformAxes
            app.WaveformAxes = uiaxes(app.WaveformContainer);
            title(app.WaveformAxes, 'Waveform - None')
            xlabel(app.WaveformAxes, 'Time (s)')
            ylabel(app.WaveformAxes, 'Magnitude')
            app.WaveformAxes.Layout.Row = 1;
            app.WaveformAxes.Layout.Column = 1;

            % Create TabGroup2
            app.TabGroup2 = uitabgroup(app.GridLayout);
            app.TabGroup2.Layout.Row = 2;
            app.TabGroup2.Layout.Column = 1;

            % Create PlaybackTab
            app.PlaybackTab = uitab(app.TabGroup2);
            app.PlaybackTab.Title = 'Playback';

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.PlaybackTab);
            app.GridLayout2.ColumnWidth = {'1x', '1x', '1x', '0.3x'};
            app.GridLayout2.RowHeight = {'1x', '1x', '1x'};
            app.GridLayout2.Padding = [5 5 5 5];

            % Create PitchKnobLabel
            app.PitchKnobLabel = uilabel(app.GridLayout2);
            app.PitchKnobLabel.HorizontalAlignment = 'center';
            app.PitchKnobLabel.Layout.Row = 3;
            app.PitchKnobLabel.Layout.Column = 1;
            app.PitchKnobLabel.Text = 'Pitch';

            % Create PitchKnob
            app.PitchKnob = uiknob(app.GridLayout2, 'continuous');
            app.PitchKnob.Limits = [0.5 1.5];
            app.PitchKnob.MajorTicks = [0.5 1 1.5];
            app.PitchKnob.MajorTickLabels = {''};
            app.PitchKnob.ValueChangedFcn = createCallbackFcn(app, @PitchKnobValueChanged, true);
            app.PitchKnob.MinorTicks = [0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5];
            app.PitchKnob.Layout.Row = [1 2];
            app.PitchKnob.Layout.Column = 1;
            app.PitchKnob.Value = 1;

            % Create TempoKnobLabel
            app.TempoKnobLabel = uilabel(app.GridLayout2);
            app.TempoKnobLabel.HorizontalAlignment = 'center';
            app.TempoKnobLabel.Layout.Row = 3;
            app.TempoKnobLabel.Layout.Column = 2;
            app.TempoKnobLabel.Text = 'Tempo';

            % Create TempoKnob
            app.TempoKnob = uiknob(app.GridLayout2, 'continuous');
            app.TempoKnob.Limits = [0.5 2];
            app.TempoKnob.MajorTicks = [0.5 1 1.5 2];
            app.TempoKnob.MajorTickLabels = {''};
            app.TempoKnob.ValueChangedFcn = createCallbackFcn(app, @TempoKnobValueChanged, true);
            app.TempoKnob.MinorTicks = [0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2];
            app.TempoKnob.Layout.Row = [1 2];
            app.TempoKnob.Layout.Column = 2;
            app.TempoKnob.Value = 1;

            % Create PostAmpKnobLabel
            app.PostAmpKnobLabel = uilabel(app.GridLayout2);
            app.PostAmpKnobLabel.HorizontalAlignment = 'center';
            app.PostAmpKnobLabel.Layout.Row = 3;
            app.PostAmpKnobLabel.Layout.Column = 3;
            app.PostAmpKnobLabel.Text = 'Post-Amp';

            % Create PostAmpKnob
            app.PostAmpKnob = uiknob(app.GridLayout2, 'continuous');
            app.PostAmpKnob.Limits = [0 2];
            app.PostAmpKnob.MajorTicks = [0 1 2];
            app.PostAmpKnob.MajorTickLabels = {''};
            app.PostAmpKnob.ValueChangedFcn = createCallbackFcn(app, @PostAmpKnobValueChanged, true);
            app.PostAmpKnob.MinorTicks = [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2];
            app.PostAmpKnob.Tooltip = {'Amplification applied after processing'};
            app.PostAmpKnob.Layout.Row = [1 2];
            app.PostAmpKnob.Layout.Column = 3;
            app.PostAmpKnob.Value = 1;

            % Create PlaybackResetButton
            app.PlaybackResetButton = uibutton(app.GridLayout2, 'push');
            app.PlaybackResetButton.ButtonPushedFcn = createCallbackFcn(app, @PlaybackResetButtonPushed, true);
            app.PlaybackResetButton.Tooltip = {'Reset playback panel'};
            app.PlaybackResetButton.Layout.Row = [1 3];
            app.PlaybackResetButton.Layout.Column = 4;
            app.PlaybackResetButton.Text = 'Reset';

            % Create ConvolutionTab
            app.ConvolutionTab = uitab(app.TabGroup2);
            app.ConvolutionTab.Title = 'Convolution';

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.ConvolutionTab);
            app.GridLayout3.ColumnWidth = {'9x', 'fit'};
            app.GridLayout3.RowHeight = {'1x', '1x', '1x'};
            app.GridLayout3.Padding = [5 5 5 5];

            % Create ConvolutionWaveformAxes
            app.ConvolutionWaveformAxes = uiaxes(app.GridLayout3);
            title(app.ConvolutionWaveformAxes, 'Waveform - None')
            xlabel(app.ConvolutionWaveformAxes, 'Time (s)')
            ylabel(app.ConvolutionWaveformAxes, 'Magnitude')
            zlabel(app.ConvolutionWaveformAxes, 'Z')
            app.ConvolutionWaveformAxes.Toolbar.Visible = 'off';
            app.ConvolutionWaveformAxes.Layout.Row = [1 3];
            app.ConvolutionWaveformAxes.Layout.Column = 1;

            % Create EnableConvolutionButton
            app.EnableConvolutionButton = uibutton(app.GridLayout3, 'state');
            app.EnableConvolutionButton.ValueChangedFcn = createCallbackFcn(app, @EnableConvolutionButtonValueChanged, true);
            app.EnableConvolutionButton.Tooltip = {'If selected, the current audio sample will be convolved with the loaded convolution sample.'};
            app.EnableConvolutionButton.Text = 'Enable Convolution';
            app.EnableConvolutionButton.Layout.Row = 1;
            app.EnableConvolutionButton.Layout.Column = 2;
            app.EnableConvolutionButton.Value = true;

            % Create ClearSampleButton
            app.ClearSampleButton = uibutton(app.GridLayout3, 'push');
            app.ClearSampleButton.ButtonPushedFcn = createCallbackFcn(app, @ClearSampleButtonPushed, true);
            app.ClearSampleButton.Layout.Row = 3;
            app.ClearSampleButton.Layout.Column = 2;
            app.ClearSampleButton.Text = 'Clear Sample';

            % Create LoadSampleButton
            app.LoadSampleButton = uibutton(app.GridLayout3, 'push');
            app.LoadSampleButton.ButtonPushedFcn = createCallbackFcn(app, @LoadSampleButtonPushed, true);
            app.LoadSampleButton.Layout.Row = 2;
            app.LoadSampleButton.Layout.Column = 2;
            app.LoadSampleButton.Text = 'Load Sample';

            % Create VolumeShapingTab
            app.VolumeShapingTab = uitab(app.TabGroup2);
            app.VolumeShapingTab.Title = 'Volume Shaping';

            % Create GridLayout5
            app.GridLayout5 = uigridlayout(app.VolumeShapingTab);
            app.GridLayout5.ColumnWidth = {'9x', 'fit', 'fit'};
            app.GridLayout5.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.GridLayout5.Padding = [5 5 5 5];

            % Create VolumeShapingAxes
            app.VolumeShapingAxes = uiaxes(app.GridLayout5);
            title(app.VolumeShapingAxes, 'Volume Envelope')
            xlabel(app.VolumeShapingAxes, 'Time (s)')
            ylabel(app.VolumeShapingAxes, 'Amplitude')
            zlabel(app.VolumeShapingAxes, 'Z')
            app.VolumeShapingAxes.Layout.Row = [1 8];
            app.VolumeShapingAxes.Layout.Column = 1;

            % Create EnvelopeEnableButton
            app.EnvelopeEnableButton = uibutton(app.GridLayout5, 'state');
            app.EnvelopeEnableButton.ValueChangedFcn = createCallbackFcn(app, @EnvelopeEnableButtonValueChanged, true);
            app.EnvelopeEnableButton.Text = 'Enable';
            app.EnvelopeEnableButton.Layout.Row = 1;
            app.EnvelopeEnableButton.Layout.Column = [2 3];
            app.EnvelopeEnableButton.Value = true;

            % Create AttackSpinnerLabel
            app.AttackSpinnerLabel = uilabel(app.GridLayout5);
            app.AttackSpinnerLabel.HorizontalAlignment = 'right';
            app.AttackSpinnerLabel.Layout.Row = 3;
            app.AttackSpinnerLabel.Layout.Column = 2;
            app.AttackSpinnerLabel.Text = 'Attack';

            % Create EnvelopeAttackSpinner
            app.EnvelopeAttackSpinner = uispinner(app.GridLayout5);
            app.EnvelopeAttackSpinner.Step = 0.05;
            app.EnvelopeAttackSpinner.Limits = [0 1];
            app.EnvelopeAttackSpinner.ValueChangedFcn = createCallbackFcn(app, @EnvelopeAttackSpinnerValueChanged, true);
            app.EnvelopeAttackSpinner.Tooltip = {'How quickly the sound reaches full volume'};
            app.EnvelopeAttackSpinner.Layout.Row = 3;
            app.EnvelopeAttackSpinner.Layout.Column = 3;

            % Create DecaySpinnerLabel
            app.DecaySpinnerLabel = uilabel(app.GridLayout5);
            app.DecaySpinnerLabel.HorizontalAlignment = 'right';
            app.DecaySpinnerLabel.Layout.Row = 4;
            app.DecaySpinnerLabel.Layout.Column = 2;
            app.DecaySpinnerLabel.Text = 'Decay';

            % Create EnvelopeDecaySpinner
            app.EnvelopeDecaySpinner = uispinner(app.GridLayout5);
            app.EnvelopeDecaySpinner.Step = 0.05;
            app.EnvelopeDecaySpinner.Limits = [0 1];
            app.EnvelopeDecaySpinner.ValueChangedFcn = createCallbackFcn(app, @EnvelopeDecaySpinnerValueChanged, true);
            app.EnvelopeDecaySpinner.Tooltip = {'How quickly sound drops to sustain level after initial peak'};
            app.EnvelopeDecaySpinner.Layout.Row = 4;
            app.EnvelopeDecaySpinner.Layout.Column = 3;

            % Create SustainSpinnerLabel
            app.SustainSpinnerLabel = uilabel(app.GridLayout5);
            app.SustainSpinnerLabel.HorizontalAlignment = 'right';
            app.SustainSpinnerLabel.Layout.Row = 5;
            app.SustainSpinnerLabel.Layout.Column = 2;
            app.SustainSpinnerLabel.Text = 'Sustain';

            % Create EnvelopeSustainSpinner
            app.EnvelopeSustainSpinner = uispinner(app.GridLayout5);
            app.EnvelopeSustainSpinner.Step = 0.05;
            app.EnvelopeSustainSpinner.Limits = [0 1];
            app.EnvelopeSustainSpinner.ValueChangedFcn = createCallbackFcn(app, @EnvelopeSustainSpinnerValueChanged, true);
            app.EnvelopeSustainSpinner.Tooltip = {'Constant volume after decay period'};
            app.EnvelopeSustainSpinner.Layout.Row = 5;
            app.EnvelopeSustainSpinner.Layout.Column = 3;
            app.EnvelopeSustainSpinner.Value = 1;

            % Create ReleaseSpinnerLabel
            app.ReleaseSpinnerLabel = uilabel(app.GridLayout5);
            app.ReleaseSpinnerLabel.HorizontalAlignment = 'right';
            app.ReleaseSpinnerLabel.Layout.Row = 6;
            app.ReleaseSpinnerLabel.Layout.Column = 2;
            app.ReleaseSpinnerLabel.Text = 'Release';

            % Create EnvelopeReleaseSpinner
            app.EnvelopeReleaseSpinner = uispinner(app.GridLayout5);
            app.EnvelopeReleaseSpinner.Step = 0.05;
            app.EnvelopeReleaseSpinner.Limits = [0 1];
            app.EnvelopeReleaseSpinner.ValueChangedFcn = createCallbackFcn(app, @EnvelopeReleaseSpinnerValueChanged, true);
            app.EnvelopeReleaseSpinner.Tooltip = {'How quickly the sound fades'};
            app.EnvelopeReleaseSpinner.Layout.Row = 6;
            app.EnvelopeReleaseSpinner.Layout.Column = 3;

            % Create MaxVolumeSpinnerLabel
            app.MaxVolumeSpinnerLabel = uilabel(app.GridLayout5);
            app.MaxVolumeSpinnerLabel.HorizontalAlignment = 'right';
            app.MaxVolumeSpinnerLabel.Layout.Row = 7;
            app.MaxVolumeSpinnerLabel.Layout.Column = 2;
            app.MaxVolumeSpinnerLabel.Text = 'Max Volume';

            % Create EnvelopeMaxVolumeSpinner
            app.EnvelopeMaxVolumeSpinner = uispinner(app.GridLayout5);
            app.EnvelopeMaxVolumeSpinner.Step = 0.05;
            app.EnvelopeMaxVolumeSpinner.Limits = [0 1];
            app.EnvelopeMaxVolumeSpinner.ValueChangedFcn = createCallbackFcn(app, @EnvelopeMaxVolumeSpinnerValueChanged, true);
            app.EnvelopeMaxVolumeSpinner.Layout.Row = 7;
            app.EnvelopeMaxVolumeSpinner.Layout.Column = 3;
            app.EnvelopeMaxVolumeSpinner.Value = 1;

            % Create MinVolumeSpinnerLabel
            app.MinVolumeSpinnerLabel = uilabel(app.GridLayout5);
            app.MinVolumeSpinnerLabel.HorizontalAlignment = 'right';
            app.MinVolumeSpinnerLabel.Layout.Row = 8;
            app.MinVolumeSpinnerLabel.Layout.Column = 2;
            app.MinVolumeSpinnerLabel.Text = 'Min Volume';

            % Create EnvelopeMinVolumeSpinner
            app.EnvelopeMinVolumeSpinner = uispinner(app.GridLayout5);
            app.EnvelopeMinVolumeSpinner.Step = 0.05;
            app.EnvelopeMinVolumeSpinner.Limits = [0 1];
            app.EnvelopeMinVolumeSpinner.ValueChangedFcn = createCallbackFcn(app, @EnvelopeMinVolumeSpinnerValueChanged, true);
            app.EnvelopeMinVolumeSpinner.Layout.Row = 8;
            app.EnvelopeMinVolumeSpinner.Layout.Column = 3;

            % Create EnvelopeResetButton
            app.EnvelopeResetButton = uibutton(app.GridLayout5, 'push');
            app.EnvelopeResetButton.ButtonPushedFcn = createCallbackFcn(app, @EnvelopeResetButtonPushed, true);
            app.EnvelopeResetButton.Layout.Row = 2;
            app.EnvelopeResetButton.Layout.Column = [2 3];
            app.EnvelopeResetButton.Text = 'Reset';

            % Create EqualiserTab
            app.EqualiserTab = uitab(app.TabGroup2);
            app.EqualiserTab.Title = 'Equaliser';

            % Create EqualiserGridLayout
            app.EqualiserGridLayout = uigridlayout(app.EqualiserTab);
            app.EqualiserGridLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.EqualiserGridLayout.RowHeight = {'9x', '1x'};
            app.EqualiserGridLayout.ColumnSpacing = 5;
            app.EqualiserGridLayout.RowSpacing = 5;
            app.EqualiserGridLayout.Padding = [5 5 5 5];

            % Create Label
            app.Label = uilabel(app.EqualiserGridLayout);
            app.Label.HorizontalAlignment = 'center';
            app.Label.Layout.Row = 2;
            app.Label.Layout.Column = 1;
            app.Label.Text = '32 Hz';

            % Create EqSlider32
            app.EqSlider32 = uislider(app.EqualiserGridLayout);
            app.EqSlider32.Limits = [-1 1];
            app.EqSlider32.MajorTicks = [-1 0 1];
            app.EqSlider32.MajorTickLabels = {''};
            app.EqSlider32.Orientation = 'vertical';
            app.EqSlider32.ValueChangedFcn = createCallbackFcn(app, @EqSlider32ValueChanged, true);
            app.EqSlider32.MinorTicks = [-1 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];
            app.EqSlider32.Layout.Row = 1;
            app.EqSlider32.Layout.Column = 1;

            % Create Label_2
            app.Label_2 = uilabel(app.EqualiserGridLayout);
            app.Label_2.HorizontalAlignment = 'center';
            app.Label_2.Layout.Row = 2;
            app.Label_2.Layout.Column = 2;
            app.Label_2.Text = '64 Hz';

            % Create EqSlider64
            app.EqSlider64 = uislider(app.EqualiserGridLayout);
            app.EqSlider64.Limits = [-1 1];
            app.EqSlider64.MajorTicks = [-1 0 1];
            app.EqSlider64.MajorTickLabels = {''};
            app.EqSlider64.Orientation = 'vertical';
            app.EqSlider64.ValueChangedFcn = createCallbackFcn(app, @EqSlider64ValueChanged, true);
            app.EqSlider64.MinorTicks = [-1 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];
            app.EqSlider64.Layout.Row = 1;
            app.EqSlider64.Layout.Column = 2;

            % Create Label_3
            app.Label_3 = uilabel(app.EqualiserGridLayout);
            app.Label_3.HorizontalAlignment = 'center';
            app.Label_3.Layout.Row = 2;
            app.Label_3.Layout.Column = 3;
            app.Label_3.Text = '128 Hz';

            % Create EqSlider128
            app.EqSlider128 = uislider(app.EqualiserGridLayout);
            app.EqSlider128.Limits = [-1 1];
            app.EqSlider128.MajorTicks = [-1 0 1];
            app.EqSlider128.MajorTickLabels = {''};
            app.EqSlider128.Orientation = 'vertical';
            app.EqSlider128.ValueChangedFcn = createCallbackFcn(app, @EqSlider128ValueChanged, true);
            app.EqSlider128.MinorTicks = [-1 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];
            app.EqSlider128.Layout.Row = 1;
            app.EqSlider128.Layout.Column = 3;

            % Create Label_4
            app.Label_4 = uilabel(app.EqualiserGridLayout);
            app.Label_4.HorizontalAlignment = 'center';
            app.Label_4.Layout.Row = 2;
            app.Label_4.Layout.Column = 4;
            app.Label_4.Text = '256 Hz';

            % Create EqSlider256
            app.EqSlider256 = uislider(app.EqualiserGridLayout);
            app.EqSlider256.Limits = [-1 1];
            app.EqSlider256.MajorTicks = [-1 0 1];
            app.EqSlider256.MajorTickLabels = {''};
            app.EqSlider256.Orientation = 'vertical';
            app.EqSlider256.ValueChangedFcn = createCallbackFcn(app, @EqSlider256ValueChanged, true);
            app.EqSlider256.MinorTicks = [-1 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];
            app.EqSlider256.Layout.Row = 1;
            app.EqSlider256.Layout.Column = 4;

            % Create Label_5
            app.Label_5 = uilabel(app.EqualiserGridLayout);
            app.Label_5.HorizontalAlignment = 'center';
            app.Label_5.Layout.Row = 2;
            app.Label_5.Layout.Column = 5;
            app.Label_5.Text = '512 Hz';

            % Create EqSlider512
            app.EqSlider512 = uislider(app.EqualiserGridLayout);
            app.EqSlider512.Limits = [-1 1];
            app.EqSlider512.MajorTicks = [-1 0 1];
            app.EqSlider512.MajorTickLabels = {''};
            app.EqSlider512.Orientation = 'vertical';
            app.EqSlider512.ValueChangedFcn = createCallbackFcn(app, @EqSlider512ValueChanged, true);
            app.EqSlider512.MinorTicks = [-1 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];
            app.EqSlider512.Layout.Row = 1;
            app.EqSlider512.Layout.Column = 5;

            % Create Label_6
            app.Label_6 = uilabel(app.EqualiserGridLayout);
            app.Label_6.HorizontalAlignment = 'center';
            app.Label_6.Layout.Row = 2;
            app.Label_6.Layout.Column = 6;
            app.Label_6.Text = '1 KHz';

            % Create EqSlider1k
            app.EqSlider1k = uislider(app.EqualiserGridLayout);
            app.EqSlider1k.Limits = [-1 1];
            app.EqSlider1k.MajorTicks = [-1 0 1];
            app.EqSlider1k.MajorTickLabels = {''};
            app.EqSlider1k.Orientation = 'vertical';
            app.EqSlider1k.ValueChangedFcn = createCallbackFcn(app, @EqSlider1kValueChanged, true);
            app.EqSlider1k.MinorTicks = [-1 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];
            app.EqSlider1k.Layout.Row = 1;
            app.EqSlider1k.Layout.Column = 6;

            % Create Label_7
            app.Label_7 = uilabel(app.EqualiserGridLayout);
            app.Label_7.HorizontalAlignment = 'center';
            app.Label_7.Layout.Row = 2;
            app.Label_7.Layout.Column = 7;
            app.Label_7.Text = '2 KHz';

            % Create EqSlider2k
            app.EqSlider2k = uislider(app.EqualiserGridLayout);
            app.EqSlider2k.Limits = [-1 1];
            app.EqSlider2k.MajorTicks = [-1 0 1];
            app.EqSlider2k.MajorTickLabels = {''};
            app.EqSlider2k.Orientation = 'vertical';
            app.EqSlider2k.ValueChangedFcn = createCallbackFcn(app, @EqSlider2kValueChanged, true);
            app.EqSlider2k.MinorTicks = [-1 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];
            app.EqSlider2k.Layout.Row = 1;
            app.EqSlider2k.Layout.Column = 7;

            % Create Label_8
            app.Label_8 = uilabel(app.EqualiserGridLayout);
            app.Label_8.HorizontalAlignment = 'center';
            app.Label_8.Layout.Row = 2;
            app.Label_8.Layout.Column = 8;
            app.Label_8.Text = '4 KHz';

            % Create EqSlider4k
            app.EqSlider4k = uislider(app.EqualiserGridLayout);
            app.EqSlider4k.Limits = [-1 1];
            app.EqSlider4k.MajorTicks = [-1 0 1];
            app.EqSlider4k.MajorTickLabels = {''};
            app.EqSlider4k.Orientation = 'vertical';
            app.EqSlider4k.ValueChangedFcn = createCallbackFcn(app, @EqSlider4kValueChanged, true);
            app.EqSlider4k.MinorTicks = [-1 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];
            app.EqSlider4k.Layout.Row = 1;
            app.EqSlider4k.Layout.Column = 8;

            % Create Label_9
            app.Label_9 = uilabel(app.EqualiserGridLayout);
            app.Label_9.HorizontalAlignment = 'center';
            app.Label_9.Layout.Row = 2;
            app.Label_9.Layout.Column = 9;
            app.Label_9.Text = '8 KHz';

            % Create EqSlider8k
            app.EqSlider8k = uislider(app.EqualiserGridLayout);
            app.EqSlider8k.Limits = [-1 1];
            app.EqSlider8k.MajorTicks = [-1 0 1];
            app.EqSlider8k.MajorTickLabels = {''};
            app.EqSlider8k.Orientation = 'vertical';
            app.EqSlider8k.ValueChangedFcn = createCallbackFcn(app, @EqSlider8kValueChanged, true);
            app.EqSlider8k.MinorTicks = [-1 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];
            app.EqSlider8k.Layout.Row = 1;
            app.EqSlider8k.Layout.Column = 9;

            % Create Label_10
            app.Label_10 = uilabel(app.EqualiserGridLayout);
            app.Label_10.HorizontalAlignment = 'center';
            app.Label_10.Layout.Row = 2;
            app.Label_10.Layout.Column = 10;
            app.Label_10.Text = '16 KHz';

            % Create EqSlider16k
            app.EqSlider16k = uislider(app.EqualiserGridLayout);
            app.EqSlider16k.Limits = [-1 1];
            app.EqSlider16k.MajorTicks = [-1 0 1];
            app.EqSlider16k.MajorTickLabels = {''};
            app.EqSlider16k.Orientation = 'vertical';
            app.EqSlider16k.ValueChangedFcn = createCallbackFcn(app, @EqSlider16kValueChanged, true);
            app.EqSlider16k.MinorTicks = [-1 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];
            app.EqSlider16k.Layout.Row = 1;
            app.EqSlider16k.Layout.Column = 10;

            % Create EqualiserResetButton
            app.EqualiserResetButton = uibutton(app.EqualiserGridLayout, 'push');
            app.EqualiserResetButton.ButtonPushedFcn = createCallbackFcn(app, @EqualiserResetButtonPushed, true);
            app.EqualiserResetButton.Tooltip = {'Reset equaliser settings'};
            app.EqualiserResetButton.Layout.Row = [1 2];
            app.EqualiserResetButton.Layout.Column = 11;
            app.EqualiserResetButton.Text = 'Reset';

            % Create GridLayout4
            app.GridLayout4 = uigridlayout(app.GridLayout);
            app.GridLayout4.ColumnWidth = {'1x'};
            app.GridLayout4.Padding = [5 5 5 5];
            app.GridLayout4.Layout.Row = 2;
            app.GridLayout4.Layout.Column = 2;

            % Create StopButton
            app.StopButton = uibutton(app.GridLayout4, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.Tooltip = {'Stop current playback'};
            app.StopButton.Layout.Row = 2;
            app.StopButton.Layout.Column = 1;
            app.StopButton.Text = 'Stop';

            % Create PlayButton
            app.PlayButton = uibutton(app.GridLayout4, 'push');
            app.PlayButton.ButtonPushedFcn = createCallbackFcn(app, @PlayButtonPushed, true);
            app.PlayButton.Tooltip = {'Process audio and begin playback'};
            app.PlayButton.Layout.Row = 1;
            app.PlayButton.Layout.Column = 1;
            app.PlayButton.Text = 'Play';

            % Create SpectrogramContextMenu
            app.SpectrogramContextMenu = uicontextmenu(app.UIFigure);

            % Create SpectrogramContextMenuClear
            app.SpectrogramContextMenuClear = uimenu(app.SpectrogramContextMenu);
            app.SpectrogramContextMenuClear.MenuSelectedFcn = createCallbackFcn(app, @SpectrogramContextMenuClearSelected, true);
            app.SpectrogramContextMenuClear.Text = 'Clear';

            % Create SpectrogramContextMenuReDraw
            app.SpectrogramContextMenuReDraw = uimenu(app.SpectrogramContextMenu);
            app.SpectrogramContextMenuReDraw.MenuSelectedFcn = createCallbackFcn(app, @SpectrogramContextMenuReDrawSelected, true);
            app.SpectrogramContextMenuReDraw.Text = 'Re-Draw';
            
            % Assign app.SpectrogramContextMenu
            app.SpectrogramAxes.ContextMenu = app.SpectrogramContextMenu;

            % Create GraphContextMenu
            app.GraphContextMenu = uicontextmenu(app.UIFigure);

            % Create GraphContextMenuReDraw
            app.GraphContextMenuReDraw = uimenu(app.GraphContextMenu);
            app.GraphContextMenuReDraw.MenuSelectedFcn = createCallbackFcn(app, @GraphContextMenuReDrawSelected, true);
            app.GraphContextMenuReDraw.Text = 'Re-Draw';
            
            % Assign app.GraphContextMenu
            app.MagnitudeAxes.ContextMenu = app.GraphContextMenu;
            app.WaveformAxes.ContextMenu = app.GraphContextMenu;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Synthesiser

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end