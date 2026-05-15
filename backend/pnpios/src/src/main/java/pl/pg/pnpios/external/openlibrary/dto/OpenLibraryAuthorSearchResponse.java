package pl.pg.pnpios.external.openlibrary.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.util.List;

@JsonIgnoreProperties(ignoreUnknown = true)
public record OpenLibraryAuthorSearchResponse(
    @JsonAlias({"num_found", "numFound"}) Integer numFound,
    Integer start,
    List<OpenLibraryAuthorDoc> docs
) {}
