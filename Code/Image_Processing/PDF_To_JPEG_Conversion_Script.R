library(pdftools)

setwd("") # Set working directory to final destination of converted JPEG files with forward slashes between folders

directory <-
  "" # this directory is where the PDF files slated to be converted are located.
#Remember to include final forward slash after last folder name
file.list <-
  paste(directory, list.files(directory, pattern = "*.pdf"), sep = "")

lapply(
  file.list,
  FUN = function(files) {
    pdf_convert(files, format = "jpeg")
  }
)

# If you receive an error message ("Error in poppler_pdf_info(loadfile(pdf), opw, upw) : PDF parsing failure."), you probably
# have a corrupt PDF that needs to be deleted from directory. Then script can be successfully re-run. You can look in the console
# to see the last file successfully converted to determine which is the corrupted file (next file in directory).
