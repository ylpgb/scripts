#!/bin/bash

[[ $# < 1 ]] && { echo "Usage: $1 repo_name"; echo "repo_name is the name with path relative to the directory";  exit 1; }

IMX_MYANDROID_DIR=/home/u-blox/work/nxp/MCIMX6Q-SDB/android7.1.2/myandroid/

GIT_SERVER=ssh://git@10.122.253.32
GIT_REPO_DIR=/home/git/MCIMX6Q-SDB/Android/platform/

MIRROR_REPO_DIR=/home/u-blox/temp/imx6/mirror_git

## Get branch name and original remote
cd $IMX_MYANDROID_DIR/$1
branch=`git branch | cut -d' ' -f2`
remote=`git remote -v | grep aosp | grep fetch | cut -d$'\t' -f2 | cut -d' ' -f1`
echo "branch is $branch"
echo "remote is $remote"

if [ "$branch" == "" ] || [ "$remote" == "" ] ; then 
  echo "Can't find branch and remote"
  exit 1
fi

# create repository
echo "Creating repo $GIT_REPO_DIR/$1"
sudo mkdir -p $GIT_REPO_DIR/$1
cd $GIT_REPO_DIR/$1
sudo git --bare init
cd -
sudo chown -R git.git $GIT_REPO_DIR/$1

# mirror the repo
cd $MIRROR_REPO_DIR
echo "mirroring repo $remote"
git clone --mirror $remote
repo_name=`echo $remote | rev| cut -d/ -f1 | rev`
cd $repo_name.git
git remote add server $GIT_SERVER$GIT_REPO_DIR$1
echo "pushing mirror to server $GIT_SERVER$GIT_REPO_DIR$1"
git push server --mirror

# push the branch
cd $IMX_MYANDROID_DIR/$1
git remote add server $GIT_SERVER$GIT_REPO_DIR$1
echo "pushing branch $branch to repo $GIT_SERVER$GIT_REPO_DIR$1"
git push server $branch

