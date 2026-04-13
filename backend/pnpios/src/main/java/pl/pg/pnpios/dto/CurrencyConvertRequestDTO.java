package pl.pg.pnpios.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public record CurrencyConvertRequestDTO(
    @NotNull @DecimalMin("0.0") BigDecimal amount,
    @NotBlank String from,
    @NotBlank String to
) {}
