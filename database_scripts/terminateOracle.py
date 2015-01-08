#!/usr/bin/python
import boto
import boto.ec2
import sys
import time
import os

#Using API to terminate instance.
conn = boto.ec2.connect_to_region('us-east-1')
conn.terminate_instances(os.environ['ORACLEINSTANCEID'])

print "Terminate ", os.environ['ORACLEINSTANCEID']