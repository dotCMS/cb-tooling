#!/usr/bin/env bash


# Enable echoing commands
trap 'echo "[$USER@$(hostname) $PWD]\$ $BASH_COMMAND"' DEBUG

export GRADLE_OPTS="-Xmx1024m -Xms256m -XX:MaxPermSize=512m"


echo "**** ENV ****"
env
echo "**** ENV ****"

cd "$WORKSPACE"

rm -rf "$WORKSPACE/${GIT_BRANCH_NAME}/dotCMS/build/"
rm -rf "$WORKSPACE/${GIT_BRANCH_NAME}/dist-output"

cd "$WORKSPACE/${GIT_BRANCH_NAME}/dotCMS"

#Cleaning up gradle cache
rm -rf "$WORKSPACE/${GIT_BRANCH_NAME}/dotCMS/.gradle/"

./gradlew clean --no-daemon --refresh-dependencies
./gradlew createDist --no-daemon

#VERSION=$(grep dotcms.release.version  src/main/webapp/WEB-INF/classes/release.properties | awk -F = '{ print $2 }')
VERSION="${GIT_BRANCH_NAME}"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")

DISTRO="$JENKINS_HOME/distro"

DIR="$WORKSPACE/${GIT_BRANCH_NAME}/dist-output"

rm -rf $DISTRO/ready/$VERSION/$TIMESTAMP
mkdir -p $DISTRO/ready/$VERSION/$TIMESTAMP
mkdir -p $DISTRO/ready/${GIT_BRANCH#*/}

if [ -f $DIR/dotcms_*.zip ]; then

	echo "Distribution Created. Moving $WORKSPACE/${GIT_BRANCH_NAME}/dist-output to $DISTRO/ready/$VERSION/$TIMESTAMP"
    if [ -d $DISTRO/ready/$VERSION/$TIMESTAMP ]; then
    	rm -rf $DISTRO/ready/$VERSION/$TIMESTAMP
  	fi
    mv $DIR/dotcms_*.zip $DIR/dotcms_${GIT_BRANCH_NAME}.zip
    mv $DIR/dotcms_*.tar.gz $DIR/dotcms_${GIT_BRANCH_NAME}.tar.gz
	mv $WORKSPACE/${GIT_BRANCH_NAME}/dist-output/* $DISTRO/ready/$VERSION/
    echo "DOTCMS_BUILD_VERSION=$VERSION" > $DISTRO/ready/${GIT_BRANCH#*/}/params
else

	echo "Distribution still not created"
fi

echo "$GIT_COMMIT" > $JENKINS_HOME/distro/ready/$VERSION/commit
echo "$GIT_BRANCH_NAME" > $JENKINS_HOME/distro/ready/$VERSION/branch

echo "TIMESTAMP=$TIMESTAMP"
echo "VERSION=$VERSION"