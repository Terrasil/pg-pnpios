package pl.pg.pnpios.external.internetarchive.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record InternetArchiveMetadata(
    String identifier,
    Object title,
    Object creator,
    Object mediatype,
    Object collection
) {}
