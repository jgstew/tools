"""
This python script takes 1 argument as a site gather url

It will find the version of that site and the newest modification time of the files within that site
"""

import datetime
import re
import ssl
import sys
import urllib.request


def get_bessite_info(bes_site_url, verify_ssl=True):
    """get bes site info"""
    ctx = ssl.create_default_context()
    if not verify_ssl:
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
    # https://docs.python.org/3/howto/urllib2.html
    with urllib.request.urlopen(bes_site_url, context=ctx) as response:
        html = response.read()
        return html


def get_bessite_version(bes_site_html):
    """get bes site version"""
    site_version = int(
        re.search(b"(?:\n|\r\n?)Version: (\d+)(?:\n|\r\n?)", bes_site_html).group(1)
    )
    return site_version


def get_bessite_modification(bes_site_html):
    """get bes site modification date"""
    site_mod = re.findall(
        b"(?:\n|\r\n?)(?:MODIFIED:|Date:) (.+)(?:\n|\r\n?)", bes_site_html
    )
    # print(site_mod)

    # get unix epoch as "oldest" date.
    newest_mod = datetime.datetime.strptime(
        "Thu, 1 Jan 1970 00:00:01 +0000\r", "%a, %d %b %Y %H:%M:%S %z\r"
    )

    for result in site_mod:
        result_parsed = datetime.datetime.strptime(
            result.decode(), "%a, %d %b %Y %H:%M:%S %z\r"
        )
        if result_parsed > newest_mod:
            newest_mod = result_parsed

    return newest_mod


def main(bes_site_url):
    print(f"BES Site URL:           {bes_site_url}")
    # if run through main, disable SSL verification
    bes_site_html = get_bessite_info(bes_site_url, False)
    site_version = get_bessite_version(bes_site_html)
    print(f"BES Site Version Found: {site_version}")
    site_mod = get_bessite_modification(bes_site_html)
    print(f"BES Site Modification Found: {site_mod.astimezone()}")

    time_delta = datetime.datetime.now(datetime.timezone.utc) - site_mod
    time_hours = time_delta.total_seconds() / 3600
    print(f"Last changed: {int(time_hours)} hours ago.")


if __name__ == "__main__":
    try:
        exit(main(sys.argv[1]))
    except IndexError:
        bes_site = "https://sync.bigfix.com/cgi-bin/bfgather/bessupport"
        exit(main(bes_site))
