fullPath = "./samples/drums.wav";

% Read audio sample in
[y, Fs] = audioread(fullPath);
y = y(:, 1);
N = length(y);
nyquist = N / 2;

% Create fourier transform
yfft = fft(y);

% Cut some samples to experiment with out
yCut = sliceSamples(y, 1, N);
yCutFft = fft(yCut);

% Normalised frequencies
lowerFreq = 0.2;
upperFreq = 1;

filter = fourierBandpass(N, lowerFreq, upperFreq, false);

% Apply bandpass to cut sample
yCutFft = yCutFft .* filter;

% Perform subtractive synthesis
yfft = yfft - yCutFft;


% Recover data with inverse fourier
y = real(ifft(yfft));
player = audioplayer(y, Fs);

play(player);



% Plot magnitudes
yMag = abs(yfft);
yCutMag = abs(yCutFft);

subplot(2, 1, 1);
plot(yMag);
subplot(2, 1, 2);
plot(yCutMag)


%spectrogram(y, 100);