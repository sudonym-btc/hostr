# Proxy OTLP telemetry to the on-VM OpenTelemetry Collector.
# The collector authenticates to Google Cloud via VM service account ADC.
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

    # ── Forward to otelcol OTLP HTTP receiver ─────────────────────────
    rewrite ^/otlp/(.*)$ /$1 break;

    proxy_pass         http://otelcol:4318;
    proxy_http_version 1.1;
    proxy_set_header   Host otelcol;
    proxy_set_header   Connection "";
    proxy_set_header   X-Real-IP $remote_addr;
    proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;

    # ── CORS response headers ──────────────────────────────────────────
    add_header Access-Control-Allow-Origin  "$http_origin" always;
    add_header Access-Control-Allow-Methods "POST, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Content-Type, Traceparent, Tracestate, Baggage, X-Requested-With" always;
    add_header Vary "Origin" always;
}
