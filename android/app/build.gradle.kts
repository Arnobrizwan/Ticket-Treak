// File: android/app/build.gradle.kts

import java.util.Properties
import java.io.FileInputStream // Import FileInputStream
import java.io.File // IMPORTANT: Add this import for File class

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android") // Assumes you've updated this to "2.0.0" in settings.gradle.kts
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties from key.properties
val keystoreProperties = Properties()

// --- THIS IS THE CRUCIAL LINE CHANGE ---
// This line now correctly points to key.properties in the Flutter project root.
// project.projectDir is 'android/app'
// .parentFile.parentFile goes up two levels to the Flutter project root ('Ticket-Treak/')
val keystorePropertiesFile = File(project.projectDir.parentFile.parentFile, "key.properties")
// --- END CRUCIAL LINE CHANGE ---


// --- ADDED DEBUGGING PRINTS (Keep these for verification, remove later) ---
println("DEBUG: Looking for key.properties at calculated path: ${keystorePropertiesFile.absolutePath}")
println("DEBUG: key.properties file exists (according to Gradle now): ${keystorePropertiesFile.exists()}")
// --- END DEBUGGING PRINTS ---

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    println("WARNING: key.properties not found at project root. Attempting to use environment variables for signing.")
}

android {
    namespace = "com.example.ticket_trek"
    compileSdk = flutter.compileSdkVersion

    // Force Gradle to use Android NDK r27.0.12077973:
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID
        applicationId = "com.example.ticket_trek"

        // Explicit minimum SDK version
        minSdk = flutter.minSdkVersion

        // These can stay as Flutter-provided values
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Add this signingConfigs block
    signingConfigs {
        create("release") {
            // Priority: key.properties > Environment Variables > Throw Error
            val storeFileProperty = keystoreProperties["storeFile"] as String?
            val storePasswordProperty = keystoreProperties["storePassword"] as String?
            val keyAliasProperty = keystoreProperties["keyAlias"] as String?
            val keyPasswordProperty = keystoreProperties["keyPassword"] as String?

            // Use 'System.getenv' for environment variables
            storeFile = storeFileProperty?.let { file(it) } ?: System.getenv("ANDROID_UPLOAD_STORE_FILE")?.let { file(it) }
            storePassword = storePasswordProperty ?: System.getenv("ANDROID_UPLOAD_STORE_PASSWORD")
            keyAlias = keyAliasProperty ?: System.getenv("ANDROID_UPLOAD_KEY_ALIAS")
            keyPassword = keyPasswordProperty ?: System.getenv("ANDROID_UPLOAD_KEY_PASSWORD")

            // Add robust checks to ensure credentials are set for release builds
            if (storeFile == null || storePassword.isNullOrEmpty() || keyAlias.isNullOrEmpty() || keyPassword.isNullOrEmpty()) {
                throw GradleException("Missing signing configuration for release build. " +
                                      "Ensure 'key.properties' exists in project root or " +
                                      "environment variables (ANDROID_UPLOAD_STORE_FILE, ANDROID_UPLOAD_STORE_PASSWORD, ANDROID_UPLOAD_KEY_ALIAS, ANDROID_UPLOAD_KEY_PASSWORD) are set.")
            }
        }
    }

    buildTypes {
        release {
            // Enable R8 for code shrinking and obfuscation
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")

            // THIS IS THE CRUCIAL CHANGE: Assign the release signing config
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            // The debug build uses default debug signing. No explicit signing config is needed here unless you have a custom debug setup.
            signingConfig = signingConfigs.getByName("debug") // Explicitly specifying debug signing is good practice
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Add any specific Android dependencies here if needed.
}
