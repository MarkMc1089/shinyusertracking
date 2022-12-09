
#' Add user tracking
#'
#' Log session ID, username (only for Private apps), session start, end and
#' duration to a Google sheet.
#'
#' @param google_email Email used for Google account username.
#' @param sheet_id Google sheet ID.
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
#'     "joe.bloggs@google.com",
#'     "1234567890987654321",
#'     session
#'   )
#' }
#'
#' shinyApp(ui, server)
#' }
#'
set_user_tracking <- function(google_email, sheet_id, session) {
  googlesheets4::gs4_auth(
    email = google_email,
    cache = ".secret/"
  )

  shiny::isolate({
    userdata <<- userdata <- data.frame( # Exclude Linting
      id = session$token,
      username = ifelse(is.null(session$user), "unknown", session$user),
      login = Sys.time(),
      logout = lubridate::NA_POSIXct_,
      duration = NA_character_
    )
  })

  session$onSessionEnded(function() {
    shiny::isolate({
      userdata[userdata$id == session$token, "logout"] <- Sys.time()
      userdata[userdata$id == session$token, "duration"] <- as.character(
        hms::hms(
          round(
            lubridate::as.period(
              userdata[userdata$id == session$token, "logout"] -
                userdata[userdata$id == session$token, "login"],
              "seconds"
            )
          )
        )
      )

      googlesheets4::sheet_append(sheet_id, userdata)
    })
  })

  invisible()
}
