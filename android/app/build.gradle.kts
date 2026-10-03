import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun releaseKeystoreReady(): Boolean {
    val storePath = keystoreProperties.getProperty("storeFile")
    val store = storePath?.let { rootProject.file(it) }
    return keystorePropertiesFile.exists() &&
        !keystoreProperties.getProperty("keyAlias").isNullOrBlank() &&
        !keystoreProperties.getProperty("keyPassword").isNullOrBlank() &&
        !keystoreProperties.getProperty("storePassword").isNullOrBlank() &&
        store != null &&
        store.isFile
}

android {
    namespace = "com.sid.hollow.hour.com"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.sid.hollow.hour.com"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            if (releaseKeystoreReady()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Never silently sign Play/release artifacts with the debug keystore.
            check(releaseKeystoreReady()) {
                "Release signing is missing. Copy android/key.properties.example to " +
                    "android/key.properties and set storeFile to your .jks " +
                    "(see README Release signing). Debug-key fallback is disabled."
            }
            signingConfig = signingConfigs.getByName("release")
            // Keep AdMob classes if R8 runs; shrinking off avoids known VerifyError crashes.
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

gradle.taskGraph.whenReady {
    val releaseBuild = allTasks.any {
        it.name.contains("Release", ignoreCase = true) &&
            (it.name.startsWith("bundle") ||
                it.name.startsWith("assemble") ||
                it.name.startsWith("package"))
    }
    if (releaseBuild && !keystorePropertiesFile.exists()) {
        throw GradleException(
            "key.properties missing - refusing to build a release with the debug key",
        )
    }
}
