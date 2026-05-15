package pl.pg.pnpios.external.openlibrary.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.util.List;

@JsonIgnoreProperties(ignoreUnknown = true)
public record OpenLibraryAuthorResponse(
    String key,
    String name,
    Object bio,
    String birth_date,
    String death_date,
    List<Integer> photos
) {}
