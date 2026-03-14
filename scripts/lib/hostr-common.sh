#!/usr/bin/env bash

hostr_validate_environment() {
    case "${1:-}" in
        local|test|staging|prod) ;;
        *)
            echo "Usage: ${2:-$0} [local|test|staging|prod] [regtest-fast|regtest-managed]" >&2
            return 64
            ;;
    esac
}

hostr_validate_rif_relay_mode() {
    case "${1:-}" in
        regtest-fast|regtest-managed) ;;
        *)
            echo "Usage: ${2:-$0} [local|test|staging|prod] [regtest-fast|regtest-managed]" >&2
            return 64
            ;;
    esac
}

hostr_require_env_file() {
    local repo_root="$1"
    local environment="$2"
    local env_file="$repo_root/.env.$environment"

    if [ ! -f "$env_file" ]; then
        echo "Missing env file: $env_file" >&2
        return 66
    fi
}

hostr_compose_cmd() {
    local environment="$1"
    shift

    if [ "$environment" = "staging" ] || [ "$environment" = "prod" ]; then
        docker compose -f compose.yaml -f compose.hosted.yaml "$@"
    else
        docker compose "$@"
    fi
}

hostr_load_env() {
    local repo_root="$1"
    local environment="$2"

    hostr_require_env_file "$repo_root" "$environment" || return $?

    set -a
    if { [ "$environment" = "local" ] || [ "$environment" = "test" ]; } && [ -f "$repo_root/dependencies/boltz-regtest/.env" ]; then
        source "$repo_root/dependencies/boltz-regtest/.env"
    fi
    source "$repo_root/.env"
    source "$repo_root/.env.$environment"
    set +a
}

hostr_ensure_certs() {
    local repo_root="$1"
    local environment="$2"

    if [ "$environment" != "local" ] && [ "$environment" != "test" ]; then
        return 0
    fi

    mkdir -p "$repo_root/docker/certs" "$repo_root/docker/tls/ca"

    rm -f "$repo_root/docker/certs"/*.crt "$repo_root/docker/certs"/*.key
    rm -f "$repo_root/docker/tls/ca/ca-bundle.crt"

    docker run --rm \
        -e DOMAIN="${DOMAIN:-hostr.development}" \
        -v "$repo_root/docker/certs:/certs" \
        -v "$repo_root/docker/tls/ca:/ca" \
        -v "$repo_root/docker/tls:/scripts:ro" \
        alpine:3.20 sh /scripts/generate-dev-certs.sh
}
