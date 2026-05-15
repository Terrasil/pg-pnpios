package pl.pg.pnpios.services.external;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import feign.FeignException;
import pl.pg.pnpios.dto.CurrencyConvertRequestDTO;
import pl.pg.pnpios.dto.CurrencyConvertResponseDTO;
import pl.pg.pnpios.dto.MoneyDTO;
import pl.pg.pnpios.dto.OfferDTO;
import pl.pg.pnpios.enums.AvailabilityStatus;
import pl.pg.pnpios.external.GoogleBooksClient;
import pl.pg.pnpios.services.CurrencyService;
import pl.pg.pnpios.services.support.BookSeed;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;

@Service
public class GoogleBooksService {
    private final GoogleBooksClient client;
    private final ObjectMapper objectMapper;
    private final CurrencyService currencyService;
    private final boolean enabled;
    private volatile boolean quotaExceededForRun;
    private final String apiKey;
    private final String defaultCountry;
    private final List<String> offerCountries;

    public GoogleBooksService(
        GoogleBooksClient client,
        ObjectMapper objectMapper,
        CurrencyService currencyService,
        @Value("${google.books.api.enabled:false}") boolean enabled,
        @Value("${google.books.api.key:}") String apiKey,
        @Value("${google.books.country:PL}") String defaultCountry,
        @Value("${google.books.offer-countries:PL,US,GB,DE}") String offerCountries
    ) {
        this.client = client;
        this.objectMapper = objectMapper;
        this.currencyService = currencyService;
        this.enabled = enabled;
        this.apiKey = apiKey == null ? "" : apiKey.trim();
        this.defaultCountry = normalizeCountry(defaultCountry, "PL");
        this.offerCountries = parseCountries(offerCountries, this.defaultCountry);
    }

    public BookSeed enrichBook(BookSeed seed) {
        if (!isAvailable()) {
            return seed;
        }
        Optional<JsonNode> volume = findBestVolume(seed);
        if (volume.isEmpty()) {
            return seed;
        }
        JsonNode volumeInfo = volume.get().path("volumeInfo");
        List<String> categories = stringList(volumeInfo.path("categories"), 6);
        return seed.withMetadata(
            text(volumeInfo, "subtitle"),
            imageLink(volumeInfo.path("imageLinks")),
            text(volumeInfo, "language"),
            categories.isEmpty() ? null : categories.get(0),
            extractIndustryIdentifier(volumeInfo.path("industryIdentifiers"), "ISBN_10"),
            extractIndustryIdentifier(volumeInfo.path("industryIdentifiers"), "ISBN_13"),
            yearFromPublishedDate(text(volumeInfo, "publishedDate")),
            text(volumeInfo, "description"),
            text(volumeInfo, "publisher"),
            intValue(volumeInfo.path("pageCount")),
            categories
        );
    }

    public List<OfferDTO> searchOffers(BookSeed seed, String targetCurrency) {
        if (!isAvailable()) {
            return List.of();
        }
        Set<String> dedupe = new LinkedHashSet<>();
        List<OfferDTO> offers = new ArrayList<>();
        for (String country : offerCountries) {
            for (String query : buildQueries(seed)) {
                JsonNode root = searchVolumes(query, 8, country, "paid-ebooks");
                collectOffers(root, offers, dedupe, targetCurrency, country);
                if (offers.size() >= 4) {
                    return offers;
                }
                JsonNode fallback = searchVolumes(query, 8, country, null);
                collectOffers(fallback, offers, dedupe, targetCurrency, country);
                if (offers.size() >= 4) {
                    return offers;
                }
            }
        }
        return offers;
    }

