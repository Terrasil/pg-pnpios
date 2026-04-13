package pl.pg.pnpios.services;

import org.springframework.stereotype.Service;
import pl.pg.pnpios.dto.BookDetailsDTO;
import pl.pg.pnpios.dto.BookSearchResponseDTO;
import pl.pg.pnpios.dto.OfferDTO;
import pl.pg.pnpios.enums.OfferSortType;

import java.util.Collections;
import java.util.List;

@Service
public class BookService {

    public BookSearchResponseDTO searchBooks(String q, int page, int size, String currency) {
        return new BookSearchResponseDTO(
            q,
            page,
            size,
            0L,
            0,
            Collections.emptyList()
        );
    }

    public BookDetailsDTO getBookDetails(String bookId, String currency) {
        return new BookDetailsDTO(
            bookId,
            "",
            null,
            null,
            Collections.emptyList(),
            null,
            null,
            null,
            null,
            null,
            Collections.emptyList(),
            null,
            null,
            Collections.emptyList()
        );
    }

    public List<OfferDTO> getBookOffers(String bookId, String currency, OfferSortType sort, String source) {
        return Collections.emptyList();
    }
}