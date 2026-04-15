package pl.pg.pnpios.services;

import org.springframework.stereotype.Service;
import pl.pg.pnpios.dto.CurrencyConvertRequestDTO;
import pl.pg.pnpios.dto.CurrencyConvertResponseDTO;
import pl.pg.pnpios.dto.CurrencyListResponseDTO;
import pl.pg.pnpios.dto.CurrencyRateDTO;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.List;
import java.util.Locale;

@Service
public class CurrencyService {

    public CurrencyListResponseDTO getCurrencies(String base) {
        String normalizedBase = normalizeCurrency(base);

        return new CurrencyListResponseDTO(
            normalizedBase,
            List.of(
                new CurrencyRateDTO("PLN", "Polish Zloty", convert(BigDecimal.ONE, "PLN", normalizedBase), LocalDate.now()),
                new CurrencyRateDTO("USD", "US Dollar", convert(BigDecimal.ONE, "USD", normalizedBase), LocalDate.now()),
                new CurrencyRateDTO("EUR", "Euro", convert(BigDecimal.ONE, "EUR", normalizedBase), LocalDate.now()),
                new CurrencyRateDTO("GBP", "British Pound", convert(BigDecimal.ONE, "GBP", normalizedBase), LocalDate.now())
            )
        );
    }

    public CurrencyListResponseDTO getRates(String base) {
        return getCurrencies(base);
    }

    public CurrencyConvertResponseDTO convert(CurrencyConvertRequestDTO request) {
        BigDecimal convertedAmount = convert(request.amount(), request.from(), request.to());
        BigDecimal rate = convert(BigDecimal.ONE, request.from(), request.to());

        return new CurrencyConvertResponseDTO(
            request.amount(),
            normalizeCurrency(request.from()),
            normalizeCurrency(request.to()),
            rate,
            convertedAmount,
            "STUB_LOCAL_RATES",
            LocalDate.now()
        );
    }

    private BigDecimal convert(BigDecimal amount, String from, String to) {
        String normalizedFrom = normalizeCurrency(from);
        String normalizedTo = normalizeCurrency(to);

        BigDecimal amountInPln = amount.multiply(rateToPln(normalizedFrom));
        return amountInPln.divide(rateToPln(normalizedTo), 2, RoundingMode.HALF_UP);
    }

    private BigDecimal rateToPln(String currency) {
        return switch (normalizeCurrency(currency)) {
            case "USD" -> BigDecimal.valueOf(4.02);
            case "EUR" -> BigDecimal.valueOf(4.32);
            case "GBP" -> BigDecimal.valueOf(5.05);
            case "PLN" -> BigDecimal.ONE;
            default -> BigDecimal.ONE;
        };
    }

    private String normalizeCurrency(String currency) {
        return currency == null || currency.isBlank()
            ? "PLN"
            : currency.trim().toUpperCase(Locale.ROOT);
    }
}