package pl.pg.pnpios.external.openlibrary.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.util.List;

@JsonIgnoreProperties(ignoreUnknown = true)
public record OpenLibraryBookDoc(
    String key,
    String title,
    List<String> author_name,
    List<String> author_key,
    Integer cover_i,
    Integer first_publish_year,
    List<String> language,
    List<String> publisher,
    List<String> isbn,
    List<String> subject,
    String ebook_access,
    List<String> ia,
    Boolean public_scan_b,
    OpenLibraryEditions editions
) {}
