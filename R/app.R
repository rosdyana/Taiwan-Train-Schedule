library(shiny)
library(shinyTime)
library(XML)
library(RCurl)
library(rlist)
library(stringr)

nortStation <- read.csv("north_stations.csv", sep = ",", header = TRUE)

ui <- fluidPage(
  titlePanel(span(
    tagList(icon("train"), "TRA Schedule"))),
  fluidRow(
    column(2,
           selectInput("from",
                       "From Station:",
                       nortStation$StationName,
                       selected = "Neili")
    ),
    column(2,
           selectInput("to",
                       "To Station:",
                       nortStation$StationName,
                       selected = "Taipei")
    ),
    column(2,
           selectInput("types",
                       "Train Types:",
                       c("All" = "2",
                         "Ordinary" = "1131,1132,1140",
                         "Express" = "1100,1101,1102,1107,1110,1120"))
    ),
    column(2,
           dateInput("date", "Date:", value = Sys.Date(), format = "yyyy/mm/dd")
    ),
    column(2,
           timeInput("time", "Time:", value = Sys.time(),seconds = FALSE)
    )
  ),

  fluidRow(
    actionButton("search", div(icon("train"), icon("search"), "Search")),
    DT::dataTableOutput("table")
  )
)

server <- function(input, output) {
  
  inputFrom <- reactive({
    if (input$search == 0) 
      return(NULL)
    pos = which(nortStation$StationName == input$from, arr.ind = T)
    paste0(nortStation$id[pos])
  })
  
  inputTo <- reactive({
    if (input$search == 0) 
      return(NULL)
    pos = which(nortStation$StationName == input$to, arr.ind = T)
    paste0(nortStation$id[pos])
  })
  
  inputTime <- reactive({
    if (input$search == 0) 
      return(NULL)
    c = strftime(input$time, "%R")
    paste0(str_replace(c, ":", ""))
  })
  
  inputDate <- reactive({
    if (input$search == 0) 
      return(NULL)
    paste0(strftime(input$date, "%Y/%m/%d"))
  })
  
  output$table <- DT::renderDataTable(DT::datatable({
    if (input$search == 0) 
      return(NULL)
    m_url = paste("http://twtraffic.tra.gov.tw/twrail/PrintResult.aspx?printtype=1&searchdate=", 
                  inputDate(), "&fromstation=", inputFrom(), "&tostation=", inputTo(), 
                  "&trainclass=", input$types, "&timetype=1&fromtime=", inputTime(), 
                  "&totime=2359&language=eng", sep = "")
    theurl = getURL(m_url, .opts = list(ssl.verifypeer = FALSE))
    tables = readHTMLTable(theurl)
    tables = list.clean(tables, fun = is.null, recursive = FALSE)
    n.rows = unlist(lapply(tables, function(t) dim(t)[1]))
    result = data.frame(tables[which.max(n.rows)])
    finalResult = data.frame(TrainType = result$QuickSearchDataList.Train.Type, 
                             Code = result$QuickSearchDataList.Train.Code, Destination = result$QuickSearchDataList.Origin.Dest, 
                             Departure = result$QuickSearchDataList.Departure, Arrival = result$QuickSearchDataList.Arrival, 
                             Duration = result$QuickSearchDataList.Estimate.Time)
    finalResult
    
  }))

}

shinyApp(ui = ui , server = server)
