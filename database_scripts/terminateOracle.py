#!/usr/bin/python
import boto
import boto.ec2
import sys
import time
import os

#Using API to terminate instance.
conn = boto.ec2.connect_to_region('us-east-1')

reservations = conn.get_all_instances(filters={"tag:TerminateName" : "dotcms-oracle-terminate"})
instances = [i for r in reservations for i in r.instances]
if instances:
	conn.terminate_instances(str(instances[0].id))
	print "Terminate ", str(instances[0].id)
