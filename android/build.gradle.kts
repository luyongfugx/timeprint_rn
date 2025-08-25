// Top-level build file where you can add configuration options common to all sub-projects/modules.
plugins {
    id("com.facebook.react.rootproject") version "1.0.0" apply false
}

buildscript {
    extra.apply {
        set("buildToolsVersion", "35.0.0")
        set("minSdkVersion", 24)
        set("compileSdkVersion", 35)
        set("targetSdkVersion", 35)
        set("ndkVersion", "27.1.12297006")
        set("kotlinVersion", "2.1.20")
    }

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.3.2")
        classpath("com.facebook.react:react-native-gradle-plugin")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.20")
//        classpath("com.google.gms:google-services:4.4.1")
    }
}
