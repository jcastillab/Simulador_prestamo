server_logic <- function(input, output, session) {
  valores <- reactiveValues(kpis = NULL, kpis2 = NULL, tabla = NULL, tabla2 = NULL)
  
  abonos_csv <- reactiveVal(NULL)
  
  observeEvent(input$archivo_abonos, {
    df <- tryCatch(read.csv(input$archivo_abonos$datapath), error = function(e) NULL)
    
    if (!is.null(df) && all(c("Periodo", "Abono") %in% names(df))) {
      abonos_csv(df)
    } else {
      showModal(modalDialog(
        title = "Error en el archivo",
        "El archivo debe contener las columnas 'Periodo' y 'Abono'.",
        easyClose = TRUE
      ))
    }
  })
  
  
  observeEvent(input$calcular, {
    # Monto procesado desde textInput
    monto1 <- as.numeric(gsub("\\.", "", input$monto_texto))
    monto2 <- as.numeric(gsub("\\.", "", input$monto2_texto))
    plazo_meses <- input$plazo
    cap_meses <- as.numeric(input$capitalizacion)
    tasa_anual <- input$tasa / 100
    
    # Tasa efectiva por período de capitalización
    tasa_periodo <- (1 + tasa_anual)^(cap_meses / 12) - 1
    
    # Número total de pagos
    num_pagos <- floor(plazo_meses / cap_meses)
    
    if (!is.null(input$archivo_tasas)) {
      tasas_data <- read.csv(input$archivo_tasas$datapath)
      
      # Extrae la primera columna como vector de tasas en proporción (no porcentaje)
      tasa_vector <- tasas_data[[1]] / 100
      
      # Verificación contra el número de pagos reales
      if (length(tasa_vector) != num_pagos) {
        showModal(modalDialog(
          title = "Advertencia",
          paste0("La cantidad de tasas en el archivo (", length(tasa_vector), 
                 ") no coincide con el número de pagos esperados (", num_pagos, ")."),
          easyClose = TRUE
        ))
        return()
      }
    } else {
      # Genera un vector constante con la tasa efectiva por período
      tasa_vector <- rep(tasa_periodo, num_pagos)
    }
    
    # Calcular tabla para escenario 1
    tabla <- tabla <- generar_amortizacion_cap(
      monto = monto1,
      tasa = tasa_periodo,
      pagos = num_pagos,
      frecuencia = cap_meses,
      seguro = input$seguro,
      comision = input$comision,
      abonos_df =abonos_csv()
    )
    valores$tabla <- tabla
    valores$kpis <- calcular_kpis(tabla)
    
    # Escenario 2 si aplica
    if (input$escenarios >= 2) {
      tasa_anual2 <- input$tasa2 / 100
      plazo2 <- input$plazo2
      
      tasa_cap2 <- (1 + tasa_anual2)^(1 / (12 / cap_meses)) - 1
      tasa_base2 <- (1 + tasa_cap2)^(1 / cap_meses) - 1
      
      tasa_vector2 <- tasa_vector2 <- rep(tasa_base2, floor(plazo2 / cap_meses))
      
      tabla2 <- generar_amortizacion_cap(
        monto = monto2,
        tasa = tasa_base2,
        pagos = floor(plazo2 / cap_meses),  # Ajusta también a periodo de capitalización
        frecuencia = cap_meses,
        seguro = input$seguro2,
        comision = input$comision2
      )
      valores$tabla2 <- tabla2
      valores$kpis2 <- calcular_kpis(tabla2)
    }
    
    output$tabla <- renderDataTable({
      tabla_formateada <- valores$tabla
      numeric_cols <- c("Cuota", "Interes", "Abono", "Saldo")
      
      # Aplicar formato con scales::comma a cada columna
      for (col in numeric_cols) {
        tabla_formateada[[col]] <- scales::comma(tabla_formateada[[col]])
      }
      
      DT::datatable(
        tabla_formateada,
        rownames = FALSE,
        class = 'table table-striped table-hover table-bordered',
        options = list(
          pageLength = 12,
          lengthChange = FALSE,
          dom = 'tp'
        )
      )
    })
    
    output$tabla_kpi_1 <- renderTable({
      data.frame(
        Indicador = c("Cuota", "Total pagado", "Intereses", "% Interés", "CTC", "TEA"),
        Valor = c(
          scales::comma(valores$kpis$cuota),
          scales::comma(valores$kpis$pagado),
          scales::comma(valores$kpis$interes),
          paste0(valores$kpis$porcentaje, "%"),
          valores$kpis$ctc,
          paste0(valores$kpis$tea, "%")
        )
      )
    })
    
    output$tabla_kpi_2 <- renderTable({
      if (input$escenarios < 2 || is.null(valores$kpis2)) return(NULL)
      data.frame(
        Indicador = c("Cuota", "Total pagado", "Intereses", "% Interés", "CTC", "TEA"),
        Valor = c(
          scales::comma(valores$kpis2$cuota),
          scales::comma(valores$kpis2$pagado),
          scales::comma(valores$kpis2$interes),
          paste0(valores$kpis2$porcentaje, "%"),
          valores$kpis2$ctc,
          paste0(valores$kpis2$tea, "%")
        )
      )
    })
    
    output$grafico_comp <- renderPlot({
      if (input$escenarios < 2 || is.null(valores$kpis2)) return(NULL)
      df <- data.frame(
        Escenario = c("Escenario 1", "Escenario 2"),
        Total_pagado = c(valores$kpis$pagado, valores$kpis2$pagado)
      )
      ggplot(df, aes(x = Escenario, y = Total_pagado, fill = Escenario)) +
        geom_col(width = 0.5) +
        scale_y_continuous(labels = scales::comma) +
        scale_fill_manual(values = c("#2980b9", "#e67e22")) +
        labs(title = "Total pagado por escenario", y = "Valor total") +
        theme_minimal()
    })
    
    output$cuota_kpi <- renderText({ scales::comma(valores$kpis$cuota) })
    output$pagado_kpi <- renderText({ scales::comma(valores$kpis$pagado) })
    output$intereses_kpi <- renderText({ scales::comma(valores$kpis$interes) })
    output$porcentaje_kpi <- renderText({ paste0(valores$kpis$porcentaje, " %") })
    output$ctc_kpi <- renderText({ valores$kpis$ctc })
    output$tea_kpi <- renderText({ paste0(valores$kpis$tea, " %") })
    
    output$grafico_pagos <- renderPlot({
      req(valores$tabla)
      x_label <- switch(as.character(input$capitalizacion),
                        "1" = "Mes",
                        "2" = "Bimestre",
                        "3" = "Trimestre",
                        "6" = "Semestre",
                        "Periodo")
      n_periodos <- nrow(valores$tabla)
      df_long <- reshape2::melt(valores$tabla, id.vars = "Pago", measure.vars = c("Interes", "Abono", "AbonoExtra"))
      df_long$Pago <- factor(df_long$Pago, levels = rev(unique(df_long$Pago)))
      
      ggplot(df_long, aes(x = Pago, y = value, fill = variable)) +
        geom_bar(stat = "identity",color="black") +
        geom_text(aes(label = paste0("$", scales::comma(value))),
                  position = position_stack(vjust = 0.5),
                  size = 4, color = "black") +
        coord_flip() +
        labs(
          title = "Distribución del pago: Interés vs Abono vs Extra",
          y = "Valor del pago", x = x_label, fill = "Componente"
        ) +
        scale_y_continuous(labels = scales::comma) +
        scale_fill_manual(values = c(
          "Interes" = "#FF6B6B",
          "Abono" = "#4ECDC4",
          "AbonoExtra" = "#3498db"
        )) +
        theme_minimal() +
        theme(plot.title = element_text(face = "bold"),
              axis.text.x = element_text(size=15),
              axis.text.y = element_text(size=15),
              legend.title = element_text(size = 14, face = "bold"),
              legend.text = element_text(size = 12))
    })
    
    output$grafico_saldo <- renderPlot({
      req(valores$tabla)
      x_label <- switch(as.character(input$capitalizacion),
                        "1" = "Mes",
                        "2" = "Bimestre",
                        "3" = "Trimestre",
                        "6" = "Semestre",
                        "Periodo")
      n_periodos <- nrow(valores$tabla)
      ggplot(valores$tabla, aes(x = Pago, y = Saldo)) +
        geom_line(color = "#2980b9", size = 1.2) +
        labs(title = "Evolución del saldo restante",
             y = "Saldo",
             x = x_label) +
        scale_y_continuous(labels = scales::comma,
                           breaks = pretty(valores$tabla$Saldo)) +
        scale_x_continuous(
          breaks = pretty(1:n_periodos),
          labels = scales::number_format(accuracy = 1)
        )+
        theme_minimal(base_size = 14) +
        theme(plot.title = element_text(face = "bold"))
    })
    
    output$grafico_totales <- renderPlot({
      df_tot <- data.frame(
        Componente = c("Intereses", "Abono a capital"),
        Total = c(sum(valores$tabla$Interes), sum(valores$tabla$Abono))
      )
      ggplot(df_tot, aes(x = Componente, y = Total, fill = Componente)) +
        geom_col(width = 0.5,color="black") +
        geom_text(aes(label = scales::comma(Total)), vjust = -0.5, size = 4) +
        labs(title = "Totales pagados por componente", y = "Total") +
        scale_y_continuous(labels = scales::comma) +
        scale_fill_manual(values = c("Intereses" = "#FF6B6B", "Abono a capital" = "#4ECDC4")) +
        theme_minimal(base_size = 14) +
        theme(plot.title = element_text(face = "bold"))
    })
    
    output$descargar <- downloadHandler(
      filename = function() { paste0("amortizacion_", Sys.Date(), ".csv") },
      content = function(file) {
        write.csv(valores$tabla, file, row.names = FALSE)
      }
    )
    
    
    output$curva_acumulada <- renderPlot({
      req(valores$tabla)
      tabla_cum <- valores$tabla
      tabla_cum$InteresAcum <- cumsum(tabla_cum$Interes)
      tabla_cum$AbonoAcum <- cumsum(tabla_cum$Abono)
      
      
      x_label <- switch(as.character(input$capitalizacion),
                        "1" = "Mes",
                        "2" = "Bimestre",
                        "3" = "Trimestre",
                        "6" = "Semestre",
                        "Periodo")
      n_periodos <- nrow(tabla_cum)
      
      ggplot(tabla_cum, aes(x = Pago)) +
        geom_line(aes(y = InteresAcum, color = "Intereses"), size = 1.2) +
        geom_line(aes(y = AbonoAcum, color = "Abono a capital"), size = 1.2) +
        scale_color_manual(values = c("Intereses" = "#e74c3c", "Abono a capital" = "#27ae60")) +
        scale_y_continuous(labels = scales::comma) +
        scale_x_continuous(
          breaks = pretty(1:n_periodos),
          labels = scales::number_format(accuracy = 1)
        )+
        labs(title = "Evolución acumulada del préstamo",
             y = "Monto acumulado", color = "Componente",
             x=x_label) +
        theme_minimal()
    })
    
    output$alertas_inteligentes <- renderUI({
      req(valores$kpis)
      
      mensajes <- list()
      
      if (valores$kpis$porcentaje > 40) {
        mensajes <- append(mensajes, list(
          div(class = "alert alert-danger",
              strong("⚠️ Atención: "),
              "Más del 40% del total pagado corresponde a intereses. Este préstamo puede no ser eficiente.")
        ))
      } else if (valores$kpis$porcentaje > 25) {
        mensajes <- append(mensajes, list(
          div(class = "alert alert-warning",
              strong("🔎 Observación: "),
              "Los intereses representan más del 25% del total. Evalúa si puedes mejorar condiciones.")
        ))
      } else {
        mensajes <- append(mensajes, list(
          div(class = "alert alert-success",
              strong("✅ Buen dato: "),
              "Los intereses representan menos del 25% del total. Es un préstamo razonable.")
        ))
      }
      
      if (valores$kpis$ctc > 1.5) {
        mensajes <- append(mensajes, list(
          div(class = "alert alert-warning",
              strong("💸 Costo elevado: "),
              paste0("El Costo Total del Crédito (CTC) es ", valores$kpis$ctc,
                     ", lo que indica una carga financiera significativa."))
        ))
      }
      
      mensajes <- append(mensajes, list(
        div(class = "alert alert-info",
            strong("💡 Tip: "),
            "Intenta reducir el plazo o hacer un abono extra para ahorrar intereses.")
      ))
      
      do.call(tagList, mensajes)
    })
    
    output$descargar_excel <- downloadHandler(
      filename = function() {
        paste0("simulacion_prestamo_", Sys.Date(), ".xlsx")
      },
      content = function(file) {
        wb <- createWorkbook()
        addWorksheet(wb, "Amortización")
        
        tabla_xlsx <- valores$tabla
        # Formato moneda para columnas relevantes
        dinero_cols <- c("Cuota", "Interes", "Abono", "Saldo")
        for (col in dinero_cols) {
          tabla_xlsx[[col]] <- round(tabla_xlsx[[col]], 2)
        }
        
        writeDataTable(wb, "Amortización", tabla_xlsx, withFilter = TRUE)
        
        # Formato
        dollar_style <- createStyle(numFmt = "COP #,##0")
        addStyle(wb, "Amortización", dollar_style, cols = 2:5, rows = 2:(nrow(tabla_xlsx)+1), gridExpand = TRUE)
        
        saveWorkbook(wb, file, overwrite = TRUE)
      }
    )
    
    output$tabla_tasas_manual <- renderRHandsontable({
      req(input$usar_tasas_manual)
      rhandsontable(tasas_df(), rowHeaders = NULL)
    })
    
    output$descargar_html <- downloadHandler(
      filename = function() {
        paste0("reporte_prestamo_", Sys.Date(), ".html")
      },
      content = function(file) {
        # Copia tu plantilla a un archivo temporal
        tempReport <- tempfile(fileext = ".Rmd")
        file.copy("reporte/plantilla.Rmd", tempReport, overwrite = TRUE)
        
        # GENERACIÓN DE GRÁFICOS
        g1 <- ggplot(valores$tabla, aes(x = Mes, y = Cuota)) +
          geom_line(color = "#2980b9", size = 1.2) +
          labs(title = "Evolución de cuota mensual") +
          theme_minimal()
        
        g2 <- ggplot(valores$tabla, aes(x = Mes, y = Saldo)) +
          geom_line(color = "#e67e22", size = 1.2) +
          labs(title = "Evolución del saldo") +
          theme_minimal()
        
        tabla_cum <- valores$tabla
        tabla_cum$InteresAcum <- cumsum(tabla_cum$Interes)
        tabla_cum$AbonoAcum <- cumsum(tabla_cum$Abono)
        g3 <- ggplot(tabla_cum, aes(x = Mes)) +
          geom_line(aes(y = InteresAcum, color = "Intereses"), size = 1.2) +
          geom_line(aes(y = AbonoAcum, color = "Abono a capital"), size = 1.2) +
          scale_color_manual(values = c("Intereses" = "#e74c3c", "Abono a capital" = "#27ae60")) +
          labs(title = "Curva acumulada de pagos", color = "") +
          theme_minimal()
        
        # RENDERIZA EL ARCHIVO RMD A HTML
        rmarkdown::render(
          input = tempReport,
          output_file = file,
          params = list(
            tabla = valores$tabla,
            kpis = valores$kpis,
            plots = list(
              grafico1 = g1,
              grafico2 = g2,
              grafico3 = g3
            )
          ),
          envir = new.env(parent = globalenv())
        )
      }
    )
  })

  
  
  
}
