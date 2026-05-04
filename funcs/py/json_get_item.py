#!/usr/bin/env python
import sys
import json

# What items are required from the json data
# If nothing, we will write out all of the content
# This goes down to the third layer of content
layer1=""; layer2=""; layer3=""
if len(sys.argv) > 1:
	layer1 = sys.argv[1]
if len(sys.argv) > 2:
	layer2 = sys.argv[2]
if len(sys.argv) > 3:
	layer3 = sys.argv[3]

#------------------------------------------------------------
# Read in the data that is being passed in through stdin
# and put that into a JSON data object
data=""
for line in sys.stdin:
	data = data + line

# What if we get no content?
if "" == data:
        sys.exit()

# Now deal with the data
jsondata = json.loads(data)

#------------------------------------------------------------
# If no layer 1 requested, print out the whole element
if "" == layer1:
	print jsondata
	sys.exit()

# Extract the layer1 content
data1 = jsondata[layer1]

# If no layer 2 requested, print out the layer 1 content
if "" == layer2:
	print data1
	sys.exit()

# Now get the layer 2 content if required
for data2 in data1:
	if "" == layer3:
		print data2[layer2]
		sys.exit()

# Otherwise, print out the layer 3 that has been requested
for data3 in data2[layer2]:
	if layer3 == data3:
		print data2[layer2][layer3]


