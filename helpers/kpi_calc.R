
calcular_kpis <- function(tabla) {
  total_pagado <- sum(tabla$Cuota)
  total_interes <- sum(tabla$Interes)
  total_abono <- sum(tabla$Abono)
  cuota_mensual <- tabla$Cuota[1]
  porcentaje_interes <- round(100 * total_interes / total_pagado, 2)
  ctc <- round(total_pagado / total_abono, 3)
  tea_aprox <- round(((1 + (total_interes / total_abono))^(12 / nrow(tabla)) - 1) * 100, 2)
  list(
    cuota = cuota_mensual,
    pagado = total_pagado,
    interes = total_interes,
    porcentaje = porcentaje_interes,
    ctc = ctc,
    tea = tea_aprox
  )
}