package pl.pg.pnpios.dto;

import java.util.List;

public record CurrencyListResponseDTO(
    String base,
    List<CurrencyRateDTO> items
) {}
