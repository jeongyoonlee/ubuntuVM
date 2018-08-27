# config.py
# 19 Jul 2018 JMA
# parse the VM metadata properties json
# Test this with
# $ cat meta.json | python config.py

import json, os, pprint, sys

# Read from stdin
the_properties = sys.stdin.read()
if len(the_properties) > 0 :
    ad_json = json.loads(the_properties)
    print('This machine is: ')
    # Machine description
    pprint.pprint(ad_json['compute'])
    # Public IP address
    pprint.pprint(ad_json['network']['interface'][0]['ipv4']['ipAddress'][0])
    # Set environment variables, to identify this as a DSVM
    os.environ['DSVM'] = ad_json['compute']['offer']
    os.environ['DSVM_version'] = ad_json['compute']['version']
    # Make these permanent over sessions.
    with open(os.path.expanduser("~/.bashrc"), "a") as outfile:
    outfile.write("export MYVAR=MYVALUE")
else:
    print("No json generated", file=sys.stderr)


