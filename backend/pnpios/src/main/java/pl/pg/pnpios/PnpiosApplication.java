package pl.pg.pnpios;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;

@SpringBootApplication
@EnableFeignClients(basePackages = "pl.pg.pnpios.external")
public class PnpiosApplication {
    public static void main(String[] args) {
        SpringApplication.run(PnpiosApplication.class, args);
    }
}
