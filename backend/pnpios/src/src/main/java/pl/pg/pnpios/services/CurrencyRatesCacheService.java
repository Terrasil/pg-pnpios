package pl.pg.pnpios.services;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import pl.pg.pnpios.external.dto.NbpExchangeRatesTableResponse;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Optional;

@Service
public class CurrencyRatesCacheService {
    private final ObjectMapper objectMapper;
    private final Path cacheFile;

    public CurrencyRatesCacheService(
        ObjectMapper objectMapper,
        @Value("${currency.rates.cache-file:cache/currency-rates.json}") String cacheFile
    ) {
        this.objectMapper = objectMapper;
        this.cacheFile = Path.of(cacheFile);
    }

    public void save(NbpExchangeRatesTableResponse response) {
        try {
            Path parent = cacheFile.getParent();
            if (parent != null) {
                Files.createDirectories(parent);
            }

            objectMapper
                .writerWithDefaultPrettyPrinter()
                .writeValue(cacheFile.toFile(), response);
        } catch (IOException ex) {
            ex.printStackTrace();
        }
    }

    public Optional<NbpExchangeRatesTableResponse> load() {
        if (!Files.exists(cacheFile)) {
            return Optional.empty();
        }

        try {
            NbpExchangeRatesTableResponse response =
                objectMapper.readValue(cacheFile.toFile(), NbpExchangeRatesTableResponse.class);

            return Optional.ofNullable(response);
        } catch (JacksonException ex) {
            ex.printStackTrace();
            return Optional.empty();
        }
    }
}
