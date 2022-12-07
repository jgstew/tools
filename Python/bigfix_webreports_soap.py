"""
Example using the BigFix Web Reports SOAP API
"""
import requests


def main(
    username, password, server_url="https://localhost:888", session_relevance="now"
):
    """Execution starts here"""
    print("main()")

    print(f"find the soap wsdl here: {server_url}/webreports?wsdl")

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


if __name__ == "__main__":
    main("demo_user", "bad_password", "http://bigfix:888")
