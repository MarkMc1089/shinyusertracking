set_credentials <- function(file = ".google-sheets-credentials") {
  if (file.exists(file)) {
    tryCatch(
      lines <- readLines(file),
      error = \(e) stop("Error reading lines from ", file)
    )
  } else {
    stop("File ", file, " does not exist")
  }

  ID <- "GOOGLE_SHEET_ID"
  id_line <- lines[startsWith(lines, ID)]
  if (!length(id_line)) stop("No value for ", ID, " in ", file)

  USER  <- "GOOGLE_SHEET_USER"
  user_line  <- lines[startsWith(lines, USER)]
  if (!length(user_line)) stop("No value for ", USER, " in ", file)

  Sys.setenv(GOOGLE_SHEET_ID = gsub('^[^\\=]*\\=(.*)$', '\\1', id_line))
  Sys.setenv(GOOGLE_SHEET_USER = gsub('^[^\\=]*\\=(.*)$', '\\1', user_line))
}


check_cols <- function(columns) {
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
    stopifnot(
      "Columns not in: id, username, login, logout, duration" = columns %in% known_cols
    )
  }
}


setup_sheet <- function(sheet_name = pkgload::pkg_name(), columns = NULL) {
  check_cols(columns)

  googlesheets4::gs4_auth(
    email = Sys.getenv("GOOGLE_SHEET_USER"),
    cache = ".secret/"
  )

  googlesheets4::sheet_add(Sys.getenv("GOOGLE_SHEET_ID"), sheet_name)
  googlesheets4::sheet_append(
    Sys.getenv("GOOGLE_SHEET_ID"),
    data.frame(matrix(columns, nrow = 1)),
    sheet_name
  )
}


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
  check_cols(columns)

  googlesheets4::gs4_auth(
    email = Sys.getenv("GOOGLE_SHEET_USER"),
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
      Sys.getenv("GOOGLE_SHEET_ID"),
      subset(session$userData$tracking, select = columns)
    )
  })
}
