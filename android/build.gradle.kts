val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    repositories {
        google()
        mavenCentral()
        val flutterSdkPath = rootProject.file("local.properties").inputStream().use {
            val props = java.util.Properties()
            props.load(it)
            props.getProperty("flutter.sdk")
        }
        if (flutterSdkPath != null) {
            maven { url = uri("$flutterSdkPath/bin/cache/artifacts/engine/android") }
        }
    }
}

