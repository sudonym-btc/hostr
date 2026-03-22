#!/usr/bin/env bash

hostr_validate_environment() {
    case "${1:-}" in
        local|test|staging|prod) ;;
        *)
            echo "Usage: ${2:-$0} [local|test|staging|prod]" >&2
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

    local compose_files="${HOSTR_COMPOSE_FILES:-}"

    if [ -z "$compose_files" ]; then
        if [ "$environment" = "staging" ] || [ "$environment" = "prod" ]; then
            compose_files="compose.yaml,compose.hosted.yaml"
        else
            compose_files="compose.yaml,compose.local.yaml"
        fi
    fi

    local file_args=()
    IFS=',' read -ra files <<< "$compose_files"
    for f in "${files[@]}"; do
        file_args+=(-f "$f")
    done

    docker compose "${file_args[@]}" "$@"
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
