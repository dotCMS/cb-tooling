#!/usr/bin/env bash


# Enable echoing commands
trap 'echo "[$USER@$(hostname) $PWD]\$ $BASH_COMMAND"' DEBUG


echo "**** ENV ****"
env
echo "**** ENV ****"

cd "$WORKSPACE"

rm -rf "$WORKSPACE/repo/dotCMS/build/"
rm -rf "$WORKSPACE/repo/dist-output"

cd "$WORKSPACE/repo/dotCMS"

#Cleaning up gradle cache
rm -rf "$WORKSPACE/repo/dotCMS/.gradle/"

./gradlew -d clean --no-daemon --refresh-dependencies
./gradlew -d createDist --no-daemon

#VERSION=$(grep dotcms.release.version  src/main/webapp/WEB-INF/classes/release.properties | awk -F = '{ print $2 }')
VERSION='master'
TIMESTAMP=$(date +"%Y%m%d%H%M%S")

DISTRO="$JENKINS_HOME/distro"

DIR="$WORKSPACE/repo/dist-output"

rm -rf $DISTRO/ready/$VERSION/$TIMESTAMP
mkdir -p $DISTRO/ready/$VERSION/$TIMESTAMP
mkdir -p $DISTRO/ready/${GIT_BRANCH#*/}

if [ -f $DIR/dotcms_*.zip ]; then

	echo "Distribution Created. Moving $WORKSPACE/repo/dist-output to $DISTRO/ready/$VERSION/$TIMESTAMP"
    if [ -d $DISTRO/ready/$VERSION/$TIMESTAMP ]; then
    	rm -rf $DISTRO/ready/$VERSION/$TIMESTAMP
  	fi
    mv $DIR/dotcms_*.zip $DIR/dotcms_master.zip
    mv $DIR/dotcms_*.tar.gz $DIR/dotcms_master.tar.gz
	mv $WORKSPACE/repo/dist-output/* $DISTRO/ready/$VERSION/
    echo "DOTCMS_BUILD_VERSION=$VERSION" > $DISTRO/ready/${GIT_BRANCH#*/}/params
else

	echo "Distribution still not created"
fi

echo "$GIT_COMMIT" > $JENKINS_HOME/distro/ready/$VERSION/commit
echo "master" > $JENKINS_HOME/distro/ready/$VERSION/branch

echo "TIMESTAMP=$TIMESTAMP"
echo "VERSION=$VERSION"