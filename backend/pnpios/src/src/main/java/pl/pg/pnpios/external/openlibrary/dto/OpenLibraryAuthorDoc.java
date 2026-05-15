package pl.pg.pnpios.external.openlibrary.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record OpenLibraryAuthorDoc(
    String key,
    String name,
    String birth_date,
    String death_date,
    Integer work_count,
    String top_work
) {}
