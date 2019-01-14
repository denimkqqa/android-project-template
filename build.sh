#!/bin/bash

# Author: Authmane Terki (authmane512)
# E-mail: authmane512 (at) protonmail.ch
# Blog: https://medium.com/@authmane512
# Source: https://github.com/authmane512/android-project-template
# Tutorial: https://medium.com/@authmane512/how-to-do-android-development-faster-without-gradle-9046b8c1cf68
# This project is on public domain
#
# Hello! I've made this little script that allow you to init, compile and run an Android Project.
# I tried to make it as simple as possible to allow you to understand and modify it easily.
# If you think there is a very important missing feature, don't hesitate to do a pull request on Github and I will answer quickly.
# Thanks! 

set -e

APP_NAME="Your App Name"
PACKAGE_NAME="your.pkg.name"

AAPT=$BUILD_TOOLS/aapt2
DX=$BUILD_TOOLS/d8
ZIPALIGN=$BUILD_TOOLS/zipalign
APKSIGNER=$BUILD_TOOLS/apksigner

init() {
	rm -rf .git README.md
	echo "Making ${PACKAGE_NAME}..."
	mkdir -p "src/$PACKAGE_DIR"
	mkdir bin
	mkdir -p res/layout
	mkdir res/values
	mkdir res/drawable
	
	sed "s/{{ PACKAGE_NAME }}/${PACKAGE_NAME}/" "template_files/MainActivity.java" > "src/$PACKAGE_DIR/MainActivity.java"
	sed "s/{{ PACKAGE_NAME }}/${PACKAGE_NAME}/" "template_files/AndroidManifest.xml" > "AndroidManifest.xml"
	sed "s/{{ APP_NAME }}/${APP_NAME}/" "template_files/strings.xml" > "res/values/strings.xml"
	cp "template_files/activity_main.xml" "res/layout/activity_main.xml"
	rm -rf template_files
}

build() {
	rm -rf build/
	mkdir build
	mkdir build/outputResources
	mkdir build/out
	mkdir build/classses
	mkdir build/out/dex
	
	echo "Compiling resources"
	$AAPT compile -o build/outputResources res/*/*  -v
	ls -d -1 $PWD/build/outputResources/*.* | awk 1 ORS=' ' > build/r_files.txt
	
	echo "Linking resouces..."
	$AAPT link -I\
          $PLATFORM\
          --manifest\
          AndroidManifest.xml\
          -o\
          build/out/resources.apk\
          -R\
          @build/r_files.txt\
          --auto-add-overlay\
          --java\
          build/r\
          --custom-package\
          $PACKAGE_NAME\
          -0\
          apk\
          --output-text-symbols\
          build/R.txt\
          --no-version-vectors

	echo "Compiling code..."
	javac -cp $PLATFORM build/r/$PACKAGE_DIR/*.java src/$PACKAGE_DIR/*.java -d build/classes

	echo "Translating in Dalvik bytecode..."
	$DX build/classes/$PACKAGE_DIR/*.class --output build/out/dex

	echo "Adding classes to resources APK..."
	zip build/out/resources.apk build/out/dex/classes.dex

	echo "Aligning and signing APK..."
	$APKSIGNER sign --ks debug.keystore --ks-pass "pass:123456" build/out/resources.apk
	$ZIPALIGN -f 4 build/out/resources.apk build/app.apk
}

run() {
	echo "Launching..."
	adb install -r bin/app.apk 
	adb shell am start -n "${PACKAGE_NAME}/.MainActivity"
}

if [[ -z "$BUILD_TOOLS" ]]; then
    echo "Please specify BUILD_TOOLS env variable"
    exit -1
fi

if [[ -z "$PLATFORM" ]]; then
    echo "Please specify PLATFORM env variable"
    exit -1
fi

PACKAGE_DIR="$(echo ${PACKAGE_NAME} | sed 's/\./\//g')"

case $1 in
	init)
		init
		;;
	build)
		build
		;;
	run)
		run
		;;
	build-run)
		build
		run
		;;
	*)
		echo "error: unknown argument"
		;;
esac
