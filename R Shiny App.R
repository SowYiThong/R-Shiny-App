library(shiny)
library(readxl)
library(ggplot2)
library(reshape2)
library(dplyr)
library(magrittr)

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
)

server <- function(input, output, session) {
  
  uploaded_file <- reactive({
    req(input$upload)
    file <- input$upload$datapath
    if (grepl(".csv", input$upload$name)) {
      read.csv(file, stringsAsFactors = FALSE)
    } else if (grepl(".xlsx", input$upload$name)) {
      read_excel(file)
    }
  })
  
  output$original_table <- renderDataTable({
    uploaded_file()
  })
  
  output$slider_output <- renderPrint({
    input$slider
  })
  
  results <- reactive({
    results_table <- data.frame(
      Loss_Year = unique(uploaded_file()$Loss_Year), 
      stringsAsFactors = FALSE)
    
    for (i in 1:nrow(results_table)) {
      lossyear <- results_table$Loss_Year[i]
      Dev1 <- sum(uploaded_file()$Amount_of_Claims_Paid[        
        uploaded_file()$Loss_Year == lossyear &          
          uploaded_file()$Development_Year == 1])
      Dev2 <- sum(uploaded_file()$Amount_of_Claims_Paid[        
        uploaded_file()$Loss_Year == lossyear &          
          uploaded_file()$Development_Year %in% c(1, 2)])
      Dev3 <- sum(uploaded_file()$Amount_of_Claims_Paid[        
        uploaded_file()$Loss_Year == lossyear &          
          uploaded_file()$Development_Year %in% c(1, 2, 3)])
      Dev4 <- sum(uploaded_file()$Amount_of_Claims_Paid[        
        uploaded_file()$Loss_Year == lossyear &          
          uploaded_file()$Development_Year %in% c(1, 2, 3, 4)])
      
      results_table[i, c("1", "2", "3", "4")] = c(Dev1, Dev2, Dev3, Dev4)
      
      results_table[nrow(results_table), 3] <- round(
        results_table[nrow(results_table), 2] * (
          sum(results_table[1:nrow(results_table) - 1, 3]) / 
            sum(results_table[1:nrow(results_table) - 1, 2])), 2)
      
      results_table[i, ncol(results_table) - 1] <- round(
        results_table[i, ncol(results_table) - 2] * (
          results_table[1, ncol(results_table) - 1] / 
            results_table[1, ncol(results_table) - 2]), 2)
      
      tail_factor <- input$slider 
      
      results_table[i, ncol(results_table)] <- round(results_table[
        i, ncol(results_table) - 1] * tail_factor, 2)  
    }
    
    return(results_table)
    
  })
  
  output$results_table <- renderDataTable({
    results()
  })
  
  cumulative_paid_claims <- reactive({
    df <- results()
    df_plot <- reshape2::melt(df, id.vars = "Loss_Year",
                              measure.vars = c("1", "2", "3", "4"))
    df_plot$Development_Year <- as.numeric(gsub("X", "", df_plot$variable))
    df_plot$cumulative_paid_claims <- ave(df_plot$value, df_plot$Loss_Year, 
                                          df_plot$Development_Year,
                                          FUN = cumsum)
    df_plot$point_label <- ifelse(df_plot$Development_Year %in% c(1, 2, 3, 4),
                                  df_plot$cumulative_paid_claims, NA)
    return(df_plot)
  })
  
  output$cumulative_plot <- renderPlot({
    ggplot(data = cumulative_paid_claims(), aes(x = Development_Year,
                                                y = cumulative_paid_claims,
                                                colour = factor(Loss_Year))) +
      geom_line(size = 1) + 
      geom_point(size = 2) + 
      geom_text(aes(label = point_label),
                size = 3, vjust = -1) +
      labs(x = "Development Year", y = "Cumulative Paid Claims ($)",
           title = "Cumulative Paid Claims") +
      scale_colour_discrete(name = "Loss Year")
  })
  
}

shinyApp(ui, server)

