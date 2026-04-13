package pl.pg.pnpios.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public record CurrencyRateDTO(
    String code,
    String name,
    BigDecimal rate,
    LocalDate rateDate
) {}
