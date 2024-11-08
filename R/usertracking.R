#' Securely ask for Google sheet ID and username
#'
#' Uses Rstudio secret functionality together with the keyring package to securely
#' store the input values. If keyring is not installed and up to date, the option to
#' do so will be given. Once keyring is present, tick the box to save the secrets.
#' The next time this is run, the secrets will be pre-filled.
#'
#' @param file File used to store credentials. Defaults to `.google-sheets-credentials`.
#' @param overwrite Whether to overwrite file if it already exists. Default is FALSE.
#'
#' @return Nothing, used for side-effects only
#'
#' @export
#'
#' @examples
#' \dontrun{
#' add_credentials(overwrite = TRUE)
#' }
add_credentials <- function(file = ".google-sheets-credentials", overwrite = FALSE) {
  if (!overwrite && file.exists(file)) {
    stop(
      "Credentials file ", file, " already exists; set overwrite = TRUE if you are sure."
    )
  }

  writeLines(
    c(
      paste0(
        "GOOGLE_SHEET_ID=",
        tryCatch(
          rstudioapi::askForSecret("GOOGLE_SHEET_ID"),
          error = \(e) stop("Aborting...")
        )
      ),
      paste0(
        "GOOGLE_SHEET_USER=",
        tryCatch(
          rstudioapi::askForSecret("GOOGLE_SHEET_USER"),
          error = \(e) stop("Aborting...")
        )
      )
    ),
    file
  )

  usethis::use_git_ignore(file)
}


#' Set environment variables for the Google sheet ID and username
#'
#' @param file File used to store credentials. Defaults to `.google-sheets-credentials`.
#'
#' @return Nothing, used for side-effects only
#'
#' @export
#'
#' @examples
#' \dontrun{
#' set_credentials()
#' }
set_credentials <- function(file = ".google-sheets-credentials") {
  if (file.exists(file)) {
    tryCatch(
      lines <- readLines(file),
      error = \(e) stop("Error reading lines from ", file)
    )
  } else {
    stop("File ", file, " does not exist")
  }

  id <- "GOOGLE_SHEET_ID"
  id_line <- lines[startsWith(lines, id)]
  if (!length(id_line)) stop("No value for ", id, " in ", file)

  user <- "GOOGLE_SHEET_USER"
  user_line <- lines[startsWith(lines, user)]
  if (!length(user_line)) stop("No value for ", user, " in ", file)

  Sys.setenv(GOOGLE_SHEET_ID = gsub("^[^\\=]*\\=(.*)$", "\\1", id_line))
  Sys.setenv(GOOGLE_SHEET_USER = gsub("^[^\\=]*\\=(.*)$", "\\1", user_line))
}


#' Check that only known columns are provided
#'
#' @param columns Either NULL or vector of column names.
#'
#' @return The provided columns, if all are known; all known columns if NULL input;
#'  or error if some provided columns are not known.
#'
#' @noRd
check_cols <- function(columns) {
  known_cols <- c(
    "id",
    "username",
    "login",
    "logout",
    "duration"
  )

  if (is.null(columns)) {
    return(known_cols)
  } else {
    stopifnot(
      "Columns not in: id, username, login, logout, duration" = columns %in% known_cols
    )
  }

  columns
}


#' Add a new sheet for tracking to the Google sheets
#'
#' @param sheet_name Name for the sheet. Default is to use current package name.
#' @param columns Which columns to log, from id, username, login, logout and
#'  duration. By default login, logout and duration will be logged.
#' @param creds File used to store credentials. Defaults to `.google-sheets-credentials`.
#'
#' @return Nothing, used for side-effects only
#'
#' @export
#'
#' @examples
#' \dontrun{
#' setup_sheet("A new Shiny app", c("login", "logout", "duration"))
#' }
setup_sheet <- function(sheet_name = pkgload::pkg_name(),
                        columns = c("login", "logout", "duration"),
                        creds = ".google-sheets-credentials") {
  columns <- check_cols(columns)

  set_credentials(creds)

  googlesheets4::gs4_auth(
    email = Sys.getenv("GOOGLE_SHEET_USER"),
    cache = ".secret/"
  )

  usethis::use_git_ignore(".secret")

  googlesheets4::sheet_add(Sys.getenv("GOOGLE_SHEET_ID"), sheet_name)
  googlesheets4::sheet_append(
    Sys.getenv("GOOGLE_SHEET_ID"),
    data.frame(matrix(columns, nrow = 1)),
    sheet_name
  )
}


#' Add visit tracking to Shiny app
#'
#' Log session ID, username (only for Private apps), session start, end and
#' duration to a Google sheet.
#'
#' @param sheet_name Name for the sheet. Default is to use current package name.
#' @param columns Which columns to log, from id, username, login, logout and
#'  duration. By default login, logout and duration will be logged.
#' @param creds File used to store credentials. Defaults to `.google-sheets-credentials`.
#'
#' @return Nothing, used for side-effects only
#'
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
use_logging <- function(sheet_name = pkgload::pkg_name(),
                         columns = c("login", "logout", "duration"),
                         creds = ".google-sheets-credentials") {
  columns <- check_cols(columns)

  stopifnot(
    "set_user_tracking can run only in a Shiny app" = shiny::isRunning(),
    "set_user_tracking requires a Shiny session object to run" = exists(
      "session",
      parent.frame()
    )
  )

  session <- get("session", parent.frame())

  set_credentials(creds)

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
      subset(session$userData$tracking, select = columns),
      sheet_name
    )
  })
}
