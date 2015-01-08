#!/usr/bin/python
import boto
import boto.ec2
import sys
import time
import os

#Using API to terminate instance.
conn = boto.ec2.connect_to_region('us-east-1')

reservations = conn.get_all_instances(filters={"tag:TerminateName" : "dotcms-mssql-terminate"})
instances = [i for r in reservations for i in r.instances]
for instance in instances:
	conn.terminate_instances(str(instance.id))
	print "Terminate ", str(instance.id)