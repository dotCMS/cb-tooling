#!/usr/bin/env bash


# Enable echoing commands
trap 'echo "[$(date) $USER@$(hostname) $PWD]\$ $BASH_COMMAND"' DEBUG

export GRADLE_OPTS="-Xmx1024m -Xms256m -XX:MaxPermSize=512m"


cd "$WORKSPACE/repo/dotCMS"

git fetch
current_commit=`git rev-parse HEAD`
current_branch=`git branch -r --contains $current_commit`

cd src/main/enterprise
branch_exists=$(git ls-remote --heads git@github.com:dotCMS/enterprise-2.x.git $current_branch);

echo $branch_exists

if [[ $branch_exists ]]; then
    (git fetch && git checkout $current_branch)
    echo "Enterprise branch updated"
    cd "$WORKSPACE/repo/dotCMS"
fi

sed -i "s,^org.gradle.jvmargs=,#org.gradle.jvmargs=,g" gradle.properties

./gradlew clean --no-daemon
./gradlew test --no-daemon || true