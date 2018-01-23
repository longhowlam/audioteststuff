### calculation of mel spectrogram via python librosa
library(dplyr)
library(purrr)
library(reticulate)
use_python(python = "/usr/bin/python3")

#### test for one specific file ############

librosa = import("librosa")
ff = librosa$feature

##### test run for one test mp3
audio_path = 'mp3/059G9tpE3kl6wz3kiddaN0.mp3'
mp3 = librosa$load(audio_path)
plot(mp3[[1]][1:30000], type="l")

melgram = librosa$logamplitude(
  ff$melspectrogram(
    mp3[[1]], 
    sr = mp3[[2]],
    n_mels=96),
  ref_power=1.0
)
dim(melgram)


##### now do this for all mp3 in a folder
mel = function(file, dir, .pb = NULL)
{
  if ((!is.null(.pb)) && inherits(.pb, "Progress") && (.pb$i < .pb$n)) .pb$tick()$print()
  
  pathfile = paste0(dir, "/", file)
  mp3 = librosa$load(pathfile)
  
  # calc  mel to file
  melgram = librosa$logamplitude(
    ff$melspectrogram(
      mp3[[1]], 
      sr = mp3[[2]],
      n_mels=96),
    ref_power=1.0
  )
  melgram
}


## one mel calculation
mp3s = paste0(list.files("mp3"))
tmp = mel(mp3s[11], "mp3")


## all mp3 files in a dir
pb <- progress_estimated(length(mp3s))
EurosongsMels = purrr::map(mp3s, mel, dir = "mp3", .pb = pb)
names(EurosongsMels) = mp3s
length(EurosongsMels)

### remove mels with wrong dimension
zz = purrr::map_int(EurosongsMels, function(x)dim(x)[2])
yy = names(zz)[zz != 1292]
EurosongsMels[yy] = NULL
length(EurosongsMels)


saveRDS(EurosongsMels, "EurosongsMels.RDs")

#### transform as array
tmp = unlist(EurosongsMels)
dim(tmp) = c(422, 96, 1292,1)
422*96*1292

image(tmp[1, , ,])
saveRDS(tmp, "EurosongsMelArrays.RDs")










