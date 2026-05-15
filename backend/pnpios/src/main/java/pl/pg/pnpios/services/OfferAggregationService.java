package pl.pg.pnpios.services;

import org.springframework.stereotype.Service;
import pl.pg.pnpios.dto.OfferDTO;
import pl.pg.pnpios.dto.PriceRangeDTO;
import pl.pg.pnpios.enums.OfferSortType;
import pl.pg.pnpios.services.external.GoogleBooksService;
import pl.pg.pnpios.services.support.BookSeed;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class OfferAggregationService {
    private final GoogleBooksService googleBooksService;

    public OfferAggregationService(
        GoogleBooksService googleBooksService
    ) {
        this.googleBooksService = googleBooksService;
    }

    public List<OfferDTO> resolveOffers(BookSeed seed, String currency, OfferSortType sort, String source) {
        Map<String, OfferDTO> deduped = new LinkedHashMap<>();
        for (OfferDTO offer : googleBooksService.searchOffers(seed, currency)) {
            deduped.putIfAbsent(dedupKey(offer), offer);
        }

        List<OfferDTO> offers = new ArrayList<>(deduped.values());
        if (source != null && !source.isBlank()) {
            String normalizedSource = source.trim().toLowerCase(Locale.ROOT);
            offers = offers.stream()
                .filter(offer -> offer.source() != null && offer.source().trim().toLowerCase(Locale.ROOT).equals(normalizedSource))
                .toList();
        }

        Comparator<OfferDTO> comparator = switch (sort) {
            case PRICE_DESC -> Comparator.comparing((OfferDTO offer) -> safeAmount(offer)).reversed();
            case SOURCE_ASC -> Comparator.comparing(offer -> normalizeSource(offer.source()));
            case PRICE_ASC -> Comparator.comparing(this::safeAmount);
        };

        return offers.stream().sorted(comparator).toList();
    }

    public PriceRangeDTO buildPriceRange(List<OfferDTO> offers, String currency) {
        if (offers == null || offers.isEmpty()) {
            return null;
        }

        BigDecimal min = offers.stream().map(this::safeAmount).min(BigDecimal::compareTo).orElse(BigDecimal.ZERO);
        BigDecimal max = offers.stream().map(this::safeAmount).max(BigDecimal::compareTo).orElse(BigDecimal.ZERO);
        return new PriceRangeDTO(min, max, currency == null || currency.isBlank() ? "PLN" : currency.trim().toUpperCase(Locale.ROOT));
    }

    private BigDecimal safeAmount(OfferDTO offer) {
        if (offer == null || offer.convertedPrice() == null || offer.convertedPrice().amount() == null) {
            return BigDecimal.ZERO;
        }
        return offer.convertedPrice().amount();
    }

    private String dedupKey(OfferDTO offer) {
        return normalizeSource(offer.source()) + '|' + (offer.offerUrl() == null ? "" : offer.offerUrl()) + '|' + safeAmount(offer);
    }

    private String normalizeSource(String source) {
        return source == null ? "" : source.trim().toLowerCase(Locale.ROOT);
    }
}
