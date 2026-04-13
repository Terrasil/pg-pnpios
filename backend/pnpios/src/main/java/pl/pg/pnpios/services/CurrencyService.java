package pl.pg.pnpios.services;

import org.springframework.stereotype.Service;
import pl.pg.pnpios.dto.CurrencyConvertRequestDTO;
import pl.pg.pnpios.dto.CurrencyConvertResponseDTO;
import pl.pg.pnpios.dto.CurrencyListResponseDTO;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collections;

@Service
public class CurrencyService {

    public CurrencyListResponseDTO getCurrencies(String base) {
        return new CurrencyListResponseDTO(
            base,
            Collections.emptyList()
        );
    }

    public CurrencyListResponseDTO getRates(String base) {
        return new CurrencyListResponseDTO(
            base,
            Collections.emptyList()
        );
    }

    public CurrencyConvertResponseDTO convert(CurrencyConvertRequestDTO request) {
        return new CurrencyConvertResponseDTO(
            request.amount(),
            request.from(),
            request.to(),
            BigDecimal.ONE,
            request.amount(),
            "STUB",
            LocalDate.now()
        );
    }
}