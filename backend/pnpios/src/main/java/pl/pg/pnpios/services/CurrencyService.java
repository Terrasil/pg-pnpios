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
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

@Service
public class CurrencyService {
    private final CurrencyRatesClient currencyRatesClient;
    private final CurrencyRatesCacheService currencyRatesCacheService;
    private final CacheCurrencyRatesService cacheCurrencyRatesService;
    private final boolean remoteEnabled;

    public CurrencyService(
        CurrencyRatesClient currencyRatesClient,
        CurrencyRatesCacheService currencyRatesCacheService,
        CacheCurrencyRatesService cacheCurrencyRatesService,
        @Value("${currency.rates.remote-enabled:true}") boolean remoteEnabled
    ) {
        this.currencyRatesClient = currencyRatesClient;
        this.currencyRatesCacheService = currencyRatesCacheService;
        this.cacheCurrencyRatesService = cacheCurrencyRatesService;
        this.remoteEnabled = remoteEnabled;
    }

    public CurrencyListResponseDTO getCurrencies(String base) {
        return buildCurrencyListResponse(normalizeCurrency(base));
    }

    public CurrencyListResponseDTO getRates(String base) {
        return buildCurrencyListResponse(normalizeCurrency(base));
    }

    public CurrencyConvertResponseDTO convert(CurrencyConvertRequestDTO request) {
        String from = normalizeCurrency(request.from());
        String to = normalizeCurrency(request.to());

        RatesSnapshot snapshot = loadRatesSnapshot();
        BigDecimal convertedAmount = convertAmount(request.amount(), from, to, snapshot.ratesToPln());
        BigDecimal rate = convertAmount(BigDecimal.ONE, from, to, snapshot.ratesToPln());

        return new CurrencyConvertResponseDTO(
            request.amount(),
            from,
            to,
            rate,
            convertedAmount,
            snapshot.source(),
            snapshot.rateDate()
        );
    }

    private CurrencyListResponseDTO buildCurrencyListResponse(String base) {
        RatesSnapshot snapshot = loadRatesSnapshot();
        List<CurrencyRateDTO> items = new ArrayList<>();

        for (Map.Entry<String, CurrencyEntry> entry : snapshot.entries().entrySet()) {
            String code = entry.getKey();
            CurrencyEntry currencyEntry = entry.getValue();
            BigDecimal rateInBase = convertAmount(BigDecimal.ONE, code, base, snapshot.ratesToPln());

            items.add(new CurrencyRateDTO(
                code,
                currencyEntry.name(),
                rateInBase,
                snapshot.rateDate()
            ));
        }

        return new CurrencyListResponseDTO(base, items);
    }

    private RatesSnapshot loadRatesSnapshot() {
        if (remoteEnabled) {
            try {
                List<NbpExchangeRatesTableResponse> response = currencyRatesClient.getTableA("json");

                if (response != null && !response.isEmpty() && response.get(0) != null) {
                    NbpExchangeRatesTableResponse table = response.get(0);
                    currencyRatesCacheService.save(table);
                    return mapSnapshot(table, "NBP");
                }
            } catch (Exception ex) {
                ex.printStackTrace();
            }
        }

        Optional<NbpExchangeRatesTableResponse> cached = currencyRatesCacheService.load();
        if (cached.isPresent()) {
            return mapSnapshot(cached.get(), "NBP_CACHE");
        }

        Optional<NbpExchangeRatesTableResponse> bundled = cacheCurrencyRatesService.load();
        if (bundled.isPresent()) {
            return mapSnapshot(bundled.get(), "NBP_BUNDLED");
        }

        throw new IllegalStateException("Nie udało się pobrać kursów walut z NBP, brak danych w cache i brak danych wbudowanych.");
    }

    private RatesSnapshot mapSnapshot(NbpExchangeRatesTableResponse table, String source) {
        Map<String, CurrencyEntry> entries = new LinkedHashMap<>();
        Map<String, BigDecimal> ratesToPln = new LinkedHashMap<>();

        entries.put("PLN", new CurrencyEntry("Polski złoty"));
        ratesToPln.put("PLN", BigDecimal.ONE);

        if (table.rates() != null) {
            for (NbpExchangeRatesTableResponse.NbpRateItem rateItem : table.rates()) {
                if (rateItem == null || rateItem.code() == null || rateItem.mid() == null) {
                    continue;
                }

                String code = normalizeCurrency(rateItem.code());
                String name = rateItem.currency() == null || rateItem.currency().isBlank()
                    ? code
                    : rateItem.currency();

                entries.put(code, new CurrencyEntry(name));
                ratesToPln.put(code, rateItem.mid());
            }
        }

        LocalDate rateDate = table.effectiveDate() != null
            ? table.effectiveDate()
            : LocalDate.now();

        return new RatesSnapshot(rateDate, entries, ratesToPln, source);
    }

    private BigDecimal convertAmount(BigDecimal amount, String from, String to, Map<String, BigDecimal> ratesToPln) {
        BigDecimal fromRate = rateToPln(from, ratesToPln);
        BigDecimal toRate = rateToPln(to, ratesToPln);
        BigDecimal amountInPln = amount.multiply(fromRate);
        return amountInPln.divide(toRate, 4, RoundingMode.HALF_UP);
    }

    private BigDecimal rateToPln(String currency, Map<String, BigDecimal> ratesToPln) {
        BigDecimal rate = ratesToPln.get(normalizeCurrency(currency));
        if (rate == null) {
            throw new IllegalArgumentException("Nieobsługiwana waluta: " + currency);
        }
        return rate;
    }

    private String normalizeCurrency(String currency) {
        return currency == null || currency.isBlank()
            ? "PLN"
            : currency.trim().toUpperCase(Locale.ROOT);
    }

    private record CurrencyEntry(String name) {}

    private record RatesSnapshot(
        LocalDate rateDate,
        Map<String, CurrencyEntry> entries,
        Map<String, BigDecimal> ratesToPln,
        String source
    ) {}
}
