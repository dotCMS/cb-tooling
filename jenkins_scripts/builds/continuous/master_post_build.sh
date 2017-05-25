#!/usr/bin/env bash


# Enable echoing commands
trap 'echo "[$(date) $USER@$(hostname) $PWD]\$ $BASH_COMMAND"' DEBUG

export GRADLE_OPTS="-Xmx1024m -Xms256m -XX:MaxPermSize=512m"


export AWS_CREDENTIAL_PROFILES_FILE=$JENKINS_HOME/credentials
export AWS_CREDENTIAL_PRIVATE_KEY_FILE=$JENKINS_HOME/dotcms-dev-test-deploy-2017-02-0x5513.pem


cd "$WORKSPACE/repo/dotCMS"
sed -i "s,^org.gradle.jvmargs=,#org.gradle.jvmargs=,g" gradle.properties


export CONTINOUS_AWS_EC2_INSTANCE_ID=$JENKINS_HOME/continuous/aws-ec2-instance-id.txt

export DOTCMS_DATABASE_NAME=Postgres


# Terminate and delete AWS instance if this job is running a Stop Phase
if [ -f $CONTINOUS_AWS_EC2_INSTANCE_ID ]; then

	echo "Terminating AWS EC2 Instance"

	./gradlew clean --no-daemon --refresh-dependencies

	export AWS_EC2_INSTANCE_ID=$(cat $CONTINOUS_AWS_EC2_INSTANCE_ID)

    ./gradlew -b build-aws-tests.gradle terminateInstance -PpropertiesFile=build-aws-tests-continuous.properties -Pbranch=all -Pdatabase=$DOT_CMS_DATABASE_TYPE -PinstanceId=$AWS_EC2_INSTANCE_ID -PkeyFile=$AWS_CREDENTIAL_PRIVATE_KEY_FILE --no-daemon

	rm $CONTINOUS_AWS_EC2_INSTANCE_ID
fi