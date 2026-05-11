package pl.pg.pnpios.services;

import org.springframework.stereotype.Service;
import pl.pg.pnpios.dto.*;
import pl.pg.pnpios.enums.AvailabilityStatus;
import pl.pg.pnpios.enums.OfferSortType;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

@Service
public class BookService {

    public BookSearchResponseDTO searchBooks(String q, int page, int size, String currency) {
        final String targetCurrency = normalizeCurrency(currency);
        final String query = normalize(q);

        List<BookSearchItemDTO> allBooks = List.of(
            new BookSearchItemDTO("book_1", "The Fellowship of the Ring", null, List.of("J. R. R. Tolkien"), null, "en", "Fantasy", "9780261103573", 3,
                new PriceRangeDTO(convert(BigDecimal.valueOf(39.99), "PLN", targetCurrency), convert(BigDecimal.valueOf(59.99), "PLN", targetCurrency), targetCurrency)),
            new BookSearchItemDTO("book_2", "Harry Potter and the Philosopher's Stone", null, List.of("J. K. Rowling"), null, "en", "Fantasy", "9780747532699", 3,
                new PriceRangeDTO(convert(BigDecimal.valueOf(29.99), "PLN", targetCurrency), convert(BigDecimal.valueOf(49.99), "PLN", targetCurrency), targetCurrency)),
            new BookSearchItemDTO("book_3", "Clean Code", "A Handbook of Agile Software Craftsmanship", List.of("Robert C. Martin"), null, "en", "Programming", "9780132350884", 3,
                new PriceRangeDTO(convert(BigDecimal.valueOf(79.99), "PLN", targetCurrency), convert(BigDecimal.valueOf(129.99), "PLN", targetCurrency), targetCurrency)),
            new BookSearchItemDTO("book_4", "Ostatnie życzenie", null, List.of("Andrzej Sapkowski"), null, "pl", "Fantasy", "9788375780635", 2,
                new PriceRangeDTO(convert(BigDecimal.valueOf(24.99), "PLN", targetCurrency), convert(BigDecimal.valueOf(39.99), "PLN", targetCurrency), targetCurrency))
        );

        List<BookSearchItemDTO> filtered = allBooks.stream()
            .filter(book -> query.isBlank() || normalize(book.title()).contains(query) || normalize(book.isbn13()).contains(query)
                || book.authors().stream().anyMatch(author -> normalize(author).contains(query)))
            .collect(Collectors.toList());

        return new BookSearchResponseDTO(q, page, size, filtered.size(), calculateTotalPages(filtered.size(), size), paginate(filtered, page, size));
    }

    public BookDetailsDTO getBookDetails(String bookId, String currency) {
        String targetCurrency = normalizeCurrency(currency);
        return switch (bookId) {
            case "book_1" -> new BookDetailsDTO("book_1", "The Fellowship of the Ring", null, "Pierwsza część trylogii Władca Pierścieni.", List.of(new AuthorShortDTO("author_1", "J. R. R. Tolkien")), null, "George Allen & Unwin", 1954, "en", 423, List.of("Fantasy", "Adventure"), "0261103571", "9780261103573", getBookOffers("book_1", targetCurrency, OfferSortType.PRICE_ASC, null));
            case "book_2" -> new BookDetailsDTO("book_2", "Harry Potter and the Philosopher's Stone", null, "Pierwsza część serii o Harrym Potterze.", List.of(new AuthorShortDTO("author_2", "J. K. Rowling")), null, "Bloomsbury", 1997, "en", 223, List.of("Fantasy", "Young adult"), "0747532699", "9780747532699", getBookOffers("book_2", targetCurrency, OfferSortType.PRICE_ASC, null));
            case "book_3" -> new BookDetailsDTO("book_3", "Clean Code", "A Handbook of Agile Software Craftsmanship", "Książka o dobrych praktykach programistycznych.", List.of(new AuthorShortDTO("author_3", "Robert C. Martin")), null, "Prentice Hall", 2008, "en", 464, List.of("Programming", "Software engineering"), "0132350882", "9780132350884", getBookOffers("book_3", targetCurrency, OfferSortType.PRICE_ASC, null));
            case "book_4" -> new BookDetailsDTO("book_4", "Ostatnie życzenie", null, "Zbiór opowiadań otwierający cykl o Wiedźminie.", List.of(new AuthorShortDTO("author_4", "Andrzej Sapkowski")), null, "SuperNOWA", 1993, "pl", 288, List.of("Fantasy"), "8375780637", "9788375780635", getBookOffers("book_4", targetCurrency, OfferSortType.PRICE_ASC, null));
            default -> new BookDetailsDTO(bookId, "Nieznana książka", null, "Brak opisu.", List.of(), null, null, null, null, null, List.of(), null, null, List.of());
        };
    }

