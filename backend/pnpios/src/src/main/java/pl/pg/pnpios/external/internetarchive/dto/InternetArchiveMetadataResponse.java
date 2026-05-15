package pl.pg.pnpios.external.internetarchive.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record InternetArchiveMetadataResponse(
    String created,
    InternetArchiveMetadata metadata
) {}
