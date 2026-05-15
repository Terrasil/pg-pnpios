package pl.pg.pnpios.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public record CurrencyConvertResponseDTO(
    BigDecimal amount,
    String from,
    String to,
    BigDecimal rate,
    BigDecimal convertedAmount,
    String provider,
    LocalDate rateDate
) {}
