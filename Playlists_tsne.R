###############################################################################
##
##  download different playlists and visualise with t-sne

library(httr)
library(purrr)
library(dplyr)
library(reticulate)
library(Rtsne)
library(plotly)

use_python(python = "/usr/bin/python3")

## spotify credientials
clientID = readRDS("clientID.RDs")
secret = readRDS("secret.RDs")


###### Spotify api helper functions ###########################################

## given a clientID and secret we can retrieve a token that is 
## needed for further Spotify API calls

GetSpotifyToken = function(clientID, secret){
  
  response <- POST(
    'https://accounts.spotify.com/api/token',
    accept_json(),
    authenticate(clientID, secret),
    body=list(grant_type='client_credentials'),
    encode='form',
    verbose()
  )
  
  if (status_code(response) == 200){
    return(content(response)$access_token)
  }
  else{
    return("")
  }
}

###################################################################################
## given an userid and a playlistID we extract the tracks from this specific playlist

ExtractTracksFromPlaylist = function(offset = 0, ownerID, playlistID, clientID, secret, mylabel = ""){ 
  ### get the playlist itself
  URI = paste0(
    "https://api.spotify.com/v1/users/", 
    ownerID,
    "/playlists/", 
    playlistID,
    "/tracks",
    "?offset=",
    offset
  )
  token = GetSpotifyToken(clientID = clientID, secret = secret)
  HeaderValue = paste("Bearer ", token, sep="")
  r2 = GET(url = URI, add_headers(Authorization = HeaderValue))
  tracks = content(r2)
  
  ## put track info in a data set, we need to extract it from nested lists
  tibble::tibble(
    label       = mylabel,
    artist      = purrr::map_chr(tracks$items, .f=function(x)x[["track"]][["artists"]][[1]][["name"]]),
    song        = purrr::map_chr(tracks$items, .f=function(x)x[["track"]][["name"]]),
    preview_url = purrr::map_chr(tracks$items, .f=function(x)x[["track"]][["preview_url"]] %||% ""),
    image       = purrr::map_chr(tracks$items, .f=function(x)x[["track"]][["album"]][["images"]][[1]][["url"]]),
    duration    = purrr::map_chr(tracks$items, .f=function(x)x[["track"]][["duration_ms"]]),
    trackid     = purrr::map_chr(tracks$items, .f=function(x)x[["track"]][["id"]])
  )
}


######## get different kind of songs ####################################################

########  Bach songs ################
ownerID = "spotify"
playlistID = "37i9dQZF1DWZnzwzLBft6A"

BACH_tracks = ExtractTracksFromPlaylist(
  offset = 0, 
  ownerID = ownerID,  
  playlistID = playlistID,
  clientID, 
  secret, 
  mylabel = "BACH"
)

## ignore the songs without preview URL
BACH_tracks = BACH_tracks %>% filter(preview_url != "")

######### Heavy metal songs ###########
ownerID = "spotify"
playlistID = "37i9dQZF1DX9qNs32fujYe"

HEAVYMETAL_tracks = ExtractTracksFromPlaylist(
  offset = 0, 
  ownerID = ownerID,  
  playlistID = playlistID,
  clientID, 
  secret, 
  mylabel = "HEAVY METAL"
)

## ignore the songs without preview URL
HEAVYMETAL_tracks = HEAVYMETAL_tracks %>% filter(preview_url != "")


######### Michael Jackson songs #####
ownerID = "spotify"
playlistID = "37i9dQZF1DXaTIN6XNquoW"

MJ_tracks = ExtractTracksFromPlaylist(
  offset = 0, 
  ownerID = ownerID,  
  playlistID = playlistID,
  clientID, 
  secret, 
  mylabel = "JACKSON"
)

## ignore the songs without preview URL
MJ_tracks = MJ_tracks %>% filter(preview_url != "")




########## bach violin
ownerID = "adrientsuzuki"
playlistID = "6sGxlZaDfoTTQ4FCimYgl7"

VIOLIN_tracks = ExtractTracksFromPlaylist(
  offset = 0, 
  ownerID = ownerID,  
  playlistID = playlistID,
  clientID, 
  secret, 
  mylabel = "VIOLIN"
)

## ignore the songs without preview URL
VIOLIN_tracks = VIOLIN_tracks %>% filter(preview_url != "")



######### stack all songs in one data frame and retrive mp3's #####################

AllSongs = bind_rows(MJ_tracks, HEAVYMETAL_tracks, BACH_tracks, VIOLIN_tracks)

for(i in seq_along(AllSongs$preview_url))
{
  download.file(
    AllSongs$preview_url[i], 
    destfile = paste0("mp3songs/", AllSongs$trackid[i]),
    mode="wb" 
  )
}

########  Calculate melspectogram #################################################
## using python librosa pacakge (via the reticulate package)
## all downloaded mp3's are put trhough librosa

librosa = import("librosa")
ff = librosa$feature

### helper function around librosa call
mfcc = function(file, dir, .pb = NULL)
{
  if ((!is.null(.pb)) && inherits(.pb, "Progress") && (.pb$i < .pb$n)) .pb$tick()$print()
  
  pathfile = paste0(dir, "/", file)
  mp3 = librosa$load(pathfile)
  
  # calc  mel to file
  librosa$logamplitude(
    ff$melspectrogram(
      mp3[[1]], 
      sr = mp3[[2]],
      n_mels=96),
    ref_power=1.0
  )
}

mp3s = list.files("mp3songs/")
pb = progress_estimated(length(mp3s))

AllSongsMFCC = purrr::map(mp3s, mfcc, dir = "mp3songs", .pb = pb)

## create a feature matrix. Simply flatten the matrix
## each song is now a row of 13*1292 values

nsongs = dim(AllSongs)[1]
AllSongsMFCCMatrix = matrix(NA , nrow = nsongs, ncol=96*1292)
for(i in 1:nsongs){
  AllSongsMFCCMatrix[i,] = as.numeric(AllSongsMFCC[[i]])
}

### apply T-sne on the songs to reduce to 3 dimensions
tsne_out <- Rtsne(AllSongsMFCCMatrix, dims=3) # Run TSNE

### transform result to a data frame and match original songs data frame
reduced = tsne_out$Y %>%
  as_data_frame() 
reduced$trackid = mp3s
  
reduced = reduced %>% left_join(AllSongs)

plot_ly(
  reduced,
  x = ~V1, y = ~V2, z = ~V3,
  color=~label,
  text = ~artist
) %>%
  add_markers() %>%
  layout(title="3D t-sne on spotify mp3 samples")

