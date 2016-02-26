#!/bin/bash

set -e

echo "clean workspace"
cd "$WORKSPACE" && rm -rf *

echo "untar the distribution"
tar zxf $JENKINS_HOME/distro/running/$VERSION/$TIMESTAMP/dotcms_*.tar.gz

# rename tomcat-version to just tomcat
mv dotserver/`ls dotserver | grep  tomcat` dotserver/tomcat

echo "copy the jar with the tests"
cp $JENKINS_HOME/distro/running/$VERSION/$TIMESTAMP/dotcms_tests_*.jar dotserver/tomcat/webapps/ROOT/WEB-INF/lib

echo "copy the jars required to run the tests"
cp $JENKINS_HOME/distro/running/$VERSION/$TIMESTAMP/junit-*.jar dotserver/tomcat/webapps/ROOT/WEB-INF/lib

echo "uncomment test servlet"
sed -i '/TEST FRAMEWORK SERVLETS/d' dotserver/tomcat/webapps/ROOT/WEB-INF/web.xml

echo "build-tests.xml"
jar xf dotserver/tomcat/webapps/ROOT/WEB-INF/lib/dotcms_tests_*.jar build-tests.xml

echo "se es cluster name"
sed -i "s/dotCMSContentIndex/$ESCLUSTER/g" dotserver/tomcat/webapps/ROOT/WEB-INF/classes/dotcms-config-cluster.properties

echo "set Autowire False"
sed -i "s/CLUSTER_AUTOWIRE=true/CLUSTER_AUTOWIRE=false/g" dotserver/tomcat/webapps/ROOT/WEB-INF/classes/dotcms-config-cluster.properties

echo "set Max tries to push publish to 1"
sed -i "s/PUBLISHER_QUEUE_MAX_TRIES=3/PUBLISHER_QUEUE_MAX_TRIES=1/g" dotserver/tomcat/webapps/ROOT/WEB-INF/classes/dotmarketing-config.properties
