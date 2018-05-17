#!/bin/bash

repo forall -c 'echo $REPO_REMOTE $REPO_PATH $REPO_LREV $REPO_RREV; COMMIT=`git status * | grep "nothing to commit"` ;  if [ "$COMMIT" == "" ] ; then echo "===> change to commit";  fi '
