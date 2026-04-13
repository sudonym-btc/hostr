# Proxy OTLP telemetry to Google Cloud.
# Rendered at deploy time by hostr-fetch-secrets — DO NOT EDIT directly.
# Source template: docker/vhost.d/otlp-proxy.conf.tpl

location /otlp/ {
    # ── CORS preflight ────────────────────────────────────────────────
    if ($request_method = OPTIONS) {
        add_header Access-Control-Allow-Origin  "$http_origin" always;
        add_header Access-Control-Allow-Methods "POST, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Traceparent, Tracestate, Baggage, X-Requested-With" always;
        add_header Access-Control-Max-Age       86400 always;
        add_header Vary "Origin" always;
        return 204;
    }

    # ── Strip /otlp prefix, forward to Google Cloud OTLP endpoint ─────
    rewrite ^/otlp/(.*)$ /$1 break;

    proxy_pass              https://telemetry.googleapis.com;
    proxy_ssl_server_name   on;
    proxy_http_version      1.1;
    proxy_set_header        Host telemetry.googleapis.com;
    proxy_set_header        x-goog-api-key ${GOOGLE_TELEMETRY_API_KEY};
    proxy_set_header        Connection "";
    proxy_set_header        X-Real-IP $remote_addr;
    proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;

    # ── CORS response headers ─────────────────────────────────────────
    add_header Access-Control-Allow-Origin  "$http_origin" always;
    add_header Access-Control-Allow-Methods "POST, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Content-Type, Traceparent, Tracestate, Baggage, X-Requested-With" always;
    add_header Vary "Origin" always;
}
