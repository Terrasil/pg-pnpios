package pl.pg.pnpios.external.openlibrary.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.util.List;

@JsonIgnoreProperties(ignoreUnknown = true)
public record OpenLibraryAuthorWorksResponse(
    Integer size,
    Integer entriesCount,
    List<OpenLibraryAuthorWorkEntry> entries
) {}
