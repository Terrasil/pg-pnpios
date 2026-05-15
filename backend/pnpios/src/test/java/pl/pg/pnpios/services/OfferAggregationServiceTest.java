package pl.pg.pnpios.services;

import org.junit.jupiter.api.Test;
import pl.pg.pnpios.dto.MoneyDTO;
import pl.pg.pnpios.dto.OfferDTO;
import pl.pg.pnpios.enums.AvailabilityStatus;
import pl.pg.pnpios.enums.OfferSortType;
import pl.pg.pnpios.services.external.GoogleBooksService;
import pl.pg.pnpios.services.support.BookSeed;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

class OfferAggregationServiceTest {

    @Test
    void resolveOffersDeduplicatesResultsAndSortsByConvertedPriceAscending() {
        OfferDTO expensive = offer("2", "Google Books", "https://books.example/2", "30.00");
        OfferDTO cheap = offer("1", "Google Books", "https://books.example/1", "10.00");
        OfferDTO duplicatedCheap = offer("1-copy", "Google Books", "https://books.example/1", "10.00");
        OfferAggregationService service = new OfferAggregationService(
            new StubGoogleBooksService(List.of(expensive, cheap, duplicatedCheap))
        );

        List<OfferDTO> result = service.resolveOffers(bookSeed(), "PLN", OfferSortType.PRICE_ASC, null);

        assertEquals(2, result.size());
        assertEquals("1", result.get(0).id());
        assertEquals("2", result.get(1).id());
    }

    @Test
    void resolveOffersFiltersBySourceName() {
        OfferDTO googleOffer = offer("1", "Google Books", "https://books.example/1", "10.00");
        OfferDTO biblioOffer = offer("2", "Biblio", "https://biblio.example/2", "15.00");
        OfferAggregationService service = new OfferAggregationService(
            new StubGoogleBooksService(List.of(googleOffer, biblioOffer))
        );

        List<OfferDTO> result = service.resolveOffers(bookSeed(), "PLN", OfferSortType.SOURCE_ASC, "biblio");

        assertEquals(1, result.size());
        assertEquals("Biblio", result.get(0).source());
    }

    @Test
    void buildPriceRangeUsesConvertedPricesAndRequestedCurrency() {
        OfferAggregationService service = new OfferAggregationService(new StubGoogleBooksService(List.of()));

        var range = service.buildPriceRange(
            List.of(
                offer("1", "Google Books", "https://books.example/1", "10.00"),
                offer("2", "Google Books", "https://books.example/2", "25.50")
            ),
            "pln"
        );

        assertEquals(0, new BigDecimal("10.00").compareTo(range.min()));
        assertEquals(0, new BigDecimal("25.50").compareTo(range.max()));
        assertEquals("PLN", range.currency());
    }

    private static BookSeed bookSeed() {
        return new BookSeed(
            "OL1W",
            "The Hobbit",
            null,
            List.of("J. R. R. Tolkien"),
            null,
            "eng",
            "Fantasy",
            "0345339681",
            "9780345339683",
            1937,
            null,
            "Random House",
            320,
            List.of("Fantasy")
        );
    }

    private static OfferDTO offer(String id, String source, String url, String amount) {
        BigDecimal value = new BigDecimal(amount);
        MoneyDTO money = new MoneyDTO(value, "PLN");
        return new OfferDTO(
            id,
            source,
            "API",
            url,
            AvailabilityStatus.AVAILABLE,
            money,
            money,
            BigDecimal.ONE,
            Instant.parse("2026-05-15T12:00:00Z")
        );
    }

    private static final class StubGoogleBooksService extends GoogleBooksService {
        private final List<OfferDTO> offers;

        private StubGoogleBooksService(List<OfferDTO> offers) {
            super(null, null, null, false, "", "PL", "PL");
            this.offers = offers;
        }

        @Override
        public List<OfferDTO> searchOffers(BookSeed seed, String targetCurrency) {
            return offers;
        }
    }
}
