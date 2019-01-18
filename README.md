In order to use this script following actions required:
- Download build-tools (ie 28.0.1) and android source code (ie android-28)
- Specify environment varibles with path of build tools(export BUILD_TOOLS="path/to/build/tools/") and platform source code (export PLATFORM="path/to/android.jar")
- Generate initial project, example: bash build.sh init test
- build project, example: bash build.sh build test

In order to reproduce it with docker (probably easiest way) following steps are required (copy-paste):
```
docker run -it --user root  thedrhax/android-sdk bash

git clone https://github.com/denimkqqa/android-project-template 
cd android-project-template

./init_defaults.sh

source "/root/.sdkman/bin/sdkman-init.sh"
export BUILD_TOOLS="/home/user/android-sdk-linux/build-tools/28.0.1/"
export PLATFORM="/home/user/android-sdk-linux/platforms/android-28/android.jar"

alias build_apk=$PWD/build.sh 
unzip HelloWorld -d /home/user/
cd /home/user/HelloWorld

build_apk
```

In order to copy apk from docker (if needed) following commands should be executed from another shell window:
```
$ docker ps  # in results there will be container_id in first colum
$ docker docker cp container_id:/home/user/android-project-template/build/app.apk ~/Downloads/
```
