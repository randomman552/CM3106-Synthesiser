samplePath = "./samples/drums.wav";

% Read audio samples in
[y, Fs] = audioread(samplePath);
y = y(:, 1);

% Perform convolution
% y = conv(y1, y1);
% y = y ./ max(y);

pitch = 1;
tempo = 1;
y = pvoc(y, ((2/pitch)/(2*pitch)) * tempo);
y = y(1:(2*pitch)/(2/pitch):end);
sound(y, Fs);

% y = real(istft(ystft, Fs));
% sound(y, Fs);