package pl.pg.pnpios.config.external;

import feign.RequestInterceptor;
import feign.RequestTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;

public class InternetArchiveFeignConfig {

    @Bean
    public RequestInterceptor internetArchiveUserAgentInterceptor(
        @Value("${external.api.user-agent:PNPiOS-26/1.0 (contact: unknown@example.com)}") String userAgent
    ) {
        return new RequestInterceptor() {
            @Override
            public void apply(RequestTemplate template) {
                template.header("User-Agent", userAgent);
                template.header("Accept", "application/json");
            }
        };
    }
}
