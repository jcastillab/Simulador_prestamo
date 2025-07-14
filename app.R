library(shiny)
library(bslib)
library(shiny)
library(bslib)
library(htmltools)
library(ggplot2)
library(dplyr)
library(scales)
library(DT)
library(reshape2)
library(openxlsx)
library(rmarkdown)
library(rhandsontable)
library(thematic)
library(ragg)
library(shinyWidgets)
library(shinyBS)

source("global.R")
source("modules/ui_sidebar.R")
source("modules/ui_tabs.R")
source("modules/server_logic.R")


ui <- fluidPage(
  theme = bs_theme(
    version = 5,
    bootswatch = "yeti", # Otros: "cerulean", "lux", "yeti", "minty"
    base_font = font_google("Roboto"),
    heading_font = font_google("Poppins"),
    primary = "#2980b9",
    success = "#27ae60",
    warning = "#f39c12"
  ),
  
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
    tags$style(HTML("
  input.form-control, select.form-control {
    border-radius: 8px;
  }
"))
  ),
  
  div(class = "theme-selector",
      radioButtons("tema", NULL,
                   choices = c("Claro", "Oscuro"),
                   selected = "Claro",
                   inline = TRUE)
  ),
  titlePanel("Simulador de Préstamos"),
  sidebarLayout(
    ui_sidebar,
    ui_tabs
  )
)
server <- function(input, output, session) {
  server_logic(input, output, session)
  observe({
    new_theme <- if (input$tema == "Oscuro") {
      bs_theme(bootswatch = "darkly", version = 5)
    } else {
      bs_theme(bootswatch = "flatly", version = 5)
    }
    session$setCurrentTheme(new_theme)
  })
}


shinyApp(ui, server)

