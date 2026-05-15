package pl.pg.pnpios.services.external;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import pl.pg.pnpios.external.OpenLibraryClient;
import pl.pg.pnpios.external.openlibrary.dto.OpenLibraryAuthorDoc;
import pl.pg.pnpios.external.openlibrary.dto.OpenLibraryAuthorResponse;
import pl.pg.pnpios.external.openlibrary.dto.OpenLibraryAuthorSearchResponse;
import pl.pg.pnpios.external.openlibrary.dto.OpenLibraryAuthorWorkEntry;
import pl.pg.pnpios.external.openlibrary.dto.OpenLibraryAuthorWorksResponse;
import pl.pg.pnpios.external.openlibrary.dto.OpenLibraryBookDoc;
import pl.pg.pnpios.external.openlibrary.dto.OpenLibrarySearchResponse;
import pl.pg.pnpios.external.openlibrary.dto.OpenLibraryWorkAuthorRef;
import pl.pg.pnpios.external.openlibrary.dto.OpenLibraryWorkResponse;
import pl.pg.pnpios.services.support.AuthorSearchData;
import pl.pg.pnpios.services.support.AuthorSeed;
import pl.pg.pnpios.services.support.BookSearchData;
import pl.pg.pnpios.services.support.BookSeed;

import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

@Service
public class OpenLibraryService {
    private static final String SEARCH_FIELDS = "key,title,author_name,cover_i,first_publish_year,language,publisher,isbn,subject,ebook_access,ia,public_scan_b,editions";

    private final OpenLibraryClient client;
    private final int authorWorksLimit;

    public OpenLibraryService(
        OpenLibraryClient client,
        @Value("${openlibrary.author-works-limit:20}") int authorWorksLimit
    ) {
        this.client = client;
        this.authorWorksLimit = Math.max(1, authorWorksLimit);
    }

    public BookSearchData searchBooks(String query, int page, int size) {
        if (isBlank(query)) {
            return new BookSearchData(0, List.of());
        }

        try {
            OpenLibrarySearchResponse response = client.searchBooks(
                query.trim(),
                SEARCH_FIELDS,
                Math.max(1, page + 1),
                Math.max(1, Math.min(size, 20))
            );

            long total = response == null || response.numFound() == null ? 0 : response.numFound();
            List<BookSeed> items = safeList(response == null ? null : response.docs()).stream()
                .map(this::mapBookDoc)
                .toList();

            return new BookSearchData(total, items);
        } catch (Exception ex) {
            return new BookSearchData(0, List.of());
        }
    }

    public Optional<BookSeed> getBookById(String workId) {
        if (isBlank(workId)) {
            return Optional.empty();
        }

        try {
            OpenLibraryWorkResponse work = client.getWork(workId.trim());
            if (work == null) {
                return Optional.empty();
            }

            List<String> authors = new ArrayList<>();
            for (OpenLibraryWorkAuthorRef ref : safeList(work.authors())) {
                if (ref == null || ref.author() == null) {
                    continue;
                }
                String authorKey = firstNonBlank(ref.author().authorKey(), ref.author().key());
                if (!isBlank(authorKey)) {
                    findAuthorNameByKey(authorKey).ifPresent(authors::add);
                }
            }

            List<String> subjects = limitStrings(work.subjects(), 8);
            Integer year = yearFromText(null);

            return Optional.of(new BookSeed(
                stripPrefix(work.key(), "/works/"),
                firstNonBlank(work.title(), "Nieznany tytuł"),
                null,
                authors,
                buildWorkCoverUrl(work.covers()),
                null,
                subjects.isEmpty() ? null : subjects.get(0),
                null,
                null,
                year,
                descriptionText(work.description()),
                null,
                null,
                subjects
            ));
        } catch (Exception ex) {
            return Optional.empty();
        }
    }

    public AuthorSearchData searchAuthors(String query, int page, int size) {
        if (isBlank(query)) {
            return new AuthorSearchData(0, List.of());
        }

        try {
            OpenLibraryAuthorSearchResponse response = client.searchAuthors(
                query.trim(),
                Math.max(1, Math.min(size, 20)),
                Math.max(0, page * size)
            );

            long total = response == null || response.numFound() == null ? 0 : response.numFound();
            List<AuthorSeed> items = safeList(response == null ? null : response.docs()).stream()
                .map(this::mapAuthorDoc)
                .toList();

            return new AuthorSearchData(total, items);
        } catch (Exception ex) {
            return new AuthorSearchData(0, List.of());
        }
    }

    public Optional<AuthorSeed> getAuthorById(String authorId) {
        if (isBlank(authorId)) {
            return Optional.empty();
        }

        try {
            OpenLibraryAuthorResponse author = client.getAuthor(authorId.trim());
            if (author == null) {
                return Optional.empty();
            }

            int booksCount = getAuthorWorks(authorId, authorWorksLimit).size();
            return Optional.of(new AuthorSeed(
                stripPrefix(author.key(), "/authors/"),
                firstNonBlank(author.name(), "Nieznany autor"),
                yearFromText(author.birth_date()),
                yearFromText(author.death_date()),
                descriptionText(author.bio()),
                buildAuthorPhotoUrl(stripPrefix(author.key(), "/authors/"), author.photos()),
                booksCount
            ));
        } catch (Exception ex) {
            return Optional.empty();
        }
    }

