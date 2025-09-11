import time


# http://stackoverflow.com/questions/2487109/python-date-time-formatting
# https://docs.python.org/2/library/datetime.html
def yyyymmddhhmmss(before="", after="", now=time.localtime()):
    return before + time.strftime("%Y%m%d%H%M%S", now) + after


def yyyymmddhhmm(before="", after="", now=time.localtime()):
    return before + time.strftime("%Y%m%d%H%M", now) + after


if __name__ == "__main__":
    print(yyyymmddhhmmss())
