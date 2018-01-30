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
mp3[[2]]

length(mp3[[1]])
length(mp3[[1]])/mp3[[2]]  # 30 seconds sound

## 2 seconds plot
pp = 2*mp3[[2]]
plot(mp3[[1]][1:pp], type="l")

melgram = librosa$logamplitude(
  ff$melspectrogram(
    mp3[[1]], 
    sr = mp3[[2]],
    n_mels=96),
  ref_power=1.0
)
dim(melgram)
image(melgram)

##### mfcc 
mfcc = function(file, dir, .pb = NULL)
{
  if ((!is.null(.pb)) && inherits(.pb, "Progress") && (.pb$i < .pb$n)) .pb$tick()$print()
  
  pathfile = paste0(dir, "/", file)
  mp3 = librosa$load(pathfile)
  
  # calc  mel to file
  log_S = librosa$logamplitude(
    ff$melspectrogram(
      mp3[[1]], 
      sr = mp3[[2]],
      n_mels=96),
    ref_power=1.0
  )
  mfcc = ff$mfcc(S=log_S, n_mfcc=13L)
  mfcc1 = ff$delta(mfcc)
  mfcc2 = ff$delta(mfcc, order=2L)
  list(mfcc,mfcc1,mfcc2)
}


## one mel calculation
mp3s = paste0(list.files("mp3"))

tmp = mfcc(mp3s[1], "mp3")
image(tmp[[3]])

## all mp3 files in a dir
mp3s = paste0(list.files("mp3"))
pb = progress_estimated(length(mp3s))
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
EurosongsMelsArray = array(NA , dim=c(422,96,1292,1))
for(i in 1:422){
  EurosongsMelsArray[i,,,] = EurosongsMels[[i]]
}

image(t(EurosongsMelsArray[11, , ,]))
image((EurosongsMelsArray[11, , ,]))

saveRDS(EurosongsMelsArray, "EurosongsMelArrays.RDs")

EurosongsMelsArray = readRDS("EurosongsMelArrays.RDs")

