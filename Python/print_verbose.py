
from __future__ import print_function

# https://stackoverflow.com/questions/5980042/how-to-implement-the-verbose-or-v-option-into-a-script
verbose = False
print_verbose = print if verbose else lambda *a, **k: None

print( "This will always print" )
print_verbose( "This will only print if verbose=True" )
