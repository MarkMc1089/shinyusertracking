
# shinyusertracking

<!-- badges: start -->
[![Codecov test coverage](https://codecov.io/gh/MarkMc1089/shinyusertracking/branch/master/graph/badge.svg)](https://app.codecov.io/gh/MarkMc1089/shinyusertracking?branch=master)
[![R-CMD-check](https://github.com/MarkMc1089/shinyusertracking/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/MarkMc1089/shinyusertracking/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

`shinyusertracking` logs session ID, username (only for Private apps), session start, end and duration to a Google sheet.

## Installation

You can install `shinyusertracking` from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("nhsbsa-data-analytics/shinyusertracking")
```

## Example

Just add the function at the top of your `server` code. You will need to provide the ID of a Google Sheet and the username (email) of the Google account it is in.

``` r
library(shiny)

ui <- fluidPage()
  
server <- function(input, output, session) {
  shinyusertracking::set_user_tracking(
    "joe.bloggs@google.com",
    "1234567890987654321",
    session
  )
}

shinyApp(ui, server)
```
