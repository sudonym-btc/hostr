#!/usr/bin/env python3
"""
lnbits_init.py — Bootstrap LNbits instances for local development.

For each configured LNbits instance this script:
  1. First-install (create superuser admin) — idempotent.
  2. Login to obtain an access token.
  3. Install + enable the lnurlp and nostrnip5 extensions.
  4. Get the admin wallet ID + key.
  5. Configure nostrnip5 settings (lnaddress endpoint).
  6. Create a lnurlp "tips" link (idempotent).
  7. Create the NIP-05 domain if it doesn't exist yet.
  8. Rename the domain ID in SQLite to a fixed deterministic value so the
     committed nginx vhost.d proxy config never needs to change between
     restarts.

Running this at container startup means seed_relay.sh never needs to touch
nginx or the LNbits database.
"""

import json
import os
import sqlite3
import sys
import time
import urllib.error
import urllib.request

# ── Extension coordinates ────────────────────────────────────────────────────
_EXTENSIONS = [
    (
        "lnurlp",
        "https://github.com/lnbits/lnurlp/archive/refs/tags/v1.3.0.zip",
        "1.3.0",
    ),
    (
        "nostrnip5",
        "https://github.com/lnbits/nostrnip5/archive/refs/tags/v1.0.4.zip",
        "1.0.4",
    ),
]

_SOURCE_REPO = (
    "https://raw.githubusercontent.com/lnbits/lnbits-extensions"
    "/main/extensions.json"
)


# ── HTTP helpers ─────────────────────────────────────────────────────────────

