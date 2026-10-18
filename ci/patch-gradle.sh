#!/bin/bash
set -e

if [ -f android/build.gradle.kts ]; then
cat >> android/build.gradle.kts << 'KTS'

subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            (ext as com.android.build.gradle.BaseExtension).compileSdkVersion(36)
        }
    }
}
KTS
echo "Patched android/build.gradle.kts"
fi

if [ -f android/build.gradle ]; then
cat >> android/build.gradle << 'GRADLE'

subprojects {
    afterEvaluate { p ->
        if (p.hasProperty('android')) {
            p.android.compileSdkVersion 36
        }
    }
}
GRADLE
echo "Patched android/build.gradle"
fi
