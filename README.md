
# shinyusertracking

<!-- badges: start -->
[![R-CMD-check](https://github.com/MarkMc1089/shinyusertracking/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/MarkMc1089/shinyusertracking/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

`shinyusertracking` logs session ID, username (only for Private apps), session start, end and duration to a Google sheet.

## Installation

To install this package from GitHub, use the below code. Note that you must explicitly ask for vignettes to be built when installing from GitHub.

``` r
remotes::install_github("nhsbsa-data-analytics/shinyusertracking", build_vignettes = TRUE)
```

## Usage

Fields available for logging are:

Column|Description
:---:|:---: 
id|The Shiny session ID
username|The username of user, if available (`null` if app is public)
login|Timestamp of session start
logout|Timestamp of session end
duration|Duration of session in `hh:mm:ss` format

By default, `login`, `logout` and `duration` will be logged. Although `sessionid` and `username` are also available, these have potential to be treated as PII, so please ensure you meet any legal obligations if logging these.

For instructions on using check out the vignette by running

``` r
vignette("adding-logging-to-a-shiny-app", "shinyusertracking")
```

Note that 'visits' when running it locally in development will not be logged by default. You can force logging by setting `no_local = FALSE` (useful if you want to check logging is working as expected before deploying).

## Example

Once the necessary credentials are in place, and a Google sheet is ready to be logged to, just place a call to `use_logging()` at the top of your server function.

``` r
shinyusertracking::use_logging()
```

Using a minimal shiny app as an example it would look like

``` r
library(shiny)

ui <- fluidPage()
  
server <- function(input, output, session) {
  shinyusertracking::use_logging()
  
  # Rest of your server code
}

shinyApp(ui, server)
```
