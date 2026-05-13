package pl.pg.pnpios.external.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@JsonIgnoreProperties(ignoreUnknown = true)
public record NbpExchangeRatesTableResponse(
    String table,
    String no,
    LocalDate effectiveDate,
    List<NbpRateItem> rates
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record NbpRateItem(
        String currency,
        String code,
        BigDecimal mid
    ) {}
}
