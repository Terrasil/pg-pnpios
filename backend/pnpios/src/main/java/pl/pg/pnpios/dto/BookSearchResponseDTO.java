package pl.pg.pnpios.dto;

import java.util.List;

public record BookSearchResponseDTO(
    String query,
    int page,
    int size,
    long totalElements,
    int totalPages,
    List<BookSearchItemDTO> items
) {}
