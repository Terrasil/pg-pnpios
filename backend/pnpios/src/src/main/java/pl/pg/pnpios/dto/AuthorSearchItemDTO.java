package pl.pg.pnpios.dto;

public record AuthorSearchItemDTO(
    String id,
    String name,
    Integer birthYear,
    Integer deathYear,
    String photoUrl,
    int booksCount
) {}
