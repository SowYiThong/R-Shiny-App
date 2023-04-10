library(shiny)

ui <- fluidPage(
  "Cumulative Paid Claims", 
  fileInput("upload", 
            label = "Upload one CSV or Excel file", 
            multiple = FALSE, 
            accept = c(".xlsx",".csv"), 
            buttonLabel = "Upload"),
  dataTableOutput("original_table"), 
  sliderInput("slider", 
              label = "Tail Factor:",
              min = 0,
              max = 2,
              value = 1.1,
              step = 0.1,),
  verbatimTextOutput("slider_output"), 
  dataTableOutput("results_table"), 
  plotOutput("cumulative_plot")

