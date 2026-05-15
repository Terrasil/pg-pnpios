package pl.pg.pnpios.services;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import pl.pg.pnpios.external.dto.NbpExchangeRatesTableResponse;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Optional;

@Service
public class CacheCurrencyRatesService {
    private final ObjectMapper objectMapper;
    private final Path cacheFile;

    public CacheCurrencyRatesService(
            ObjectMapper objectMapper,
            @Value("${currency.rates.cache-file:cache/currency-rates.json}") String cacheFile
    ) {
        this.objectMapper = objectMapper;
        this.cacheFile = Path.of(cacheFile);
    }

    public Optional<NbpExchangeRatesTableResponse> load() {
        if (!Files.exists(cacheFile)) {
            return Optional.empty();
        }

        try {
            String json = Files.readString(cacheFile);

            if (json == null || json.isBlank()) {
                return Optional.empty();
            }

            String trimmed = json.trim();

            if (trimmed.startsWith("[")) {
                List<NbpExchangeRatesTableResponse> responseList = objectMapper.readValue(
                        trimmed,
                        new TypeReference<List<NbpExchangeRatesTableResponse>>() {}
                );

                if (responseList == null || responseList.isEmpty()) {
                    return Optional.empty();
                }

                return Optional.ofNullable(responseList.get(0));
            }

            NbpExchangeRatesTableResponse response = objectMapper.readValue(
                    trimmed,
                    NbpExchangeRatesTableResponse.class
            );

            return Optional.ofNullable(response);
        } catch (IOException ex) {
            ex.printStackTrace();
            return Optional.empty();
        }
    }
}