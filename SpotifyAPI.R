### Spotify api functions

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


ConvertToDataFrame = function(tracks)
{
  naampjes = function(x)
  {
    c(x$added_at,
    x$track$artists[[1]]$name,
    x$track$name,
    x$track$duration_ms,
    x$track$popularity)
  }

  tmp = as.data.frame(t(sapply( tracks, naampjes)))
  names(tmp) = c("added", "Artist", "Song","duration", "popularity")
  tmp
}
