#!/usr/bin/env bash


# Enable echoing commands
trap 'echo "[$(date) $USER@$(hostname) $PWD]\$ $BASH_COMMAND"' DEBUG

export GRADLE_OPTS="-Xmx1024m -Xms256m -XX:MaxPermSize=512m"


export AWS_CREDENTIAL_PROFILES_FILE=$JENKINS_HOME/credentials
export AWS_CREDENTIAL_PRIVATE_KEY_FILE=$JENKINS_HOME/dotcms-dev-test-deploy-2017-02-0x5513.pem


cd "$WORKSPACE/${GIT_BRANCH_NAME}/dotCMS"
sed -i "s,^org.gradle.jvmargs=,#org.gradle.jvmargs=,g" gradle.properties


echo "$GIT_COMMIT" > $JENKINS_HOME/builds/continuous/git-commit-id-${GIT_BRANCH_NAME}.txt


export CONTINUOUS_AWS_EC2_INSTANCE_ID=$JENKINS_HOME/builds/continuous/aws-ec2-instance-id.txt

export DOTCMS_DATABASE_NAME=Postgres


if [ -f $CONTINUOUS_AWS_EC2_INSTANCE_ID ]; then

	echo "Building ${GIT_BRANCH_NAME} and testing against ${DOTCMS_DATABASE_NAME}"

	./gradlew clean --no-daemon --refresh-dependencies 

	export AWS_EC2_INSTANCE_ID=$(cat $CONTINUOUS_AWS_EC2_INSTANCE_ID)


	# Run tests on remote AWS EC2 instance
	./gradlew -b build-aws-tests.gradle executeScript -PpropertiesFile=build-aws-tests-continuous.properties -Pbranch=${GIT_BRANCH_NAME} -Pcommit=${GIT_COMMIT} -Pdatabase=$DOTCMS_DATABASE_NAME -PkeyFile=$AWS_CREDENTIAL_PRIVATE_KEY_FILE -PoutputFile=build-aws-tests-${GIT_BRANCH_NAME}.zip -Pprovisioned=true -PinstanceId=$AWS_EC2_INSTANCE_ID --no-daemon


	# Uncompress tests results
	#cd "$WORKSPACE/${GIT_BRANCH_NAME}/dotCMS/build"
	#unzip build-aws-tests-${GIT_BRANCH_NAME}.zip

	# Print logs to console
	cat "$WORKSPACE/${GIT_BRANCH_NAME}/dotCMS/build/tests/logs/dotcms.log"

	# Saving tomcat logs into the build folder
	mkdir -p "$WORKSPACE/logs/${BUILD_NUMBER}"
	mv "$WORKSPACE/${GIT_BRANCH_NAME}/dotCMS/build/tests/logs"/* "$WORKSPACE/logs/${BUILD_NUMBER}/"
	rm -r "$WORKSPACE/${GIT_BRANCH_NAME}/dotCMS/build/tests/logs/"

	#Removes old logs folders, preserving the first 20 (most recent)
	cd "$WORKSPACE/logs/"
	ls -dt */ | tail -n +21 | xargs rm -rf
else
	echo "Nothing to do. Server is down"
fi