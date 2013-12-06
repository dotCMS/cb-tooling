#!/bin/bash
source /etc/bashrc
source /var/lib/jenkins/mssql_scripts/credentials.sh

ii=$(grep INSTANCE /var/run/jenkins/mssql.run |awk '{print $2}')
ec2-terminate-instances $ii

