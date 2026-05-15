package pl.pg.pnpios.dto;

import java.util.List;

public record BookSearchItemDTO(
    String id,
    String title,
    String subtitle,
    List<String> authors,
    String coverUrl,
    String language,
    String genre,
    String isbn13,
    int offersCount,
    PriceRangeDTO priceRange
) {}
