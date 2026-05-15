package pl.pg.pnpios.services.support;

import java.util.List;

public record BookSeed(
    String id,
    String title,
    String subtitle,
    List<String> authors,
    String coverUrl,
    String language,
    String genre,
    String isbn10,
    String isbn13,
    Integer publishedYear,
    String description,
    String publisher,
    Integer pageCount,
    List<String> genres
) {
    public BookSeed {
        authors = authors == null ? List.of() : List.copyOf(authors);
        genres = genres == null ? List.of() : List.copyOf(genres);
    }

    public BookSeed withMetadata(
        String subtitle,
        String coverUrl,
        String language,
        String genre,
        String isbn10,
        String isbn13,
        Integer publishedYear,
        String description,
        String publisher,
        Integer pageCount,
        List<String> genres
    ) {
        return new BookSeed(
            id,
            title,
            coalesce(this.subtitle, subtitle),
            authors,
            coalesce(this.coverUrl, coverUrl),
            coalesce(this.language, language),
            coalesce(this.genre, genre),
            coalesce(this.isbn10, isbn10),
            coalesce(this.isbn13, isbn13),
            this.publishedYear != null ? this.publishedYear : publishedYear,
            coalesce(this.description, description),
            coalesce(this.publisher, publisher),
            this.pageCount != null ? this.pageCount : pageCount,
            mergeGenres(this.genres, genres)
        );
    }

    private static String coalesce(String first, String second) {
        if (first != null && !first.isBlank()) {
            return first;
        }
        return second;
    }

    private static List<String> mergeGenres(List<String> first, List<String> second) {
        if (first != null && !first.isEmpty()) {
            return first;
        }
        return second == null ? List.of() : List.copyOf(second);
    }
}
