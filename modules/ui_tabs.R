ui_tabs <- mainPanel(
  tabsetPanel(
    tabPanel("Tabla de amortización",
             dataTableOutput("tabla")
    ),
    
    tabPanel("KPIs",icon = icon("chart-bar"),
             fluidRow(
               column(4, div(class = "card bg-primary text-white p-3 mb-3 shadow-sm rounded",
                             h5("💰 Cuota"),
                             h3(textOutput("cuota_kpi"))
               )),
               column(4, div(class = "card bg-success text-white p-3 mb-3 shadow-sm rounded",
                             h5("💸 Total pagado"),
                             h3(textOutput("pagado_kpi"))
               )),
               column(4, div(class = "card bg-danger text-white p-3 mb-3 shadow-sm rounded",
                             h5("📉 Intereses"),
                             h3(textOutput("intereses_kpi"))
               ))
             ),
             fluidRow(
               column(4, div(class = "card bg-warning text-dark p-3 mb-3 shadow-sm rounded",
                             h5("📊 % Interés"),
                             h3(textOutput("porcentaje_kpi"))
               )),
               column(4, div(class = "card bg-info text-white p-3 mb-3 shadow-sm rounded",
                             h5("🏦 CTC"),
                             h3(textOutput("ctc_kpi"))
               )),
               column(4, div(class = "card bg-secondary text-white p-3 mb-3 shadow-sm rounded",
                             h5("📈 TEA"),
                             h3(textOutput("tea_kpi"))
               ))
             )
    ),
    
    tabPanel("Comparación de escenarios",
             conditionalPanel(
               condition = "input.escenarios >= 2",
               fluidRow(
                 column(6, h4("Escenario 1"), tableOutput("tabla_kpi_1")),
                 column(6, h4("Escenario 2"), tableOutput("tabla_kpi_2"))
               ),
               br(),
               h4("Comparación gráfica de cuota total"),
               plotOutput("grafico_comp", height = "300px")
             )
    ),
    
    tabPanel("Gráfico de pagos",
             plotOutput("grafico_pagos", height = "1500px")
    ),
    
    tabPanel("Saldo restante",
             plotOutput("grafico_saldo", height = "400px")
    ),
    
    tabPanel("Totales comparados",
             plotOutput("grafico_totales", height = "500px")
    ),
    
    tabPanel("Visualizaciones avanzadas",icon("chart-area"),
             tabsetPanel(
               tabPanel("Curva acumulada",
                        plotOutput("curva_acumulada", height = "400px")
               )
             )
    ),
    
    tabPanel("Inteligencia del préstamo",icon = icon("lightbulb"),
             fluidRow(
               column(12,
                      uiOutput("alertas_inteligentes")
               )
             )
    )
  ),
  br(),
  fluidRow(
    #column(6, downloadButton("descargar", "Descargar CSV")),
    column(6, downloadButton("descargar_excel", label = tagList(
      icon("file-excel"), "Descargar Excel"
    ), class = "btn btn-success btn-lg shadow-sm")
  ),
  
  downloadButton("descargar_html", "Reporte HTML Completo")
)
)
