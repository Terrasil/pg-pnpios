package pl.pg.pnpios.services;

import org.junit.jupiter.api.Test;
import pl.pg.pnpios.dto.CurrencyConvertRequestDTO;
import pl.pg.pnpios.dto.CurrencyConvertResponseDTO;
import pl.pg.pnpios.external.CurrencyRatesClient;
import pl.pg.pnpios.external.dto.NbpExchangeRatesTableResponse;
import tools.jackson.databind.ObjectMapper;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertSame;

class CurrencyServiceTest {

    @Test
    void convertsMoneyUsingRemoteNbpRatesAndNormalizesCurrencyCodes() {
        NbpExchangeRatesTableResponse table = rateTable(
            rate("dolar amerykański", "USD", "4.00"),
            rate("euro", "EUR", "5.00")
        );
        InMemoryCurrencyRatesCacheService cacheService = new InMemoryCurrencyRatesCacheService(Optional.empty());
        CurrencyService service = new CurrencyService(format -> List.of(table), cacheService, true);

        CurrencyConvertResponseDTO result = service.convert(
            new CurrencyConvertRequestDTO(new BigDecimal("10.00"), "usd", "eur")
        );

        assertEquals("USD", result.from());
        assertEquals("EUR", result.to());
        assertBigDecimalEquals("0.800000", result.rate());
        assertBigDecimalEquals("8.00", result.convertedAmount());
        assertEquals("NBP_TABLE_A", result.provider());
        assertEquals(LocalDate.of(2026, 5, 15), result.rateDate());
        assertSame(table, cacheService.savedResponse);
    }

    @Test
    void fallsBackToCachedRatesWhenRemoteClientFails() {
        NbpExchangeRatesTableResponse cachedTable = rateTable(
            rate("funt szterling", "GBP", "5.00")
        );
        InMemoryCurrencyRatesCacheService cacheService = new InMemoryCurrencyRatesCacheService(Optional.of(cachedTable));
        CurrencyRatesClient failingClient = format -> {
            throw new IllegalStateException("Remote API unavailable");
        };
        CurrencyService service = new CurrencyService(failingClient, cacheService, true);

        CurrencyConvertResponseDTO result = service.convert(
            new CurrencyConvertRequestDTO(new BigDecimal("10.00"), "GBP", "PLN")
        );

        assertEquals("GBP", result.from());
        assertEquals("PLN", result.to());
        assertBigDecimalEquals("5.000000", result.rate());
        assertBigDecimalEquals("50.00", result.convertedAmount());
        assertEquals(LocalDate.of(2026, 5, 15), result.rateDate());
    }

    @Test
    void exposesRatesInRequestedBaseCurrency() {
        NbpExchangeRatesTableResponse table = rateTable(
            rate("dolar amerykański", "USD", "4.00"),
            rate("euro", "EUR", "5.00")
        );
        CurrencyService service = new CurrencyService(
            format -> List.of(table),
            new InMemoryCurrencyRatesCacheService(Optional.empty()),
            true
        );

        var response = service.getCurrencies("EUR");

        assertEquals("EUR", response.base());
        assertNotNull(response.items());
        var usd = response.items().stream()
            .filter(item -> item.code().equals("USD"))
            .findFirst()
            .orElseThrow();
        assertBigDecimalEquals("0.800000", usd.rate());
    }

    private static NbpExchangeRatesTableResponse rateTable(NbpExchangeRatesTableResponse.NbpRateItem... rates) {
        return new NbpExchangeRatesTableResponse(
            "A",
            "001/A/NBP/2026",
            LocalDate.of(2026, 5, 15),
            List.of(rates)
        );
    }

    private static NbpExchangeRatesTableResponse.NbpRateItem rate(String name, String code, String value) {
        return new NbpExchangeRatesTableResponse.NbpRateItem(name, code, new BigDecimal(value));
    }

    private static void assertBigDecimalEquals(String expected, BigDecimal actual) {
        assertEquals(0, new BigDecimal(expected).compareTo(actual), () -> "Expected " + expected + " but was " + actual);
    }

    private static final class InMemoryCurrencyRatesCacheService extends CurrencyRatesCacheService {
        private final Optional<NbpExchangeRatesTableResponse> cachedResponse;
        private NbpExchangeRatesTableResponse savedResponse;

        private InMemoryCurrencyRatesCacheService(Optional<NbpExchangeRatesTableResponse> cachedResponse) {
            super(new ObjectMapper(), "target/test-currency-rates-cache.json");
            this.cachedResponse = cachedResponse;
        }

        @Override
        public void save(NbpExchangeRatesTableResponse response) {
            this.savedResponse = response;
        }

        @Override
        public Optional<NbpExchangeRatesTableResponse> load() {
            return cachedResponse;
        }
    }
}