    public List<BookSeed> getAuthorWorks(String authorId, int limit) {
        if (isBlank(authorId)) {
            return List.of();
        }

        try {
            OpenLibraryAuthorWorksResponse response = client.getAuthorWorks(
                authorId.trim(),
                Math.max(1, limit),
                0
            );

            Set<String> seen = new LinkedHashSet<>();
            List<BookSeed> items = new ArrayList<>();
            for (OpenLibraryAuthorWorkEntry entry : safeList(response == null ? null : response.entries())) {
                String id = stripPrefix(entry == null ? null : entry.key(), "/works/");
                if (isBlank(id) || !seen.add(id)) {
                    continue;
                }
                List<String> subjects = limitStrings(entry.subject(), 5);
                items.add(new BookSeed(
                    id,
                    firstNonBlank(entry.title(), "Nieznany tytuł"),
                    null,
                    List.of(),
                    buildWorkCoverUrl(entry.covers()),
                    null,
                    subjects.isEmpty() ? null : subjects.get(0),
                    null,
                    null,
                    entry.first_publish_year(),
                    descriptionText(entry.description()),
                    null,
                    null,
                    subjects
                ));
            }
            return items;
        } catch (Exception ex) {
            return List.of();
        }
    }

    private BookSeed mapBookDoc(OpenLibraryBookDoc doc) {
        List<String> genres = limitStrings(doc == null ? null : doc.subject(), 6);
        return new BookSeed(
            stripPrefix(doc == null ? null : doc.key(), "/works/"),
            firstNonBlank(doc == null ? null : doc.title(), "Nieznany tytuł"),
            null,
            safeList(doc == null ? null : doc.author_name()),
            buildBookCoverUrl(doc == null ? null : doc.cover_i()),
            firstString(doc == null ? null : doc.language()),
            genres.isEmpty() ? null : genres.get(0),
            firstLength(doc == null ? null : doc.isbn(), 10),
            firstLength(doc == null ? null : doc.isbn(), 13),
            doc == null ? null : doc.first_publish_year(),
            null,
            firstString(doc == null ? null : doc.publisher()),
            null,
            genres
        );
    }

    private AuthorSeed mapAuthorDoc(OpenLibraryAuthorDoc doc) {
        String id = stripPrefix(doc == null ? null : doc.key(), "/authors/");
        int booksCount = doc == null || doc.work_count() == null ? 0 : doc.work_count();
        return new AuthorSeed(
            id,
            firstNonBlank(doc == null ? null : doc.name(), "Nieznany autor"),
            yearFromText(doc == null ? null : doc.birth_date()),
            yearFromText(doc == null ? null : doc.death_date()),
            null,
            buildAuthorPhotoUrl(id, null),
            booksCount
        );
    }

    private Optional<String> findAuthorNameByKey(String authorKey) {
        String normalized = stripPrefix(authorKey, "/authors/");
        return getAuthorById(normalized).map(AuthorSeed::name).filter(name -> !isBlank(name));
    }

    private String buildBookCoverUrl(Integer coverId) {
        return coverId == null ? null : "https://covers.openlibrary.org/b/id/" + coverId + "-L.jpg";
    }

    private String buildWorkCoverUrl(List<Integer> covers) {
        Integer first = covers == null || covers.isEmpty() ? null : covers.get(0);
        return first == null ? null : "https://covers.openlibrary.org/b/id/" + first + "-L.jpg";
    }

    private String buildAuthorPhotoUrl(String authorId, List<Integer> photos) {
        if (isBlank(authorId)) {
            return null;
        }
        if (photos != null && !photos.isEmpty() && photos.get(0) != null) {
            return "https://covers.openlibrary.org/a/id/" + photos.get(0) + "-L.jpg";
        }
        return "https://covers.openlibrary.org/a/olid/" + authorId + "-M.jpg";
    }

    private String descriptionText(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof String text) {
            return text;
        }
        if (value instanceof java.util.Map<?, ?> map) {
            Object inner = map.get("value");
            return inner == null ? null : inner.toString();
        }
        return value.toString();
    }

    private Integer yearFromText(String value) {
        if (isBlank(value)) {
            return null;
        }
        StringBuilder digits = new StringBuilder();
        for (char c : value.toCharArray()) {
            if (Character.isDigit(c)) {
                digits.append(c);
                if (digits.length() == 4) {
                    break;
                }
            }
        }
        if (digits.length() != 4) {
            return null;
        }
        try {
            return Integer.parseInt(digits.toString());
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private String stripPrefix(String value, String prefix) {
        if (value == null) {
            return "";
        }
        String normalized = value.trim();
        if (prefix != null && normalized.startsWith(prefix)) {
            normalized = normalized.substring(prefix.length());
        }
        return normalized;
    }

    private List<String> limitStrings(List<String> values, int limit) {
        if (values == null || values.isEmpty()) {
            return List.of();
        }
        List<String> result = new ArrayList<>();
        for (String value : values) {
            if (!isBlank(value)) {
                result.add(value.trim());
                if (result.size() >= limit) {
                    break;
                }
            }
        }
        return result;
    }

    private String firstString(List<String> values) {
        if (values == null) {
            return null;
        }
        for (String value : values) {
            if (!isBlank(value)) {
                return value.trim();
            }
        }
        return null;
    }

    private String firstLength(List<String> values, int length) {
        if (values == null) {
            return null;
        }
        for (String value : values) {
            if (!isBlank(value) && value.trim().length() == length) {
                return value.trim();
            }
        }
        return null;
    }

    private String firstNonBlank(String... values) {
        if (values == null) {
            return null;
        }
        for (String value : values) {
            if (!isBlank(value)) {
                return value.trim();
            }
        }
        return null;
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private <T> List<T> safeList(Collection<T> values) {
        return values == null ? List.of() : new ArrayList<>(values);
    }
}
