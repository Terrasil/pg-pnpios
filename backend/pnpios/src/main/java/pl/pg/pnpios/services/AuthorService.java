package pl.pg.pnpios.services;

import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;
import pl.pg.pnpios.dto.*;

import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

@Service
@AllArgsConstructor
public class AuthorService {
    private final BookService bookService;

    public AuthorSearchResponseDTO searchAuthors(String q, int page, int size) {
        final String query = normalize(q);
        List<AuthorSearchItemDTO> allAuthors = List.of(
            new AuthorSearchItemDTO("author_1", "J. R. R. Tolkien", 1892, 1973, null, 1),
            new AuthorSearchItemDTO("author_2", "J. K. Rowling", 1965, null, null, 1),
            new AuthorSearchItemDTO("author_3", "Robert C. Martin", 1952, null, null, 1),
            new AuthorSearchItemDTO("author_4", "Andrzej Sapkowski", 1948, null, null, 1)
        );
        List<AuthorSearchItemDTO> filtered = allAuthors.stream()
            .filter(author -> query.isBlank() || normalize(author.name()).contains(query))
            .collect(Collectors.toList());
        return new AuthorSearchResponseDTO(q, page, size, filtered.size(), calculateTotalPages(filtered.size(), size), paginate(filtered, page, size));
    }

    public AuthorDetailsDTO getAuthorDetails(String authorId) {
        return switch (authorId) {
            case "author_1" -> new AuthorDetailsDTO("author_1", "J. R. R. Tolkien", 1892, 1973, "Brytyjski pisarz i filolog, autor literatury fantasy, najbardziej znany z Władcy Pierścieni.", null, findBooksByAuthorName("J. R. R. Tolkien", "PLN"));
            case "author_2" -> new AuthorDetailsDTO("author_2", "J. K. Rowling", 1965, null, "Brytyjska pisarka, autorka serii o Harrym Potterze.", null, findBooksByAuthorName("J. K. Rowling", "PLN"));
            case "author_3" -> new AuthorDetailsDTO("author_3", "Robert C. Martin", 1952, null, "Programista i autor książek o czystym kodzie i architekturze oprogramowania.", null, findBooksByAuthorName("Robert C. Martin", "PLN"));
            case "author_4" -> new AuthorDetailsDTO("author_4", "Andrzej Sapkowski", 1948, null, "Polski pisarz fantasy, autor cyklu o Wiedźminie.", null, findBooksByAuthorName("Andrzej Sapkowski", "PLN"));
            default -> new AuthorDetailsDTO(authorId, "Nieznany autor", null, null, "Brak opisu.", null, List.of());
        };
    }

    public BookSearchResponseDTO getAuthorBooks(String authorId, int page, int size, String currency) {
        String authorName = switch (authorId) {
            case "author_1" -> "J. R. R. Tolkien";
            case "author_2" -> "J. K. Rowling";
            case "author_3" -> "Robert C. Martin";
            case "author_4" -> "Andrzej Sapkowski";
            default -> "";
        };
        List<BookSearchItemDTO> books = findBooksByAuthorName(authorName, currency);
        return new BookSearchResponseDTO(authorName, page, size, books.size(), calculateTotalPages(books.size(), size), paginate(books, page, size));
    }

    private List<BookSearchItemDTO> findBooksByAuthorName(String authorName, String currency) {
        return bookService.searchBooks("", 0, 100, currency).items().stream()
            .filter(book -> book.authors().stream().anyMatch(author -> author.equalsIgnoreCase(authorName)))
            .collect(Collectors.toList());
    }

    private String normalize(String value) { return value == null ? "" : value.trim().toLowerCase(Locale.ROOT); }
    private int calculateTotalPages(int totalElements, int size) { return size <= 0 ? (totalElements > 0 ? 1 : 0) : (int) Math.ceil((double) totalElements / size); }
    private <T> List<T> paginate(List<T> data, int page, int size) {
        if (size <= 0) return data;
        int fromIndex = Math.max(0, page * size);
        if (fromIndex >= data.size()) return List.of();
        int toIndex = Math.min(data.size(), fromIndex + size);
        return data.subList(fromIndex, toIndex);
    }
}
