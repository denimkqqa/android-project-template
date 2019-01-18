#!/bin/bash

echo "Downloading platform"
$ANDROID_HOME/tools/bin/sdkmanager "platforms;android-28"

echo "Downloading build tools"
$ANDROID_HOME/tools/bin/sdkmanager "build-tools;28.0.1"

echo "Caching default keystore"
cp debug.keystore $ANDROID_HOME/
