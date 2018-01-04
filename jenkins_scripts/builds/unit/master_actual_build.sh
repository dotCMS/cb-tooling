#!/usr/bin/env bash


# Enable echoing commands
trap 'echo "[$(date) $USER@$(hostname) $PWD]\$ $BASH_COMMAND"' DEBUG

export GRADLE_OPTS="-Xmx1024m -Xms256m -XX:MaxPermSize=512m"


cd "$WORKSPACE/repo/dotCMS"

git fetch
current_commit=`git rev-parse HEAD`
echo "Working on commit $current_commit"

current_branch=`git branch -r --contains $current_commit | head -1`
current_branch=`echo $current_branch | cut -d'/' -f2`
echo "Branch retrieved $current_branch"

cd src/main/enterprise
branch_exists=$(git ls-remote --heads git@github.com:dotCMS/enterprise-2.x.git $current_branch);

echo $branch_exists

if [[ $branch_exists ]]; then
    (git fetch && git checkout $current_branch && git pull)
    echo "Enterprise branch updated"
fi

cd "$WORKSPACE/repo/dotCMS"

sed -i "s,^org.gradle.jvmargs=,#org.gradle.jvmargs=,g" gradle.properties

./gradlew clean --no-daemon
./gradlew test --no-daemon || true