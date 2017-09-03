# TRA Schedule
# Developer : Ros (rosdyana.kusuma@gmail.com)
# https://github.com/rosdyana/Taiwan-Train-Schedule


library(shiny)
library(shinyTime)
library(XML)
library(RCurl)
library(rlist)
library(stringr)
library(dplyr)
library(leaflet)

northStation = read.csv("north_stations.csv", sep = ",", header = TRUE)
southStation = read.csv("south_stations.csv", sep = ",", header = TRUE)
middleStation = read.csv("middle_stations.csv", sep = ",", header = TRUE)
# merge data
dataPart1 = merge(northStation, southStation, all = TRUE)
fullData <- merge(dataPart1, middleStation, all = TRUE)

ui <- fluidPage(
  headerPanel("TRA Schedule", title = span(tagList(
    icon("train"), "TRA Schedule"
  ))),
  fluidRow(
    column(
      2,
      selectInput(
        "from",
        "From Station:",
        list(
          "North Bound" = northStation$StationName,
          "Middle Bound" = middleStation$StationName,
          "South Bound" = southStation$StationName
        ),
        selected = "Neili"
      )
    ),
    column(2,
           selectInput(
             "to",
             "To Station:",
             list(
               "North Bound" = northStation$StationName,
               "Middle Bound" = middleStation$StationName,
               "South Bound" = southStation$StationName
             ),
             selected = "Taipei"
           )),
    column(
      2,
      dateInput("date", "Date:", value = Sys.Date(), format = "yyyy/mm/dd")
    ),
    column(2,
           timeInput(
             "time", "Time:", value = Sys.time(), seconds = FALSE
           ))
  ),
  
  fluidRow(
    column(2,
           actionButton("search", div(
             icon("train"), icon("search"), "Search"
           ))),
    column(
      1,
      actionButton(
        "github",
        "Github",
        icon = icon("github"),
        onclick = "window.open('https://github.com/rosdyana/Taiwan-Train-Schedule', '_blank')"
      )
    ),
    column(1,
           actionButton("about",
                        "About",
                        icon = icon("user")))
  ),
  br(),
  tabsetPanel(
    tabPanel("One Way", DT::dataTableOutput("table")),
    tabPanel("Return", DT::dataTableOutput("table1")),
    tabPanel("Map", leafletOutput("mymap"))
  )
)

server <- function(input, output) {
  inputFrom <- reactive({
    if (input$search == 0)
      return(NULL)
    pos = which(fullData$StationName == input$from, arr.ind = T)
    paste0(fullData$id[pos])
  })
  
  inputTo <- reactive({
    if (input$search == 0)
      return(NULL)
    pos = which(fullData$StationName == input$to, arr.ind = T)
    paste0(fullData$id[pos])
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
  
  getData <- function(x, from, to) {
    m_url = paste(
      "http://twtraffic.tra.gov.tw/twrail/PrintResult.aspx?printtype=1&searchdate=",
      inputDate(),
      "&fromstation=",
      from,
      "&tostation=",
      to,
      "&trainclass=2&timetype=1&fromtime=",
      inputTime(),
      "&totime=2359&language=eng",
      sep = ""
    )
    theurl = getURL(m_url, .opts = list(ssl.verifypeer = FALSE))
    tables = readHTMLTable(theurl)
    tables = list.clean(tables, fun = is.null, recursive = FALSE)
    n.rows = unlist(lapply(tables, function(t)
      dim(t)[1]))
    result = data.frame(tables[which.max(n.rows)])
    finalResult = data.frame(
      Train.Type = result$QuickSearchDataList.Train.Type,
      Train.Code = result$QuickSearchDataList.Train.Code,
      Origin.Destination = result$QuickSearchDataList.Origin.Dest,
      Departure = result$QuickSearchDataList.Departure,
      Arrival = result$QuickSearchDataList.Arrival,
      Duration = result$QuickSearchDataList.Estimate.Time
    )
    # attach(finalResult)
    # expressData1 <- finalResult[ which(Train.Type=='Chu-Kuang Express'),]
    # expressData2 <- finalResult[ which(Train.Type=='Tze-Chiang Limited Express'),]
    # expressData3 <- finalResult[ which(Train.Type=='Puyuma'),]
    # expressData4 <- finalResult[ which(Train.Type=='Taroko'),]
    # expressData5 <- finalResult[ which(Train.Type=='Fu-Hsing Semi Express'),]
    # ordinaryData <- finalResult[ which(Train.Type=='Local Train'),]
    # detach(finalResult)
    # expressData <- Reduce(function(x, y) merge(x, y, all=TRUE), list(expressData1, expressData2,
    #                                                                  expressData3,expressData4,
    #                                                                  expressData5))
    
    #if(x=='all') return(finalResult)
    # if(x=='express') {
    #   finalResult %>% select(Train.Type, Train.Code, Origin.Destination, Departure, Arrival, Duration) %>% filter(Train.Type != "Local Train")
    # }
    # if(x=='ordinary') {
    #   finalResult %>% select(Train.Type, Train.Code, Origin.Destination, Departure, Arrival, Duration) %>% filter(Train.Type == "Local Train")
    # }
    # data <- finalResult
  }
  
  output$table <- DT::renderDataTable(DT::datatable({
    if (input$search == 0)
      return(NULL)
    getData('all', inputFrom(), inputTo())
  }))
  
  output$table1 <- DT::renderDataTable(DT::datatable({
    if (input$search == 0)
      return(NULL)
    getData('all', inputTo(), inputFrom())
  }))
  
  # output$table1 <- DT::renderDataTable(DT::datatable({
  #   if (input$search == 0)
  #     return(NULL)
  #   getData('express')
  # }))
  #
  # output$table2 <- DT::renderDataTable(DT::datatable({
  #   if (input$search == 0)
  #     return(NULL)
  #   getData('ordinary')
  # }))
  
  output$mymap <- renderLeaflet({
    if (input$search == 0)
      return(NULL)
    leaflet() %>%
      addTiles() %>%
      addMarkers(lng = 121.564445,
                 lat = 25.034190,
                 popup = '<a href="http://www.taipei-101.com.tw/en/index.aspx">TAIPEI 101</a>') %>%
      addMarkers(lng = 121.548834,
                 lat = 25.104165,
                 popup = '<a href="https://www.npm.edu.tw/en/">National Palace Museum</a>') %>%
      addMarkers(lng = 121.540511,
                 lat = 25.017321,
                 popup = '<a href="http://www.ntu.edu.tw/english/index.html">National Taiwan University</a>')
    
  })
  
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
