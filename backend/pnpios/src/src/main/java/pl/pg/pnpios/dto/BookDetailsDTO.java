package pl.pg.pnpios.dto;

import java.util.List;

public record BookDetailsDTO(
    String id,
    String title,
    String subtitle,
    String description,
    List<AuthorShortDTO> authors,
    String coverUrl,
    String publisher,
    Integer publishedYear,
    String language,
    Integer pageCount,
    List<String> genres,
    String isbn10,
    String isbn13,
    List<OfferDTO> offers
) {}
