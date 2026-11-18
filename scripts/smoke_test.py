#!/usr/bin/env python3
"""Check that the deployed HTTP application responds on every Ansible host."""
import sys
import urllib.error
import urllib.request
from pathlib import Path


def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: smoke_test.py <inventory.ini>")
    hosts = []
    in_web = False
    for raw in Path(sys.argv[1]).read_text().splitlines():
        line = raw.strip()
        if line.startswith("["):
            in_web = line == "[web]"
            continue
        if in_web and line and not line.startswith("#"):
            hosts.append(line.split()[0])
    if not hosts:
        raise SystemExit("No hosts found in [web] inventory group")

    failures = []
    for host in hosts:
        url = f"http://{host}/"
        try:
            with urllib.request.urlopen(url, timeout=15) as response:
                body = response.read().decode("utf-8", errors="replace")
                if response.status != 200 or "Production CI/CD Pipeline" not in body:
                    failures.append(f"{host}: unexpected HTTP response/content")
                else:
                    print(f"PASS {url} -> HTTP {response.status}")
        except (urllib.error.URLError, TimeoutError) as exc:
            failures.append(f"{host}: {exc}")
    if failures:
        raise SystemExit("Smoke test failed:\n" + "\n".join(failures))


if __name__ == "__main__":
    main()
