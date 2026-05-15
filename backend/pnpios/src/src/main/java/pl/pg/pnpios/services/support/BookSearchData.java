package pl.pg.pnpios.services.support;

import java.util.List;

public record BookSearchData(long totalElements, List<BookSeed> items) {
    public BookSearchData {
        items = items == null ? List.of() : List.copyOf(items);
    }
}
