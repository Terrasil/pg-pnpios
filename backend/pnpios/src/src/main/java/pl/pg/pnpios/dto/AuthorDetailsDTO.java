package pl.pg.pnpios.dto;

import java.util.List;

public record AuthorDetailsDTO(
    String id,
    String name,
    Integer birthYear,
    Integer deathYear,
    String biography,
    String photoUrl,
    List<BookSearchItemDTO> books
) {}
