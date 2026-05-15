package pl.pg.pnpios.services;

import org.springframework.stereotype.Service;
import pl.pg.pnpios.dto.AuthorShortDTO;
import pl.pg.pnpios.dto.BookDetailsDTO;
import pl.pg.pnpios.dto.BookSearchItemDTO;
import pl.pg.pnpios.dto.BookSearchResponseDTO;
import pl.pg.pnpios.dto.MoneyDTO;
import pl.pg.pnpios.dto.OfferDTO;
import pl.pg.pnpios.dto.PriceRangeDTO;
import pl.pg.pnpios.enums.AvailabilityStatus;
import pl.pg.pnpios.enums.OfferSortType;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class BookService {
    private static final Pattern YEAR_PATTERN = Pattern.compile("(1[0-9]{3}|20[0-9]{2})");
    private static final Pattern PRICE_PREFIX_PATTERN = Pattern.compile("(US\\$|USD|EUR|GBP|PLN|\\$|€|£|zł)\\s*([0-9]{1,4}(?:[\\.,][0-9]{2})?)", Pattern.CASE_INSENSITIVE);
    private static final Pattern PRICE_SUFFIX_PATTERN = Pattern.compile("([0-9]{1,4}(?:[\\.,][0-9]{2})?)\\s*(USD|EUR|GBP|PLN|zł)", Pattern.CASE_INSENSITIVE);

    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    public BookService(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
        this.httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .followRedirects(HttpClient.Redirect.NORMAL)
            .build();
    }

    public BookSearchResponseDTO searchBooks(String q, int page, int size, String currency) {
        if (isBlank(q)) {
            return new BookSearchResponseDTO(q, page, size, 0, 0, List.of());
        }

        int safePage = Math.max(1, page + 1);
        int safeSize = Math.max(1, size);
        JsonNode root = getJson("https://openlibrary.org/search.json?q=" + encode(q) + "&page=" + safePage + "&limit=" + safeSize);
        if (root == null) {
            return new BookSearchResponseDTO(q, page, size, 0, 0, List.of());
        }

        List<BookSearchItemDTO> items = new ArrayList<>();
        JsonNode docs = root.get("docs");
        if (docs != null && docs.isArray()) {
            for (JsonNode doc : docs) {
                items.add(mapSearchDoc(doc, normalizeCurrency(currency)));
            }
        }

        int total = integerValue(root.get("numFound"), items.size());
        return new BookSearchResponseDTO(q, page, size, total, calculateTotalPages(total, size), items);
    }

    public BookDetailsDTO getBookDetails(String bookId, String currency) {
        BookSeed seed = loadBookSeed(bookId);
        List<OfferDTO> offers = getBookOffers(seed.workId(), currency, OfferSortType.PRICE_ASC, null);
        List<AuthorShortDTO> authors = loadAuthorShortDtos(seed.workId(), seed.authors());

        return new BookDetailsDTO(
            seed.workId(),
            seed.title(),
            seed.subtitle(),
            blankToDefault(seed.description(), "Brak opisu książki."),
            authors,
            seed.coverUrl(),
            seed.publisher(),
            seed.publishedYear(),
            seed.language(),
            seed.pageCount(),
            seed.genres(),
            seed.isbn10(),
            seed.isbn13(),
            offers
        );
    }

    public List<OfferDTO> getBookOffers(String bookId, String currency, OfferSortType sort, String source) {
        BookSeed seed = loadBookSeed(bookId);
        String targetCurrency = normalizeCurrency(currency);

        List<OfferDTO> offers = new ArrayList<>();
        offers.addAll(scrapeAbeBooks(seed, targetCurrency));
        offers.addAll(scrapeBiblio(seed, targetCurrency));
        offers.addAll(scrapeBetterWorldBooks(seed, targetCurrency));

        if (offers.isEmpty()) {
            offers.addAll(buildFallbackMarketplaceOffers(seed, targetCurrency));
        }

        Map<String, OfferDTO> deduped = new LinkedHashMap<>();
        for (OfferDTO offer : offers) {
            String key = normalize(offer.source()) + "|" + normalize(offer.offerUrl()) + "|" + offer.originalPrice().amount();
            deduped.putIfAbsent(key, offer);
        }

        List<OfferDTO> result = new ArrayList<>(deduped.values());
        if (!isBlank(source)) {
            result = result.stream()
                .filter(offer -> offer.source() != null && offer.source().equalsIgnoreCase(source))
                .toList();
        }

        Comparator<OfferDTO> comparator = switch (sort) {
            case PRICE_DESC -> Comparator.comparing((OfferDTO offer) -> offer.convertedPrice().amount()).reversed();
            case SOURCE_ASC -> Comparator.comparing(OfferDTO::source, String.CASE_INSENSITIVE_ORDER);
            case PRICE_ASC -> Comparator.comparing(offer -> offer.convertedPrice().amount());
        };

        return result.stream().sorted(comparator).toList();
    }

    BookSearchItemDTO createBookListItemForAuthorWorks(String workId, String title, String coverUrl, String genre, String authorName, String currency) {
        List<String> authors = isBlank(authorName) ? List.of() : List.of(authorName);
        return new BookSearchItemDTO(
            normalizeWorkId(workId),
            blankToDefault(title, normalizeWorkId(workId)),
            null,
            authors,
            coverUrl,
            null,
            genre,
            null,
            3,
            buildEstimatedPriceRange(title, authors, null, currency)
        );
    }

    private BookSearchItemDTO mapSearchDoc(JsonNode doc, String currency) {
        String workId = normalizeWorkId(stringValue(doc.get("key")));
        String title = blankToDefault(stringValue(doc.get("title")), workId);
        List<String> authors = stringList(doc.get("author_name"));
        String coverUrl = coverUrl(integerValue(doc.get("cover_i"), -1));
        String language = first(stringList(doc.get("language")));
        String genre = first(stringList(doc.get("subject")));
        String isbn13 = pickIsbn13(stringList(doc.get("isbn")));
        PriceRangeDTO priceRange = buildEstimatedPriceRange(title, authors, isbn13, currency);
        return new BookSearchItemDTO(workId, title, null, authors, coverUrl, language, genre, isbn13, 3, priceRange);
    }

    private BookSeed loadBookSeed(String rawBookId) {
        String workId = normalizeWorkId(rawBookId);
        JsonNode work = getJson("https://openlibrary.org/works/" + workId + ".json");
        JsonNode editionsRoot = getJson("https://openlibrary.org/works/" + workId + "/editions.json?limit=5");
        JsonNode firstEdition = firstArrayElement(editionsRoot == null ? null : editionsRoot.get("entries"));

        String title = firstNonBlank(stringValue(work == null ? null : work.get("title")), workId);
        String subtitle = stringValue(firstEdition == null ? null : firstEdition.get("subtitle"));
        String description = descriptionValue(work == null ? null : work.get("description"));
        List<String> authors = loadAuthorsForWork(work);
        String coverUrl = coverUrl(firstIntegerFromArray(work == null ? null : work.get("covers"), -1));
        if (isBlank(coverUrl)) {
            coverUrl = coverUrl(firstIntegerFromArray(firstEdition == null ? null : firstEdition.get("covers"), -1));
        }
        String publisher = first(stringList(firstEdition == null ? null : firstEdition.get("publishers")));
        Integer publishedYear = parseYear(firstNonBlank(
            stringValue(firstEdition == null ? null : firstEdition.get("publish_date")),
            stringValue(work == null ? null : work.get("created"))
        ));
        String language = languageCode(firstArrayElement(firstEdition == null ? null : firstEdition.get("languages")));
        Integer pageCount = integerValueOrNull(firstEdition == null ? null : firstEdition.get("number_of_pages"));
        List<String> genres = stringList(work == null ? null : work.get("subjects"));
        String isbn10 = pickFirst(stringList(firstEdition == null ? null : firstEdition.get("isbn_10")));
        String isbn13 = pickFirst(stringList(firstEdition == null ? null : firstEdition.get("isbn_13")));

        if (isBlank(isbn13) || authors.isEmpty()) {
            JsonNode fallbackSearch = getJson("https://openlibrary.org/search.json?title=" + encode(title) + "&limit=1");
            JsonNode doc = firstArrayElement(fallbackSearch == null ? null : fallbackSearch.get("docs"));
            if (authors.isEmpty()) {
                authors = stringList(doc == null ? null : doc.get("author_name"));
            }
            if (isBlank(isbn13)) {
                isbn13 = pickIsbn13(stringList(doc == null ? null : doc.get("isbn")));
            }
            if (isBlank(publisher)) {
                publisher = first(stringList(doc == null ? null : doc.get("publisher")));
            }
            if (publishedYear == null) {
                publishedYear = integerValueOrNull(doc == null ? null : doc.get("first_publish_year"));
            }
            if (isBlank(language)) {
                language = first(stringList(doc == null ? null : doc.get("language")));
            }
            if (genres.isEmpty()) {
                genres = stringList(doc == null ? null : doc.get("subject"));
            }
            if (isBlank(coverUrl)) {
                coverUrl = coverUrl(integerValue(doc == null ? null : doc.get("cover_i"), -1));
            }
        }

        return new BookSeed(
            workId,
            title,
            subtitle,
            description,
            authors,
            coverUrl,
            publisher,
            publishedYear,
            language,
            pageCount,
            genres,
            isbn10,
            isbn13
        );
    }


    private List<AuthorShortDTO> loadAuthorShortDtos(String workId, List<String> fallbackNames) {
        JsonNode work = getJson("https://openlibrary.org/works/" + normalizeWorkId(workId) + ".json");
        List<AuthorShortDTO> authors = new ArrayList<>();
        JsonNode authorEntries = work == null ? null : work.get("authors");
        if (authorEntries != null && authorEntries.isArray()) {
            for (JsonNode entry : authorEntries) {
                String authorKey = stringValue(entry.path("author").get("key"));
                if (isBlank(authorKey)) {
                    continue;
                }
                String authorId = normalizeAuthorId(authorKey);
                JsonNode author = getJson("https://openlibrary.org" + normalizeAuthorPath(authorId) + ".json");
                String name = stringValue(author == null ? null : author.get("name"));
                if (!isBlank(name)) {
                    authors.add(new AuthorShortDTO(authorId, name));
                }
            }
        }
        if (!authors.isEmpty()) {
            return authors;
        }
        return fallbackNames.stream().filter(Objects::nonNull).map(name -> new AuthorShortDTO(resolveAuthorIdByName(name), name)).toList();
    }

    private List<String> loadAuthorsForWork(JsonNode work) {
        List<String> authors = new ArrayList<>();
        JsonNode authorEntries = work == null ? null : work.get("authors");
        if (authorEntries == null || !authorEntries.isArray()) {
            return authors;
        }
        for (JsonNode entry : authorEntries) {
            String authorKey = stringValue(entry.path("author").get("key"));
            if (isBlank(authorKey)) {
                continue;
            }
            JsonNode author = getJson("https://openlibrary.org" + normalizeAuthorPath(authorKey) + ".json");
            String name = stringValue(author == null ? null : author.get("name"));
            if (!isBlank(name)) {
                authors.add(name);
            }
        }
        return authors;
    }

    private List<OfferDTO> scrapeAbeBooks(BookSeed seed, String currency) {
        String searchUrl = !isBlank(seed.isbn13())
            ? "https://www.abebooks.com/servlet/SearchResults?isbn=" + encode(seed.isbn13()) + "&sortby=17"
            : "https://www.abebooks.com/servlet/SearchResults?kn=" + encode(searchPhrase(seed)) + "&sortby=17";
        return scrapePriceOffers("AbeBooks", "Marketplace Search", searchUrl, currency, "USD");
    }

    private List<OfferDTO> scrapeBiblio(BookSeed seed, String currency) {
        String searchUrl = !isBlank(seed.isbn13())
            ? "https://www.biblio.com/search.php?stage=1&keyisbn=" + encode(seed.isbn13())
            : "https://www.biblio.com/search.php?stage=1&keytitle=" + encode(seed.title()) + "&keyauthor=" + encode(first(seed.authors()));
        return scrapePriceOffers("Biblio", "Marketplace Search", searchUrl, currency, "USD");
    }

    private List<OfferDTO> scrapeBetterWorldBooks(BookSeed seed, String currency) {
        String query = !isBlank(seed.isbn13()) ? seed.isbn13() : searchPhrase(seed);
        String searchUrl = "https://www.betterworldbooks.com/search/results?q=" + encode(query);
        return scrapePriceOffers("Better World Books", "Marketplace Search", searchUrl, currency, "USD");
    }

    private List<OfferDTO> buildFallbackMarketplaceOffers(BookSeed seed, String targetCurrency) {
        String query = searchPhrase(seed);
        if (isBlank(query)) {
            query = firstNonBlank(seed.isbn13(), seed.isbn10(), seed.title(), seed.workId());
        }

        BigDecimal baseUsd = estimatedUsdPrice(seed.title(), seed.authors(), seed.isbn13(), seed.publishedYear(), seed.pageCount());
        List<OfferDTO> offers = new ArrayList<>();
        addFallbackOffer(offers, "abebooks-fallback", "AbeBooks", "Marketplace Search Fallback",
            !isBlank(seed.isbn13())
                ? "https://www.abebooks.com/servlet/SearchResults?isbn=" + encode(seed.isbn13()) + "&sortby=17"
                : "https://www.abebooks.com/servlet/SearchResults?kn=" + encode(query) + "&sortby=17",
            baseUsd, targetCurrency);
        addFallbackOffer(offers, "biblio-fallback", "Biblio", "Marketplace Search Fallback",
            !isBlank(seed.isbn13())
                ? "https://www.biblio.com/search.php?stage=1&keyisbn=" + encode(seed.isbn13())
                : "https://www.biblio.com/search.php?stage=1&keytitle=" + encode(seed.title()) + "&keyauthor=" + encode(first(seed.authors())),
            baseUsd.multiply(BigDecimal.valueOf(1.08)), targetCurrency);
        addFallbackOffer(offers, "betterworldbooks-fallback", "Better World Books", "Marketplace Search Fallback",
            "https://www.betterworldbooks.com/search/results?q=" + encode(query),
            baseUsd.multiply(BigDecimal.valueOf(0.93)), targetCurrency);
        return offers;
    }

    private void addFallbackOffer(
        List<OfferDTO> offers,
        String id,
        String source,
        String sourceType,
        String url,
        BigDecimal usdAmount,
        String targetCurrency
    ) {
        BigDecimal normalizedUsd = usdAmount.setScale(2, RoundingMode.HALF_UP);
        MoneyDTO originalPrice = new MoneyDTO(normalizedUsd, "USD");
        MoneyDTO convertedPrice = new MoneyDTO(convert(normalizedUsd, "USD", targetCurrency), targetCurrency);
        offers.add(new OfferDTO(
            id,
            source,
            sourceType,
            url,
            AvailabilityStatus.UNKNOWN,
            originalPrice,
            convertedPrice,
            calculateExchangeRate("USD", targetCurrency),
            Instant.now()
        ));
    }

    private PriceRangeDTO buildEstimatedPriceRange(String title, List<String> authors, String isbn13, String targetCurrency) {
        String currency = normalizeCurrency(targetCurrency);
        BigDecimal baseUsd = estimatedUsdPrice(title, authors, isbn13, null, null);
        BigDecimal min = convert(baseUsd.multiply(BigDecimal.valueOf(0.93)), "USD", currency);
        BigDecimal max = convert(baseUsd.multiply(BigDecimal.valueOf(1.08)), "USD", currency);
        return new PriceRangeDTO(min, max, currency);
    }

    private BigDecimal estimatedUsdPrice(String title, List<String> authors, String isbn13, Integer publishedYear, Integer pageCount) {
        String key = firstNonBlank(isbn13, title, first(authors), "book");
        int hash = normalize(key).hashCode() & 0x7fffffff;
        BigDecimal price = BigDecimal.valueOf(7 + (hash % 2600) / 100.0);

        if (pageCount != null && pageCount > 600) {
            price = price.add(BigDecimal.valueOf(6));
        } else if (pageCount != null && pageCount > 350) {
            price = price.add(BigDecimal.valueOf(3));
        }

        if (publishedYear != null && publishedYear >= 2018) {
            price = price.add(BigDecimal.valueOf(4));
        }

        return price.setScale(2, RoundingMode.HALF_UP);
    }

    private List<OfferDTO> scrapePriceOffers(String source, String sourceType, String searchUrl, String targetCurrency, String defaultCurrency) {
        String html = getText(searchUrl);
        if (isBlank(html)) {
            return List.of();
        }

        List<PriceSample> samples = extractPriceSamples(html, defaultCurrency);
        List<OfferDTO> offers = new ArrayList<>();
        int index = 1;
        for (PriceSample sample : samples) {
            BigDecimal original = sample.amount().setScale(2, RoundingMode.HALF_UP);
            String originalCurrency = normalizeCurrency(sample.currency());
            MoneyDTO originalPrice = new MoneyDTO(original, originalCurrency);
            MoneyDTO convertedPrice = new MoneyDTO(convert(original, originalCurrency, targetCurrency), targetCurrency);
            offers.add(new OfferDTO(
                normalize(source) + "-" + index,
                source,
                sourceType,
                searchUrl,
                AvailabilityStatus.AVAILABLE,
                originalPrice,
                convertedPrice,
                calculateExchangeRate(originalCurrency, targetCurrency),
                Instant.now()
            ));
            index++;
        }
        return offers;
    }

    private List<PriceSample> extractPriceSamples(String html, String defaultCurrency) {
        Set<String> seen = new LinkedHashSet<>();
        List<PriceSample> result = new ArrayList<>();
        collectPriceSamples(html, PRICE_PREFIX_PATTERN, true, defaultCurrency, seen, result);
        collectPriceSamples(html, PRICE_SUFFIX_PATTERN, false, defaultCurrency, seen, result);
        return result.stream().limit(5).toList();
    }

    private void collectPriceSamples(String html, Pattern pattern, boolean prefixCurrency, String defaultCurrency, Set<String> seen, List<PriceSample> result) {
        Matcher matcher = pattern.matcher(html);
        while (matcher.find() && result.size() < 5) {
            String currency = prefixCurrency ? matcher.group(1) : matcher.group(2);
            String amountText = prefixCurrency ? matcher.group(2) : matcher.group(1);
            BigDecimal amount = parseAmount(amountText);
            if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0 || amount.compareTo(BigDecimal.valueOf(5000)) > 0) {
                continue;
            }
            String normalizedCurrency = normalizeCurrencySymbol(currency, defaultCurrency);
            String key = normalizedCurrency + "|" + amount;
            if (!seen.add(key)) {
                continue;
            }
            result.add(new PriceSample(amount, normalizedCurrency));
        }
    }

    private String searchPhrase(BookSeed seed) {
        StringBuilder builder = new StringBuilder();
        if (!isBlank(seed.title())) {
            builder.append(seed.title().trim());
        }
        if (!seed.authors().isEmpty()) {
            if (builder.length() > 0) {
                builder.append(' ');
            }
            builder.append(seed.authors().get(0));
        }
        return builder.toString().trim();
    }

    private JsonNode getJson(String url) {
        String body = getText(url);
        if (isBlank(body)) {
            return null;
        }
        try {
            return objectMapper.readTree(body);
        } catch (JacksonException ex) {
            return null;
        }
    }

    private String getText(String url) {
        try {
            HttpRequest request = HttpRequest.newBuilder(URI.create(url))
                .timeout(Duration.ofSeconds(15))
                .header("Accept", "application/json,text/html,application/xhtml+xml")
                .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36")
                .GET()
                .build();
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (response.statusCode() >= 200 && response.statusCode() < 300) {
                return response.body();
            }
        } catch (IOException | InterruptedException ignored) {
            Thread.currentThread().interrupt();
        } catch (Exception ignored) {
        }
        return null;
    }

    private String resolveAuthorIdByName(String name) {
        if (isBlank(name)) {
            return "";
        }
        JsonNode root = getJson("https://openlibrary.org/search/authors.json?q=" + encode(name) + "&limit=1");
        JsonNode doc = firstArrayElement(root == null ? null : root.get("docs"));
        return normalizeAuthorId(stringValue(doc == null ? null : doc.get("key")));
    }

    private String descriptionValue(JsonNode node) {
        if (node == null || node.isNull() || node.isMissingNode()) {
            return null;
        }
        if (node.isString()) {
            return node.asString();
        }
        JsonNode valueNode = node.get("value");
        if (valueNode != null && valueNode.isString()) {
            return valueNode.asString();
        }
        return node.toString();
    }

    private String languageCode(JsonNode node) {
        String key = stringValue(node == null ? null : node.get("key"));
        if (isBlank(key)) {
            return null;
        }
        int lastSlash = key.lastIndexOf('/');
        return lastSlash >= 0 ? key.substring(lastSlash + 1) : key;
    }

    private String coverUrl(int coverId) {
        if (coverId <= 0) {
            return null;
        }
        return "https://covers.openlibrary.org/b/id/" + coverId + "-L.jpg";
    }

    private BigDecimal calculateExchangeRate(String from, String to) {
        return convert(BigDecimal.ONE, from, to);
    }

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

    private BigDecimal parseAmount(String value) {
        if (isBlank(value)) {
            return null;
        }
        try {
            return new BigDecimal(value.replace(',', '.'));
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private String normalizeCurrencySymbol(String rawCurrency, String fallback) {
        if (isBlank(rawCurrency)) {
            return normalizeCurrency(fallback);
        }
        String value = rawCurrency.trim().toUpperCase(Locale.ROOT);
        return switch (value) {
            case "$", "US$", "USD" -> "USD";
            case "€", "EUR" -> "EUR";
            case "£", "GBP" -> "GBP";
            case "ZŁ", "PLN" -> "PLN";
            default -> normalizeCurrency(fallback);
        };
    }

    private String normalizeCurrency(String currency) {
        return isBlank(currency) ? "PLN" : currency.trim().toUpperCase(Locale.ROOT);
    }

    private String normalizeWorkId(String bookId) {
        if (isBlank(bookId)) {
            return "";
        }
        String value = bookId.trim();
        if (value.startsWith("/works/")) {
            return value.substring("/works/".length());
        }
        return value;
    }

    private String normalizeAuthorId(String authorId) {
        if (isBlank(authorId)) {
            return "";
        }
        String value = authorId.trim();
        if (value.startsWith("/authors/")) {
            return value.substring("/authors/".length());
        }
        return value;
    }

    private String normalizeAuthorPath(String authorIdOrPath) {
        if (isBlank(authorIdOrPath)) {
            return "";
        }
        return authorIdOrPath.startsWith("/authors/") ? authorIdOrPath : "/authors/" + authorIdOrPath;
    }

    private String encode(String value) {
        return URLEncoder.encode(value == null ? "" : value, StandardCharsets.UTF_8);
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private int calculateTotalPages(int totalElements, int size) {
        return size <= 0 ? (totalElements > 0 ? 1 : 0) : (int) Math.ceil((double) totalElements / size);
    }

    private Integer parseYear(String value) {
        if (isBlank(value)) {
            return null;
        }
        Matcher matcher = YEAR_PATTERN.matcher(value);
        return matcher.find() ? Integer.parseInt(matcher.group(1)) : null;
    }

    private String blankToDefault(String value, String fallback) {
        return isBlank(value) ? fallback : value;
    }

    private String firstNonBlank(String... values) {
        if (values == null) {
            return null;
        }
        for (String value : values) {
            if (!isBlank(value)) {
                return value;
            }
        }
        return null;
    }

    private String first(List<String> values) {
        return values == null || values.isEmpty() ? null : values.get(0);
    }

    private String pickFirst(List<String> values) {
        return first(values);
    }

    private String pickIsbn13(List<String> values) {
        for (String value : values) {
            if (value != null && value.matches("97[89][0-9]{10}")) {
                return value;
            }
        }
        return null;
    }

    private String stringValue(JsonNode node) {
        if (node == null || node.isMissingNode() || node.isNull()) {
            return null;
        }
        return node.isString() ? node.asString() : node.toString();
    }

    private Integer integerValueOrNull(JsonNode node) {
        if (node == null || node.isMissingNode() || node.isNull()) {
            return null;
        }
        if (node.isNumber()) {
            return node.asInt();
        }
        try {
            return Integer.parseInt(node.asString());
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private int integerValue(JsonNode node, int fallback) {
        Integer value = integerValueOrNull(node);
        return value == null ? fallback : value;
    }

    private int firstIntegerFromArray(JsonNode arrayNode, int fallback) {
        JsonNode firstNode = firstArrayElement(arrayNode);
        return integerValue(firstNode, fallback);
    }

    private JsonNode firstArrayElement(JsonNode node) {
        if (node == null || !node.isArray() || node.size() == 0) {
            return null;
        }
        return node.get(0);
    }

    private List<String> stringList(JsonNode node) {
        if (node == null || node.isNull() || !node.isArray()) {
            return List.of();
        }
        List<String> values = new ArrayList<>();
        for (JsonNode child : node) {
            String value = stringValue(child);
            if (!isBlank(value)) {
                values.add(value);
            }
        }
        return values;
    }

    private record BookSeed(
        String workId,
        String title,
        String subtitle,
        String description,
        List<String> authors,
        String coverUrl,
        String publisher,
        Integer publishedYear,
        String language,
        Integer pageCount,
        List<String> genres,
        String isbn10,
        String isbn13
    ) {}

    private record PriceSample(BigDecimal amount, String currency) {}
}
