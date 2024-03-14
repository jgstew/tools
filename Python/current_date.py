"""
Return the current date in the same format is BigFix Relevance.
"""

import datetime

# remove datetime.timezone.utc if wanting local time
time_now = datetime.datetime.now(datetime.timezone.utc)
print(time_now.strftime("%d %b %Y"))
