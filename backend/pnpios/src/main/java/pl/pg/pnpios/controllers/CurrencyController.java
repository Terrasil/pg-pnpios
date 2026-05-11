package pl.pg.pnpios.controllers;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import pl.pg.pnpios.dto.CurrencyConvertRequestDTO;
import pl.pg.pnpios.dto.CurrencyConvertResponseDTO;
import pl.pg.pnpios.dto.CurrencyListResponseDTO;
import pl.pg.pnpios.services.CurrencyService;

@RestController
@AllArgsConstructor
@RequestMapping("/api/v1/currencies")
public class CurrencyController {
    private final CurrencyService currencyService;

    @GetMapping
    public ResponseEntity<CurrencyListResponseDTO> getCurrencies(@RequestParam(defaultValue = "PLN") String base) {
        return ResponseEntity.ok(currencyService.getCurrencies(base));
    }

    @GetMapping("/rates")
    public ResponseEntity<CurrencyListResponseDTO> getRates(@RequestParam(defaultValue = "PLN") String base) {
        return ResponseEntity.ok(currencyService.getRates(base));
    }

    @PostMapping("/convert")
    public ResponseEntity<CurrencyConvertResponseDTO> convert(@Valid @RequestBody CurrencyConvertRequestDTO request) {
        return ResponseEntity.ok(currencyService.convert(request));
    }
}
