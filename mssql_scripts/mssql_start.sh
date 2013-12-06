#!/bin/bash
source /etc/bashrc
source /var/lib/jenkins/mssql_scripts/credentials.sh

# clean up any instance of ami-9cb6d6f5
for id in $(ec2-describe-instances | grep -v terminated | grep ami-9cb6d6f5 | awk '{ print $2  }'); do 
      echo "terminating instance $id we left in last run";
      ec2-terminate-instances $id;
      sleep 20;
      until [ $(ec2-describe-instances $id | grep INSTANCE | awk '{print $4}') == "terminated" ]; do
          echo "instance $id still not terminated. will check again in 20s";
          sleep 20;
      done;
      echo "instance $id terminated";
done;


# launch ami-9cb6d6f5
ec2-run-instances ami-9cb6d6f5 -n 1 -g "mssql open" -t c1.medium -z us-east-1a > /var/run/jenkins/mssql.run

ii=$(grep INSTANCE /var/run/jenkins/mssql.run |awk '{print $2}')
sleep 1
ec2-create-tags $ii --tag Name=jenkins_mssql

# wait for the 'running status'
x=1
sleep 5
until [ `(ec2-describe-instances $ii | grep INSTANCE | awk '{print $6}')` == "running" ]; do   
   x=$((x+1))
   if [ "$x" == "20" ]; then
      echo "timeout waiting for the instace to be running"
      ec2-terminate-instances $ii
      exit 1
   fi;
   echo "instance $ii not running... will ask again in 20s" 
   sleep 20
done;


ec2-associate-address -i $ii 54.225.119.135

# wait for mssql to open the port
x=1
sleep 5
until (nc -z 54.225.119.135 1433); do
   x=$((x+1))
   if [ "$x" == "20" ]; then
      echo "timeout waiting for the port"
      ec2-terminate-instances $ii
      exit 1
   fi;
   echo "instance $ii not listening to 1433 port... will try again in 20s";
   sleep 20;
done;

echo "instance $ii running with IP 54.225.119.135 MSSQL Port 1443 ready"
