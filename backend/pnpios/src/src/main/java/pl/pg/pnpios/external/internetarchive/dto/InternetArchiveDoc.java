package pl.pg.pnpios.external.internetarchive.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record InternetArchiveDoc(
    String identifier,
    String title,
    String creator,
    String publicdate,
    Integer downloads,
    String mediatype,
    String year
) {}
