package pl.pg.pnpios.services.support;

public record AuthorSeed(
    String id,
    String name,
    Integer birthYear,
    Integer deathYear,
    String biography,
    String photoUrl,
    int booksCount
) {}
