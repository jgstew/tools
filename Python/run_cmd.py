
import os
command = 'echo Hello World'
stream = os.popen(command)
output = stream.read()
print(output)
