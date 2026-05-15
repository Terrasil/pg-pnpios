package pl.pg.pnpios.services.support;

import java.util.List;

public record AuthorSearchData(long totalElements, List<AuthorSeed> items) {
    public AuthorSearchData {
        items = items == null ? List.of() : List.copyOf(items);
    }
}
