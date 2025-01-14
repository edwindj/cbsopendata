% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/as.data.table.sdmx_v2_1_data_request.R
\name{as.data.table.sdmx_v2_1_data_request}
\alias{as.data.table.sdmx_v2_1_data_request}
\title{Get data from a SDMX API}
\usage{
\method{as.data.table}{sdmx_v2_1_data_request}(x, keep.rownames = FALSE, ...)
}
\arguments{
\item{x}{An httr2 request object}

\item{keep.rownames}{logical, not used}

\item{...}{reserved for future use}
}
\value{
data.table
}
\description{
Retrieve data from an sdmx api and return it as a data.frame
}
\examples{
if (interactive()){
  dfs <- get_dataflows()
  flowRef <- dfs$ref[2]

  system.time({
    d <-
      sdmx_v2_1_data_request(flowRef = flowRef)

    sdmx_v2_1_as_data_frame()
  })


  # json
  d <-
    sdmx_v2_1_data_request(flowRef = flowRef) |>
    sdmx_v2_1_as_data_frame(format = "json")

}
}
