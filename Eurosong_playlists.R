library(httr)
library(purrr)

clientID = readRDS("clientID.RDs")
secret = readRDS("secret.RDs")


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

##### given a query string search for playlists, take the first found

ExtractTracksFromPlaylistSearch = function(query, clientID, secret) 
{
  
  URI = paste0(
    "https://api.spotify.com/v1/search?q=",
    query,
    "&type=playlist"
  )
  
  token = GetSpotifyToken(clientID = clientID, secret = secret)
  HeaderValue = paste("Bearer ", token, sep="")
  r2 = GET(url = URI, add_headers(Authorization = HeaderValue))
  results = content(r2)
  
  ### for now take the first match
  playlistID = results[["playlists"]][["items"]][[1]][["id"]]
  ownerID = results[["playlists"]][["items"]][[1]][["owner"]][["id"]]

  ### get the playlist itself
  URI = paste0(
    "https://api.spotify.com/v1/users/", 
    ownerID,
    "/playlists/", 
    playlistID,
    "/tracks"
  )
  HeaderValue = paste("Bearer ", token, sep="")
  r2 = GET(url = URI, add_headers(Authorization = HeaderValue))
  tracks = content(r2)

  
  ## put track info in a data set, we need to extract it from nested lists
  tibble::tibble(
    query       = query,
    artist      = purrr::map_chr(tracks$items, .f=function(x)x[["track"]][["artists"]][[1]][["name"]]),
    song        = purrr::map_chr(tracks$items, .f=function(x)x[["track"]][["name"]]),
    preview_url = purrr::map_chr(tracks$items, .f=function(x)x[["track"]][["preview_url"]] %||% ""),
    image       = purrr::map_chr(tracks$items, .f=function(x)x[["track"]][["album"]][["images"]][[1]][["url"]]),
    duration    = purrr::map_chr(tracks$items, .f=function(x)x[["track"]][["duration_ms"]]),
    trackid     = purrr::map_chr(tracks$items, .f=function(x)x[["track"]][["id"]])
  )
}

## run on one query
EURO2017 = ExtractTracksFromPlaylistSearch("Eurovision%202017", clientID , secret )

## run multiple queries
query = paste0("Eurovision%20", 1996:2017)
Eurosongs = purrr::map_df(query, ExtractTracksFromPlaylist, clientID, secret)



##################################################################################
## given an userid and an playlistID we extract the tracks from this specific playlist

ExtractTracksFromPlaylist = function(offset = 0, ownerID, playlistID, clientID, secret){ 
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
    image       = purrr::map_chr(tracks$items, .f=function(x)x[["track"]][["album"]][["images"]][[1]][["url"]]),
    duration    = purrr::map_chr(tracks$items, .f=function(x)x[["track"]][["duration_ms"]]),
    trackid     = purrr::map_chr(tracks$items, .f=function(x)x[["track"]][["id"]])
  )
}

### there is one playlist with many eurovision songs
ownerID = "victortronx"
playlistID = "7KL2JUGEGuCJU53TuDs8xk"

## run for one offset
ExtractTracksFromPlaylist( offset = 100, "victortronx",  "7KL2JUGEGuCJU53TuDs8xk", clientID, secret)


## run on multiple offsets
offset = 100*(0:10)

Eurosongs = purrr::map_df(
  offset,
  ExtractTracksFromPlaylist,
  "victortronx",
  "7KL2JUGEGuCJU53TuDs8xk", 
  clientID, 
  secret
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














