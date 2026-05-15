package pl.pg.pnpios.external.internetarchive.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.util.List;

@JsonIgnoreProperties(ignoreUnknown = true)
public record InternetArchiveInnerResponse(
    Integer numFound,
    Integer start,
    List<InternetArchiveDoc> docs
) {}
