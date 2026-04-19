# Hosted well-known shims for exact public addresses.

location = /.well-known/nostr.json {
    default_type application/json;
    add_header Access-Control-Allow-Origin * always;
    if ($arg_name != escrow) { return 404; }
    return 200 '{"names":{"escrow":"__HOSTR_BOOTSTRAP_ESCROW_PUBKEY__"},"relays":{"__HOSTR_BOOTSTRAP_ESCROW_PUBKEY__":["__HOSTR_RELAY_URL__"]}}';
}

location = /.well-known/lnurlp/tips {
    proxy_pass https://walletofsatoshi.com/.well-known/lnurlp/paco;
    proxy_ssl_server_name on;
    proxy_set_header Host walletofsatoshi.com;
    proxy_hide_header Access-Control-Allow-Origin;
    add_header Access-Control-Allow-Origin * always;
}
