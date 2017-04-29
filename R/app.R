# TRA Schedule
# Developer : Ros (rosdyana.kusuma@gmail.com)
# https://github.com/rosdyana/Taiwan-Train-Schedule


library(shiny)
library(shinyTime)
library(XML)
library(RCurl)
library(rlist)
library(stringr)
library(plyr)

northStation = read.csv("north_stations.csv", sep = ",", header = TRUE)
southStation = read.csv("south_stations.csv", sep = ",", header = TRUE)
middleStation = read.csv("middle_stations.csv", sep = ",", header = TRUE)
# to-do merge to fulldata


ui <- fluidPage(
  headerPanel("TRA Schedule", title = span(
    tagList(icon("train"), "TRA Schedule")
  )),
  fluidRow(
    column(2,
           selectInput("from",
                       "From Station:",
                       northStation$StationName,
                       selected = "Neili")
    ),
    column(2,
           selectInput("to",
                       "To Station:",
                       northStation$StationName,
                       selected = "Taipei")
    ),
    column(2,
           dateInput("date", "Date:", value = Sys.Date(), format = "yyyy/mm/dd")
    ),
    column(2,
           timeInput("time", "Time:", value = Sys.time(),seconds = FALSE)
    )
  ),

  fluidRow(
    column(2,
           actionButton("search", div(icon("train"), icon("search"), "Search"))
    ),
    column(1,
           actionButton(
             "github",
             "Github",
             icon = icon("github"),
             onclick = "window.open('https://github.com/rosdyana/Taiwan-Train-Schedule', '_blank')"
           )
    ),
    column(1,
           actionButton(
             "about",
             "About",
             icon = icon("user")
           )
    )
  ),
  br(),
  tabsetPanel(
    tabPanel("All", DT::dataTableOutput("table")),
    tabPanel("Express", plotOutput("table1")),
    tabPanel("Ordinary", plotOutput("table2"))
  )
)

server <- function(input, output) {
  inputFrom <- reactive({
    if (input$search == 0) 
      return(NULL)
    pos = which(northStation$StationName == input$from, arr.ind = T)
    paste0(northStation$id[pos])
  })
  
  inputTo <- reactive({
    if (input$search == 0) 
      return(NULL)
    pos = which(northStation$StationName == input$to, arr.ind = T)
    paste0(northStation$id[pos])
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
  
  getData <- function(x){
    m_url = paste("http://twtraffic.tra.gov.tw/twrail/PrintResult.aspx?printtype=1&searchdate=", 
                  inputDate(), "&fromstation=", inputFrom(), "&tostation=", inputTo(), 
                  "&trainclass=2&timetype=1&fromtime=", inputTime(), 
                  "&totime=2359&language=eng", sep = "")
    theurl = getURL(m_url, .opts = list(ssl.verifypeer = FALSE))
    tables = readHTMLTable(theurl)
    tables = list.clean(tables, fun = is.null, recursive = FALSE)
    n.rows = unlist(lapply(tables, function(t) dim(t)[1]))
    result = data.frame(tables[which.max(n.rows)])
    finalResult = data.frame("Train Type" = result$QuickSearchDataList.Train.Type, 
                             "Train Code" = result$QuickSearchDataList.Train.Code, "Origin.Destination" = result$QuickSearchDataList.Origin.Dest, 
                             Departure = result$QuickSearchDataList.Departure, Arrival = result$QuickSearchDataList.Arrival, 
                             Duration = result$QuickSearchDataList.Estimate.Time)
    attach(finalResult)
    expressData <- finalResult[ which(Train.Type=='Chu-Kuang Express' || Train.Type=='Tze-Chiang Limited Express' ||
                                        Train.Type=='Puyuma' || Train.Type=='Taroko'),]
    ordinaryData <- finalResult[ which(Train.Type=='Local Train'),]
    detach(finalResult)
    
    if(x=='all') return(finalResult)
    if(x=='express') return(expressData)
    if(x=='ordinary') return(ordinaryData)
  }
  
  output$table <- DT::renderDataTable(DT::datatable({
    if (input$search == 0) 
      return(NULL)
    getData('all')
  }))
  
  output$table1 <- DT::renderDataTable(DT::datatable({
    if (input$search == 0) 
      return(NULL)
    h2("atatatat")
  }))
  
  output$table2 <- DT::renderDataTable(DT::datatable({
    if (input$search == 0) 
      return(NULL)
    getData('ordinary')
  }))
  observeEvent(input$about, {
    showModal(modalDialog(
      title = span(tagList(icon("info-circle"), "About")),
      tags$div(
        HTML(
          "<img src='https://avatars1.githubusercontent.com/u/4516635?v=3&s=460' width=150><br/><br/>",
          "<p>Developer : Rosdyana Kusuma</br>Email : <a href=mailto:rosdyana.kusuma@gmail.com>rosdyana.kusuma@gmail.com</a></br>linkedin : <a href='https://www.linkedin.com/in/rosdyanakusuma/' target=blank>Open me</a></p>"
        )
      ),
      easyClose = TRUE
    ))
  })

}

shinyApp(ui = ui , server = server)


