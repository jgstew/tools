"""
Return the current time in the same format is BigFix Relevance.
"""
import datetime

time_now = datetime.datetime.now(datetime.timezone.utc)
print(time_now.strftime("%a, %d %b %Y %H:%M:%S %z"))
