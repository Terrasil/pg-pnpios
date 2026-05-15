package pl.pg.pnpios.external;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

@FeignClient(name = "googleBooksClient", url = "${google.books.api.base-url:https://www.googleapis.com/books/v1}")
public interface GoogleBooksClient {

    @GetMapping(value = "/volumes")
    String searchVolumes(
        @RequestParam String q,
        @RequestParam int maxResults,
        @RequestParam(required = false) String filter,
        @RequestParam(required = false) String printType,
        @RequestParam(required = false) String projection,
        @RequestParam(required = false) String country,
        @RequestParam(required = false) String key
    );
}
