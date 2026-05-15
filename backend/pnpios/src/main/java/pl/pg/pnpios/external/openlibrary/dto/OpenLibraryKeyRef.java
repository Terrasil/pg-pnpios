package pl.pg.pnpios.external.openlibrary.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record OpenLibraryKeyRef(
    String key,
    String authorKey,
    String name
) {}
