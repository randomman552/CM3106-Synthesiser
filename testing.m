fullPath = "./samples/drums.wav";

% Read audio sample in
[y, Fs] = audioread(fullPath);
y = y(:, 1);
N = length(y);
nyquist = N / 2;


s = stft(y, Fs);
s = s - stftBandpass(s, 0.1, 0.9, 0, 0.5);
y = real(istft(s));
sound(y, Fs);