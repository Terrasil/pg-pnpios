package pl.pg.pnpios.dto;

import java.util.List;

public record AuthorSearchResponseDTO(
    String query,
    int page,
    int size,
    long totalElements,
    int totalPages,
    List<AuthorSearchItemDTO> items
) {}
