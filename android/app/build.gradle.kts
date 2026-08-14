import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.clipval"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.clipval"
        minSdk = maxOf(flutter.minSdkVersion, 26)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath =
                System.getenv("ANDROID_KEYSTORE_PATH")
                    ?: keystoreProperties["storeFile"]?.toString()
            val storePassword =
                System.getenv("ANDROID_KEYSTORE_PASSWORD")
                    ?: keystoreProperties["storePassword"]?.toString()
            val keyAliasEnv =
                System.getenv("ANDROID_KEY_ALIAS")
                    ?: keystoreProperties["keyAlias"]?.toString()
            val keyPassword =
                System.getenv("ANDROID_KEY_PASSWORD")
                    ?: keystoreProperties["keyPassword"]?.toString()

            if (
                !storeFilePath.isNullOrBlank() &&
                !storePassword.isNullOrBlank() &&
                !keyAliasEnv.isNullOrBlank() &&
                !keyPassword.isNullOrBlank()
            ) {
                storeFile =
                    if (storeFilePath.startsWith("/")) {
                        file(storeFilePath)
                    } else {
                        rootProject.file(storeFilePath)
                    }
                this.storePassword = storePassword
                this.keyAlias = keyAliasEnv
                this.keyPassword = keyPassword
            }
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.getByName("release")
            signingConfig =
                if (releaseSigning.storeFile != null) {
                    releaseSigning
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }
}

flutter {
    source = "../.."
}
