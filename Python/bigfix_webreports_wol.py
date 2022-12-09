"""
Example using the BigFix Web Reports SOAP API

References:
- https://developer.bigfix.com/other/soap-api/soap_url.html
- https://developer.bigfix.com/other/soap-api/methods/GetRelevanceResult.html
"""
import re

import requests


def bfwr_session_relevance_raw(
    username, password, server_url="https://localhost:888", session_relevance="now"
):
    """get raw soap xml result from session relevance query"""

    soap_xml = (
        r"""<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
   <env:Body>
      <GetRelevanceResult xmlns="http://schemas.bigfix.com/Relevance">
        <relevanceExpr><![CDATA["""
        + session_relevance
        + r"""]]></relevanceExpr>
         <username>"""
        + username
        + r"""</username>
         <password>"""
        + password
        + r"""</password>
      </GetRelevanceResult>
   </env:Body>
</env:Envelope>"""
    )

    # print(soap_xml)

    result = requests.post(server_url + "/soap", data=soap_xml, timeout=180)

    print(result)
    print(result.text)

    return result.text


def bfwr_session_relevance_array(
    username, password, server_url="https://localhost:888", session_relevance="now"
):
    """get array result from session relevance query"""

    result_raw = bfwr_session_relevance_raw(
        username, password, server_url, session_relevance
    )

    regex = "\s<a>(.+?)</a>\W"
    return re.findall(regex, result_raw)


def main():
    """Execution starts here"""

    server_url = "https://bigfix:888"
    username = "demo_user"
    password = "password"
    print(f"find the soap wsdl here: {server_url}/webreports?wsdl")

    session_relevance = r"""
tuple string items (0;1;2) of concatenations ", " of (it as string) of ids of bes computers whose(now - last report time of it < 3 * hour)
    """

    result_array = bfwr_session_relevance_array(
        username, password, server_url, session_relevance
    )

    print(result_array)

    # http://localhost:__WebReportsPort__/json/wakeonlan?cid=_ComputerID_&cid=_NComputerID_

    wr_wol_url = server_url + "/json/wakeonlan?cid=" + result_array.pop(0)

    for item in result_array:
        wr_wol_url += "&cid=" + item

    print(wr_wol_url)

    session = requests.Session()

    result_login = session.post(
        server_url + "/webreports", data={"Username": username, "Password": password}
    )

    # print(result_login, result_login.text)

    result_wol = session.get(wr_wol_url)

    print(result_wol, result_wol.text)


if __name__ == "__main__":
    main()
