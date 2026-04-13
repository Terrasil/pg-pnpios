package pl.pg.pnpios.controllers;

import lombok.AllArgsConstructor;
import pl.pg.pnpios.dto.CurrencyConvertRequestDTO;
import pl.pg.pnpios.dto.CurrencyConvertResponseDTO;
import pl.pg.pnpios.dto.CurrencyListResponseDTO;
import org.springframework.http.ResponseEntity;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import pl.pg.pnpios.services.CurrencyService;

@RestController
@AllArgsConstructor
@RequestMapping("/api/v1/currencies")
public class CurrencyController {
    private final CurrencyService currencyService;

    @GetMapping
    public ResponseEntity<CurrencyListResponseDTO> getCurrencies(
        @RequestParam(defaultValue = "PLN") String base
    ) {
        return ResponseEntity.ok(currencyService.getCurrencies(base));
    }

    @GetMapping("/rates")
    public ResponseEntity<CurrencyListResponseDTO> getRates(
        @RequestParam(defaultValue = "PLN") String base
    ) {
        return ResponseEntity.ok(currencyService.getRates(base));
    }

    @PostMapping("/convert")
    public ResponseEntity<CurrencyConvertResponseDTO> convert(
        @Valid @RequestBody CurrencyConvertRequestDTO request
    ) {
        return ResponseEntity.ok(currencyService.convert(request));
    }
}
