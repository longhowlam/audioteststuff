# Spotify aanroep

library(httr)

clientID = "bf061bc472ad45a2965b5ec1fff02010"
secret = "1fd02c5e94324b41b5dbfea565cbcf57"


################################################
########### 
########### Album info
########### frank sinatra album

albumURL = "https://api.spotify.com/v1/albums/3CyomBjyhtq3xLtMq2Oxi2"
out = GET(url = albumURL)

album = content(out)
album$album_type
album$artists

tracks = album$tracks

### song nr 1 "come fly with me
tracks$items[[1]]
trackid = tracks$items[[1]]$id

###########################################################
###########
########### info opvragen van een track, 
########### moet met token authorisatie


### vraag token op
token = GetSpotifyToken(clientID = clientID, secret = secret)

# gebruik token om track info op te vragen
UriTrack =  paste0("https://api.spotify.com/v1/audio-features/", trackid)
HeaderValue = paste("Bearer ", token, sep="")
r2 = GET(url = UriTrack, add_headers(Authorization = HeaderValue))
trackAudioFeatures = content(r2)


##############################################################
##
## profiel informatie

URI = "https://api.spotify.com/v1/users/1113437359"

token = GetSpotifyToken(clientID = clientID, secret = secret)
HeaderValue = paste("Bearer ", token, sep="")
r2 = GET(url = URI, add_headers(Authorization = HeaderValue))
profileInfo = content(r2)


#############################################################
##
## playlists van een user 

URI = "https://api.spotify.com/v1/users/longhowlam/playlists?limit=30"
token = GetSpotifyToken(clientID = clientID, secret = secret)
HeaderValue = paste("Bearer ", token, sep="")
r2 = GET(url = URI, add_headers(Authorization = HeaderValue))
playlists = content(r2)$items
playlists[[2]]




################################################################
##
##  lijst van tracks op een specifieke playlist

URI = "https://api.spotify.com/v1/users/longhowlam/playlists/61g7vZ7cx9jCOZWlzLnlUC/tracks"
token = GetSpotifyToken(clientID = clientID, secret = secret)
HeaderValue = paste("Bearer ", token, sep="")
r2 = GET(url = URI, add_headers(Authorization = HeaderValue))
tracks = content(r2)$items
tracksDF = ConvertToDataFrame(tracks)



