#' Add user tracking
#'
#' Log session ID, username (only for Private apps), session start, end and
#' duration to a Google sheet.
#'
#' @param columns Which columns to record, from id, username, login, logout and
#'  duration. By default all will be recorded.
#' @param session Shiny session object.
#'
#' @return Nothing; used for side effect.
#' @export
#'
#' @examples
#' \dontrun{
#' library(shiny)
#'
#' ui <- fluidPage()
#' server <- function(input, output, session) {
#'   shinyusertracking::set_user_tracking(
#'     c("login", "logout", "duration"),
#'     session
#'   )
#' }
#'
#' shinyApp(ui, server)
#' }
#'
set_user_tracking <- function(columns = NULL, session) {
  known_cols <- c(
    "id",
    "username",
    "login",
    "logout",
    "duration"
  )

  if (is.null(columns)) {
    columns <- known_cols
  } else {
    stopifnot({
      columns %in% known_cols
    })
  }

  eval_lines(".google-sheets-credentials")

  google_email <- NULL
  sheet_id <- NULL

  try({
    google_email <- get("GOOGLE_SHEET_USER")
  })
  try({
    sheet_id <- get("GOOGLE_SHEET_ID")
  })

  if (is.null(google_email) || is.null(sheet_id)) {
    warning(
      "Credentials missing for shinyusertracking::set_user_tracking",
      call. = FALSE
    )
    return()
  }

  googlesheets4::gs4_auth(
    email = google_email,
    cache = ".secret/"
  )

  session$userData$tracking <- data.frame(
    id = session$token,
    username = ifelse(is.null(session$user), "unknown", session$user),
    login = Sys.time(),
    logout = lubridate::NA_POSIXct_,
    duration = NA_character_
  )

  session$onSessionEnded(function() {
    session$userData$tracking$logout <- Sys.time()

    duration <- difftime(
      session$userData$tracking$logout,
      session$userData$tracking$login,
      units = "secs"
    )
    duration <- abs(as.numeric(duration))
    duration <- sprintf(
      "%02d:%02d:%02d", # hh:mm:ss
      duration %/% 3600, # whole hours (could be > 24)
      duration %% 3600 %/% 60, # whole minutes left
      duration %% 60 %/% 1 + round(duration %% 60 %% 1) # rounded seconds left
    )

    session$userData$tracking$duration <- as.character(duration)

    googlesheets4::sheet_append(
      sheet_id,
      subset(session$userData$tracking, select = columns)
    )
  })
}


#' Evaluate each line of plain text file
#'
#' Reads a plain text file line by line, evaluating each line. Useful for
#' creating variables dynamically, e.g. reading in parameters.
#'
#' @param filepath Filepath as a String.
#' @param envir Environment to evaluate in. Default is calling environment.
#'
#' @return Nothing
#'
#' @examples
#' \dontrun{
#' filepath <- tempfile()
#' writeLines(
#'   text = "LEFT = \"right\"",
#'   con = filepath
#' )
#' eval_lines(filepath)
#' print(LEFT)
#' unlink(filepath) # delete temporary file
#' rm(left) # remove example variable
#' }
eval_lines <- function(filepath, envir = parent.frame()) {
  con <- file(filepath, open = "r")
  on.exit(close(con))

  while (length(line <- readLines(con, n = 1, warn = FALSE)) > 0) {
    eval(parse(text = line), envir = envir)
  }
}
