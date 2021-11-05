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
lowerFreq = 0.1;
upperFreq = 1;

filter = fourierBandpass(N, lowerFreq, upperFreq);

% Apply bandpass to cut sample
yCutFft = yCutFft .* filter;


%yMag = abs(yFourier);
%plot(yMag(1:end/2));

% Perform subtractive synthesis
yfft = yfft - yCutFft;

% Recover data with inverse fourier
y = real(ifft(yfft));
sound(y, Fs);
spectrogram(y, 100);