    private void collectOffers(JsonNode root, List<OfferDTO> offers, Set<String> dedupe, String targetCurrency, String country) {
        if (root == null || !root.path("items").isArray()) {
            return;
        }
        for (JsonNode item : root.path("items")) {
            JsonNode saleInfo = item.path("saleInfo");
            JsonNode volumeInfo = item.path("volumeInfo");
            String saleability = text(saleInfo, "saleability");
            String baseUrl = firstNonBlank(text(saleInfo, "buyLink"), text(volumeInfo, "infoLink"));
            String itemId = firstNonBlank(text(item, "id"), "google-books");
            List<PriceData> prices = extractPrices(saleInfo);
            for (int i = 0; i < prices.size(); i++) {
                PriceData price = prices.get(i);
                if (price.amount() == null || price.amount().compareTo(BigDecimal.ZERO) <= 0 || price.currency() == null || price.currency().isBlank()) {
                    continue;
                }
                String uniqueKey = itemId + '|' + country + '|' + price.amount() + '|' + price.currency() + '|' + baseUrl;
                if (!dedupe.add(uniqueKey)) {
                    continue;
                }
                BigDecimal exchangeRate = calculateExchangeRate(price.currency(), targetCurrency);
                MoneyDTO originalPrice = new MoneyDTO(price.amount().setScale(2, RoundingMode.HALF_UP), normalizeCurrency(price.currency()));
                MoneyDTO convertedPrice = new MoneyDTO(convert(price.amount(), price.currency(), targetCurrency), normalizeCurrency(targetCurrency));
                offers.add(new OfferDTO(
                    itemId + '-' + country + '-' + i,
                    "Google Books",
                    "API " + country,
                    baseUrl,
                    mapGoogleAvailability(saleability),
                    originalPrice,
                    convertedPrice,
                    exchangeRate,
                    Instant.now()
                ));
            }
        }
    }

    private Optional<JsonNode> findBestVolume(BookSeed seed) {
        JsonNode best = null;
        int bestScore = Integer.MIN_VALUE;
        for (String query : buildQueries(seed)) {
            JsonNode root = searchVolumes(query, 8, defaultCountry, null);
            if (root == null || !root.path("items").isArray()) {
                continue;
            }
            for (JsonNode item : root.path("items")) {
                int score = score(item, seed);
                if (score > bestScore) {
                    bestScore = score;
                    best = item;
                }
            }
            if (bestScore >= 100) {
                break;
            }
        }
        return Optional.ofNullable(best);
    }

    private JsonNode searchVolumes(String query, int maxResults, String country, String filter) {
        if (!isAvailable()) {
            return null;
        }
        try {
            String body = client.searchVolumes(
                query,
                Math.max(1, Math.min(maxResults, 10)),
                filter,
                "books",
                "full",
                normalizeCountry(country, defaultCountry),
                apiKey.isBlank() ? null : apiKey
            );
            return readTree(body);
        } catch (FeignException.TooManyRequests ex) {
            quotaExceededForRun = true;
            return null;
        } catch (FeignException ex) {
            if (ex.status() == 429) {
                quotaExceededForRun = true;
            }
            return null;
        } catch (Exception ex) {
            return null;
        }
    }

    private boolean isAvailable() {
        return enabled && !quotaExceededForRun;
    }

    private List<String> buildQueries(BookSeed seed) {
        List<String> queries = new ArrayList<>();
        if (seed.isbn13() != null && !seed.isbn13().isBlank()) {
            queries.add("isbn:" + seed.isbn13());
        }
        if (seed.isbn10() != null && !seed.isbn10().isBlank()) {
            queries.add("isbn:" + seed.isbn10());
        }
        String title = safe(seed.title());
        String author = seed.authors().isEmpty() ? "" : safe(seed.authors().get(0));
        if (!title.isBlank() && !author.isBlank()) {
            queries.add("intitle:" + title + " inauthor:" + author);
            queries.add(title + " " + author);
        }
        if (!title.isBlank()) {
            queries.add("intitle:" + title);
            queries.add(title);
        }
        return queries;
    }

