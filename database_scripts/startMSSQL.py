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
	'ami-3c1e6954',
	key_name='aws-dev-2014',
	instance_type='m3.medium',
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
instance.add_tag("Name", "dotcms-mssql-" + str(millis))
instance.add_tag("TerminateName", "dotcms-mssql-terminate")

#Setting ID and IP in OS Env.
#Creating file with instance id.
fo = open("/etc/mssqlInstance.properties", "wb")
fo.write("MSSQLINSTANCEIP="+str(instance.ip_address)+" \nMSSQLINSTANCEID="+str(instance).split(':')[-1])
fo.close()

print "Give 60 seconds to MS-SQL to Start"
time.sleep(60)

#Printing info.
print "MS SQL Instance Running: ", instance, "with public IP: ", instance.ip_address
