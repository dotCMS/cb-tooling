#!/usr/bin/env bash


# Enable echoing commands
trap 'echo "[$USER@$(hostname) $PWD]\$ $BASH_COMMAND"' DEBUG


VERSION='master'
cd "$JENKINS_HOME/distro/ready/$VERSION/"
GIT_COMMIT=$(cat commit)
echo "latest were built for commit $GIT_COMMIT" 
BRANCH=$(cat branch)
ZIPFILE="@dotcms_$VERSION.zip"
TARFILE="@dotcms_$VERSION.tar.gz"
for DB in `ls -1F | grep "/$"`; do
cd $DB
  pwd

  echo "clear older"
  COUNT=$(ls | wc -l)
  if (( COUNT>2 )); then
    TOCLEAN=$(( COUNT-2 ))
    ls | sort | head --lines=$TOCLEAN | xargs rm -rf
  fi

  echo "pick latest"
  TIMESTAMP=$(ls | sort | tail --lines=1)
  cd $TIMESTAMP

  lastBuild=$(curl https://dotcms.com/api/content/query/+structureName:DotcmsNightlyBuilds%20+conhost:SYSTEM_HOST%20+live:true%20+DotcmsNightlyBuilds.version:$VERSION/limit/1 2>/dev/null | python -c 'import sys, json; jsonValue = json.load(sys.stdin)["contentlets"];print jsonValue[0]["commitNumber"] if jsonValue else 0;')
  echo "lastbuild uploaded to dotcms.com for version $VERSION: $lastBuild "

    if [ -f pg_build ]; then
       PGBuild=$(cat Postgres_build)
    fi

    if [ -f my_build ]; then
       MyBuild=$(cat MySQL_build)
    fi

    if [ -f ora_build ]; then
       OraBuild=$(cat Oracle_build)
    fi

    if [ -f h2_build ]; then
       H2Build=$(cat H2_build)
    fi

    if [ -f ms_build ]; then
       MSBuild=$(cat MSSQL_build)
    fi

    T=$TIMESTAMP
    TT="${T:0:4}-${T:4:2}-${T:6:2} ${T:8:2}:${T:10:2}:${T:12:2}"

    cd "$JENKINS_HOME/distro/ready/$VERSION/"
done

if [ "$GIT_COMMIT" == "$lastBuild" ]; then
    echo "Nothing to do. No new commit "
else
    curl -K $JENKINS_HOME/dotcms-credentials/creds -XPUT https://dotcms.com/api/content/publish/1  -F "json={stName:'DotcmsNightlyBuilds', version:'$VERSION', branch:'$BRANCH', timestamp:'$TT', commitNumber:'$GIT_COMMIT',pgBuild:'$PGBuild',h2Build:'$H2Build',myBuild:'$MyBuild',oraBuild:'$OraBuild',msBuild:'$MSBuild'}; type=application/json" -F "zip=$ZIPFILE; type=application/zip" -F "tar=$TARFILE; type=application/gzip"
    echo "uploaded nightly build for version $VERSION branch $BRANCH commit $GIT_COMMIT"
fi