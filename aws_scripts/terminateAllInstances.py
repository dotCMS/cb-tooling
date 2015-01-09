#!/usr/bin/python
import boto
import boto.ec2
import sys
import time
import os

#Using API to terminate instance.
conn = boto.ec2.connect_to_region('us-east-1')

#Killing All builder instances
reservationsBuilder = conn.get_all_instances(filters={"tag:TerminateName" : "dotcms-builder-terminate"})
instancesBuilder = [i for r in reservationsBuilder for i in r.instances]
for instanceBuilder in instancesBuilder:
	conn.terminate_instances(str(instanceBuilder.id))
	print "Terminate ", str(instanceBuilder.id)

#Killing All MS SQL instances
reservationsSQL = conn.get_all_instances(filters={"tag:TerminateName" : "dotcms-mssql-terminate"})
instancesSQL = [j for r in reservationsSQL for j in r.instances]
for instanceMsSql in instancesSQL:
	conn.terminate_instances(str(instanceMsSql.id))
	print "Terminate ", str(instanceMsSql.id)

#Killing All Oracle instances
reservationsOracle = conn.get_all_instances(filters={"tag:TerminateName" : "dotcms-oracle-terminate"})
instancesOracle = [k for r in reservationsOracle for k in r.instances]
for instanceOracle in instancesOracle:
	conn.terminate_instances(str(instanceOracle.id))
	print "Terminate ", str(instanceOracle.id)