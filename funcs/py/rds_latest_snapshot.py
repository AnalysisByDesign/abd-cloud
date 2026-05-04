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
# print out SnapTime, SnapName, SnapType for available snapshots
output = []
for snap in jsondata['DBSnapshots']:
	if "available" == snap['Status']:
		data = []
		data.append(snap['SnapshotCreateTime'])
		data.append(snap['DBSnapshotIdentifier'])
		data.append(snap['SnapshotType'])
		output.append(','.join(map(str,data)))

# sort the output textually
output.sort()

# Write out the last line
print output.pop()
