package sqlancer.common.oracle;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.List;
import com.fasterxml.jackson.databind.ObjectMapper;

public class RustEGraphVariantGenerator implements EGraphVariantGenerator {

    //  Monitoring: enable with -Degraph.monitor=true (one-shot, first call only) 
    private static boolean monitorActive = Boolean.getBoolean("egraph.monitor");

    private final String url;
    private final int maxVariants;
    private final long timeoutMillis;

    public RustEGraphVariantGenerator(String url, int maxVariants, long timeoutMillis) {
        if (url == null || url.isBlank()) {
            throw new IllegalArgumentException("Rust e-graph URL must be configured");
        }
        if (maxVariants <= 0) {
            throw new IllegalArgumentException("maxVariants must be positive");
        }
        this.url = url;
        this.maxVariants = maxVariants;
        this.timeoutMillis = timeoutMillis;
    }

    @Override
    public List<String> generateVariants(String query) throws Exception {
        // One-shot: capture monitoring flag, then disable for subsequent calls
        final boolean show = monitorActive;

        if (show) {
            System.err.println();
            System.err.println("   EGRAPH SERVER REQUEST ");
            System.err.printf("  Endpoint: %s/generate-variants%n", url);
            System.err.printf("  Timeout: %d ms%n", timeoutMillis);
            System.err.printf("  Max variants requested: %d%n", maxVariants);
            // Show the original query (truncated)
            String displayQuery = query.length() > 150 ? query.substring(0, 147) + "..." : query;
            System.err.printf("  Original query: %s%n", displayQuery);
        }

        long startTime = System.currentTimeMillis();
        URL endpoint = URI.create(url + "/generate-variants").toURL();
        HttpURLConnection conn = (HttpURLConnection) endpoint.openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setDoOutput(true);
        conn.setConnectTimeout((int) timeoutMillis);
        conn.setReadTimeout((int) timeoutMillis);

        ObjectMapper mapper = new ObjectMapper();
        String requestBody;
        try (OutputStream outputStream = conn.getOutputStream()) {
            GenerateRequest req = new GenerateRequest(query, maxVariants);
            requestBody = mapper.writeValueAsString(req);
            mapper.writeValue(outputStream, req);
        }

        if (show) {
            System.err.printf("  Request body size: %d bytes%n", requestBody.length());
        }

        long connectTime = System.currentTimeMillis() - startTime;
        int responseCode = conn.getResponseCode();

        if (show) {
            System.err.printf("  HTTP response code: %d (connect: %d ms)%n", responseCode, connectTime);
        }

        if (responseCode != 200) {
            StringBuilder errorResponse = new StringBuilder();
            try (BufferedReader errorReader = new BufferedReader(
                    new InputStreamReader(conn.getErrorStream(), StandardCharsets.UTF_8))) {
                String line;
                while (errorReader != null && (line = errorReader.readLine()) != null) {
                    errorResponse.append(line);
                }
            } catch (Exception e) {
                // ignore error stream reading failures
            }

            if (show) {
                System.err.printf("  ERROR response body: %s%n",
                        errorResponse.length() > 200 ? errorResponse.substring(0, 197) + "..."
                                : errorResponse.toString());
            }
            throw new IOException("HTTP request failed with code " + responseCode + ": " + errorResponse.toString());
        }

        String responseBody;
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8))) {
            StringBuilder response = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                response.append(line);
            }
            responseBody = response.toString();
        }

        GenerateResponse resp = mapper.readValue(responseBody, GenerateResponse.class);
        if (resp.error != null && !resp.error.isBlank()) {
            throw new IOException("e-graph server error: " + resp.error);
        }
        long totalTime = System.currentTimeMillis() - startTime;

        if (show) {
            System.err.printf("  Response time: %d ms%n", totalTime);
            System.err.printf("  Variants returned: %d%n",
                    resp.variants != null ? resp.variants.size() : 0);
            if (resp.variants != null) {
                for (int i = 0; i < resp.variants.size(); i++) {
                    String v = resp.variants.get(i);
                    String display = v != null && v.length() > 150 ? v.substring(0, 147) + "..." : v;
                    System.err.printf("    [%d] %s%n", i + 1, display);
                }
            }
            System.err.println("   END EGRAPH SERVER ");
        }

        return resp.variants;
    }

    static class GenerateRequest {
        public String query_base64;
        public int max_variants;

        public GenerateRequest() {
        }

        public GenerateRequest(String query, int maxVariants) {
            this.query_base64 = Base64.getEncoder().encodeToString(query.getBytes(StandardCharsets.UTF_8));
            this.max_variants = maxVariants;
        }
    }

    static class GenerateResponse {
        public List<String> variants;
        public String error;
    }
}
