#!/usr/bin/python
import boto
import boto.ec2
import sys
import time
import base64
import os

#Cleaning OS Env for Oracle Instance.
os.environ["ORACLEINSTANCEIP"] = ""
os.environ["ORACLEINSTANCEID"] = ""

conn = boto.ec2.connect_to_region('us-east-1')

#Running Oracle Instance.
reservation = conn.run_instances(
	'ami-3e167056',
	key_name='aws-dev-2014',
	instance_type='t2.micro',
	subnet_id = 'subnet-10368867',
	security_group_ids=['sg-e800e88c'],
	instance_initiated_shutdown_behavior='stop')

instance = reservation.instances[0]
instance.update()
while instance.state == "pending":
    print instance, instance.state
    time.sleep(5)
    instance.update()

millis = int(round(time.time() * 1000))
instance.add_tag("Name", "dotcms-oracle-" + str(millis))

#Setting ID and IP in OS Env.
#Creating file with instance id.
fo = open("~/oracleInstanceScript.sh", "wb")
fo.write("#!/bin/bash \n export ORACLEINSTANCEIP="+str(instance.ip_address)+" \n export ORACLEINSTANCEID="+str(instance).split(':')[-1])
fo.close()

#Printing info.
print "Oracle Instance Running: ", instance, "with public IP: ", instance.ip_address
