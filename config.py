# config.py
# 19 Jul 2018 JMA
# parse the VM metadata properties json
import json, sys

# Read from stdin
the_input = []
for k in sys.stdin:
    the_input.append(k)
