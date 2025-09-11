"""
Open an existing yaml file

Append new data to the yaml file

Write back the updated data to the yaml file

This example is specific to Google Cloud URL Maps
"""

import ruamel.yaml

yaml = ruamel.yaml.YAML()


def append_header(file_path, new_header):
    with open(file_path) as f:
        data = yaml.load(f)

    # Ensure the structure exists
    if "headerAction" not in data:
        data["headerAction"] = {}
    if "responseHeadersToAdd" not in data["headerAction"]:
        data["headerAction"]["responseHeadersToAdd"] = []

    # Append the new header if it doesn't already exist otherwise overwrite existing
    for i, header in enumerate(data["headerAction"]["responseHeadersToAdd"]):
        if header["headerName"] == new_header["headerName"]:
            data["headerAction"]["responseHeadersToAdd"][i] = new_header
            break
    # do this if for loop does not break:
    else:
        data["headerAction"]["responseHeadersToAdd"].append(new_header)

    with open(file_path, "w") as f:
        yaml.dump(data, f)


def main():
    new_headers = [
        {
            "headerName": "X-Content-Type-Options",
            "headerValue": "nosniff",
            "replace": True,
        },
        {
            "headerName": "Strict-Transport-Security",
            "headerValue": "max-age=31536000; includeSubDomains; preload",
            "replace": True,
        },
    ]
    for header in new_headers:
        append_header("Python/url-map-config.yaml", header)


if __name__ == "__main__":
    main()
