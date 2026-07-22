"""
Extract every URL from a file and report:
  * dead URLs (network errors or HTTP >= 400 that don't resolve after a GET fallback)
  * http:// URLs that would work equally well as https://

Uses only the Python standard library.

Usage:
    python file_check_urls.py <path-to-file> [--timeout SECONDS] [--workers N]
                                             [--autofix-http]

Exit codes:
    0 - no dead URLs found (http->https suggestions are informational)
    1 - at least one dead URL
    2 - usage / IO error
"""

import argparse
import concurrent.futures
import re
import sys
import urllib.error
import urllib.request

URL_REGEX = re.compile(
    r"""https?://[^\s"'<>)\]}`,]+""",
    re.IGNORECASE,
)

TRAILING_PUNCT = ".,;:!?"

DEFAULT_TIMEOUT = 15
DEFAULT_WORKERS = 16

# Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36
USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36"


def extract_urls(text):
    """Return a de-duplicated, order-preserved list of URLs found in text.

    Templated URLs containing shell-style ``$VAR`` or ``${VAR}`` placeholders
    are skipped because they can't be resolved as-is.
    """
    seen = set()
    urls = []
    for match in URL_REGEX.finditer(text):
        url = match.group(0).rstrip(TRAILING_PUNCT)
        if "$" in url:
            continue
        if url in seen:
            continue
        seen.add(url)
        urls.append(url)
    return urls


def _request(url, method, timeout):
    req = urllib.request.Request(url, method=method, headers={"User-Agent": USER_AGENT})
    return urllib.request.urlopen(req, timeout=timeout)


def check_url(url, timeout):
    """Return (ok, detail). ok=True means the URL is live."""
    for method in ("HEAD", "GET"):
        try:
            with _request(url, method, timeout) as resp:
                status = resp.status
                if 200 <= status < 400:
                    return True, status
                if method == "HEAD" and status in (400, 403, 405, 501):
                    continue
                return False, f"HTTP {status}"
        except urllib.error.HTTPError as exc:
            if method == "HEAD" and exc.code in (400, 403, 405, 501):
                continue
            return False, f"HTTP {exc.code}"
        except (urllib.error.URLError, TimeoutError, ConnectionError) as exc:
            reason = getattr(exc, "reason", exc)
            return False, f"{type(exc).__name__}: {reason}"
        except Exception as exc:  # pylint: disable=broad-except
            return False, f"{type(exc).__name__}: {exc}"
    return False, "unreachable"


def check_all(urls, timeout, workers):
    """Return dict: url -> (ok, detail)."""
    results = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
        future_map = {pool.submit(check_url, u, timeout): u for u in urls}
        for future in concurrent.futures.as_completed(future_map):
            url = future_map[future]
            results[url] = future.result()
    return results


def main():
    """Execution starts here."""
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n", maxsplit=1)[0])
    parser.add_argument("path", help="File to scan for URLs")
    parser.add_argument(
        "--timeout",
        type=int,
        default=DEFAULT_TIMEOUT,
        help="Per-request timeout, seconds",
    )
    parser.add_argument(
        "--workers", type=int, default=DEFAULT_WORKERS, help="Parallel request workers"
    )
    parser.add_argument(
        "--autofix-http",
        action="store_true",
        help="Rewrite the file in place, upgrading each http:// URL whose https:// variant is live.",
    )
    args = parser.parse_args()

    try:
        with open(args.path, encoding="utf-8", errors="replace") as fh:
            text = fh.read()
    except OSError as exc:
        print(f"error: cannot read {args.path}: {exc}", file=sys.stderr)
        return 2

    urls = extract_urls(text)
    if not urls:
        print("No URLs found.")
        return 0

    print(f"Found {len(urls)} unique URL(s). Checking...")
    results = check_all(urls, args.timeout, args.workers)

    # First pass: dead URL report
    dead = [(u, results[u][1]) for u in urls if not results[u][0]]
    if dead:
        print(f"\nDead URLs ({len(dead)}):")
        for url, detail in dead:
            print(f"  [{detail}] {url}")
    else:
        print("\nAll URLs are live.")

    # Second pass: http -> https upgrade candidates
    http_urls = [u for u in urls if u.lower().startswith("http://")]
    upgrade_candidates = []
    if http_urls:
        https_variants = ["https://" + u[len("http://") :] for u in http_urls]
        https_results = check_all(https_variants, args.timeout, args.workers)
        for http_url, https_url in zip(http_urls, https_variants):
            https_ok, _ = https_results[https_url]
            if https_ok:
                upgrade_candidates.append((http_url, https_url))

    if upgrade_candidates:
        print(f"\nhttp -> https upgrade candidates ({len(upgrade_candidates)}):")
        for http_url, https_url in upgrade_candidates:
            print(f"  {http_url}")
            print(f"    -> {https_url}")
        if args.autofix_http:
            replaced = 0
            new_text = text
            for http_url, https_url in upgrade_candidates:
                count = new_text.count(http_url)
                if count:
                    new_text = new_text.replace(http_url, https_url)
                    replaced += count
            if new_text != text:
                try:
                    with open(args.path, "w", encoding="utf-8") as fh:
                        fh.write(new_text)
                except OSError as exc:
                    print(f"\nerror: cannot write {args.path}: {exc}", file=sys.stderr)
                    return 2
                print(
                    f"\nAuto-fix: rewrote {args.path} "
                    f"({replaced} occurrence(s) across "
                    f"{len(upgrade_candidates)} URL(s) upgraded to https)."
                )
            else:
                print("\nAuto-fix: nothing to write.")
        else:
            print("\nTip: re-run with --autofix-http to rewrite the file in place.")
    elif http_urls:
        print("\nNo http:// URLs can be upgraded to https://.")

    return 1 if dead else 0


if __name__ == "__main__":
    sys.exit(main())
