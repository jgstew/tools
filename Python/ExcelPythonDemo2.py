import time
import random
# win32com does not come with python
from win32com.client import Dispatch
xlApp = Dispatch("Excel.Application")
xlApp.Visible = 1
xlApp.Workbooks.Add()
# http://web.archive.org/web/20090916091434/http://www.markcarter.me.uk/computing/python/excel.html
# http://stackoverflow.com/questions/510348/how-can-i-make-a-time-delay-in-python
time.sleep(.5)

xlApp.ActiveSheet.Cells(11,1).Value = 'Total:'
xlApp.ActiveSheet.Cells(11,2).Value = '=SUM(B1:B10)'
xlApp.ActiveSheet.Cells(12,1).Value = 'Average:'
xlApp.ActiveSheet.Cells(12,2).Value = '=AVERAGE(B1:B10)'
time.sleep(.5)
# https://wiki.python.org/moin/ForLoop
for x in range(5, 25):
    time.sleep(.5)
    # https://docs.python.org/2/library/random.html
    rand = random.randrange(100)
    print rand
    xlApp.ActiveSheet.Cells(x,3).Value = rand


