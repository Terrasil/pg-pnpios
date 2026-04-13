package pl.pg.pnpios.services;

import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;
import pl.pg.pnpios.dto.AuthorDetailsDTO;
import pl.pg.pnpios.dto.AuthorSearchResponseDTO;
import pl.pg.pnpios.dto.BookSearchResponseDTO;

import java.util.Collections;

@Service
public class AuthorService  {

    public AuthorSearchResponseDTO searchAuthors(String q, int page, int size) {
        return new AuthorSearchResponseDTO(
            q,
            page,
            size,
            0L,
            0,
            Collections.emptyList()
        );
    }

    public AuthorDetailsDTO getAuthorDetails(String authorId) {
        return new AuthorDetailsDTO(
            authorId,
            "",
            null,
            null,
            null,
            null,
            Collections.emptyList()
        );
    }

    public BookSearchResponseDTO getAuthorBooks(String authorId, int page, int size, String currency) {
        return new BookSearchResponseDTO(
            "",
            page,
            size,
            0L,
            0,
            Collections.emptyList()
        );
    }
}