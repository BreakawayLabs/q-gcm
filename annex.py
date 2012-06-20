import os
import sys

filename = sys.argv[-1]
project = "qgcm"

## Add a file to the local annex
cmd = "git annex add %s --backend=WORM" % filename
print cmd
os.system(cmd)
print
## Upload the file to the cloud annex
cmd = "git annex copy %s --to cloud" % filename
print cmd
os.system(cmd)
print
target = os.path.realpath(filename).split(os.path.sep)[-1]

## Make the file public
cmd = "s3cmd setacl --acl-public s3://breakawaylabs-%s-data/%s" % (project, target)
print cmd
os.system(cmd)
print
## Add the file to the web annex
cmd = "git annex addurl http://s3.amazonaws.com/breakawaylabs-%s-data/%s --file=%s" % (project, target, filename)
print cmd
os.system(cmd)
print