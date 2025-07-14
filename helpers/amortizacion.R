
generar_amortizacion_cap <- function(monto, 
                                     tasa, 
                                     pagos, 
                                     frecuencia, 
                                     seguro = 0, 
                                     comision = 0,
                                     abonos_df=NULL) {
  cuota <- (monto * tasa) / (1 - (1 + tasa)^(-pagos))
  tabla <- data.frame(
    Pago = 1:pagos,
    Periodo = seq(frecuencia, pagos * frecuencia, by = frecuencia),
    Cuota = rep(0, pagos),
    Interes = rep(0, pagos),
    Abono = rep(0, pagos),
    AbonoExtra = rep(0, pagos),
    Saldo = rep(0, pagos)
  )
  
  saldo <- monto
  for (i in 1:pagos) {
    tasa_i <- if (length(tasa) == 1) tasa else tasa[i]  # 🔹 Esto es clave para manejar vectores
    
    abono_extra <- 0
    if (!is.null(abonos_df) && i %in% abonos_df$Periodo) {
      abono_extra <- abonos_df$Abono[abonos_df$Periodo == i]
    }
    
    interes <- saldo * tasa_i
    abono <- cuota - interes + abono_extra
    saldo <- saldo - abono
    
    tabla$Cuota[i] <- round(cuota, 0)
    tabla$Interes[i] <- round(interes, 0)
    tabla$Abono[i] <- round(abono, 0)
    tabla$AbonoExtra[i] <- round(abono_extra, 0)
    tabla$Saldo[i] <- round(saldo, 0)
  }
  
  return(tabla)
}