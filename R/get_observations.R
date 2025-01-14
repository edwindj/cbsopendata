#' Get data from a SDMX API
#'
#' Get data from an SDMX API
#' @param req An endpoint
#' @param agencyID The agency ID
#' @param id The id of the dataflow
#' @param version The version of the dataflow
#' @param flowRef The flow reference can be used in stead of agencyID, id and version
#' @param startPeriod The start period for which the data should be returned
#' @param endPeriod The end period for which the data should be returned
#' @param filter_on A named list of filters to apply to the data, if not speficied, it is the default selection, set to NULL to select all.
#' @param ... Additional parameters to pass to the request
#' @param dim_contents The contents of the dimension columns, either "label", "id" or "both"
#' @param attributes_contents The contents of the attribute columns, either "label", "id" or "both"
#' @param obs_value_numeric Should the OBS_VALUE column be coerced to numeric? Default is `TRUE`
#' @param raw If `TRUE` return the raw data.frame from the SDMX, otherwise the data.frame is processed
#' @param drop_first_columns Should the first columns be dropped? Default is `TRUE` (if not raw)
#' @param cache_dir The directory to cache the meta data, set to `NULL` to disable caching
#' @param verbose if `TRUE` print information about the caching.
#' @param as.data.table If `TRUE` return a [data.table()], otherwise a [data.frame()]
#' @return [data.frame()] or [data.table::data.table()] depending on `as.data.table`
#' @example example/get_observations.R
#' @export
get_observations <- function(
    req  = NULL,
    agencyID,
    id,
    version = "latest",
    flowRef = NULL,
    startPeriod = NULL,
    endPeriod = NULL,
    filter_on = NULL,
    ...,
    as.data.table = FALSE,
    dim_contents = c("label", "both", "id"),
    attributes_contents = c("label", "id", "both"),
    obs_value_numeric = TRUE,
    raw = FALSE,
    drop_first_columns = !raw,
    cache_dir = tempdir(),
    verbose = getOption("cbsopendata.verbose", FALSE)
  ){

  if (missing(flowRef) && (missing(agencyID) || missing(id))){
    return(NULL)
  }
  dim_contents <- match.arg(dim_contents)
  attributes_contents <- match.arg(attributes_contents)

  dfi <- get_dataflow_info(
    req = req,
    flowRef = flowRef,
    agencyID = agencyID,
    id = id,
    version = version,
    verbose = verbose,
    cache_dir = cache_dir
  )

  # dims <- get_dimensions(dfi)
  if (missing(filter_on)){
    filter_on <- dfi$default_selection

    if (!is.null(filter_on)){
      fl <- filter_on |>
        lapply(\(x) {
          deparse(x) |>
            paste(collapse = "")
        })
      fl2 <- paste("\t", names(fl),"=",fl, collapse = ",\n")
      message("\n* `filter_on` argument not specified, using default selection:\n "
             , "  filter_on = list(\n",
               fl2,
             "\n   )",
               "\n*  To select all data, set `filter_on` to `NULL`.\n"
             )
    }
  }

  key <- create_filter_key(dims = dfi$dimensions, filter_on)

  if (!is.null(startPeriod) || !is.null(endPeriod)){
    warning("`startPeriod` and `endPeriod` are only implemented for ",
            "dataflows with an explicit time dimension.",
            call. = FALSE
          )
  }

  req <- sdmx_v2_1_data_request(
    req = req,
    resource = "data",
    flowRef = dfi$flowRef,
    key = key,
    startPeriod = startPeriod,
    endPeriod = endPeriod,
    ...
  )

  # print(list(req = req))

  df <- req |> as.data.table()
  if (as.data.table){
    return(df)
  }
  data.table::setDF(df)

  # shitty return from SDMX rest, empty selection.
  # fixing it by returning a data.frame without rows.
  if (nrow(df) == 0){
    df <-
      dfi$columns$id |>
      sapply(\(x) character()) |>
      as.data.frame()
  }

  if (isTRUE(raw)){
    return(df)
  }


  if (obs_value_numeric){
    value <- dfi$measure$id
    df[[value]] <-
      as.numeric(df[[value]]) |>
      suppressWarnings()
  }

  # should the first columns be dropped?
  if (isTRUE(drop_first_columns)){
    df <- df[, -(1:3)]
  }

  # embellish data.frame with metadata

  for (d in dfi$dimensions){
    id <- d$id
    code <- d$codes
    if (!is.null(code)){
      labels <- switch(
        dim_contents,
        both  = sprintf("%s: %s", code$id, code$name),
        label = code$name,
        id    = code$id,
        code$id
      )
      df[[id]] <- df[[id]] |>
        factor(levels = code$id, labels=labels)
    }
  }

  # CBS specific
  for (a in dfi$attributes){
      id <- a$id
      code <- a$codes
      if (!is.null(code)){
        labels <- switch(
          attributes_contents,
          both  = sprintf("%s: %s", code$id, code$name),
          label = code$name,
          id    = code$id,
          code$id
        )
        df[[id]] <- df[[id]] |>
          factor(levels = code$id, labels=labels)
      }
  }


  columns <- dfi$columns
  columns <- columns[columns$id %in% names(df),]
  nms <- columns$name |> stats::setNames(columns$id)

  df[columns$id] <- lapply(columns$id, function(id) {
    x <- df[[id]]
    attr(x, "label") <- nms[id]
    x
  })


  attr(df, "flowRef") <- dfi$dataflow$ref

  df
}
