pluginManagement {
    includeBuild("../node_modules/@react-native/gradle-plugin")
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
        maven {setUrl("https://maven.aliyun.com/repository/jcenter")}
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
        maven {setUrl("https://maven.aliyun.com/repository/jcenter")}
        maven { setUrl("https://jitpack.io") }
    }
}

plugins {
    id("com.facebook.react.settings")
}

configure<com.facebook.react.ReactSettingsExtension> {
    autolinkLibrariesFromCommand()
}

//rootProject.name = "timeprint_rn"
rootProject.name = "com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto"
include(":app")
include(":core") // 確保這個模組被包含在內
includeBuild("../node_modules/@react-native/gradle-plugin")



