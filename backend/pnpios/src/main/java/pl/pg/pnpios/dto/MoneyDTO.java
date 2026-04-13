package pl.pg.pnpios.dto;

import java.math.BigDecimal;

public record MoneyDTO(
    BigDecimal amount,
    String currency
) {}
