library(Rtsne)


EurosongsMelsMatrix = matrix(NA , nrow = 422, ncol=96*1292)
for(i in 1:422){
  EurosongsMelsMatrix[i,] = as.numeric(EurosongsMels[[i]])
}
songids = names(EurosongsMels) %>% stringr::str_replace(".mp3", "")

EurosongsMelsMatrix[1,1:10]
EurosongsMels[[1]][2,1]
tsne_out <- Rtsne(EurosongsMelsMatrix, dims=3) # Run TSNE
plot(tsne_out$Y) # Plot the result


library(plotly)

reduced = tsne_out$Y %>%
  as_data_frame() %>%
  mutate(trackid = songids)

reduced = reduced %>% left_join(Eurosongs) %>% mutate(songduration = as.numeric(duration)/60000 ) %>% filter(songduration < 5)

  plot_ly(
    reduced,
    x = ~V1, y = ~V2, z = ~V3,
    color=~songduration,
    size=2,
    text = ~song,
    sizes=c(2.2,2.2)
  ) %>%
  add_markers() %>%
  layout(title="3D tsne")

hist(reduced$songduration)

