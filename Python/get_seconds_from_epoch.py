"""
Simple script to get seconds from epoch from 30 days before now.
"""

import datetime

# get 30 days ago:
thirty_days_ago = datetime.datetime.now() - datetime.timedelta(days=30)

# get just the seconds:
seconds_from_epoch = int(thirty_days_ago.timestamp())

print(seconds_from_epoch)
