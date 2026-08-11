function x = record_audio(fs, duration)
    nBits = 16;
    nChannels = 1;

    recObj = audiorecorder(fs, nBits, nChannels);

    fprintf('Recording for %.1f seconds at %d Hz... speak now.\n', duration, fs);
    recordblocking(recObj, duration);
    fprintf('Recording finished.\n');

    x = getaudiodata(recObj);
end
