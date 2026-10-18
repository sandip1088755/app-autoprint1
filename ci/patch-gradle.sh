#!/bin/bash
set -e

if [ -f android/build.gradle.kts ]; then
cat >> android/build.gradle.kts << 'KTS'

subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            compileSdk = 36
        }
    }
}
KTS
echo "Patched android/build.gradle.kts"
fi

if [ -f android/build.gradle ]; then
cat >> android/build.gradle << 'GRADLE'

subprojects {
    plugins.withId('com.android.library') {
        android.compileSdkVersion 36
    }
}
GRADLE
echo "Patched android/build.gradle"
fi
