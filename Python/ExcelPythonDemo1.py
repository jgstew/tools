import time
# win32com does not come with python
from win32com.client import Dispatch
xlApp = Dispatch("Excel.Application")
xlApp.Visible = 1
xlApp.Workbooks.Add()
# http://stackoverflow.com/questions/510348/how-can-i-make-a-time-delay-in-python
time.sleep(1)
xlApp.ActiveSheet.Cells(1,1).Value = 56
time.sleep(.5)
xlApp.ActiveWorkbook.ActiveSheet.Cells(2,1).Value = 67
time.sleep(.5)
xlApp.ActiveWorkbook.ActiveSheet.Cells(3,1).Value = '=SUM(A1:A2)'

# http://web.archive.org/web/20090916091434/http://www.markcarter.me.uk/computing/python/excel.html
