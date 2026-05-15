package pl.pg.pnpios.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import pl.pg.pnpios.dto.AuthorDetailsDTO;
import pl.pg.pnpios.dto.AuthorSearchItemDTO;
import pl.pg.pnpios.dto.AuthorSearchResponseDTO;
import pl.pg.pnpios.dto.BookSearchItemDTO;
import pl.pg.pnpios.dto.BookSearchResponseDTO;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class AuthorService {
    private static final Pattern YEAR_PATTERN = Pattern.compile("(1[0-9]{3}|20[0-9]{2})");

    private final BookService bookService;
    private final ObjectMapper objectMapper;

    private final HttpClient httpClient = HttpClient.newBuilder()
        .connectTimeout(Duration.ofSeconds(10))
        .followRedirects(HttpClient.Redirect.NORMAL)
        .build();

    public AuthorSearchResponseDTO searchAuthors(String q, int page, int size) {
        if (isBlank(q)) {
            return new AuthorSearchResponseDTO(q, page, size, 0, 0, List.of());
        }

        int safePage = Math.max(1, page + 1);
        int safeSize = Math.max(1, size);
        JsonNode root = getJson("https://openlibrary.org/search/authors.json?q=" + encode(q) + "&page=" + safePage + "&limit=" + safeSize);
        if (root == null) {
            return new AuthorSearchResponseDTO(q, page, size, 0, 0, List.of());
        }

        List<AuthorSearchItemDTO> items = new ArrayList<>();
        JsonNode docs = root.get("docs");
        if (docs != null && docs.isArray()) {
            for (JsonNode doc : docs) {
                items.add(new AuthorSearchItemDTO(
                    normalizeAuthorId(stringValue(doc.get("key"))),
                    blankToDefault(stringValue(doc.get("name")), "Nieznany autor"),
                    parseYear(stringValue(doc.get("birth_date"))),
                    parseYear(stringValue(doc.get("death_date"))),
                    authorPhotoUrl(normalizeAuthorId(stringValue(doc.get("key")))),
                    integerValue(doc.get("work_count"), 0)
                ));
            }
        }

        int total = integerValue(root.get("numFound"), items.size());
        return new AuthorSearchResponseDTO(q, page, size, total, calculateTotalPages(total, size), items);
    }

    public AuthorDetailsDTO getAuthorDetails(String authorId) {
        String normalizedAuthorId = normalizeAuthorId(authorId);
        JsonNode author = getJson("https://openlibrary.org/authors/" + normalizedAuthorId + ".json");
        String name = blankToDefault(stringValue(author == null ? null : author.get("name")), normalizedAuthorId);
        String biography = descriptionValue(author == null ? null : author.get("bio"));
        Integer birthYear = parseYear(stringValue(author == null ? null : author.get("birth_date")));
        Integer deathYear = parseYear(stringValue(author == null ? null : author.get("death_date")));
        String photoUrl = authorPhotoUrl(normalizedAuthorId);
        List<BookSearchItemDTO> books = getAuthorBooks(normalizedAuthorId, 0, 20, "PLN").items();

        return new AuthorDetailsDTO(
            normalizedAuthorId,
            name,
            birthYear,
            deathYear,
            blankToDefault(biography, "Brak opisu autora."),
            photoUrl,
            books
        );
    }

    public BookSearchResponseDTO getAuthorBooks(String authorId, int page, int size, String currency) {
        String normalizedAuthorId = normalizeAuthorId(authorId);
        String url = "https://openlibrary.org/authors/" + normalizedAuthorId + "/works.json?limit=" + Math.max(1, size) + "&offset=" + Math.max(0, page * size);
        JsonNode root = getJson(url);
        if (root == null) {
            return new BookSearchResponseDTO(normalizedAuthorId, page, size, 0, 0, List.of());
        }

        JsonNode authorNode = getJson("https://openlibrary.org/authors/" + normalizedAuthorId + ".json");
        String authorName = blankToDefault(stringValue(authorNode == null ? null : authorNode.get("name")), normalizedAuthorId);

        List<BookSearchItemDTO> books = new ArrayList<>();
        JsonNode entries = root.get("entries");
        if (entries != null && entries.isArray()) {
            for (JsonNode entry : entries) {
                String workId = normalizeWorkId(stringValue(entry.get("key")));
                String title = stringValue(entry.get("title"));
                String coverUrl = coverUrl(firstIntegerFromArray(entry.get("covers"), -1));
                String genre = first(stringList(entry.get("subjects")));
                books.add(bookService.createBookListItemForAuthorWorks(workId, title, coverUrl, genre, authorName, currency));
            }
        }

        int total = integerValue(root.get("size"), books.size());
        return new BookSearchResponseDTO(authorName, page, size, total, calculateTotalPages(total, size), books);
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
                .header("Accept", "application/json")
                .header("User-Agent", "Mozilla/5.0")
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

    private String authorPhotoUrl(String authorId) {
        if (isBlank(authorId)) {
            return null;
        }
        return "https://covers.openlibrary.org/a/olid/" + authorId + "-L.jpg";
    }

    private String normalizeAuthorId(String authorId) {
        if (isBlank(authorId)) {
            return "";
        }
        return authorId.startsWith("/authors/") ? authorId.substring("/authors/".length()) : authorId;
    }

    private String normalizeWorkId(String workId) {
        if (isBlank(workId)) {
            return "";
        }
        return workId.startsWith("/works/") ? workId.substring("/works/".length()) : workId;
    }

    private String coverUrl(int coverId) {
        if (coverId <= 0) {
            return null;
        }
        return "https://covers.openlibrary.org/b/id/" + coverId + "-L.jpg";
    }

    private String encode(String value) {
        return URLEncoder.encode(value == null ? "" : value, StandardCharsets.UTF_8);
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private String blankToDefault(String value, String fallback) {
        return isBlank(value) ? fallback : value;
    }

    private Integer parseYear(String value) {
        if (isBlank(value)) {
            return null;
        }
        Matcher matcher = YEAR_PATTERN.matcher(value);
        return matcher.find() ? Integer.parseInt(matcher.group(1)) : null;
    }

    private int integerValue(JsonNode node, int fallback) {
        if (node == null || node.isNull() || node.isMissingNode()) {
            return fallback;
        }
        if (node.isNumber()) {
            return node.asInt();
        }
        try {
            return Integer.parseInt(node.asString());
        } catch (NumberFormatException ex) {
            return fallback;
        }
    }

    private int calculateTotalPages(int totalElements, int size) {
        return size <= 0 ? (totalElements > 0 ? 1 : 0) : (int) Math.ceil((double) totalElements / size);
    }

    private String stringValue(JsonNode node) {
        if (node == null || node.isNull() || node.isMissingNode()) {
            return null;
        }
        return node.isString() ? node.asString() : node.toString();
    }

    private int firstIntegerFromArray(JsonNode node, int fallback) {
        if (node == null || !node.isArray() || node.size() == 0) {
            return fallback;
        }
        return integerValue(node.get(0), fallback);
    }

    private List<String> stringList(JsonNode node) {
        if (node == null || !node.isArray()) {
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

    private String first(List<String> values) {
        return values == null || values.isEmpty() ? null : values.get(0);
    }
}
