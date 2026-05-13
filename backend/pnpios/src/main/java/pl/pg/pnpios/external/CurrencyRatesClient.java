package pl.pg.pnpios.external;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import pl.pg.pnpios.external.dto.NbpExchangeRatesTableResponse;

import java.util.List;

@FeignClient(name = "currencyRatesClient", url = "${currency.rates.api.url:https://api.nbp.pl}")
public interface CurrencyRatesClient {
    @GetMapping(value = "/api/exchangerates/tables/A")
    List<NbpExchangeRatesTableResponse> getTableA(@RequestParam(defaultValue = "json") String format);
}
