#! /usr/bin/env bash
#
# Copyright (C) 2013-2014 Bilibili
# Copyright (C) 2013-2014 Zhang Rui <bbcallen@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if [ -z "$ANDROID_NDK" -o -z "$ANDROID_NDK" ]; then
    echo "You must define ANDROID_NDK, ANDROID_SDK before starting."
    echo "They must point to your NDK and SDK directories.\n"
    exit 1
fi

REQUEST_TARGET=$1
REQUEST_SUB_CMD=$2
ACT_ABI_32="armv5 armv7a x86"
ACT_ABI_64="armv5 armv7a arm64 x86 x86_64"
ACT_ABI_ALL=$ACT_ABI_64
UNAME_S=$(uname -s)

FF_MAKEFLAGS=
if which nproc >/dev/null
then
    FF_MAKEFLAGS=-j`nproc`
elif [ "$UNAME_S" = "Darwin" ] && which sysctl >/dev/null
then
    FF_MAKEFLAGS=-j`sysctl -n machdep.cpu.thread_count`
fi

NDKBUILD_COMMAND=ndk-build

if [[ $UNAME_S =~ "CYGWIN" ]] ; then
	NDKBUILD_COMMAND=ndk-build.cmd
fi
NDKBUILD_COMMAND=${NDKBUILD_COMMAND}" UNAME_S=$UNAME_S NDK_DEBUG=1"
do_sub_cmd () {
    SUB_CMD=$1
    if [[ ! $UNAME_S =~ "CYGWIN" ]] ; then
       if [ -L "./android-ndk-prof" ]; then
           rm android-ndk-prof
       fi

       if [ "$PARAM_SUB_CMD" = 'prof' ]; then
           echo 'profiler build: YES';
           ln -s ../../../../../../ijkprof/android-ndk-profiler/jni android-ndk-prof
       else
           echo 'profiler build: NO';
           ln -s ../../../../../../ijkprof/android-ndk-profiler-dummy/jni android-ndk-prof
       fi
    fi

    case $SUB_CMD in
        prof)
            $ANDROID_NDK/$NDKBUILD_COMMAND $FF_MAKEFLAGS
        ;;
        clean)
            $ANDROID_NDK/$NDKBUILD_COMMAND clean
        ;;
        rebuild)
            $ANDROID_NDK/$NDKBUILD_COMMAND clean
            $ANDROID_NDK/$NDKBUILD_COMMAND $FF_MAKEFLAGS
        ;;
        *)
            $ANDROID_NDK/$NDKBUILD_COMMAND $FF_MAKEFLAGS
        ;;
    esac
}

do_ndk_build () {
	shellpath=$(cd `dirname $0`; pwd)
	ijkmediaPath=${shellpath}/../ijkmedia/
	sh ${ijkmediaPath}/ijkplayer/version.sh ${ijkmediaPath}/ijkplayer/ ijkversion.h
	
    PARAM_TARGET=$1
    PARAM_SUB_CMD=$2
    case "$PARAM_TARGET" in
        armv5|armv7a)
            cd "ijkplayer/ijkplayer-$PARAM_TARGET/src/main/jni"
			if [ "$PARAM_TARGET" = "armv5" ] ;then
				rm ./Android.mk
				rm -r ./ffmpeg
				cp "../../../../ijkplayer-armv7a/src/main/jni/Android.mk" .
				cp -r "../../../../ijkplayer-armv7a/src/main/jni/ffmpeg" .
			fi
			
            do_sub_cmd $PARAM_SUB_CMD
            cd -
        ;;
        arm64|x86|x86_64)
            cd "ijkplayer/ijkplayer-$PARAM_TARGET/src/main/jni"
			rm ./Android.mk
			rm -r ./ffmpeg
			cp "../../../../ijkplayer-armv7a/src/main/jni/Android.mk" .
			cp -r "../../../../ijkplayer-armv7a/src/main/jni/ffmpeg" .
            if [ "$PARAM_SUB_CMD" = 'prof' ]; then PARAM_SUB_CMD=''; fi
            do_sub_cmd $PARAM_SUB_CMD
            cd -
        ;;
    esac
	
	
}


case "$REQUEST_TARGET" in
    "")
        do_ndk_build armv7a;
    ;;
    armv5|armv7a|arm64|x86|x86_64)
        do_ndk_build $REQUEST_TARGET $REQUEST_SUB_CMD;
    ;;
    all32)
        for ABI in $ACT_ABI_32
        do
            do_ndk_build "$ABI" $REQUEST_SUB_CMD;
        done
    ;;
    all|all64)
        for ABI in $ACT_ABI_64
        do
            do_ndk_build "$ABI" $REQUEST_SUB_CMD;
        done
    ;;
    clean)
        for ABI in $ACT_ABI_ALL
        do
            do_ndk_build "$ABI" clean;
        done
    ;;
    *)
        echo "Usage:"
        echo "  compile-ijk.sh armv5|armv7a|arm64|x86|x86_64"
        echo "  compile-ijk.sh all|all32"
        echo "  compile-ijk.sh all64"
        echo "  compile-ijk.sh clean"
    ;;
esac

