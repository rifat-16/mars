// Fix for AGP AndroidLocationsException when both ANDROID_PREFS_ROOT and ANDROID_USER_HOME are set in environment
@Suppress("UNCHECKED_CAST")
run {
    try {
        val peClass = Class.forName("java.lang.ProcessEnvironment")
        val envField = peClass.getDeclaredField("theEnvironment").apply { isAccessible = true }
        val env = envField.get(null) as? MutableMap<Any, Any>
        env?.keys?.firstOrNull { it.toString() == "ANDROID_PREFS_ROOT" }?.let { env.remove(it) }

        val unmodField = peClass.getDeclaredField("theUnmodifiableEnvironment").apply { isAccessible = true }
        val unmodEnv = unmodField.get(null) as? MutableMap<Any, Any>
        unmodEnv?.keys?.firstOrNull { it.toString() == "ANDROID_PREFS_ROOT" }?.let { unmodEnv.remove(it) }
    } catch (_: Exception) {}
}

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.3.10") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