    private int score(JsonNode item, BookSeed seed) {
        int score = 0;
        JsonNode volumeInfo = item.path("volumeInfo");
        String title = normalize(text(volumeInfo, "title"));
        String expectedTitle = normalize(seed.title());
        if (!title.isBlank() && !expectedTitle.isBlank()) {
            if (title.equals(expectedTitle)) {
                score += 40;
            } else if (title.contains(expectedTitle) || expectedTitle.contains(title)) {
                score += 20;
            }
        }
        List<String> authors = stringList(volumeInfo.path("authors"), 5);
        if (!seed.authors().isEmpty() && !authors.isEmpty()) {
            String expectedAuthor = normalize(seed.authors().get(0));
            if (authors.stream().map(this::normalize).anyMatch(author -> author.equals(expectedAuthor))) {
                score += 30;
            }
        }
        String isbn13 = extractIndustryIdentifier(volumeInfo.path("industryIdentifiers"), "ISBN_13");
        if (seed.isbn13() != null && !seed.isbn13().isBlank() && seed.isbn13().equals(isbn13)) {
            score += 100;
        }
        String isbn10 = extractIndustryIdentifier(volumeInfo.path("industryIdentifiers"), "ISBN_10");
        if (seed.isbn10() != null && !seed.isbn10().isBlank() && seed.isbn10().equals(isbn10)) {
            score += 80;
        }
        if (!extractPrices(item.path("saleInfo")).isEmpty()) {
            score += 10;
        }
        return score;
    }

    private List<PriceData> extractPrices(JsonNode saleInfo) {
        List<PriceData> result = new ArrayList<>();
        if (saleInfo == null || saleInfo.isMissingNode() || saleInfo.isNull()) {
            return result;
        }
        addPrice(result, saleInfo.path("retailPrice"), false);
        addPrice(result, saleInfo.path("listPrice"), false);
        JsonNode offers = saleInfo.path("offers");
        if (offers.isArray()) {
            for (JsonNode offer : offers) {
                addPrice(result, offer.path("retailPrice"), true);
                addPrice(result, offer.path("listPrice"), true);
            }
        }
        return result;
    }

    private void addPrice(List<PriceData> result, JsonNode node, boolean micros) {
        if (node == null || node.isMissingNode() || node.isNull() || !node.isObject()) {
            return;
        }
        String currency = text(node, "currencyCode");
        BigDecimal amount = micros ? microsToAmount(node.path("amountInMicros")) : decimalOrNull(node.path("amount"));
        if (amount != null && currency != null && !currency.isBlank()) {
            result.add(new PriceData(amount, currency));
        }
    }

    private AvailabilityStatus mapGoogleAvailability(String saleability) {
        if (saleability == null || saleability.isBlank()) {
            return AvailabilityStatus.UNKNOWN;
        }
        return switch (saleability.toUpperCase(Locale.ROOT)) {
            case "FOR_SALE", "FREE", "FOR_SALE_AND_RENTAL" -> AvailabilityStatus.AVAILABLE;
            case "FOR_PREORDER", "FOR_RENTAL_ONLY" -> AvailabilityStatus.LIMITED;
            case "NOT_FOR_SALE" -> AvailabilityStatus.OUT_OF_STOCK;
            default -> AvailabilityStatus.UNKNOWN;
        };
    }

    private String imageLink(JsonNode imageLinksNode) {
        if (imageLinksNode == null || imageLinksNode.isMissingNode() || imageLinksNode.isNull()) {
            return null;
        }
        String[] fields = {"extraLarge", "large", "medium", "small", "thumbnail", "smallThumbnail"};
        for (String field : fields) {
            String value = text(imageLinksNode, field);
            if (value != null && !value.isBlank()) {
                return value;
            }
        }
        return null;
    }

    private String extractIndustryIdentifier(JsonNode identifiers, String type) {
        if (identifiers == null || identifiers.isMissingNode() || identifiers.isNull() || !identifiers.isArray()) {
            return null;
        }
        for (JsonNode item : identifiers) {
            String candidateType = text(item, "type");
            String identifier = text(item, "identifier");
            if (candidateType != null && candidateType.equalsIgnoreCase(type) && identifier != null && !identifier.isBlank()) {
                return identifier;
            }
        }
        return null;
    }

