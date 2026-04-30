#!/usr/bin/env python3
import argparse
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


def latest_launch(wrapper_log: Path):
    if not wrapper_log.exists():
        return None

    port = None
    url = None
    for line in wrapper_log.read_text(errors="ignore").splitlines():
        if not line.startswith("args="):
            continue
        port_match = re.search(r"--remote-debugging-port=(\d+)", line)
        url_match = re.search(r"(https?://localhost:\d+)\S*", line)
        if port_match and url_match:
            port = port_match.group(1)
            url = url_match.group(1)

    if port is None or url is None:
        return None
    return port, url


def read_json(url: str, timeout: float = 1.0):
    with urllib.request.urlopen(url, timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8"))


def close_target(port: str, target_id: str):
    quoted_id = urllib.parse.quote(target_id, safe="")
    urllib.request.urlopen(
        f"http://127.0.0.1:{port}/json/close/{quoted_id}",
        timeout=1.0,
    ).read()


def close_stale_targets(port: str, keep_url: str) -> tuple[int, int]:
    keep_netloc = urllib.parse.urlsplit(keep_url).netloc
    targets = read_json(f"http://127.0.0.1:{port}/json/list")
    total_pages = 0
    closed = 0

    for target in targets:
        if target.get("type") != "page":
            continue
        total_pages += 1
        target_url = target.get("url") or ""
        target_netloc = urllib.parse.urlsplit(target_url).netloc
        if target_netloc == keep_netloc:
            continue
        target_id = target.get("id")
        if not target_id:
            continue
        try:
            close_target(port, target_id)
            closed += 1
        except (OSError, urllib.error.URLError):
            pass

    return total_pages, closed


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--wrapper-log", required=True)
    parser.add_argument("--timeout", type=float, default=90.0)
    parser.add_argument("--poll", type=float, default=0.5)
    args = parser.parse_args()

    wrapper_log = Path(args.wrapper_log)
    deadline = time.monotonic() + args.timeout
    last_error = None

    while time.monotonic() < deadline:
        launch = latest_launch(wrapper_log)
        if launch is None:
            time.sleep(args.poll)
            continue

        port, keep_url = launch
        try:
            total, closed = close_stale_targets(port, keep_url)
            print(
                "CHROME_TAB_CLEANUP "
                f"port={port} keep={keep_url} pages={total} closed={closed}",
                flush=True,
            )
            return 0
        except (OSError, urllib.error.URLError, json.JSONDecodeError) as error:
            last_error = error
            time.sleep(args.poll)

    print(
        "CHROME_TAB_CLEANUP timeout "
        f"wrapper_log={wrapper_log} error={last_error}",
        file=sys.stderr,
        flush=True,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
