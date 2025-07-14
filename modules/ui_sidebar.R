ui_sidebar <- sidebarPanel(
  h4("Parámetros del préstamo"),
  selectInput("escenarios", "¿Cuántos escenarios comparar?", choices = 1:2, selected = 1),
  textInput("monto_texto", "Monto del préstamo:", value = "100.000.000"),
  helpText("Valor total a financiar sin incluir comisión inicial."),
  numericInput("plazo", "Plazo (meses):", 60, min = 1, max = 360),
  numericInput("tasa", "Tasa anual inicial (%):", 12, step = 0.1),
  selectInput(
    inputId = "capitalizacion",
    label = "Capitalización de intereses:",
    choices = c(
      "Mensual" = 1,
      "Bimestral" = 2,
      "Trimestral" = 3,
      "Semestral" = 6
    ),
    selected = 1
  ),
  numericInput("seguro", "Seguro mensual (COP):", 0),
  numericInput("comision", "Comisión inicial (COP):", 0),
  tags$hr(),
  
  conditionalPanel(
    condition = "input.escenarios >= 2",
    tags$hr(),
    h4("Escenario 2"),
    textInput("monto2_texto", "Monto del préstamo:", value = "100.000.000"),
    numericInput("plazo2", "Plazo (meses):", 60),
    numericInput("tasa2", "Tasa anual inicial (%):", 14),
    radioButtons("tipo_tasa2", "Tipo de tasa:",
                 choices = c("Fija", "Variable (creciente 1% anual)")),
    numericInput("seguro2", "Seguro mensual (COP):", 0),
    numericInput("comision2", "Comisión inicial (COP):", 0)
  ),
  
  fileInput("archivo_abonos", "Cargar abonos por periodo (.csv opcional)", accept = ".csv"),
  helpText("Formato: columnas 'Periodo' y 'Abono'. Los abonos se suman al pago base."),
  actionButton("calcular", "Calcular", class = "btn-primary")
)
