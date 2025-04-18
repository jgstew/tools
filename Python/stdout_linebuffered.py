import sys
import time

print(
    "\nThis should be block buffered if run non interactively, but line buffered if run interactively.\n"
)

sys.stdout.reconfigure(line_buffering=False)
print("sys.stdout.reconfigure(line_buffering=False)")
print("This is a block buffered output, even when run interactively.\n")
# need to call flush specifically to see the output or print with flush=True
# sys.stdout.flush()
# print("message", flush=True)

# sleep so that we can see that the output is not printed yet due to buffering
time.sleep(2)

sys.stdout.reconfigure(line_buffering=True)
print("sys.stdout.reconfigure(line_buffering=True)")
print("This is a line buffered output, even when run non interactively.")
