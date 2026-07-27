#!/usr/bin/env python3
# Related:
# - https://github.com/jgstew/tools/blob/master/bash/bfsite_get_id.sh
# - https://github.com/jgstew/tools/blob/master/SQL/BigFix_ExternalSites_SiteIDs.sql
import base64
import re
import subprocess
import tempfile
import urllib.request

URL = "https://sync.bigfix.com/cgi-bin/bfgather/patchesforubuntu2404"


def extract_p7s_der(smime_bytes: bytes) -> bytes:
    text = smime_bytes.decode("latin-1", errors="replace")
    sig = False
    body = False
    b64_lines = []

    for raw_line in text.splitlines():
        line = raw_line.rstrip("\r")

        if not sig and "Content-Type: application/x-pkcs7-signature" in line:
            sig = True
            continue

        if sig and not body and line == "":
            body = True
            continue

        if body:
            if line.startswith("--"):
                break
            if line:
                b64_lines.append(line)

    if not b64_lines:
        raise RuntimeError("Could not find S/MIME PKCS7 signature body")

    return base64.b64decode("".join(b64_lines))


def main() -> None:
    smime = urllib.request.urlopen(URL).read()
    p7s_der = extract_p7s_der(smime)

    with tempfile.NamedTemporaryFile(suffix=".p7s") as f:
        f.write(p7s_der)
        f.flush()

        out = subprocess.check_output(
            [
                "openssl",
                "pkcs7",
                "-inform",
                "DER",
                "-in",
                f.name,
                "-print_certs",
                "-text",
            ],
            stderr=subprocess.DEVNULL,
            text=True,
        )

    # Pair "Serial Number" then next "Subject"
    pairs = []
    sn = ""
    for line in out.splitlines():
        if "Serial Number:" in line:
            sn = line.strip()
            continue
        if "Subject:" in line:
            subject = line.strip()
            pairs.append((sn, subject))
            sn = ""

    # Equivalent to: grep "Sitename:" | grep -oE 'Serial Number: [0-9A-F]+ ' | uniq
    seen = set()
    for serial_line, subject in pairs:
        if "Sitename:" not in subject:
            continue
        m = re.search(r"Serial Number:\s*([0-9A-F]+)\b", serial_line)
        if not m:
            continue
        value = m.group(1)
        if value not in seen:
            seen.add(value)
            print(f"Serial Number: {value}")


if __name__ == "__main__":
    main()
