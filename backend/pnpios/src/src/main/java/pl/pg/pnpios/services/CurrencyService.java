package pl.pg.pnpios.services;

import org.springframework.stereotype.Service;
import pl.pg.pnpios.dto.CurrencyConvertRequestDTO;
import pl.pg.pnpios.dto.CurrencyConvertResponseDTO;
import pl.pg.pnpios.dto.CurrencyListResponseDTO;
import pl.pg.pnpios.dto.CurrencyRateDTO;
import pl.pg.pnpios.external.CurrencyRatesClient;
import pl.pg.pnpios.external.dto.NbpExchangeRatesTableResponse;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

@Service
public class CurrencyService {
    private static final Duration RATES_CACHE_TTL = Duration.ofHours(6);
    private static final Map<String, BigDecimal> FALLBACK_RATES_TO_PLN = Map.of(
        "PLN", BigDecimal.ONE,
        "USD", BigDecimal.valueOf(4.02),
        "EUR", BigDecimal.valueOf(4.32),
        "GBP", BigDecimal.valueOf(5.05)
    );

    private final CurrencyRatesClient currencyRatesClient;
    private final CurrencyRatesCacheService currencyRatesCacheService;
    private volatile RatesSnapshot cachedSnapshot;
    private volatile Instant cachedSnapshotTime;

    public CurrencyService(
        CurrencyRatesClient currencyRatesClient,
        CurrencyRatesCacheService currencyRatesCacheService
    ) {
        this.currencyRatesClient = currencyRatesClient;
        this.currencyRatesCacheService = currencyRatesCacheService;
    }

    public CurrencyListResponseDTO getCurrencies(String base) {
        String normalizedBase = normalizeCurrency(base);
        RatesSnapshot snapshot = loadRatesSnapshot();

        List<CurrencyRateDTO> items = snapshot.ratesToPln().entrySet().stream()
            .sorted(Map.Entry.comparingByKey())
            .map(entry -> new CurrencyRateDTO(
                entry.getKey(),
                currencyName(entry.getKey()),
                convertAmount(BigDecimal.ONE, entry.getKey(), normalizedBase),
                snapshot.rateDate()
            ))
            .toList();

        return new CurrencyListResponseDTO(normalizedBase, items);
    }

    public CurrencyListResponseDTO getRates(String base) {
        return getCurrencies(base);
    }

    public CurrencyConvertResponseDTO convert(CurrencyConvertRequestDTO request) {
        BigDecimal convertedAmount = convertAmount(request.amount(), request.from(), request.to());
        BigDecimal rate = exchangeRate(request.from(), request.to());
        RatesSnapshot snapshot = loadRatesSnapshot();
        return new CurrencyConvertResponseDTO(
            request.amount(),
            normalizeCurrency(request.from()),
            normalizeCurrency(request.to()),
            rate,
            convertedAmount,
            snapshot.provider(),
            snapshot.rateDate()
        );
    }

    public BigDecimal convertAmount(BigDecimal amount, String from, String to) {
        if (amount == null) {
            return BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        }
        String normalizedFrom = normalizeCurrency(from);
        String normalizedTo = normalizeCurrency(to);
        RatesSnapshot snapshot = loadRatesSnapshot();
        BigDecimal amountInPln = amount.multiply(rateToPln(snapshot, normalizedFrom));
        return amountInPln.divide(rateToPln(snapshot, normalizedTo), 2, RoundingMode.HALF_UP);
    }

    public BigDecimal exchangeRate(String from, String to) {
        return convertAmount(BigDecimal.ONE, from, to);
    }

    private RatesSnapshot loadRatesSnapshot() {
        RatesSnapshot snapshot = cachedSnapshot;
        Instant snapshotTime = cachedSnapshotTime;
        Instant now = Instant.now();
        if (snapshot != null && snapshotTime != null && snapshotTime.plus(RATES_CACHE_TTL).isAfter(now)) {
            return snapshot;
        }

        synchronized (this) {
            snapshot = cachedSnapshot;
            snapshotTime = cachedSnapshotTime;
            now = Instant.now();
            if (snapshot != null && snapshotTime != null && snapshotTime.plus(RATES_CACHE_TTL).isAfter(now)) {
                return snapshot;
            }

            RatesSnapshot resolved = resolveRatesSnapshot();
            cachedSnapshot = resolved;
            cachedSnapshotTime = now;
            return resolved;
        }
    }

    private RatesSnapshot resolveRatesSnapshot() {
        Optional<NbpExchangeRatesTableResponse> online = fetchOnlineTableA();
        if (online.isPresent()) {
            return snapshotFromTable(online.get(), "NBP_TABLE_A");
        }

        Optional<NbpExchangeRatesTableResponse> cached = currencyRatesCacheService.load();
        if (cached.isPresent()) {
            return snapshotFromTable(cached.get(), "NBP_TABLE_A_CACHE");
        }

        return new RatesSnapshot(
            new LinkedHashMap<>(FALLBACK_RATES_TO_PLN),
            LocalDate.now(),
            "LOCAL_FALLBACK_RATES"
        );
    }

    private Optional<NbpExchangeRatesTableResponse> fetchOnlineTableA() {
        try {
            List<NbpExchangeRatesTableResponse> tables = currencyRatesClient.getTableA("json");
            if (tables == null || tables.isEmpty() || tables.get(0) == null) {
                return Optional.empty();
            }
            NbpExchangeRatesTableResponse table = tables.get(0);
            currencyRatesCacheService.save(table);
            return Optional.of(table);
        } catch (Exception ex) {
            return Optional.empty();
        }
    }

    private RatesSnapshot snapshotFromTable(NbpExchangeRatesTableResponse table, String provider) {
        Map<String, BigDecimal> rates = new LinkedHashMap<>();
        rates.put("PLN", BigDecimal.ONE);

        if (table != null && table.rates() != null) {
            table.rates().stream()
                .filter(rate -> rate != null && rate.code() != null && rate.mid() != null)
                .sorted(Comparator.comparing(rate -> rate.code().toUpperCase(Locale.ROOT)))
                .forEach(rate -> rates.put(normalizeCurrency(rate.code()), rate.mid()));
        }

        FALLBACK_RATES_TO_PLN.forEach(rates::putIfAbsent);
        LocalDate rateDate = table == null || table.effectiveDate() == null ? LocalDate.now() : table.effectiveDate();
        return new RatesSnapshot(rates, rateDate, provider);
    }

    private BigDecimal rateToPln(RatesSnapshot snapshot, String currency) {
        return snapshot.ratesToPln().getOrDefault(normalizeCurrency(currency), BigDecimal.ONE);
    }

    private String currencyName(String code) {
        return switch (normalizeCurrency(code)) {
            case "PLN" -> "Polish Zloty";
            case "USD" -> "US Dollar";
            case "EUR" -> "Euro";
            case "GBP" -> "British Pound";
            default -> normalizeCurrency(code);
        };
    }

    private String normalizeCurrency(String currency) {
        return currency == null || currency.isBlank() ? "PLN" : currency.trim().toUpperCase(Locale.ROOT);
    }

    private record RatesSnapshot(
        Map<String, BigDecimal> ratesToPln,
        LocalDate rateDate,
        String provider
    ) {}
}
