package pl.pg.pnpios.dto;

import java.time.Instant;
import java.util.List;

public record ApiErrorDTO(
    Instant timestamp,
    int status,
    String error,
    String message,
    String path,
    List<String> details
) {}
