pluginManagement {
    includeBuild("../node_modules/@react-native/gradle-plugin")
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
includeBuild("../node_modules/@react-native/gradle-plugin")
