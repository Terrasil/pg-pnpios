package pl.pg.pnpios.dto;

import java.math.BigDecimal;

public record PriceRangeDTO(
    BigDecimal min,
    BigDecimal max,
    String currency
) {}
