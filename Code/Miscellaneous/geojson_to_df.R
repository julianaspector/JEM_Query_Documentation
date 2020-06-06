library(geojsonR)
tehama <-
  FROM_GeoJson("ENTER PATH HERE") # replaced all null with "NA"

c <- (2:length(tehama$features))

df.geojson <- function(list_number) {
  df <-
    data.frame(
      APN = tehama$features[[list_number]]$properties$PARCELAPN,
      owner = tehama$features[[list_number]]$properties$ASSESSEE_OWNER_NAME_1
    )
  return(df)
}

df_final <-
  data.frame(
    APN = tehama$features[[1]]$properties$PARCELAPN,
    owner = tehama$features[[1]]$properties$ASSESSEE_OWNER_NAME_1
  )

for (i in c) {
  df_final <- rbind(df_final, df.geojson(i))
  
}

write.csv(df_final, "ENTER FILE NAME HERE")
