#!/usr/bin/env bash


# Enable echoing commands
trap 'echo "[$USER@$(hostname) $PWD]\$ $BASH_COMMAND"' DEBUG

export GRADLE_OPTS="-Xmx1024m -Xms256m -XX:MaxPermSize=512m"


export AWS_CREDENTIAL_PROFILES_FILE=$JENKINS_HOME/credentials
export AWS_CREDENTIAL_PRIVATE_KEY_FILE=$JENKINS_HOME/dotcms-dev-test-deploy-2017-02-0x5513.pem

export VERSION="${GIT_BRANCH_NAME}"
export TIMESTAMP=$(date +"%Y%m%d%H%M%S")


# Terminate and delete AWS instance
cd "$WORKSPACE/${GIT_BRANCH_NAME}/dotCMS"
if [ -f aws-ec2-instance-id.txt ]; then
	export AWS_EC2_INSTANCE_ID=$(cat aws-ec2-instance-id.txt)
    ./gradlew -b build-aws-tests.gradle terminateInstance -PinstanceId=$AWS_EC2_INSTANCE_ID -Pdatabase=$DOTCMS_DATABASE_NAME -Pbranch=${GIT_BRANCH#*/} -Pcommit=$GIT_COMMIT -PkeyFile=$AWS_CREDENTIAL_PRIVATE_KEY_FILE --no-daemon
fi
if [ -f aws-rds-instance-id.txt ]; then
	export AWS_RDS_INSTANCE_ID=$(cat aws-rds-instance-id.txt)
    ./gradlew -b build-aws-tests.gradle deleteDBInstance -PdbInstanceId=$AWS_RDS_INSTANCE_ID -Pdatabase=$DOTCMS_DATABASE_NAME -Pbranch=${GIT_BRANCH#*/} -Pcommit=$GIT_COMMIT -PkeyFile=$AWS_CREDENTIAL_PRIVATE_KEY_FILE --no-daemon
fi


# Output build url
echo "VERSION="$VERSION "\nTIMESTAMP="$TIMESTAMP

mkdir -p $JENKINS_HOME/distro/ready/$VERSION/$DOTCMS_DATABASE_NAME/$TIMESTAMP

echo "write build url"
echo "$BUILD_URL" > $JENKINS_HOME/distro/ready/$VERSION/$DOTCMS_DATABASE_NAME/$TIMESTAMP/${DOTCMS_DATABASE_NAME}_build