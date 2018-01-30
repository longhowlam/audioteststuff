library(tuneR)

audio_path = 'mp3/059G9tpE3kl6wz3kiddaN0.mp3'

mp3object = readMP3(audio_path)
mp3objectL = channel(mp3object, which = "left")
melout = melfcc(mp3objectL, wintime = .1, spec_out = TRUE)

image(melout$cepstra)

      