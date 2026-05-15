package pl.pg.pnpios.external;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import pl.pg.pnpios.config.external.OpenLibraryFeignConfig;
import pl.pg.pnpios.external.openlibrary.dto.OpenLibraryAuthorResponse;
import pl.pg.pnpios.external.openlibrary.dto.OpenLibraryAuthorSearchResponse;
import pl.pg.pnpios.external.openlibrary.dto.OpenLibraryAuthorWorksResponse;
import pl.pg.pnpios.external.openlibrary.dto.OpenLibrarySearchResponse;
import pl.pg.pnpios.external.openlibrary.dto.OpenLibraryWorkResponse;

@FeignClient(name = "openLibraryClient", url = "${openlibrary.api.url}", configuration = OpenLibraryFeignConfig.class)
public interface OpenLibraryClient {

    @GetMapping("/search.json")
    OpenLibrarySearchResponse searchBooks(
        @RequestParam("q") String query,
        @RequestParam("fields") String fields,
        @RequestParam("page") int page,
        @RequestParam("limit") int limit
    );

    @GetMapping("/search/authors.json")
    OpenLibraryAuthorSearchResponse searchAuthors(
        @RequestParam("q") String query,
        @RequestParam("limit") int limit,
        @RequestParam("offset") int offset
    );

    @GetMapping("/authors/{authorId}.json")
    OpenLibraryAuthorResponse getAuthor(@PathVariable("authorId") String authorId);

    @GetMapping("/authors/{authorId}/works.json")
    OpenLibraryAuthorWorksResponse getAuthorWorks(
        @PathVariable("authorId") String authorId,
        @RequestParam("limit") int limit,
        @RequestParam("offset") int offset
    );

    @GetMapping("/works/{workId}.json")
    OpenLibraryWorkResponse getWork(@PathVariable("workId") String workId);
}
