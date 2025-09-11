"""
Read x-fixlet-modification-time from all BES files in folder

print maximum mod time found
"""

import asyncio
import datetime
import pathlib

import aiofiles
import lxml.etree

# folder which contains BES files or in subfolders of it
BASE_FOLDER = "/Users/james/Documents/_Code/besapi/tmp"
lxml_parser = lxml.etree.XMLParser(recover=True)


async def read_time_from_file(filename):
    async with aiofiles.open(filename, "rb") as file:
        content = await file.read()
        # remove invalid chars:
        content = content.decode(errors="replace").encode()
        max_time = datetime.datetime.fromtimestamp(0, datetime.timezone.utc)

        try:
            root = lxml.etree.fromstring(content, parser=lxml_parser)
            if root is None:
                print(f"root problem with file {filename}")
                return max_time
            string_datetimes = root.xpath(
                '/BES/*/MIMEField[Name[contains(text(), "x-fixlet-modification-time")]]/Value/text()'
            )
            if len(string_datetimes) == 0:
                print(
                    f"value missing from file {filename}\n    Expected for computer groups"
                )

            for item in string_datetimes:
                time_obj = datetime.datetime.strptime(
                    item.strip(), "%a, %d %b %Y %H:%M:%S %z"
                )
                if time_obj > max_time:
                    max_time = time_obj
        except lxml.etree.XMLSyntaxError as err:
            print(f"xml syntax problem with file {filename} \nERROR: {err}")
            return max_time
        return max_time


async def find_maximum_time(filenames):
    tasks = [read_time_from_file(filename) for filename in filenames]
    results = await asyncio.gather(*tasks)
    return max(results)


async def main():
    filenames = list(pathlib.Path(BASE_FOLDER).rglob("*.bes"))
    # print(filenames)
    if filenames:
        maximum_time = await find_maximum_time(filenames)
        print("Maximum time:", maximum_time)
    else:
        print("no files found!")


# if called directly, then run this example:
if __name__ == "__main__":
    asyncio.run(main())
