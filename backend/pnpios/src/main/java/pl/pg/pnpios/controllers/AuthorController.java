package pl.pg.pnpios.controllers;

import lombok.AllArgsConstructor;
import pl.pg.pnpios.dto.AuthorDetailsDTO;
import pl.pg.pnpios.dto.AuthorSearchResponseDTO;
import pl.pg.pnpios.dto.BookSearchResponseDTO;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import pl.pg.pnpios.services.AuthorService;

@RestController
@AllArgsConstructor
@RequestMapping("/api/v1/authors")
public class AuthorController {
    private final AuthorService authorService;

    @GetMapping("/search")
    public ResponseEntity<AuthorSearchResponseDTO> searchAuthors(
        @RequestParam String q,
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size
    ) {
        return ResponseEntity.ok(authorService.searchAuthors(q, page, size));
    }

    @GetMapping("/{authorId}")
    public ResponseEntity<AuthorDetailsDTO> getAuthorDetails(@PathVariable String authorId) {
        return ResponseEntity.ok(authorService.getAuthorDetails(authorId));
    }

    @GetMapping("/{authorId}/books")
    public ResponseEntity<BookSearchResponseDTO> getAuthorBooks(
        @PathVariable String authorId,
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestParam(defaultValue = "PLN") String currency
    ) {
        return ResponseEntity.ok(authorService.getAuthorBooks(authorId, page, size, currency));
    }
}
