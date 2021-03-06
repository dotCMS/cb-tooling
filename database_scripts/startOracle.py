#!/usr/bin/python
import boto
import boto.ec2
import sys
import time
import base64
import os

conn = boto.ec2.connect_to_region('us-east-1')

#Running Oracle Instance.
reservation = conn.run_instances(
	'ami-3e167056',
	key_name='aws-dev-2014',
	instance_type='m3.large',
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
instance.add_tag("TerminateName", "dotcms-oracle-terminate")

#Setting ID and IP in OS Env.
#Creating file with instance id.
fo = open("/etc/oracleInstance.properties", "wb")
fo.write("ORACLEINSTANCEIP="+str(instance.ip_address)+" \nORACLEINSTANCEID="+str(instance).split(':')[-1])
fo.close()

print "Give 60 seconds to Oracle to Start"
time.sleep(60)

#Printing info.
print "Oracle Instance Running: ", instance, "with public IP: ", instance.ip_address
