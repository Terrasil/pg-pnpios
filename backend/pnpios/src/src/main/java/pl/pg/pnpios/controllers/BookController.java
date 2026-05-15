package pl.pg.pnpios.controllers;

import lombok.AllArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import pl.pg.pnpios.dto.BookDetailsDTO;
import pl.pg.pnpios.dto.BookSearchResponseDTO;
import pl.pg.pnpios.dto.OfferDTO;
import pl.pg.pnpios.enums.OfferSortType;
import pl.pg.pnpios.services.BookService;

import java.util.List;

@RestController
@AllArgsConstructor
@RequestMapping("/api/v1/books")
public class BookController {
    private final BookService bookService;

    @GetMapping("/search")
    public ResponseEntity<BookSearchResponseDTO> searchBooks(
        @RequestParam String q, @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestParam(defaultValue = "PLN") String currency
    ) {
        return ResponseEntity.ok(bookService.searchBooks(q, page, size, currency));
    }

    @GetMapping("/{bookId}")
    public ResponseEntity<BookDetailsDTO> getBookDetails(
        @PathVariable String bookId,
        @RequestParam(defaultValue = "PLN") String currency
    ) {
        return ResponseEntity.ok(bookService.getBookDetails(bookId, currency));
    }

    @GetMapping("/{bookId}/offers")
    public ResponseEntity<List<OfferDTO>> getBookOffers(
        @PathVariable String bookId,
        @RequestParam(defaultValue = "PLN") String currency,
        @RequestParam(defaultValue = "PRICE_ASC") OfferSortType sort,
        @RequestParam(required = false) String source
    ) {
        return ResponseEntity.ok(bookService.getBookOffers(bookId, currency, sort, source));
    }
}
