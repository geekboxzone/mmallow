#!/bin/bash

project_path=${HOME}/project/geekbox/mmallow
repo_prefix=mmallow
github_urlbase=https://github.com/geekboxzone
MAXTRYNUM=3
reponum=1
trynum=1

usage() {
	echo "Usage: $0 [-s] [-d DIRECTORY]"
	echo ""
	exit 1
}

repo_check() {
	cd $1
	local_commitid=`git log -n1 --pretty=oneline | awk '{print $1}'`
	remote_commitid=`git log -n1 --pretty=oneline origin/geekbox | awk '{print $1}'`
	cd $project_path
	test "$local_commitid" = "$remote_commitid" -a -n "$local_commitid"
	echo $?
}

while getopts "sd:" args
do
	case $args in
	"s")	needSync="yes";;
	"d")	userpath=$OPTARG;;
	"?")	usage;;
	esac
done

# get the full path
if [ -n "$userpath" ]; then
	install -d $userpath
	cd $userpath
	project_path=`pwd`
fi

# clone the init repository first
install -dv $project_path
cd $project_path
if [ -d "$project_path/.git" ]; then
	git pull origin
else
	git clone $github_urlbase/$repo_prefix $project_path
fi

# convert "/" to "_"
cat ./project.list > /tmp/project.path
sed -i "s/\//_/g" /tmp/project.path

# clone all the repositories
REPONUMS=`wc -l ./project.list | cut -d" " -f1`
while [ "$reponum" -le "$REPONUMS" ]; do
	repo_path=`awk 'NR=='$reponum'' ./project.list`
	repo_name=`awk 'NR=='$reponum'' /tmp/project.path`
	github_reponame="$repo_prefix"_"$repo_name"
	repo_remoteurl=$github_urlbase/$github_reponame
	if [ -d "$repo_path/.git" ]; then
		if [ "$needSync" = "yes" ]; then
			# exist & is needed: pull to sync
			cd $repo_path
			git pull origin
			cd $project_path
		fi
	else
		# empty: clone to create
		git clone $repo_remoteurl $repo_path
	fi

	# Check completed or not
	checkresult=`repo_check $repo_path`
	if [ $checkresult = 0 ]; then
		echo "-------------->[$reponum]Done: $repo_name"
		let ++reponum
		continue
	else
		echo "Fail to clone: $repo_name [$trynum] times!"
		let ++trynum
		rm -rf $repo_path
		if [ $trynum -gt $MAXTRYNUM ]; then
			echo "Exit to try! you need clone this repository by manual."
			echo "Then fix <reponum=$reponum> to continue."
			break;
		fi
	fi
done

# Large file repositories
# 100MB limited by Github
# TODO: github LSF
android_urlbase=https://android.googlesource.com
android_version=android-6.0.1_r3
git clone $android_urlbase/platform/external/eclipse-basebuilder -b $android_version external/eclipse-basebuilder
git clone $android_urlbase/platform/prebuilts/clang/linux-x86/host/3.6 -b $android_version prebuilts/clang/linux-x86/host/3.6
git clone $android_urlbase/platform/prebuilts/sdk -b $android_version prebuilts/sdk
git clone $android_urlbase/platform/prebuilts/eclipse -b $android_version prebuilts/eclipse
git clone $android_urlbase/external/google-breakpad -b $android_version external/google-breakpad
git clone $android_urlbase/platform/prebuilts/android-emulator -b $android_version prebuilts/android-emulator
git clone $android_urlbase/platform/prebuilts/qemu-kernel -b $android_version prebuilts/qemu-kernel
