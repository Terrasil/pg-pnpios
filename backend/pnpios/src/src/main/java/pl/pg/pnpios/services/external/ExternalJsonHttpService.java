package pl.pg.pnpios.services.external;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Base64;
import java.util.Map;
import java.util.Optional;
import java.util.StringJoiner;

@Service
public class ExternalJsonHttpService {
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;
    private final String userAgent;

    public ExternalJsonHttpService(
        ObjectMapper objectMapper,
        @Value("${external.http.user-agent:PNPiOS-26/1.0}") String userAgent
    ) {
        this.objectMapper = objectMapper;
        this.userAgent = userAgent == null || userAgent.isBlank() ? "PNPiOS-26/1.0" : userAgent.trim();
        this.httpClient = HttpClient.newBuilder()
            .followRedirects(HttpClient.Redirect.NORMAL)
            .connectTimeout(Duration.ofSeconds(8))
            .build();
    }

    public Optional<JsonNode> getJson(String url) {
        return getJson(url, Map.of());
    }

    public Optional<JsonNode> getJson(String url, Map<String, String> headers) {
        try {
            HttpRequest.Builder builder = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(Duration.ofSeconds(15))
                .header(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON_VALUE)
                .header(HttpHeaders.USER_AGENT, userAgent)
                .GET();

            headers.forEach(builder::header);

            HttpResponse<String> response = httpClient.send(builder.build(), HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (response.statusCode() < 200 || response.statusCode() >= 300 || response.body() == null || response.body().isBlank()) {
                return Optional.empty();
            }
            return Optional.ofNullable(objectMapper.readTree(response.body()));
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
            return Optional.empty();
        } catch (IOException | IllegalArgumentException ex) {
            return Optional.empty();
        }
    }

    public Optional<JsonNode> postFormForJson(String url, Map<String, String> formFields, String basicUser, String basicPassword, Map<String, String> headers) {
        try {
            StringJoiner joiner = new StringJoiner("&");
            formFields.forEach((key, value) -> joiner.add(urlEncode(key) + "=" + urlEncode(value)));
            String basicToken = Base64.getEncoder().encodeToString((basicUser + ":" + basicPassword).getBytes(StandardCharsets.UTF_8));

            HttpRequest.Builder builder = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(Duration.ofSeconds(15))
                .header(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON_VALUE)
                .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_FORM_URLENCODED_VALUE)
                .header(HttpHeaders.AUTHORIZATION, "Basic " + basicToken)
                .header(HttpHeaders.USER_AGENT, userAgent)
                .POST(HttpRequest.BodyPublishers.ofString(joiner.toString(), StandardCharsets.UTF_8));

            headers.forEach(builder::header);

            HttpResponse<String> response = httpClient.send(builder.build(), HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (response.statusCode() < 200 || response.statusCode() >= 300 || response.body() == null || response.body().isBlank()) {
                return Optional.empty();
            }
            return Optional.ofNullable(objectMapper.readTree(response.body()));
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
            return Optional.empty();
        } catch (IOException | IllegalArgumentException ex) {
            return Optional.empty();
        }
    }

    private String urlEncode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }
}
