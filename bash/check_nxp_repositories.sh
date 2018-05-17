#!/bin/bash

GIT_REPO_LIST=`cat repositories.log`
REPO_DIR=/home/u-blox/work/nxp/sabreAI/android6/myandroid
AUTHOR=leipo.yan@u-blox.com

for i in $GIT_REPO_LIST ; do
  PROJECT_NAME=`echo $i | sed -n 's/^.\/\(.*\)\/.git.*/\1/p' `
  if [ -e $REPO_DIR/$PROJECT_NAME ] ; then
    pushd $REPO_DIR/$PROJECT_NAME
    COMMITER_EMAIL=`git log -n1 --pretty=format:%aE`;
    if [ "$COMMITER_EMAIL" == "$AUTHOR" ] ; then 
       echo "===> $REPO_DIR/$PROJECT_NAME has local modification"
       git log --author=$AUTHOR --pretty=oneline
    else
       echo "---> No local modification"
    fi
    popd
  else
    echo "---> $REPO_DIR/$PROJECT_NAME doesn't exist"
  fi
done
