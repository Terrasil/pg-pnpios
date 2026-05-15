package pl.pg.pnpios.external.openlibrary.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.util.List;

@JsonIgnoreProperties(ignoreUnknown = true)
public record OpenLibraryWorkResponse(
    String key,
    String title,
    Object description,
    List<String> subjects,
    List<Integer> covers,
    List<OpenLibraryWorkAuthorRef> authors
) {}