def _req(method, url, *, data=None, token=None, extra_headers=None, timeout=15):
    """Minimal JSON HTTP helper — returns (status_code, parsed_body)."""
    body = json.dumps(data).encode() if data is not None else None
    headers = {"Content-Type": "application/json", "Accept": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if extra_headers:
        headers.update(extra_headers)

    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read()
            try:
                parsed = json.loads(raw) if raw else {}
            except (json.JSONDecodeError, ValueError):
                parsed = {}
            return resp.status, parsed
    except urllib.error.HTTPError as exc:
        try:
            raw = exc.read()
            try:
                return exc.code, json.loads(raw) if raw else {}
            except (json.JSONDecodeError, ValueError):
                return exc.code, {}
        except Exception:
            return exc.code, {}


def _wait_ready(base_url, retries=60, interval=2):
    """Poll until the LNbits API responds (port-open is not enough)."""
    for i in range(retries):
        try:
            # Any valid endpoint works; /api/v1/currencies is lightweight.
            status, _ = _req("GET", f"{base_url}/api/v1/currencies", timeout=3)
            if status < 500:
                return
        except Exception:
            pass
        print(f"  waiting for {base_url} to be ready ({i + 1}/{retries})…")
        time.sleep(interval)
    raise RuntimeError(f"{base_url} never became ready after {retries * interval}s")


# ── Per-instance init ────────────────────────────────────────────────────────

def setup_instance(
    *,
    base_url,
    data_path,
    domain_name,
    fixed_domain_id,
    admin_email,
    admin_password,
    nostr_private_key,
):
    print(f"\n==> Initialising {base_url}  (domain={domain_name})")

    _wait_ready(base_url)

    # ── 1. First-install ────────────────────────────────────────────────────
    # Idempotent — LNbits returns an error if already done, which we ignore.
    _req(
        "PUT",
        f"{base_url}/api/v1/auth/first_install",
        data={
            "username": admin_email,
            "password": admin_password,
            "password_repeat": admin_password,
        },
    )

    # ── 2. Login ────────────────────────────────────────────────────────────
    status, body = _req(
        "POST",
        f"{base_url}/api/v1/auth",
        data={"username": admin_email, "password": admin_password},
    )
    token = body.get("access_token", "")
    if not token:
        raise RuntimeError(f"Login failed at {base_url}: {body}")
    print(f"  ✓ Logged in")

    # ── 3. Install + enable extensions ──────────────────────────────────────
    for ext_id, archive, version in _EXTENSIONS:
        status, body = _req(
            "POST",
            f"{base_url}/api/v1/extension",
            token=token,
            data={
                "ext_id": ext_id,
                "archive": archive,
                "source_repo": _SOURCE_REPO,
                "version": version,
            },
        )
        detail = (body.get("detail") or "").lower()
        if status not in (200, 201) and "already" not in detail:
            print(f"  ⚠ Extension install {ext_id}: HTTP {status} — {detail}")

        status, body = _req(
            "PUT",
            f"{base_url}/api/v1/extension/{ext_id}/enable",
            token=token,
        )
        detail = (body.get("detail") or "").lower()
        if status not in (200, 201) and "already" not in detail:
            print(f"  ⚠ Extension enable {ext_id}: HTTP {status} — {detail}")
        else:
            print(f"  ✓ Extension {ext_id} enabled")

    # ── 4. Get wallet ────────────────────────────────────────────────────────
    status, wallets = _req("GET", f"{base_url}/api/v1/wallets", token=token)
    if not isinstance(wallets, list) or not wallets:
        raise RuntimeError(f"No wallets returned from {base_url}: {wallets}")
    wallet_id = wallets[0]["id"]
    admin_key = wallets[0]["adminkey"]
    print(f"  ✓ Wallet id={wallet_id[:8]}…")

    nip5_headers = {"X-Api-Key": admin_key}

    # ── 5. Configure nostrnip5 settings ─────────────────────────────────────
    _req(
        "PUT",
        f"{base_url}/nostrnip5/api/v1/settings",
        token=token,
        extra_headers=nip5_headers,
        data={
            "lnaddress_api_endpoint": base_url,
            "lnaddress_api_admin_key": admin_key,
        },
    )
    print(f"  ✓ nostrnip5 settings saved")

    # ── 6. Configure lnurlp Nostr key ───────────────────────────────────────
    if nostr_private_key:
        status, settings = _req(
            "GET",
            f"{base_url}/lnurlp/api/v1/settings",
            token=token,
            extra_headers={"X-Api-Key": admin_key},
        )
        if isinstance(settings, dict):
            settings["nostr_private_key"] = nostr_private_key
            _req(
                "PUT",
                f"{base_url}/lnurlp/api/v1/settings",
                token=token,
                extra_headers={"X-Api-Key": admin_key},
                data=settings,
            )
            print(f"  ✓ lnurlp Nostr key configured")

    # ── 7. Tips lnurlp link ──────────────────────────────────────────────────
    # Pass X-Forwarded-Host/Proto so LNbits uses the public domain when
    # encoding the LNURL callback URL (not the internal http://lnbits1:5000).
    status, body = _req(
        "POST",
        f"{base_url}/lnurlp/api/v1/links",
        token=token,
        extra_headers={
            "X-Api-Key": admin_key,
            "X-Forwarded-Host": domain_name,
            "X-Forwarded-Proto": "https",
        },
        data={
            "comment_chars": 0,
            "description": "tips",
            "max": 10000000,
            "min": 1,
            "username": "tips",
            "wallet": wallet_id,
            "zaps": True,
        },
    )
    detail = (body.get("detail") or "").lower()
    if status not in (200, 201) and "already" not in detail and "taken" not in detail:
        print(f"  ⚠ Tips lnurlp link: HTTP {status} — {detail}")
    else:
        print(f"  ✓ Tips lnurlp link present")

    # ── 8. Create / find NIP-05 domain ──────────────────────────────────────
    domain_id = None
    status, domains = _req(
        "GET",
        f"{base_url}/nostrnip5/api/v1/domains",
        token=token,
        extra_headers=nip5_headers,
    )
    if isinstance(domains, list):
        for d in domains:
            if (
                isinstance(d, dict)
                and d.get("domain", "").lower() == domain_name.lower()
            ):
                domain_id = d["id"]
                print(f"  ✓ Domain already exists (id={domain_id})")
                break

    if domain_id is None:
        status, body = _req(
            "POST",
            f"{base_url}/nostrnip5/api/v1/domain",
            token=token,
            extra_headers=nip5_headers,
            data={
                "wallet": wallet_id,
                "currency": "sats",
                # nostrnip5 treats cost=0 as "cannot compute price" (falsy in
                # Python). Use 1 sat so the price check passes without billing.
                "cost": 1,
                "domain": domain_name,
            },
        )
        domain_id = body.get("id")
        if not domain_id:
            raise RuntimeError(
                f"Failed to create nostrnip5 domain '{domain_name}': {body}"
            )
        print(f"  ✓ Created domain (id={domain_id})")

    # ── 9. Fix domain ID in SQLite ───────────────────────────────────────────
    # The API generates a random ID. We rename it to the fixed constant that
    # the committed nginx vhost.d file already references.
    if domain_id == fixed_domain_id:
        print(f"  ✓ Domain ID already fixed ({fixed_domain_id})")
        return

    db_path = os.path.join(data_path, "ext_nostrnip5.sqlite3")
    if not os.path.exists(db_path):
        print(f"  ⚠ SQLite DB not found at {db_path} — skipping ID fixup")
        return

    db = sqlite3.connect(db_path)
    try:
        db.execute(
            "UPDATE addresses SET domain_id=? WHERE domain_id=?",
            (fixed_domain_id, domain_id),
        )
        db.execute(
            "UPDATE domains SET id=? WHERE id=?",
            (fixed_domain_id, domain_id),
        )
        db.commit()
        print(f"  ✓ Renamed domain ID {domain_id} → {fixed_domain_id}")
    finally:
        db.close()


# ── Entrypoint ───────────────────────────────────────────────────────────────

def main():
    domain = os.environ.get("DOMAIN", "hostr.development")
    admin_email = os.environ.get("LNBITS_ADMIN_EMAIL", "admin@example.com")
    admin_password = os.environ.get("LNBITS_ADMIN_PASSWORD", "adminpassword")
    nostr_key = os.environ.get("LNBITS_NOSTR_PRIVATE_KEY", "")

    instances = [
        {
            "base_url": os.environ.get("LNBITS_1_URL", "http://lnbits1:5000"),
            "data_path": "/data/lnbits1",
            "domain_name": f"lnbits1.{domain}",
            "fixed_domain_id": "lnbits1nip05",
        },
        {
            "base_url": os.environ.get("LNBITS_2_URL", "http://lnbits2:5000"),
            "data_path": "/data/lnbits2",
            "domain_name": f"lnbits2.{domain}",
            "fixed_domain_id": "lnbits2nip05",
        },
    ]

    errors = []
    for inst in instances:
        try:
            setup_instance(
                **inst,
                admin_email=admin_email,
                admin_password=admin_password,
                nostr_private_key=nostr_key,
            )
        except Exception as exc:
            print(f"ERROR initialising {inst['base_url']}: {exc}", file=sys.stderr)
            errors.append(exc)

    if errors:
        sys.exit(1)

    print("\n✓ LNbits init complete")


if __name__ == "__main__":
    main()
