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

echo "copy license"
#mkdir -p dotserver/tomcat/webapps/ROOT/assets/license
#cp $JENKINS_HOME/dotcms_license.dat dotserver/tomcat/webapps/ROOT/assets/license/license.dat
cp $JENKINS_HOME/trial.jsp dotserver/tomcat/webapps/ROOT/trial.jsp

echo "uncomment test servlet"
sed -i '/TEST FRAMEWORK SERVLETS/d' dotserver/tomcat/webapps/ROOT/WEB-INF/web.xml

echo "build-tests.xml"
jar xf dotserver/tomcat/webapps/ROOT/WEB-INF/lib/dotcms_tests_*.jar build-tests.xml

echo "se es cluster name"
sed -i "s/dotCMSContentIndex/$ESCLUSTER/g" dotserver/tomcat/webapps/ROOT/WEB-INF/classes/dotmarketing-config.properties

