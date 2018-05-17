#!/bin/bash

GIT_SERVER_LOCAL=file:///home/u-blox/work/nxp/MCIMX6Q-SDB/android8.0.0/myandroid/
MANIFEST_SERVER=git@git-sho.u-blox.net:fae-team-global/MCIMX6Q-SDB/Android/manifest/manifest.git
RELEASE_DIR=`pwd`
LOCAL_REPO_DIR=local_repo

[[ $# < 1 ]] && { echo "Usage: $0 RELEASE_TAG"; echo "RELEASE_TAG is the tag in $MANIFEST_SERVER "; exit 1; }

function checkout_manifest() {
	echo "Checking out tag $1 from $MANIFEST_SERVER ..." 
	git clone --branch $1 $MANIFEST_SERVER
}

function checkout_project() {
	for ((i = 1; i <= $#; i=i+3 )); do
		ipath=$i
		iname=$((i+1))
		irevision=$((i+2))
		echo "Checkout out project path: ${!ipath} name: ${!iname} revision: ${!irevision}"
		cd $RELEASE_DIR/$LOCAL_REPO_DIR

		mkdir -p ${!ipath}
		cd $RELEASE_DIR/$LOCAL_REPO_DIR/${!ipath}/..
		#echo "git clone $GIT_SERVER${!iname}"
		#git clone $GIT_SERVER${!iname}
		echo "git clone $GIT_SERVER_LOCAL${!ipath}"
		git clone $GIT_SERVER_LOCAL${!ipath}

		echo "--> $RELEASE_DIR/$LOCAL_REPO_DIR/${!ipath}/" 
		cd $RELEASE_DIR/$LOCAL_REPO_DIR/${!ipath}/
		git checkout ${!irevision}
	done
        
}

function gen_run_me.sh() {
cat <<EOM > run_me.sh
#!/bin/bash

source build/envsetup.sh
lunch sabresd_6dq-eng

time make -j4 2>&1 | tee build-log.txt
EOM

chmod 777 run_me.sh
}

function gen_copy_repos_and_patch.sh() {
cat <<EOM > copy_repos_and_patch.sh
#!/bin/bash

if [ ! -d ../local_repo ] ; then
  echo "../local_repo directory does not exist"
  exit 0;
fi

echo "Copy repositories ..."
cp ../local_repo/* . -rf

echo "Create symbolic link ..."
ln -s vendor/nxp/EULA.txt EULA.txt
ln -s vendor/nxp/SCR-O8.0.0_1.0.0.txt SCR-O8.0.0_1.0.0.txt

echo "Copy build script ..."
cp ../run_me.sh .

echo "Completed"
EOM

chmod 777 copy_repos_and_patch.sh
}

checkout_manifest $1

echo "Checking out repositories ..."
mkdir -p $LOCAL_REPO_DIR
GIT_SERVER=`grep fetch -r $RELEASE_DIR/manifest/default.xml | sed 's/.*fetch="\(.*\)".*/\1/'`
PROJECTS=`grep project -r $RELEASE_DIR/manifest/default.xml | grep git-sho | sed 's/.*path="\(.*\)".*name="\(.*\)".*revision="\(.*\)".*/\1 \2 \3/'`
checkout_project $PROJECTS
cd $RELEASE_DIR
find $LOCAL_REPO_DIR -name .git | xargs rm -rf

gen_run_me.sh

gen_copy_repos_and_patch.sh
