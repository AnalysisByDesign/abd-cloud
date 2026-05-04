#!/usr/bin/env python
import sys, json

#------------------------------------------------------------
# Read in the data that is being passed in through stdin
# and put that into a JSON data object
data=""
for line in sys.stdin:
	data = data + line

# What if we get no content?
if "" == data:
        quit()

# Now deal with the data
jsondata = json.loads(data)

#------------------------------------------------------------
# print out all instance names in the supplied data
output = []
for instance in jsondata['DBInstances']:
	print instance['DBInstanceIdentifier']

