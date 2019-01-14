#!/bin/bash

echo "Downloading platform"
$ANDROID_HOME/tools/bin/sdkmanager "platforms;android-28"

echo "Downloading build tools"
$ANDROID_HOME/tools/bin/sdkmanager "build-tools;28.0.1"

echo "Setting vars"
export BUILD_TOOLS="/home/user/android-sdk-linux/build-tools/28.0.1/"
export PLATFORM="/home/user/android-sdk-linux/platforms/android-28/android.jar"
