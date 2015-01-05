#!/bin/bash

VERSION="$1"
TIMESTAMP="$2"
DISTRO=` cd $( dirname ${BASH_SOURCE[0]} ) && pwd `

DIR="$DISTRO/running/$VERSION/$TIMESTAMP"
if [ -f $DIR/pg_build ] || [ -f $DIR/my_build ] || [ -f $DIR/h2_build ] || [ -f $DIR/ora_build ] || [ -f $DIR/ms_build ]; then

  echo "At least 1 unit tests is done. moving $DISTRO/running/$VERSION/$TIMESTAMP to $DISTRO/ready/$VERSION/$TIMESTAMP"
  mkdir -p $DISTRO/ready/$VERSION/
  if [ -d $DISTRO/ready/$VERSION/$TIMESTAMP ]; then
    rm -rf $DISTRO/ready/$VERSION/$TIMESTAMP
  fi
  mv $DISTRO/running/$VERSION/$TIMESTAMP $DISTRO/ready/$VERSION/

else

  echo "unit tests still not done"

fi


