#!/usr/bin/env python3
"""
alby_init.py — Unlock AlbyHub instances for local development.

For each configured AlbyHub instance this script:
  1. POST /api/setup      — first-time password setup (idempotent).
  2. POST /api/start      — starts the wallet backend (idempotent).
  3. POST /api/unlock     — obtains an auth token to confirm the instance is
                            fully operational, with retries matching the Dart
                            AlbyHubClient logic.

Uses only Python stdlib — no extra packages needed.
"""

import json
import os
import ssl
import sys
import time
import urllib.error
import urllib.request


def _insecure_ctx():
    """SSL context that skips certificate verification (dev CA not installed)."""
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx


def _req(method, url, *, data=None, token=None, cookies=None, timeout=10):
    """Minimal JSON HTTP helper.  Returns (status, body_dict, set_cookie_header)."""
    body = json.dumps(data).encode() if data is not None else None
    headers = {"Content-Type": "application/json", "Accept": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if cookies:
        headers["Cookie"] = "; ".join(f"{k}={v}" for k, v in cookies.items())

    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout, context=_insecure_ctx()) as resp:
            raw = resp.read()
            set_cookie = resp.headers.get("Set-Cookie", "")
            return resp.status, json.loads(raw) if raw else {}, set_cookie
    except urllib.error.HTTPError as exc:
        raw = exc.read()
        set_cookie = exc.headers.get("Set-Cookie", "") if exc.headers else ""
        return exc.code, json.loads(raw) if raw else {}, set_cookie


def _extract_token(body, set_cookie):
    """Pull access_token from body or Set-Cookie header."""
    token = body.get("token") or body.get("access_token") or body.get("jwt")
    if token:
        return str(token)
    # Parse Set-Cookie: token=<value>; ...
    for part in set_cookie.split(";"):
        part = part.strip()
        if part.lower().startswith("token="):
            val = part.split("=", 1)[1].strip()
            if val:
                return val
    return None


def _wait_ready(base_url, retries=60, interval=2):
    """Poll until AlbyHub HTTP server is accepting connections."""
    for i in range(retries):
        try:
            status, _, _ = _req("GET", f"{base_url}/api/info", timeout=3)
            if status < 500:
                return
        except Exception:
            pass
        print(f"  waiting for {base_url} ({i + 1}/{retries})…")
        time.sleep(interval)
    raise RuntimeError(f"{base_url} never became ready after {retries * interval}s")


def unlock_instance(base_url, password):
    print(f"\n==> Unlocking AlbyHub at {base_url}")
    _wait_ready(base_url)

    # ── 1. Setup (idempotent) ────────────────────────────────────────────────
    status, body, _ = _req(
        "POST", f"{base_url}/api/setup",
        data={"unlockPassword": password},
    )
    error = (body.get("error") or "").lower()
    if error and "already" not in error:
        raise RuntimeError(f"Setup failed at {base_url}: {body}")
    print(f"  ✓ Setup ok")

    # ── 2. Start (idempotent) ────────────────────────────────────────────────
    status, body, set_cookie = _req(
        "POST", f"{base_url}/api/start",
        data={"unlockPassword": password},
    )
    last_token = _extract_token(body, set_cookie)
    error = (body.get("error") or "").lower()
    if error and "already" not in error:
        raise RuntimeError(f"Start failed at {base_url}: {body}")
    print(f"  ✓ Start ok")

    # ── 3. Unlock (with retries matching Dart AlbyHubClient logic) ───────────
    cookies = {}
    if last_token:
        # Some AlbyHub versions return the token as a cookie on /start.
        cookies["token"] = last_token

    for attempt in range(5):
        status, body, set_cookie = _req(
            "POST", f"{base_url}/api/unlock",
            data={"permission": "full", "unlockPassword": password},
            cookies=cookies or None,
        )
        token = _extract_token(body, set_cookie) or last_token
        if token:
            print(f"  ✓ Unlocked (attempt {attempt + 1})")
            return token

        error = (body.get("error") or "").lower()
        message = (body.get("message") or "").lower()

        if "invalid password" in message or ("invalid" in error and "password" in error):
            raise RuntimeError(f"Invalid password for {base_url}")

        if "rate limit" in message or "too many" in message:
            if attempt == 4:
                raise RuntimeError(f"Rate-limited at {base_url}: {message}")
            time.sleep(attempt + 1)
            continue

        # No token yet — try /start again then retry /unlock.
        _, start_body, start_cookie = _req(
            "POST", f"{base_url}/api/start",
            data={"unlockPassword": password},
        )
        token = _extract_token(start_body, start_cookie)
        if token:
            print(f"  ✓ Unlocked via re-start (attempt {attempt + 1})")
            return token

        if attempt < 4:
            time.sleep(attempt + 1)

    raise RuntimeError(f"Could not unlock {base_url} after 5 attempts")


def main():
    password = os.environ.get("ALBYHUB_PASSWORD", "Testing123!")

    instances = [
        os.environ.get("ALBYHUB_1_URL", "https://alby1.hostr.development"),
        os.environ.get("ALBYHUB_2_URL", "https://alby2.hostr.development"),
    ]

    errors = []
    for url in instances:
        try:
            unlock_instance(url, password)
        except Exception as exc:
            print(f"ERROR unlocking {url}: {exc}", file=sys.stderr)
            errors.append(exc)

    if errors:
        sys.exit(1)

    print("\n✓ AlbyHub init complete")


if __name__ == "__main__":
    main()
