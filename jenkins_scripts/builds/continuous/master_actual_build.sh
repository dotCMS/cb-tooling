#!/usr/bin/env bash


# Enable echoing commands
trap 'echo "[$(date) $USER@$(hostname) $PWD]\$ $BASH_COMMAND"' DEBUG

export GRADLE_OPTS="-Xmx1024m -Xms256m -XX:MaxPermSize=512m"


export AWS_CREDENTIAL_PROFILES_FILE=$JENKINS_HOME/credentials
export AWS_CREDENTIAL_PRIVATE_KEY_FILE=$JENKINS_HOME/dotcms-dev-test-deploy-2017-02-0x5513.pem


cd "$WORKSPACE/repo/dotCMS"
sed -i "s,^org.gradle.jvmargs=,#org.gradle.jvmargs=,g" gradle.properties


export CONTINOUS_AWS_EC2_INSTANCE_ID=$JENKINS_HOME/builds/continuous/aws-ec2-instance-id.txt

export DOTCMS_DATABASE_NAME=Postgres


# A new AWS instance is created if needed 
if [ ! -f $CONTINOUS_AWS_EC2_INSTANCE_ID ]; then

	echo "Creating AWS EC2 Instance"

	./gradlew clean --no-daemon --refresh-dependencies 

	# Create AWS EC2 instance
	export AWS_EC2_INSTANCE_ID="$(./gradlew -b build-aws-tests.gradle launchInstance -PpropertiesFile=build-aws-tests-continuous.properties -Pbranch=all -Pdatabase=$DOTCMS_DATABASE_NAME -PkeyFile=$AWS_CREDENTIAL_PRIVATE_KEY_FILE --no-daemon | sed 's@.*InstanceId: \([^,]*\).*@\1@g' | grep '^i-.*$' | awk 'FNR==1{print $0}')"

	# Wait for AWS EC2 instance (and set it up)
	./gradlew -b build-aws-tests.gradle waitInstanceLaunched setupInstance -PpropertiesFile=build-aws-tests-continuous.properties -Pbranch=all -Pdatabase=$DOTCMS_DATABASE_NAME -PkeyFile=$AWS_CREDENTIAL_PRIVATE_KEY_FILE -PinstanceId=$AWS_EC2_INSTANCE_ID --no-daemon

	echo $AWS_EC2_INSTANCE_ID > $CONTINOUS_AWS_EC2_INSTANCE_ID
fi