import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.jetbrains.kotlin.konan.properties.Properties
import java.io.FileInputStream
//plugins {
//    id("com.android.application")
//    id("org.jetbrains.kotlin.android")
//    id("com.facebook.react")
//}
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    alias(libs.plugins.kotlinSerialization).apply(false)
    id("com.facebook.react")
    id("kotlin-kapt")
    id("kotlin-parcelize")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("org.jetbrains.kotlin.plugin.noarg") version "1.9.23"
    // 添加 kotlin-kapt 插件
    base
}

/**
 * This is the configuration block to customize your React Native Android app.
 * By default you don't need to apply any configuration, just uncomment the lines you need.
 */
react {
    /* Folders */
    //   The root of your project, i.e. where "package.json" lives. Default is '../..'
    // root = file("../../")
    //   The folder where the react-native NPM package is. Default is ../../node_modules/react-native
    // reactNativeDir = file("../../node_modules/react-native")
    //   The folder where the react-native Codegen package is. Default is ../../node_modules/@react-native/codegen
    // codegenDir = file("../../node_modules/@react-native/codegen")
    //   The cli.js file which is the React Native CLI entrypoint. Default is ../../node_modules/react-native/cli.js
    // cliFile = file("../../node_modules/react-native/cli.js")

    /* Variants */
    //   The list of variants to that are debuggable. For those we're going to
    //   skip the bundling of the JS bundle and the assets. By default is just 'debug'.
    //   If you add flavors like lite, prod, etc. you'll have to list your debuggableVariants.
    // debuggableVariants = ["liteDebug", "prodDebug"]

    /* Bundling */
    //   A list containing the node command and its flags. Default is just 'node'.
    // nodeExecutableAndArgs = ["node"]
    //
    //   The command to run when bundling. By default is 'bundle'
    // bundleCommand = "ram-bundle"
    //
    //   The path to the CLI configuration file. Default is empty.
    // bundleConfig = file(../rn-cli.config.js)
    //
    //   The name of the generated asset file containing your JS bundle
    // bundleAssetName = "MyApplication.android.bundle"
    //
    //   The entry file for bundle generation. Default is 'index.android.js' or 'index.js'
    // entryFile = file("../js/MyApplication.android.js")
    //
    //   A list of extra flags to pass to the 'bundle' commands.
    //   See https://github.com/react-native-community/cli/blob/main/docs/commands.md#bundle
    // extraPackagerArgs = []

    /* Hermes Commands */
    //   The hermes compiler command to run. By default it is 'hermesc'
    // hermesCommand = "$rootDir/my-custom-hermesc/bin/hermesc"
    //
    //   The list of flags to pass to the Hermes compiler. By default is "-O", "-output-source-map"
    // hermesFlags = ["-O", "-output-source-map"]

    /* Autolinking */
    autolinkLibrariesWithApp()
}

/**
 * Set this to true to Run Proguard on Release builds to minify the Java bytecode.
 */
val enableProguardInReleaseBuilds = false

/**
 * The preferred build flavor of JavaScriptCore (JSC)
 *
 * For example, to use the international variant, you can use:
 * `val jscFlavor = "io.github.react-native-community:jsc-android-intl:2026004.+"`
 *
 * The international variant includes ICU i18n library and necessary data
 * allowing to use e.g. `Date.toLocaleString` and `String.localeCompare` that
 * give correct results when using with locales other than en-US. Note that
 * this variant is about 6MiB larger per architecture than default.
 */
