pluginManagement {
    val properties = java.util.Properties()
    file("local.properties").inputStream().use { properties.load(it) }
    val flutterSdkPath = properties.getProperty("flutter.sdk")
        ?: throw GradleException("flutter.sdk not set in local.properties")

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        // Flutter local Maven repo for plugins
        maven { url = uri("$flutterSdkPath/bin/cache/artifacts/engine/android") }
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()

        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
            ?: throw GradleException("flutter.sdk not set in local.properties")

        // Local Flutter engine artifacts
        maven { url = uri("$flutterSdkPath/bin/cache/artifacts/engine/android") }
        // Flutter's bundled Maven repository (needed for embedding libs)
        maven { url = uri("$flutterSdkPath/bin/cache/artifacts/engine") }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

rootProject.name = "camcontrol"
include(":app")
