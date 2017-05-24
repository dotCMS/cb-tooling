#!/usr/bin/env bash


# Enable echoing commands
trap 'echo "[$(date) $USER@$(hostname) $PWD]\$ $BASH_COMMAND"' DEBUG

export GRADLE_OPTS="-Xmx1024m -Xms256m -XX:MaxPermSize=512m"


export AWS_CREDENTIAL_PROFILES_FILE=$JENKINS_HOME/credentials
export AWS_CREDENTIAL_PRIVATE_KEY_FILE=$JENKINS_HOME/dotcms-dev-test-deploy-2017-02-0x5513.pem


cd "$WORKSPACE/${GIT_BRANCH_NAME}/dotCMS"
sed -i "s,^org.gradle.jvmargs=,#org.gradle.jvmargs=,g" gradle.properties

./gradlew clean --no-daemon --refresh-dependencies


# Create AWS EC2 instance
export AWS_EC2_INSTANCE_ID="$(./gradlew -b build-aws-tests.gradle launchInstance -PpropertiesFile=build-aws-tests-full.properties -Pdatabase=$DOTCMS_DATABASE_NAME -Pbranch=${GIT_BRANCH#*/} -Pcommit=$GIT_COMMIT -PkeyFile=$AWS_CREDENTIAL_PRIVATE_KEY_FILE --no-daemon | sed 's@.*InstanceId: \([^,]*\).*@\1@g' | grep '^i-.*$' | awk 'FNR==1{print $0}')"
echo $AWS_EC2_INSTANCE_ID > aws-ec2-instance-id.txt

# Wait for AWS EC2 instance (and set it up)
./gradlew -b build-aws-tests.gradle waitInstanceLaunched setupInstance -PpropertiesFile=build-aws-tests-full.properties -PinstanceId=$AWS_EC2_INSTANCE_ID -Pdatabase=$DOTCMS_DATABASE_NAME -Pbranch=${GIT_BRANCH#*/} -Pcommit=$GIT_COMMIT -PkeyFile=$AWS_CREDENTIAL_PRIVATE_KEY_FILE --no-daemon


# Create AWS RDS instance
export AWS_RDS_INSTANCE_ID="$(./gradlew -b build-aws-tests.gradle createDBInstance -PpropertiesFile=build-aws-tests-full.properties -Pdatabase=$DOTCMS_DATABASE_NAME -Pbranch=${GIT_BRANCH#*/} -Pcommit=$GIT_COMMIT -PkeyFile=$AWS_CREDENTIAL_PRIVATE_KEY_FILE --no-daemon | sed 's@.*DBInstanceIdentifier: \([^,]*\).*@\1@g' | grep '^dotcms-.*$' | awk 'FNR==1{print $0}')"
echo $AWS_RDS_INSTANCE_ID > aws-rds-instance-id.txt

# Wait for AWS RDS instance (and set it up)
./gradlew -b build-aws-tests.gradle waitDBInstanceCreated setupDBInstance -PpropertiesFile=build-aws-tests-full.properties -PdbInstanceId=$AWS_RDS_INSTANCE_ID -Pdatabase=$DOTCMS_DATABASE_NAME -Pbranch=${GIT_BRANCH#*/} -Pcommit=$GIT_COMMIT -PkeyFile=$AWS_CREDENTIAL_PRIVATE_KEY_FILE --no-daemon


# Run tests on remote AWS EC2 instance
./gradlew -b build-aws-tests.gradle executeScript -PpropertiesFile=build-aws-tests-full.properties -PinstanceId=$AWS_EC2_INSTANCE_ID -PdbInstanceId=$AWS_RDS_INSTANCE_ID -Pdatabase=$DOTCMS_DATABASE_NAME -Pbranch=${GIT_BRANCH#*/} -Pcommit=$GIT_COMMIT -PkeyFile=$AWS_CREDENTIAL_PRIVATE_KEY_FILE --no-daemon


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