package pl.pg.pnpios.services;

import org.springframework.stereotype.Service;
import pl.pg.pnpios.dto.AuthorShortDTO;
import pl.pg.pnpios.dto.BookDetailsDTO;
import pl.pg.pnpios.dto.BookSearchItemDTO;
import pl.pg.pnpios.dto.BookSearchResponseDTO;
import pl.pg.pnpios.dto.CurrencyConvertRequestDTO;
import pl.pg.pnpios.dto.CurrencyConvertResponseDTO;
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
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class BookService {
    private static final Pattern YEAR_PATTERN = Pattern.compile("(1[0-9]{3}|20[0-9]{2})");
    private static final Pattern PRICE_PREFIX_PATTERN = Pattern.compile("(US\\$|USD|EUR|GBP|PLN|\\$|€|£|zł)\\s*([0-9]{1,4}(?:[\\.,][0-9]{2})?)", Pattern.CASE_INSENSITIVE);
    private static final Pattern PRICE_SUFFIX_PATTERN = Pattern.compile("([0-9]{1,4}(?:[\\.,][0-9]{2})?)\\s*(USD|EUR|GBP|PLN|zł)", Pattern.CASE_INSENSITIVE);

    private final ObjectMapper objectMapper;
    private final CurrencyService currencyService;
    private final HttpClient httpClient;
    private final Map<String, List<OfferDTO>> offersCache = new ConcurrentHashMap<>();

    public BookService(ObjectMapper objectMapper, CurrencyService currencyService) {
        this.objectMapper = objectMapper;
        this.currencyService = currencyService;
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

        List<OfferDTO> offers = resolveConfirmedOffers(seed, targetCurrency).stream()
            .filter(offer -> safeAmount(offer) != null)
            .toList();

        List<OfferDTO> result = filterOffersBySource(deduplicateOffers(offers), source);
        return result.stream().sorted(offerComparator(sort)).toList();
    }

    BookSearchItemDTO createBookListItemForAuthorWorks(String workId, String title, String coverUrl, String genre, String authorName, String currency) {
        String normalizedWorkId = normalizeWorkId(workId);
        BookSeed loadedSeed = loadBookSeed(normalizedWorkId);
        List<String> authors = loadedSeed.authors().isEmpty()
            ? (isBlank(authorName) ? List.of() : List.of(authorName))
            : loadedSeed.authors();
        BookSeed summarySeed = new BookSeed(
            normalizedWorkId,
            firstNonBlank(loadedSeed.title(), title, normalizedWorkId),
            loadedSeed.subtitle(),
            loadedSeed.description(),
            authors,
            firstNonBlank(loadedSeed.coverUrl(), coverUrl),
            loadedSeed.publisher(),
            loadedSeed.publishedYear(),
            loadedSeed.language(),
            loadedSeed.pageCount(),
            loadedSeed.genres().isEmpty() && !isBlank(genre) ? List.of(genre) : loadedSeed.genres(),
            loadedSeed.isbn10(),
            loadedSeed.isbn13()
        );
        OfferSummary summary = buildOfferSummary(summarySeed, currency);
        return new BookSearchItemDTO(
            summarySeed.workId(),
            blankToDefault(summarySeed.title(), normalizedWorkId),
            summarySeed.subtitle(),
            authors,
            summarySeed.coverUrl(),
            summarySeed.language(),
            firstNonBlank(first(summarySeed.genres()), genre),
            summarySeed.isbn13(),
            summary.count(),
            summary.priceRange()
        );
    }

    private BookSearchItemDTO mapSearchDoc(JsonNode doc, String currency) {
        String workId = normalizeWorkId(stringValue(doc.get("key")));
        String title = blankToDefault(stringValue(doc.get("title")), workId);
        List<String> authors = stringList(doc.get("author_name"));
        String coverUrl = coverUrl(integerValue(doc.get("cover_i"), -1));
        String language = first(stringList(doc.get("language")));
        String genre = first(stringList(doc.get("subject")));
        List<String> isbnValues = stringList(doc.get("isbn"));
        String isbn13 = pickIsbn13(isbnValues);
        String isbn10 = pickIsbn10(isbnValues);
        Integer publishedYear = integerValueOrNull(doc.get("first_publish_year"));
        BookSeed searchSeed = new BookSeed(
            workId,
            title,
            null,
            null,
            authors,
            coverUrl,
            first(stringList(doc.get("publisher"))),
            publishedYear,
            language,
            null,
            genre == null ? List.of() : List.of(genre),
            isbn10,
            isbn13
        );
        BookSeed summarySeed = mergeSearchSeedWithLoadedSeed(searchSeed, loadBookSeed(workId));
        OfferSummary summary = buildOfferSummary(summarySeed, currency);
        return new BookSearchItemDTO(
            workId,
            summarySeed.title(),
            summarySeed.subtitle(),
            summarySeed.authors(),
            summarySeed.coverUrl(),
            summarySeed.language(),
            firstNonBlank(first(summarySeed.genres()), genre),
            summarySeed.isbn13(),
            summary.count(),
            summary.priceRange()
        );
    }

    private BookSeed mergeSearchSeedWithLoadedSeed(BookSeed searchSeed, BookSeed loadedSeed) {
        if (loadedSeed == null) {
            return searchSeed;
        }
        return new BookSeed(
            searchSeed.workId(),
            firstNonBlank(loadedSeed.title(), searchSeed.title(), searchSeed.workId()),
            firstNonBlank(loadedSeed.subtitle(), searchSeed.subtitle()),
            firstNonBlank(loadedSeed.description(), searchSeed.description()),
            loadedSeed.authors().isEmpty() ? searchSeed.authors() : loadedSeed.authors(),
            firstNonBlank(loadedSeed.coverUrl(), searchSeed.coverUrl()),
            firstNonBlank(loadedSeed.publisher(), searchSeed.publisher()),
            loadedSeed.publishedYear() == null ? searchSeed.publishedYear() : loadedSeed.publishedYear(),
            firstNonBlank(loadedSeed.language(), searchSeed.language()),
            loadedSeed.pageCount() == null ? searchSeed.pageCount() : loadedSeed.pageCount(),
            loadedSeed.genres().isEmpty() ? searchSeed.genres() : loadedSeed.genres(),
            firstNonBlank(loadedSeed.isbn10(), searchSeed.isbn10()),
            firstNonBlank(loadedSeed.isbn13(), searchSeed.isbn13())
        );
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
        return scrapePriceOffers("AbeBooks", "Marketplace Search", searchUrl, currency, "USD", seed);
    }

    private List<OfferDTO> scrapeBiblio(BookSeed seed, String currency) {
        String searchUrl = !isBlank(seed.isbn13())
            ? "https://www.biblio.com/search.php?stage=1&keyisbn=" + encode(seed.isbn13())
            : "https://www.biblio.com/search.php?stage=1&keytitle=" + encode(seed.title()) + "&keyauthor=" + encode(first(seed.authors()));
        return scrapePriceOffers("Biblio", "Marketplace Search", searchUrl, currency, "USD", seed);
    }

    private List<OfferDTO> scrapeBetterWorldBooks(BookSeed seed, String currency) {
        String query = !isBlank(seed.isbn13()) ? seed.isbn13() : searchPhrase(seed);
        String searchUrl = "https://www.betterworldbooks.com/search/results?q=" + encode(query);
        return scrapePriceOffers("Better World Books", "Marketplace Search", searchUrl, currency, "USD", seed);
    }

    private List<OfferDTO> buildMarketplaceSearchLinks(BookSeed seed) {
        String query = searchPhrase(seed);
        if (isBlank(query)) {
            query = firstNonBlank(seed.isbn13(), seed.isbn10(), seed.title(), seed.workId());
        }

        List<OfferDTO> offers = new ArrayList<>();
        addMarketplaceSearchLink(offers, "abebooks-search", "AbeBooks",
            !isBlank(seed.isbn13())
                ? "https://www.abebooks.com/servlet/SearchResults?isbn=" + encode(seed.isbn13()) + "&sortby=17"
                : "https://www.abebooks.com/servlet/SearchResults?kn=" + encode(query) + "&sortby=17");
        addMarketplaceSearchLink(offers, "biblio-search", "Biblio",
            !isBlank(seed.isbn13())
                ? "https://www.biblio.com/search.php?stage=1&keyisbn=" + encode(seed.isbn13())
                : "https://www.biblio.com/search.php?stage=1&keytitle=" + encode(seed.title()) + "&keyauthor=" + encode(first(seed.authors())));
        addMarketplaceSearchLink(offers, "betterworldbooks-search", "Better World Books",
            "https://www.betterworldbooks.com/search/results?q=" + encode(!isBlank(seed.isbn13()) ? seed.isbn13() : query));
        return offers;
    }

    private void addMarketplaceSearchLink(
        List<OfferDTO> offers,
        String id,
        String source,
        String url
    ) {
        offers.add(new OfferDTO(
            id,
            source,
            "Marketplace Search Link",
            url,
            AvailabilityStatus.UNKNOWN,
            null,
            null,
            null,
            Instant.now()
        ));
    }

    private List<OfferDTO> resolveConfirmedOffers(BookSeed seed, String targetCurrency) {
        String cacheKey = offerCacheKey(seed, targetCurrency);
        return offersCache.computeIfAbsent(cacheKey, ignored -> {
            List<OfferDTO> offers = new ArrayList<>();
            offers.addAll(scrapeAbeBooks(seed, targetCurrency));
            offers.addAll(scrapeBiblio(seed, targetCurrency));
            offers.addAll(scrapeBetterWorldBooks(seed, targetCurrency));
            return deduplicateOffers(offers).stream()
                .filter(offer -> safeAmount(offer) != null)
                .toList();
        });
    }

    private OfferSummary buildOfferSummary(BookSeed seed, String currency) {
        String targetCurrency = normalizeCurrency(currency);
        List<OfferDTO> offers = resolveConfirmedOffers(seed, targetCurrency).stream()
            .filter(offer -> safeAmount(offer) != null)
            .toList();

        if (offers.isEmpty()) {
            return new OfferSummary(0, null);
        }

        BigDecimal min = offers.stream().map(this::safeAmount).filter(Objects::nonNull).min(BigDecimal::compareTo).orElse(null);
        BigDecimal max = offers.stream().map(this::safeAmount).filter(Objects::nonNull).max(BigDecimal::compareTo).orElse(null);
        PriceRangeDTO range = min == null || max == null ? null : new PriceRangeDTO(min, max, targetCurrency);
        return new OfferSummary(offers.size(), range);
    }

    private List<OfferDTO> scrapePriceOffers(String source, String sourceType, String searchUrl, String targetCurrency, String defaultCurrency, BookSeed seed) {
        String html = getText(searchUrl);
        if (isBlank(html) || containsNoExactMatchMessage(html)) {
            return List.of();
        }

        List<OfferDTO> offers = new ArrayList<>();
        List<String> blocks = extractCandidateListingBlocks(html, seed);
        Set<String> seen = new LinkedHashSet<>();
        int index = 1;
        for (String block : blocks) {
            if (!isConcreteListingBlock(block, seed)) {
                continue;
            }
            PriceSample sample = extractListingPrice(block, defaultCurrency);
            if (sample == null) {
                continue;
            }
            BigDecimal original = sample.amount().setScale(2, RoundingMode.HALF_UP);
            String originalCurrency = normalizeCurrency(sample.currency());
            String offerUrl = extractOfferUrl(block, searchUrl);
            String dedupKey = normalize(source) + '|' + normalize(offerUrl) + '|' + originalCurrency + '|' + original;
            if (!seen.add(dedupKey)) {
                continue;
            }
            MoneyDTO originalPrice = new MoneyDTO(original, originalCurrency);
            MoneyDTO convertedPrice = new MoneyDTO(convert(original, originalCurrency, targetCurrency), targetCurrency);
            offers.add(new OfferDTO(
                normalize(source) + "-" + index,
                source,
                sourceType,
                offerUrl,
                AvailabilityStatus.AVAILABLE,
                originalPrice,
                convertedPrice,
                calculateExchangeRate(originalCurrency, targetCurrency),
                Instant.now()
            ));
            index++;
            if (offers.size() >= 10) {
                break;
            }
        }
        return offers;
    }

    private List<String> extractCandidateListingBlocks(String html, BookSeed seed) {
        List<String> blocks = new ArrayList<>();
        Set<String> ranges = new LinkedHashSet<>();
        String lowerHtml = html.toLowerCase(Locale.ROOT);
        List<String> anchors = listingAnchors(seed);

        for (String anchor : anchors) {
            String normalizedAnchor = anchor.toLowerCase(Locale.ROOT);
            int fromIndex = 0;
            while (fromIndex >= 0 && fromIndex < lowerHtml.length()) {
                int index = lowerHtml.indexOf(normalizedAnchor, fromIndex);
                if (index < 0) {
                    break;
                }
                int start = findListingStart(html, index);
                int end = findListingEnd(html, index);
                if (end <= start) {
                    start = Math.max(0, index - 2500);
                    end = Math.min(html.length(), index + 3500);
                }
                String key = start + ":" + end;
                if (ranges.add(key)) {
                    blocks.add(html.substring(start, end));
                }
                fromIndex = index + normalizedAnchor.length();
            }
        }
        return blocks;
    }

    private List<String> listingAnchors(BookSeed seed) {
        List<String> anchors = new ArrayList<>();
        String isbn13 = digitsOnly(seed.isbn13());
        String isbn10 = digitsOnly(seed.isbn10());
        if (!isBlank(isbn13)) {
            anchors.add(isbn13);
        }
        if (!isBlank(isbn10)) {
            anchors.add(isbn10);
        }
        if (!isBlank(seed.title()) && seed.title().trim().length() >= 6) {
            anchors.add(seed.title().trim());
        }
        return anchors;
    }

    private int findListingStart(String html, int index) {
        return Math.max(0, index - 900);
    }

    private int findListingEnd(String html, int index) {
        return Math.min(html.length(), index + 4200);
    }

    private boolean isConcreteListingBlock(String block, BookSeed seed) {
        String normalizedBlock = normalizeForMatching(stripTags(block));
        if (isBlank(normalizedBlock)) {
            return false;
        }

        String isbn13 = digitsOnly(seed.isbn13());
        if (!isBlank(isbn13) && normalizedBlock.contains(isbn13)) {
            return true;
        }

        String isbn10 = digitsOnly(seed.isbn10());
        if (!isBlank(isbn10) && normalizedBlock.contains(isbn10)) {
            return true;
        }

        String normalizedTitle = normalizeForMatching(seed.title());
        String normalizedAuthor = normalizeForMatching(first(seed.authors()));
        if (normalizedTitle.length() < 8 || !normalizedBlock.contains(normalizedTitle)) {
            return false;
        }
        return !isBlank(normalizedAuthor) && normalizedBlock.contains(normalizedAuthor);
    }

    private PriceSample extractListingPrice(String block, String defaultCurrency) {
        List<PriceSampleWithPosition> samples = new ArrayList<>();
        collectListingPriceSamples(block, PRICE_PREFIX_PATTERN, true, defaultCurrency, samples);
        collectListingPriceSamples(block, PRICE_SUFFIX_PATTERN, false, defaultCurrency, samples);
        return samples.stream()
            .sorted(Comparator.comparing(PriceSampleWithPosition::position))
            .map(PriceSampleWithPosition::sample)
            .findFirst()
            .orElse(null);
    }

    private void collectListingPriceSamples(String block, Pattern pattern, boolean prefixCurrency, String defaultCurrency, List<PriceSampleWithPosition> samples) {
        Matcher matcher = pattern.matcher(block);
        while (matcher.find()) {
            if (!isListingPriceContext(block, matcher.start(), matcher.end())) {
                continue;
            }
            String currency = prefixCurrency ? matcher.group(1) : matcher.group(2);
            String amountText = prefixCurrency ? matcher.group(2) : matcher.group(1);
            BigDecimal amount = parseAmount(amountText);
            if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0 || amount.compareTo(BigDecimal.valueOf(5000)) > 0) {
                continue;
            }
            samples.add(new PriceSampleWithPosition(new PriceSample(amount, normalizeCurrencySymbol(currency, defaultCurrency)), matcher.start()));
        }
    }

    private boolean isListingPriceContext(String block, int start, int end) {
        String before = stripTags(block.substring(Math.max(0, start - 120), start)).toLowerCase(Locale.ROOT);
        String after = stripTags(block.substring(end, Math.min(block.length(), end + 120))).toLowerCase(Locale.ROOT);
        String context = before + " " + after;

        if (context.contains("shipping")
            || context.contains("ship ")
            || context.contains("ships ")
            || context.contains("postage")
            || context.contains("delivery")
            || context.contains("tax")
            || context.contains("vat")
            || context.contains("wysył")) {
            return false;
        }

        return before.contains("price")
            || before.contains("cena")
            || before.contains("our price")
            || before.contains("sale")
            || !containsPriceLabelNearby(block, end);
    }

    private boolean containsPriceLabelNearby(String block, int end) {
        String after = stripTags(block.substring(end, Math.min(block.length(), end + 80))).toLowerCase(Locale.ROOT);
        return after.contains("shipping") || after.contains("delivery") || after.contains("postage");
    }

    private String extractOfferUrl(String block, String fallbackUrl) {
        Pattern hrefPattern = Pattern.compile("href=\\\"([^\\\"]+)\\\"|href='([^']+)'", Pattern.CASE_INSENSITIVE);
        Matcher matcher = hrefPattern.matcher(block);
        while (matcher.find()) {
            String href = firstNonBlank(matcher.group(1), matcher.group(2));
            if (isBlank(href) || href.startsWith("#") || href.toLowerCase(Locale.ROOT).startsWith("javascript:")) {
                continue;
            }
            if (href.contains("/servlet/")
                || href.contains("/book/")
                || href.contains("/books/")
                || href.contains("/product/")) {
                return absoluteUrl(fallbackUrl, href);
            }
        }
        return fallbackUrl;
    }

    private String absoluteUrl(String baseUrl, String href) {
        try {
            URI base = URI.create(baseUrl);
            return base.resolve(href).toString();
        } catch (Exception ex) {
            return href;
        }
    }

    private String stripTags(String value) {
        if (value == null) {
            return "";
        }
        return value
            .replaceAll("(?is)<script.*?</script>", " ")
            .replaceAll("(?is)<style.*?</style>", " ")
            .replaceAll("<[^>]+>", " ")
            .replace("&nbsp;", " ")
            .replace("&amp;", "&")
            .replace("&#36;", "$")
            .replaceAll("\\s+", " ")
            .trim();
    }

    private boolean containsNoExactMatchMessage(String html) {
        String plainText = stripTags(html).toLowerCase(Locale.ROOT);
        return plainText.contains("unable to find exact matches")
            || plainText.contains("closest match to your search")
            || plainText.contains("no results")
            || plainText.contains("no exact matches")
            || plainText.contains("did not match any products")
            || plainText.contains("0 results")
            || plainText.contains("we couldn't find any matches")
            || plainText.contains("we could not find any matches");
    }

    private List<OfferDTO> deduplicateOffers(List<OfferDTO> offers) {
        Map<String, OfferDTO> deduped = new LinkedHashMap<>();
        for (OfferDTO offer : offers) {
            String key = normalize(offer.source()) + "|" + normalize(offer.offerUrl()) + "|" + safeAmount(offer);
            deduped.putIfAbsent(key, offer);
        }
        return new ArrayList<>(deduped.values());
    }

    private List<OfferDTO> filterOffersBySource(List<OfferDTO> offers, String source) {
        if (isBlank(source)) {
            return offers;
        }
        return offers.stream()
            .filter(offer -> offer.source() != null && offer.source().equalsIgnoreCase(source))
            .toList();
    }

    private Comparator<OfferDTO> offerComparator(OfferSortType sort) {
        Comparator<OfferDTO> priceAscComparator = Comparator.comparing(
            this::safeAmount,
            Comparator.nullsLast(BigDecimal::compareTo)
        );
        Comparator<OfferDTO> priceDescComparator = Comparator.comparing(
            this::safeAmount,
            Comparator.nullsLast(Comparator.<BigDecimal>reverseOrder())
        );
        return switch (sort) {
            case PRICE_DESC -> priceDescComparator;
            case SOURCE_ASC -> Comparator.comparing(OfferDTO::source, String.CASE_INSENSITIVE_ORDER);
            case PRICE_ASC -> priceAscComparator;
        };
    }

    private String offerCacheKey(BookSeed seed, String targetCurrency) {
        return normalizeCurrency(targetCurrency) + '|'
            + normalize(firstNonBlank(seed.isbn13(), seed.isbn10(), seed.workId(), seed.title())) + '|'
            + normalize(seed.title()) + '|'
            + normalize(first(seed.authors()));
    }

    private BigDecimal safeAmount(OfferDTO offer) {
        if (offer == null || offer.convertedPrice() == null || offer.convertedPrice().amount() == null) {
            return null;
        }
        BigDecimal amount = offer.convertedPrice().amount();
        return amount.compareTo(BigDecimal.ZERO) <= 0 ? null : amount;
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


    private String normalizeForMatching(String value) {
        if (isBlank(value)) {
            return "";
        }
        return value.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]+", "");
    }

    private String digitsOnly(String value) {
        if (isBlank(value)) {
            return "";
        }
        return value.replaceAll("[^0-9]", "");
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

    private String pickIsbn10(List<String> values) {
        for (String value : values) {
            if (value != null && value.matches("[0-9]{9}[0-9Xx]")) {
                return value;
            }
        }
        return null;
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

    private record OfferSummary(int count, PriceRangeDTO priceRange) {}

    private record PriceSample(BigDecimal amount, String currency) {}

    private record PriceSampleWithPosition(PriceSample sample, int position) {}
}

