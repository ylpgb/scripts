#!/bin/bash

ANDROIDDIR=`pwd`

REPOS=`cat /home/u-blox/temp/imx6/manifest/default.xml | grep ublox | sed -n 's/^.*path=\"\(.*\)\"\ name.*/\1/p'`

GIT_SHO_URL="git@git-sho.u-blox.net:fae-team-global/MCIMX6Q-SDB/Android/platform"
REMOTE_NAME="git-sho"

for i in $REPOS ; do 
  echo "Checking repo $ANDROIDDIR/$i"
  cd $ANDROIDDIR/$i
  REMOTE=`git remote -v | grep git-sho`
  if [ "$REMOTE" == "" ] ; then
    echo "===> Repo $i has not been pushed"
    REMOTE_URL=$GIT_SHO_URL/$i.git
    git ls-remote $REMOTE_URL
    rc=$?; 
    if [[ $rc == 0 ]] ; then
      echo "Remote URL $REMOTE_URL is a valid URL. Process git pushing..."
      git remote add $REMOTE_NAME $REMOTE_URL
      git push -u $REMOTE_NAME --all
      git push -u $REMOTE_NAME --tags
    else
      echo "Invalid URL $REMOTE_URL. No action"
    fi
  else
    echo "---> Repo $i has been pushed"
  fi
  
done