    public List<OfferDTO> getBookOffers(String bookId, String currency, OfferSortType sort, String source) {
        String targetCurrency = normalizeCurrency(currency);
        List<OfferDTO> offers = switch (bookId) {
            case "book_1" -> List.of(
                createOffer("offer_1", "Books Online", "API", "https://example.com/book_1/1", AvailabilityStatus.AVAILABLE, 44.99, "PLN", targetCurrency),
                createOffer("offer_2", "World Books", "API", "https://example.com/book_1/2", AvailabilityStatus.AVAILABLE, 12.99, "USD", targetCurrency),
                createOffer("offer_3", "Readers Shop", "API", "https://example.com/book_1/3", AvailabilityStatus.LIMITED, 11.49, "EUR", targetCurrency));
            case "book_2" -> List.of(
                createOffer("offer_4", "Books Online", "API", "https://example.com/book_2/1", AvailabilityStatus.AVAILABLE, 34.99, "PLN", targetCurrency),
                createOffer("offer_5", "New Page", "API", "https://example.com/book_2/2", AvailabilityStatus.AVAILABLE, 9.99, "USD", targetCurrency),
                createOffer("offer_6", "Story Store", "API", "https://example.com/book_2/3", AvailabilityStatus.LIMITED, 8.99, "EUR", targetCurrency));
            case "book_3" -> List.of(
                createOffer("offer_7", "Tech Books", "API", "https://example.com/book_3/1", AvailabilityStatus.AVAILABLE, 119.99, "PLN", targetCurrency),
                createOffer("offer_8", "Code Store", "API", "https://example.com/book_3/2", AvailabilityStatus.AVAILABLE, 29.99, "USD", targetCurrency),
                createOffer("offer_9", "Dev Library", "API", "https://example.com/book_3/3", AvailabilityStatus.AVAILABLE, 26.99, "EUR", targetCurrency));
            case "book_4" -> List.of(
                createOffer("offer_10", "Polish Books", "API", "https://example.com/book_4/1", AvailabilityStatus.AVAILABLE, 27.99, "PLN", targetCurrency),
                createOffer("offer_11", "Fantasy World", "API", "https://example.com/book_4/2", AvailabilityStatus.LIMITED, 31.99, "PLN", targetCurrency));
            default -> List.of();
        };

        if (source != null && !source.isBlank()) {
            offers = offers.stream().filter(offer -> offer.source().equalsIgnoreCase(source)).collect(Collectors.toList());
        }

        Comparator<OfferDTO> comparator = switch (sort) {
            case PRICE_DESC -> Comparator.comparing((OfferDTO offer) -> offer.convertedPrice().amount()).reversed();
            case SOURCE_ASC -> Comparator.comparing(OfferDTO::source, String.CASE_INSENSITIVE_ORDER);
            case PRICE_ASC -> Comparator.comparing(offer -> offer.convertedPrice().amount());
        };

        return offers.stream().sorted(comparator).collect(Collectors.toList());
    }

    private OfferDTO createOffer(String id, String source, String sourceType, String offerUrl, AvailabilityStatus availability, double originalAmount, String originalCurrency, String targetCurrency) {
        BigDecimal exchangeRate = calculateExchangeRate(originalCurrency, targetCurrency);
        MoneyDTO originalPrice = new MoneyDTO(round(originalAmount), originalCurrency);
        MoneyDTO convertedPrice = new MoneyDTO(convert(BigDecimal.valueOf(originalAmount), originalCurrency, targetCurrency), targetCurrency);
        return new OfferDTO(id, source, sourceType, offerUrl, availability, originalPrice, convertedPrice, exchangeRate, Instant.now());
    }

    private BigDecimal calculateExchangeRate(String from, String to) { return convert(BigDecimal.ONE, from, to); }

    private BigDecimal convert(BigDecimal amount, String from, String to) {
        String normalizedFrom = normalizeCurrency(from);
        String normalizedTo = normalizeCurrency(to);
        BigDecimal amountInPln = amount.multiply(rateToPln(normalizedFrom));
        return amountInPln.divide(rateToPln(normalizedTo), 2, RoundingMode.HALF_UP);
    }

    private BigDecimal rateToPln(String currency) {
        return switch (normalizeCurrency(currency)) {
            case "USD" -> BigDecimal.valueOf(4.02);
            case "EUR" -> BigDecimal.valueOf(4.32);
            case "GBP" -> BigDecimal.valueOf(5.05);
            case "PLN" -> BigDecimal.ONE;
            default -> BigDecimal.ONE;
        };
    }

    private BigDecimal round(double value) { return BigDecimal.valueOf(value).setScale(2, RoundingMode.HALF_UP); }
    private String normalize(String value) { return value == null ? "" : value.trim().toLowerCase(Locale.ROOT); }
    private String normalizeCurrency(String currency) { return currency == null || currency.isBlank() ? "PLN" : currency.trim().toUpperCase(Locale.ROOT); }
    private int calculateTotalPages(int totalElements, int size) { return size <= 0 ? (totalElements > 0 ? 1 : 0) : (int) Math.ceil((double) totalElements / size); }
    private <T> List<T> paginate(List<T> data, int page, int size) {
        if (size <= 0) return data;
        int fromIndex = Math.max(0, page * size);
        if (fromIndex >= data.size()) return List.of();
        int toIndex = Math.min(data.size(), fromIndex + size);
        return data.subList(fromIndex, toIndex);
    }
}
