#!/bin/bash

AAPT=$BUILD_TOOLS/aapt2
DX=$BUILD_TOOLS/d8
ZIPALIGN=$BUILD_TOOLS/zipalign
APKSIGNER=$BUILD_TOOLS/apksigner
PACKAGE_NAME="com.example.android.helloworld"

root=`dirname $0`

download() {
	
	wget -P build/downloads/ https://maven.google.com/android/arch/lifecycle/viewmodel/1.1.0/viewmodel-1.1.0.aar
	wget -P build/downloads/ https://maven.google.com/com/android/support/support-vector-drawable/27.1.1/support-vector-drawable-27.1.1.aar
	wget -P build/downloads/ https://maven.google.com/com/android/support/support-core-utils/27.1.1/support-core-utils-27.1.1.aar
	wget -P build/downloads/ https://maven.google.com/com/android/support/support-fragment/27.1.1/support-fragment-27.1.1.aar
	wget -P build/downloads/ https://maven.google.com/com/android/support/support-core-ui/27.1.1/support-core-ui-27.1.1.aar
	wget -P build/downloads/ https://maven.google.com/com/android/support/support-compat/27.1.1/support-compat-27.1.1.aar
	wget -P build/downloads/ https://maven.google.com/android/arch/core/runtime/1.1.0/runtime-1.1.0.aar
	wget -P build/downloads/ https://maven.google.com/android/arch/lifecycle/runtime/1.1.0/runtime-1.1.0.aar
	wget -P build/downloads/ https://maven.google.com/android/arch/lifecycle/livedata-core/1.1.0/livedata-core-1.1.0.aar
	wget -P build/downloads/ https://maven.google.com/com/android/support/animated-vector-drawable/27.1.1/animated-vector-drawable-27.1.1.aar
	wget -P build/downloads/ https://maven.google.com/com/android/support/support-annotations/27.1.1/support-annotations-27.1.1.jar
	wget -P build/downloads/ https://maven.google.com/com/android/support/constraint/constraint-layout-solver/1.1.3/constraint-layout-solver-1.1.3.jar
	wget -P build/downloads/ https://maven.google.com/android/arch/lifecycle/common/1.1.0/common-1.1.0.jar
	wget -P build/downloads/ https://maven.google.com/android/arch/core/common/1.1.0/common-1.1.0.jar
	wget -P build/downloads/ https://maven.google.com/com/android/support/constraint/constraint-layout/1.1.3/constraint-layout-1.1.3.aar
	wget -P build/downloads/ https://maven.google.com/com/android/support/appcompat-v7/27.1.1/appcompat-v7-27.1.1.aar
	wget -P build/downloads/ https://maven.google.com/android/arch/lifecycle/extensions/1.1.0/extensions-1.1.0.aar
	# wget -P build/downloads/ http://central.maven.org/maven2/org/jetbrains/kotlin/kotlin-stdlib-jdk7/1.3.11/kotlin-stdlib-jdk7-1.3.11.jar
	# wget -P build/downloads/ http://central.maven.org/maven2/org/jetbrains/kotlin/kotlin-stdlib/1.3.11/kotlin-stdlib-1.3.11.jar
	# wget -P build/downloads/ http://central.maven.org/maven2/org/jetbrains/kotlin/kotlin-stdlib-common/1.3.11/kotlin-stdlib-common-1.3.11.jar

}

link() {
	$AAPT link -I\
          $PLATFORM\
          --manifest\
          $1\
          -o\
          build/out/resources.apk\
          -R\
          @build/r_files.txt\
          --auto-add-overlay\
          --java\
          build/r\
          -0\
          apk\
          --output-text-symbols\
          build/R.txt\
          --no-version-vectors
}

build() {
	rm -rf build/
	mkdir build
	mkdir build/merged
	mkdir build/outputResources
	mkdir build/out
	mkdir build/classes
	mkdir build/out/dex
	mkdir build/libs
	mkdir build/javac
	mkdir build/tmp
	mkdir build/tmp/res
	mkdir build/tmp/r
	mkdir build/tmp/classes
	download

	classpath=$PLATFORM
	for i in `ls build/downloads`; do
		echo "processing $i"
		dir=`basename $i .aar`
		mkdir build/libs/$dir
		cp build/downloads/$i build/libs/$dir
		if [ ${i: -4} == ".jar" ] || [ ${i: -6} == ".jar.1" ]; then
			classpath="$classpath:build/libs/$dir/$i"
			cp "build/libs/$dir/$i" "build/javac/$i.jar"

		else
			unzip build/libs/$dir/$i -d build/libs/$dir/ > /dev/null
			rm build/libs/$dir/$i
			classpath="$classpath:build/libs/$dir/classes.jar"
			cp "build/libs/$dir/classes.jar" "build/javac/$i.jar"
			$AAPT compile -o build/outputResources build/libs/$dir/res/*/*  2> /dev/null
		fi

	done


	echo "Merging values.."
	java -jar $root/ResourcesMerger.jar -libsDir build/libs -appRes app/src/main/res -outputDirectory build/mergedResources

	echo "Compiling resources.."


	$AAPT compile -o build/outputResources build/mergedResources/*/*
	$AAPT compile -o build/outputResources app/src/main/res/*/* 

	ls -d -1 $PWD/build/outputResources/*.* | awk 1 ORS=' ' > build/r_files.txt
	
	echo "Linking resouces..."
 	link build/libs/constraint-layout-1.1.3/AndroidManifest.xml
 	link build/libs/appcompat-v7-27.1.1/AndroidManifest.xml
	link app/src/main/AndroidManifest.xml

	echo "Compiling code..."
	
	kotlinc -cp $classpath build/r/$PACKAGE_DIR/R.java  app/src/main/java/$PACKAGE_DIR/MainActivity.kt -d build/classes
	javac -cp $classpath build/r/$PACKAGE_DIR/R.java build/r/android/support/v7/appcompat/R.java  build/r/android/support/constraint/R.java -d build/classes

	echo "Translating in Dalvik bytecode..."

	$DX build/classes/$PACKAGE_DIR/*.class build/javac/* build/classes/android/support/v7/appcompat/*  build/classes/android/support/constraint/* --output build/out/dex --classpath $PLATFORM --min-api 15 

	echo "Adding classes to resources APK..."
	cp build/out/dex/classes.dex classes.dex
	zip build/out/resources.apk classes.dex
	rm classes.dex

	echo "Aligning and signing APK..."
	$ZIPALIGN -f 4 build/out/resources.apk build/app.apk
	$APKSIGNER sign --ks $ANDROID_HOME/debug.keystore --ks-pass "pass:123456" build/app.apk

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
build
