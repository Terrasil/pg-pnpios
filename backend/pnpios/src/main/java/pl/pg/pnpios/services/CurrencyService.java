package pl.pg.pnpios.services;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import pl.pg.pnpios.dto.CurrencyConvertRequestDTO;
import pl.pg.pnpios.dto.CurrencyConvertResponseDTO;
import pl.pg.pnpios.dto.CurrencyListResponseDTO;
import pl.pg.pnpios.dto.CurrencyRateDTO;
import pl.pg.pnpios.external.CurrencyRatesClient;
import pl.pg.pnpios.external.dto.NbpExchangeRatesTableResponse;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

@Service
public class CurrencyService {
    private static final String PROVIDER = "NBP_TABLE_A";

    private final CurrencyRatesClient currencyRatesClient;
    private final CurrencyRatesCacheService cacheService;
    private final boolean remoteEnabled;

    public CurrencyService(
        CurrencyRatesClient currencyRatesClient,
        CurrencyRatesCacheService cacheService,
        @Value("${currency.rates.remote-enabled:true}") boolean remoteEnabled
    ) {
        this.currencyRatesClient = currencyRatesClient;
        this.cacheService = cacheService;
        this.remoteEnabled = remoteEnabled;
    }

    public CurrencyListResponseDTO getCurrencies(String base) {
        String normalizedBase = normalizeCurrency(base);
        RateTable table = loadRateTable();
        List<CurrencyRateDTO> items = new ArrayList<>();

        for (Map.Entry<String, RateData> entry : table.ratesToPln().entrySet()) {
            String code = entry.getKey();
            BigDecimal rate = convert(BigDecimal.ONE, code, normalizedBase, table).setScale(6, RoundingMode.HALF_UP);
            items.add(new CurrencyRateDTO(code, entry.getValue().name(), rate, table.rateDate()));
        }

        items.sort(Comparator.comparing(CurrencyRateDTO::code));
        return new CurrencyListResponseDTO(normalizedBase, items);
    }

    public CurrencyListResponseDTO getRates(String base) {
        return getCurrencies(base);
    }

    public CurrencyConvertResponseDTO convert(CurrencyConvertRequestDTO request) {
        RateTable table = loadRateTable();
        String from = normalizeCurrency(request.from());
        String to = normalizeCurrency(request.to());
        BigDecimal convertedAmount = convert(request.amount(), from, to, table).setScale(2, RoundingMode.HALF_UP);
        BigDecimal rate = convert(BigDecimal.ONE, from, to, table).setScale(6, RoundingMode.HALF_UP);
        return new CurrencyConvertResponseDTO(request.amount(), from, to, rate, convertedAmount, PROVIDER, table.rateDate());
    }

    private RateTable loadRateTable() {
        if (remoteEnabled) {
            try {
                List<NbpExchangeRatesTableResponse> response = currencyRatesClient.getTableA("json");
                if (response != null && !response.isEmpty() && response.get(0) != null) {
                    NbpExchangeRatesTableResponse table = response.get(0);
                    cacheService.save(table);
                    return mapNbpTable(table);
                }
            } catch (Exception ignored) {
                // Fallback to cache or local rates below.
            }
        }

        Optional<NbpExchangeRatesTableResponse> cached = cacheService.load();
        if (cached.isPresent()) {
            return mapNbpTable(cached.get());
        }

        return fallbackRateTable();
    }

    private RateTable mapNbpTable(NbpExchangeRatesTableResponse response) {
        Map<String, RateData> rates = new LinkedHashMap<>();
        rates.put("PLN", new RateData("Polski złoty", BigDecimal.ONE));

        if (response != null && response.rates() != null) {
            for (NbpExchangeRatesTableResponse.NbpRateItem item : response.rates()) {
                if (item == null || item.code() == null || item.mid() == null) {
                    continue;
                }
                rates.put(normalizeCurrency(item.code()), new RateData(item.currency(), item.mid()));
            }
        }

        LocalDate date = response == null || response.effectiveDate() == null ? LocalDate.now() : response.effectiveDate();
        return new RateTable(date, rates);
    }

    private RateTable fallbackRateTable() {
        Map<String, RateData> rates = new LinkedHashMap<>();
        rates.put("PLN", new RateData("Polski złoty", BigDecimal.ONE));
        rates.put("USD", new RateData("Dolar amerykański", BigDecimal.valueOf(4.02)));
        rates.put("EUR", new RateData("Euro", BigDecimal.valueOf(4.32)));
        rates.put("GBP", new RateData("Funt szterling", BigDecimal.valueOf(5.05)));
        return new RateTable(LocalDate.now(), rates);
    }

    private BigDecimal convert(BigDecimal amount, String from, String to, RateTable table) {
        BigDecimal amountInPln = amount.multiply(rateToPln(from, table));
        return amountInPln.divide(rateToPln(to, table), 8, RoundingMode.HALF_UP);
    }

    private BigDecimal rateToPln(String currency, RateTable table) {
        RateData rate = table.ratesToPln().get(normalizeCurrency(currency));
        if (rate == null || rate.rateToPln() == null || rate.rateToPln().compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ONE;
        }
        return rate.rateToPln();
    }

    private String normalizeCurrency(String currency) {
        return currency == null || currency.isBlank() ? "PLN" : currency.trim().toUpperCase(Locale.ROOT);
    }

    private record RateTable(LocalDate rateDate, Map<String, RateData> ratesToPln) {}

    private record RateData(String name, BigDecimal rateToPln) {}
}
