package pl.pg.pnpios.dto;

import pl.pg.pnpios.enums.AvailabilityStatus;

import java.math.BigDecimal;
import java.time.Instant;

public record OfferDTO(
    String id,
    String source,
    String sourceType,
    String offerUrl,
    AvailabilityStatus availability,
    MoneyDTO originalPrice,
    MoneyDTO convertedPrice,
    BigDecimal exchangeRate,
    Instant lastUpdated
) {}
