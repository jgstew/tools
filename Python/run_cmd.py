# https://janakiev.com/blog/python-shell-commands/
import os
command = 'echo Hello World'
stream = os.popen(command)
output = stream.read()
print(output)
