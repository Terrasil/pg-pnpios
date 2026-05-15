package pl.pg.pnpios.external.openlibrary.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.util.List;

@JsonIgnoreProperties(ignoreUnknown = true)
public record OpenLibraryEditionDoc(
    String key,
    String title,
    List<String> language,
    String ebook_access
) {}
