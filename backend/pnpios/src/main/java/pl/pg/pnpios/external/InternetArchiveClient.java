package pl.pg.pnpios.external;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import pl.pg.pnpios.config.external.InternetArchiveFeignConfig;
import pl.pg.pnpios.external.internetarchive.dto.InternetArchiveMetadataResponse;
import pl.pg.pnpios.external.internetarchive.dto.InternetArchiveSearchResponse;

@FeignClient(name = "internetArchiveClient", url = "${internetarchive.api.url}", configuration = InternetArchiveFeignConfig.class)
public interface InternetArchiveClient {

    @GetMapping("/advancedsearch.php")
    InternetArchiveSearchResponse search(
        @RequestParam("q") String query,
        @RequestParam("fl[]") String[] fields,
        @RequestParam("rows") int rows,
        @RequestParam("page") int page,
        @RequestParam("output") String output
    );

    @GetMapping("/metadata/{identifier}")
    InternetArchiveMetadataResponse getMetadata(@PathVariable("identifier") String identifier);
}
