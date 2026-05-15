package pl.pg.pnpios.external.openlibrary.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.util.List;

@JsonIgnoreProperties(ignoreUnknown = true)
public record OpenLibraryAuthorWorkEntry(
    String key,
    String title,
    Object description,
    List<String> subject,
    List<Integer> covers,
    Integer first_publish_year,
    List<OpenLibraryKeyRef> authors
) {}
