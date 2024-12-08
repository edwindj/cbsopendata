#' Request SDMX data
#'
#' `req_sdmx_data` is a wrapper around the smdx rest api and is used to retrieve
#' data from the api.
#'
#' @param req An endpoint or an httr2 request object
#' @param resource The resource to request. Either "data" or "metadata"
#' @param flowRef The flow reference to request, see details
#' @param key The key to request, see details
#' @param providerRef The provider reference to request, see details
#' @param format The format to request. Either "csv", "json" or "xml"
#' @param ... Additional parameters to pass to the request
#' @param startPeriod The start period for which the data should be returned
#' @param endPeriod The end period for which the data should be returned
#' @param updatedAfter Only return data that has been updated after this date
#' @param firstNObservations Only return the first n observations
#' @param lastNObservations Only return the last n observations
#' @param dimensionAtObservation The dimensions of the observations should be returned
#' @param detail The detail of the data to return. Either "full", "dataonly", "serieskeysonly" or "nodata"
#' @param includeHistory Include the different versions of the data
#' @param labels Include the labels in the data, only valid when format is "csv"
#' @return a modified [httr2::request()] object
#' @export
req_sdmx_data <- function(
    req = NULL,
    resource = c("data", "metadata"),
    flowRef = NULL,
    key = NULL,
    providerRef = NULL,
    format = c("csv", "json", "xml"),
    ...,
    startPeriod = NULL,
    endPeriod = NULL,
    updatedAfter = NULL,
    firstNObservations = NULL,
    lastNObservations = NULL,
    dimensionAtObservation = NULL,
    detail = c("full", "dataonly", "serieskeysonly", "nodata"),
    includeHistory = NULL,
    labels = c("both", "id")
    ){
  req <- sdmx_request(req)
  resource <- match.arg(resource)

  path <- c(
    resource,
    flowRef,
    key,
    providerRef
  ) |>
    lapply(function(x) if (length(x)){paste(x, collapse = "+")}) |>
    paste(collapse = "/")

  req <- req |> httr2::req_template("GET /{path}")

  if (missing(detail)){
    detail <- NULL
  }

  if (!is.null(detail)){
    detail <- match.arg(detail)
  }

  req <- req |>
    httr2::req_url_query(
      startPeriod            = startPeriod,
      endPeriod.             = endPeriod,
      updatedAfter           = updatedAfter,
      firstNObservations     = firstNObservations,
      lastNObservations      = lastNObservations,
      dimensionAtObservation = dimensionAtObservation,
      detail                 = detail,
      includeHistory         = includeHistory
    )

  format <- match.arg(format)

  req <- switch(
    format,
    csv  = req |> httr2::req_headers(accept = "application/vnd.sdmx.data+csv; version=1.0.0; charset=utf-8"),
    json = req |> httr2::req_headers(accept = "application/vnd.sdmx.data+json; version=1.0; charset=utf-8"),
    xml  = req,
    req
  )

  # only valid for csv format
  if (!missing(labels)){
    req <-
      req |>
      add_header_accept(labels = labels)
  }

  req
}

# req <- httr2::request("https://sdmx-api.beta.cbs.nl/rest") |>
#   req_sdmx_data(resource = "data")