    private List<String> stringList(JsonNode node, int limit) {
        if (node == null || node.isMissingNode() || node.isNull() || !node.isArray()) {
            return List.of();
        }
        List<String> result = new ArrayList<>();
        for (JsonNode child : node) {
            if (child != null && child.isString()) {
                String value = child.asString();
                if (value != null && !value.isBlank()) {
                    result.add(value);
                    if (limit > 0 && result.size() >= limit) {
                        break;
                    }
                }
            }
        }
        return result;
    }

    private Integer yearFromPublishedDate(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        String[] parts = value.split("-");
        if (parts.length > 0 && parts[0].length() == 4) {
            try {
                return Integer.parseInt(parts[0]);
            } catch (NumberFormatException ignored) {
            }
        }
        return null;
    }

    private BigDecimal calculateExchangeRate(String from, String to) {
        return convertResponse(BigDecimal.ONE, from, to).rate();
    }

    private BigDecimal convert(BigDecimal amount, String from, String to) {
        return convertResponse(amount, from, to).convertedAmount();
    }

    private CurrencyConvertResponseDTO convertResponse(BigDecimal amount, String from, String to) {
        return currencyService.convert(new CurrencyConvertRequestDTO(
            amount == null ? BigDecimal.ZERO : amount,
            normalizeCurrency(from),
            normalizeCurrency(to)
        ));
    }

    private String normalizeCurrency(String currency) {
        return currency == null || currency.isBlank() ? "PLN" : currency.trim().toUpperCase(Locale.ROOT);
    }

    private String normalizeCountry(String country, String fallback) {
        return country == null || country.isBlank() ? fallback : country.trim().toUpperCase(Locale.ROOT);
    }

    private List<String> parseCountries(String raw, String fallback) {
        List<String> result = new ArrayList<>();
        if (raw != null) {
            for (String part : raw.split(",")) {
                String value = normalizeCountry(part, "");
                if (!value.isBlank() && !result.contains(value)) {
                    result.add(value);
                }
            }
        }
        if (result.isEmpty()) {
            result.add(fallback);
        }
        return result;
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
    }

    private String safe(String value) {
        return value == null ? "" : value.trim();
    }

    private String firstNonBlank(String first, String second) {
        if (first != null && !first.isBlank()) {
            return first;
        }
        return second;
    }

    private String text(JsonNode node, String fieldName) {
        if (node == null || node.isMissingNode() || node.isNull()) {
            return null;
        }
        JsonNode value = node.path(fieldName);
        if (value.isMissingNode() || value.isNull()) {
            return null;
        }
        if (value.isString()) {
            String text = value.asString();
            return text == null || text.isBlank() ? null : text;
        }
        return value.toString();
    }

    private Integer intValue(JsonNode node) {
        if (node == null || node.isMissingNode() || node.isNull() || !node.isNumber()) {
            return null;
        }
        return node.asInt();
    }

    private BigDecimal decimalOrNull(JsonNode node) {
        if (node == null || node.isMissingNode() || node.isNull()) {
            return null;
        }
        if (node.isNumber()) {
            return node.decimalValue();
        }
        if (node.isString()) {
            try {
                return new BigDecimal(node.asString());
            } catch (NumberFormatException ignored) {
            }
        }
        return null;
    }

    private BigDecimal microsToAmount(JsonNode node) {
        if (node == null || node.isMissingNode() || node.isNull()) {
            return null;
        }
        BigDecimal micros = decimalOrNull(node);
        if (micros == null) {
            return null;
        }
        return micros.divide(BigDecimal.valueOf(1_000_000L), 2, RoundingMode.HALF_UP);
    }

    private JsonNode readTree(String body) {
        if (body == null || body.isBlank()) {
            return null;
        }
        try {
            return objectMapper.readTree(body);
        } catch (JacksonException ex) {
            return null;
        }
    }

    private record PriceData(BigDecimal amount, String currency) {}
}
