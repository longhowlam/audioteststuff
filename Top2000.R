library(httr)
library(purrr)
library(dplyr)

clientID = "bf061bc472ad45a2965b5ec1fff02010"
secret = "1fd02c5e94324b41b5dbfea565cbcf57"

#########################################################

#### Spotify api helper functions ####

## given clientIS and secret we can retrieve a token that is 
## needed for  further API calls

GetSpotifyToken = function(clientID, secret){
  
  response <- POST('https://accounts.spotify.com/api/token',
                   accept_json(),
                   authenticate(clientID, secret),
                   body=list(grant_type='client_credentials'),
                   encode='form',
                   verbose())
  
  if (status_code(response) == 200){
    return(content(response)$access_token)
  }
  else{
    return("")
  }
}



##################################################################################
## given an userid and an playlistID we extract the tracks from this specific playlist

ExtractTracksFromPlaylist = function(offset = 0, ownerID, playlistID, clientID, secret, .pb=NULL){ 
  
  if ((!is.null(.pb)) && inherits(.pb, "Progress") && (.pb$i < .pb$n)) .pb$tick()$print()
    
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
    artist      = purrr::map_chr(tracks$items, .f=function(x)x[["track"]][["artists"]][[1]][["name"]]),
    song        = purrr::map_chr(tracks$items, .f=function(x)x[["track"]][["name"]]),
    preview_url = purrr::map_chr(tracks$items, .f=function(x)x[["track"]][["preview_url"]] %||% ""),
    duration    = purrr::map_chr(tracks$items, .f=function(x)x[["track"]][["duration_ms"]]),
    trackid     = purrr::map_chr(tracks$items, .f=function(x)x[["track"]][["id"]])
  )
}

### there is one playlist with many top2000 songs
ownerID = "erikrougoor"
playlistID = "13ju0co4TyHAo6AuBYlFqE"

## run for one offset
tmp = ExtractTracksFromPlaylist( offset = 100, ownerID = ownerID, playlistID = playlistID, clientID, secret)


## run on multiple offsets
offset = 100*(0:18)
pb <- progress_estimated(length(offset))

Top2000 = purrr::map_df(
  offset,
  ExtractTracksFromPlaylist,
  ownerID = ownerID,
  playlistID = playlistID,
  clientID, 
  secret,
  .pb = pb
)

####  we have now a data set iwth songs and preview urls
####  download the available preview mp3's

for(i in 1:920)
{
  if (Eurosongs$preview_url[i] != "")
  {
    download.file(
      Eurosongs$preview_url[i], 
      destfile = paste0("mp3/", Eurosongs$trackid[i], ".mp3"),
      mode="wb" 
    )
  }
}