val jscFlavor = "io.github.react-native-community:jsc-android:2026004.+"
val keystorePropertiesFile: File = rootProject.file("keystore.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
//noArg {
//    annotation("com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.GenerateNoArg")
//}
base {
    archivesName.set("Timeprint")
}


//android {
//    ndkVersion = rootProject.extra["ndkVersion"] as String
//    buildToolsVersion = rootProject.extra["buildToolsVersion"] as String
//    compileSdk = rootProject.extra["compileSdkVersion"] as Int
//    compileSdkVersion(project.libs.versions.app.build.compileSDKVersion.get().toInt())
//    namespace = libs.versions.namespace.get()
//    defaultConfig {
//        applicationId = libs.versions.app.version.appId.get()
//        minSdk = project.libs.versions.app.build.minimumSDK.get().toInt()
//        targetSdk = project.libs.versions.app.build.targetSDK.get().toInt()
//        versionName = project.libs.versions.app.version.versionName.get()
//        versionCode = project.libs.versions.app.version.versionCode.get().toInt()
//        vectorDrawables.useSupportLibrary = true
//    }
////    defaultConfig {
////        applicationId "com.timeprint_rn"
////        minSdk = rootProject.extra["minSdkVersion"] as Int
////        targetSdk = rootProject.extra["targetSdkVersion"] as Int
////        versionCode 1
////        versionName "1.0"
////    }
//    signingConfigs {
//        if (keystorePropertiesFile.exists()) {
//            register("release") {
//                keyAlias = keystoreProperties.getProperty("keyAlias")
//                keyPassword = keystoreProperties.getProperty("keyPassword")
//                storeFile = file(keystoreProperties.getProperty("storeFile"))
//                storePassword = keystoreProperties.getProperty("storePassword")
//            }
//        }
//    }
////    signingConfigs {
////        debug {
////            storeFile file('debug.keystore')
////            storePassword 'android'
////            keyAlias 'androiddebugkey'
////            keyPassword 'android'
////        }
////    }
//    buildTypes {
//        debug {
//            applicationIdSuffix = ".debug"
//        }
//        release {
//            isMinifyEnabled = true
//            proguardFiles(
//                getDefaultProguardFile("proguard-android-optimize.txt"),
//                "proguard-rules.pro"
//            )
//            if (keystorePropertiesFile.exists()) {
//                signingConfig = signingConfigs.getByName("release")
//            }
//        }
//    }
//
//}
android {

    compileSdkVersion(project.libs.versions.app.build.compileSDKVersion.get().toInt())
    defaultConfig {
        applicationId = libs.versions.app.version.appId.get()
        minSdk = project.libs.versions.app.build.minimumSDK.get().toInt()
        targetSdk = project.libs.versions.app.build.targetSDK.get().toInt()
        versionName = project.libs.versions.app.version.versionName.get()
        versionCode = project.libs.versions.app.version.versionCode.get().toInt()
        vectorDrawables.useSupportLibrary = true
        externalNativeBuild {
            // For ndk-build, instead use the ndkBuild block.
            cmake {
                // Passes optional arguments to CMake.
                arguments += listOf("-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON")
            }
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            register("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildFeatures {
        dataBinding = true
        viewBinding = true
        buildConfig = true
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
//            isMinifyEnabled = true
//            proguardFiles(
//                getDefaultProguardFile("proguard-android-optimize.txt"),
//                "proguard-rules.pro"
//            )
        }
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }

    flavorDimensions.add("variants")
    productFlavors {
       register("core")
        register("fdroid")
        register("prepaid")
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/java")
    }


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility= JavaVersion.VERSION_17
    }


    kotlinOptions {
        jvmTarget = "17"
    }
//    compileOptions {
//        val currentJavaVersionFromLibs = JavaVersion.valueOf(libs.versions.app.build.javaVersion.get().toString())
//        sourceCompatibility = currentJavaVersionFromLibs
//        targetCompatibility = currentJavaVersionFromLibs
//    }
//
//    tasks.withType<KotlinCompile> {
//        kotlinOptions.jvmTarget = project.libs.versions.app.build.kotlinJVMTarget.get()
//    }

    namespace = "com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto"

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

//dependencies {
//    // The version of react-native is set by the React Native Gradle Plugin
//    implementation("com.facebook.react:react-android")
//   if (project.hasProperty("hermesEnabled")) {
//        implementation("com.facebook.react:hermes-android")
//    } else {
//        implementation(jscFlavor)
//    }
//}

dependencies {
    implementation("com.facebook.react:react-android")
//   implementation("org.jetbrains.anko:anko-commons:0.10.8")
    implementation("com.google.android.flexbox:flexbox:3.0.0")
    implementation("androidx.lifecycle:lifecycle-livedata-ktx:2.6.2") // 请使用最新版本
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.2")
    implementation("com.squareup.okhttp3:okhttp:4.11.0")
    implementation("androidx.activity:activity-ktx:1.8.2")
    implementation("org.bitbucket.b_c:jose4j:0.9.3")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("org.slf4j:slf4j-nop:1.7.25") // 或者更新的版本
    implementation("androidx.viewpager2:viewpager2:1.0.0")
    implementation("com.github.bumptech.glide:glide:4.16.0")
    implementation("com.google.android.material:material:1.2.0-alpha01")

    implementation(platform("com.google.firebase:firebase-bom:33.12.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-crashlytics")
    implementation ("com.qcloud.cos:cos-android:5.9.+")
    implementation ("com.google.android.play:review:2.0.2")
    implementation ("com.google.android.play:review-ktx:2.0.2")
    implementation("com.google.android.gms:play-services-maps:19.0.0")
    implementation ("com.google.android.gms:play-services-mlkit-subject-segmentation:16.0.0-beta1")
    implementation("io.reactivex.rxjava3:rxandroid:3.0.2")

//    implementation(libs.simple.tools.commons)
    implementation(libs.kotlinx.serialization.json)
    implementation(libs.bundles.androidx.camera)
    implementation(libs.androidx.documentfile)
    implementation(libs.androidx.exifinterface)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.window)
    implementation(libs.androidx.asynclayoutinflater)

//    implementation(libs.androidx.library)
//    dependencies {
//        implementation(libs.androidx.library) {
//            exclude(group = "androidx.databinding") // 替换为你要排除的具体组
//        }
//        // 其他依赖...
//    }

    implementation(libs.androidx.lifecycle.process)
    implementation(libs.play.services.location)
    implementation(libs.play.services.maps)
    implementation(libs.androidx.appcompat)
    implementation(libs.androidx.navigation.fragment.ktx)
    implementation(libs.androidx.navigation.ui.ktx)
    api(libs.gson)
    if (project.hasProperty("hermesEnabled")) {
        implementation("com.facebook.react:hermes-android")
    } else {
        implementation(jscFlavor)
    }
}