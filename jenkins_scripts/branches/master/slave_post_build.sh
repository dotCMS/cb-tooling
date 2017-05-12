#!/usr/bin/env bash


# Enable echoing commands
trap 'echo "[$USER@$(hostname) $PWD]\$ $BASH_COMMAND"' DEBUG


export AWS_CREDENTIAL_PROFILES_FILE=$JENKINS_HOME/credentials
export AWS_CREDENTIAL_PRIVATE_KEY_FILE=$JENKINS_HOME/dotcms-dev-test-deploy-2017-02-0x5513.pem

export VERSION='master'
export TIMESTAMP=$(date +"%Y%m%d%H%M%S")


# Terminate and delete AWS instance
cd "$WORKSPACE/repo/dotCMS"
if [ -f aws-ec2-instance-id.txt ]; then
	export AWS_EC2_INSTANCE_ID=$(cat aws-ec2-instance-id.txt)
    ./gradlew -b build-aws-tests.gradle terminateInstance -PinstanceId=$AWS_EC2_INSTANCE_ID -Pdatabase=$DOT_CMS_DATABASE_TYPE -Pbranch=${GIT_BRANCH#*/} -Pcommit=$GIT_COMMIT -PkeyFile=$AWS_CREDENTIAL_PRIVATE_KEY_FILE --no-daemon
fi
if [ -f aws-rds-instance-id.txt ]; then
	export AWS_RDS_INSTANCE_ID=$(cat aws-rds-instance-id.txt)
    ./gradlew -b build-aws-tests.gradle deleteDBInstance -PdbInstanceId=$AWS_RDS_INSTANCE_ID -Pdatabase=$DOT_CMS_DATABASE_TYPE -Pbranch=${GIT_BRANCH#*/} -Pcommit=$GIT_COMMIT -PkeyFile=$AWS_CREDENTIAL_PRIVATE_KEY_FILE --no-daemon
fi


# Output build url
echo "VERSION="$VERSION "\nTIMESTAMP="$TIMESTAMP

mkdir -p $JENKINS_HOME/distro/ready/$VERSION/$DOT_CMS_DATABASE_TYPE/$TIMESTAMP

echo "write build url"
echo "$BUILD_URL" > $JENKINS_HOME/distro/ready/$VERSION/$DOT_CMS_DATABASE_TYPE/$TIMESTAMP/${DOT_CMS_DATABASE_TYPE}_build