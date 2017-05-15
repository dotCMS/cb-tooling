#!/usr/bin/env bash


# Enable echoing commands
trap 'echo "[$USER@$(hostname) $PWD]\$ $BASH_COMMAND"' DEBUG


export AWS_CREDENTIAL_PROFILES_FILE=$JENKINS_HOME/credentials
export AWS_CREDENTIAL_PRIVATE_KEY_FILE=$JENKINS_HOME/dotcms-dev-test-deploy-2017-02-0x5513.pem


cd "$WORKSPACE/${GIT_BRANCH_NAME}/dotCMS"
./gradlew clean --no-daemon --refresh-dependencies


# Create AWS EC2 instance
export AWS_EC2_INSTANCE_ID="$(./gradlew -b build-aws-tests.gradle launchInstance -Pdatabase=$DOT_CMS_DATABASE_TYPE -Pbranch=${GIT_BRANCH#*/} -Pcommit=$GIT_COMMIT -PkeyFile=$AWS_CREDENTIAL_PRIVATE_KEY_FILE --no-daemon | sed 's@.*InstanceId: \([^,]*\).*@\1@g' | grep '^i-.*$' | awk 'FNR==1{print $0}')"
echo $AWS_EC2_INSTANCE_ID > aws-ec2-instance-id.txt

# Wait for AWS EC2 instance (and set it up)
./gradlew -b build-aws-tests.gradle waitInstanceLaunched setupInstance -PinstanceId=$AWS_EC2_INSTANCE_ID -Pdatabase=$DOT_CMS_DATABASE_TYPE -Pbranch=${GIT_BRANCH#*/} -Pcommit=$GIT_COMMIT -PkeyFile=$AWS_CREDENTIAL_PRIVATE_KEY_FILE --no-daemon


# Create AWS RDS instance
export AWS_RDS_INSTANCE_ID="$(./gradlew -b build-aws-tests.gradle createDBInstance -Pdatabase=$DOT_CMS_DATABASE_TYPE -Pbranch=${GIT_BRANCH#*/} -Pcommit=$GIT_COMMIT -PkeyFile=$AWS_CREDENTIAL_PRIVATE_KEY_FILE --no-daemon | sed 's@.*DBInstanceIdentifier: \([^,]*\).*@\1@g' | grep '^dotcms-.*$' | awk 'FNR==1{print $0}')"
echo $AWS_RDS_INSTANCE_ID > aws-rds-instance-id.txt

# Wait for AWS RDS instance (and set it up)
./gradlew -b build-aws-tests.gradle waitDBInstanceCreated setupDBInstance -PdbInstanceId=$AWS_RDS_INSTANCE_ID -Pdatabase=$DOT_CMS_DATABASE_TYPE -Pbranch=${GIT_BRANCH#*/} -Pcommit=$GIT_COMMIT -PkeyFile=$AWS_CREDENTIAL_PRIVATE_KEY_FILE --no-daemon


# Run tests on remote AWS EC2 instance
./gradlew -b build-aws-tests.gradle executeScript -PinstanceId=$AWS_EC2_INSTANCE_ID -PdbInstanceId=$AWS_RDS_INSTANCE_ID -Pdatabase=$DOT_CMS_DATABASE_TYPE -Pbranch=${GIT_BRANCH#*/} -Pcommit=$GIT_COMMIT -PkeyFile=$AWS_CREDENTIAL_PRIVATE_KEY_FILE --no-daemon


# Uncompress tests results
cd "$WORKSPACE/${GIT_BRANCH_NAME}/dotCMS/build"
unzip build-aws-tests.zip

# Print logs to console
cat "$WORKSPACE/${GIT_BRANCH_NAME}/dotCMS/build/tests/logs/dotcms.log"

# Saving tomcat logs into the build folder
mkdir -p "$WORKSPACE/logs/${BUILD_NUMBER}"
mv "$WORKSPACE/${GIT_BRANCH_NAME}/dotCMS/build/tests/logs"/* "$WORKSPACE/logs/${BUILD_NUMBER}/"
rm -r "$WORKSPACE/${GIT_BRANCH_NAME}/dotCMS/build/tests/logs/"

#Removes old logs folders, preserving the first 20 (most recent)
cd "$WORKSPACE/logs/"
ls -dt */ | tail -n +21 | xargs rm -rf