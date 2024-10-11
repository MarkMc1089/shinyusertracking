
# shinyusertracking

<!-- badges: start -->
[![R-CMD-check](https://github.com/MarkMc1089/shinyusertracking/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/MarkMc1089/shinyusertracking/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

`shinyusertracking` logs session ID, username (only for Private apps), session start, end and duration to a Google sheet.

## Installation

You can install `shinyusertracking` from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("nhsbsa-data-analytics/shinyusertracking")
```

## Usage

Column|Description
:---:|:---: 
id|The Shiny session ID
username|The username of user, if available (`null` if app is public)
login|Timestamp of session start
logout|Timestamp of session end
duration|Duration of session in `hh:mm:ss` format

1. Create a new Google sheet, with column headers corresponding to the columns you will be recording (they can be named differently to the columns given if you want).
2. Copy the contents of the file `.google-sheets-credentials.example` in this repo to a file named `.google-sheets-credentials` in the root directory of your app.
3. IMPORTANT: You must tell git to ignore this! `usethis::use_git_ignore(".google-sheets-credentials")`.
4. IMPORTANT: While you are at it, also `usethis::use_git_ignore(".secret/")`. This is the directory in which the Google authorisation secret will be stored.
5. Replace the example for `GOOGLE_SHEET_ID` with the ID of the Google sheet. You can find this in the URL. For example, if the URL is `https://docs.google.com/spreadsheets/d/1vwrKiwX4T_-A2IldWnjcd1PHlCDsGAq9U-yTtQ6tgzk/edit?gid=0#gid=0`, the ID is `1vwrKiwX4T_-A2IldWnjcd1PHlCDsGAq9U-yTtQ6tgzk`.
6. Replace the example for `GOOGLE_SHEET_USER` with the Google account username.
7. Add the code at the top of your `server` function.
8. Ensure you bundle both the `.google-sheets-credentials` file and the `.secret` directory when your app is deployed.

## Example

``` r
library(shiny)

ui <- fluidPage()
  
server <- function(input, output, session) {
  shinyusertracking::set_user_tracking(
    session
  )
}

shinyApp(ui, server)
```

Optionally, you can choose to log specific columns only.

``` r
shinyusertracking::set_user_tracking(
  columns = c("login", "logout", "duration"),
  session
)   
```
