#!/bin/bash

AAPT=$BUILD_TOOLS/aapt2
DX=$BUILD_TOOLS/d8
ZIPALIGN=$BUILD_TOOLS/zipalign
APKSIGNER=$BUILD_TOOLS/apksigner
PACKAGE_NAME="com.example.android.helloworld"

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
	download

	classpath=$PLATFORM
	for i in `ls build/downloads`; do
		echo "processing $i"
		dir=`basename $i .aar`
		mkdir build/libs/$dir
		cp build/downloads/$i build/libs/$dir
		if [ ${i: -4} == ".jar" ] || [ ${i: -6} == ".jar.1" ]; then
			classpath="$classpath:build/libs/$dir/$i"
		else
			unzip build/libs/$dir/$i -d build/libs/$dir/ > /dev/null
			rm build/libs/$dir/$i
			classpath="$classpath:build/libs/$dir/classes.jar"
			$AAPT compile -o build/outputResources build/libs/$dir/res/*/*  2> /dev/null
		fi

	done


	#workaround for merging values (no comand line tools for manual merging)
	./gradlew mergeDebugResources

	echo "Compiling resources"

	$AAPT compile -o build/outputResources build/libs/constraint-layout-1.1.3/res/*/* 
	$AAPT compile -o build/outputResources build/libs/appcompat-v7-27.1.1/res/*/* 
	$AAPT compile -o build/outputResources app/build/intermediates/incremental/mergeDebugResources/merged.dir/*/* #using merged values
	$AAPT compile -o build/outputResources app/src/main/res/*/* 


	ls -d -1 $PWD/build/outputResources/*.* | awk 1 ORS=' ' > build/r_files.txt
	
	echo "Linking resouces..."
	$AAPT link -I\
          $PLATFORM\
          --manifest\
          app/src/main/AndroidManifest.xml\
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
	kotlinc -cp $classpath build/r/com/example/android/helloworld/R.java app/src/main/java/com/example/android/helloworld/MainActivity.kt -d build/classes
	echo "Translating in Dalvik bytecode..."
	$DX build/classes/$PACKAGE_DIR/*.class --output build/out/dex

	echo "Adding classes to resources APK..."
	cp build/out/dex/classes.dex classes.dex
	zip build/out/resources.apk classes.dex
	rm classes.dex

	echo "Aligning and signing APK..."
	$APKSIGNER sign --ks debug.keystore --ks-pass "pass:123456" build/out/resources.apk
	$ZIPALIGN -f 4 build/out/resources.apk build/app.apk
}
PACKAGE_DIR="$(echo ${PACKAGE_NAME} | sed 's/\./\//g')"
build



