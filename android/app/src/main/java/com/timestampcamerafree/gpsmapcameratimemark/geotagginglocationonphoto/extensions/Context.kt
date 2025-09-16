package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions

import android.Manifest
import android.app.Activity
import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.database.Cursor
import android.graphics.Point
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.BaseColumns
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.provider.MediaStore.Audio
import android.provider.MediaStore.Files
import android.provider.MediaStore.Images
import android.provider.MediaStore.Video
import android.provider.Settings
import android.text.TextUtils
import android.view.WindowManager
import android.widget.Toast
import androidx.annotation.ChecksSdkIntAtLeast
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import androidx.core.os.bundleOf
import androidx.documentfile.provider.DocumentFile
import androidx.exifinterface.media.ExifInterface


import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.Config
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.*
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.isOnMainThread
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream
import java.text.SimpleDateFormat
import java.util.Collections
import java.util.Date
import java.util.HashSet
import java.util.Locale
import java.util.regex.Pattern

private val physicalPaths = arrayListOf(
    "/storage/sdcard1", // Motorola Xoom
    "/storage/extsdcard", // Samsung SGS3
    "/storage/sdcard0/external_sdcard", // User request
    "/mnt/extsdcard", "/mnt/sdcard/external_sd", // Samsung galaxy family
    "/mnt/external_sd", "/mnt/media_rw/sdcard1", // 4.4.2 on CyanogenMod S3
    "/removable/microsd", // Asus transformer prime
    "/mnt/emmc", "/storage/external_SD", // LG
    "/storage/ext_sd", // HTC One Max
    "/storage/removable/sdcard1", // Sony Xperia Z1
    "/data/sdext", "/data/sdext2", "/data/sdext3", "/data/sdext4", "/sdcard1", // Sony Xperia Z
    "/sdcard2", // HTC One M8s
    "/storage/usbdisk0",
    "/storage/usbdisk1",
    "/storage/usbdisk2"
)
fun Context.getSharedPrefs() = getSharedPreferences(PREFS_KEY, Context.MODE_PRIVATE)
private fun isDownloadsDocument(uri: Uri) = uri.authority == "com.android.providers.downloads.documents"
private fun isMediaDocument(uri: Uri) = uri.authority == "com.android.providers.media.documents"

val Context.otgPath: String get() = baseConfig.OTGPath
//val Context.internalStoragePath: String get() = baseConfig.internalStoragePath
private fun isExternalStorageDocument(uri: Uri) = uri.authority == "com.android.externalstorage.documents"

fun String.areDigitsOnly() = matches(Regex("[0-9]+"))
fun Context.getDataColumn(uri: Uri, selection: String? = null, selectionArgs: Array<String>? = null): String? {
    try {
        val projection = arrayOf(Files.FileColumns.DATA)
        val cursor = contentResolver.query(uri, projection, selection, selectionArgs, null)
        cursor?.use {
            if (cursor.moveToFirst()) {
                val data = cursor.getStringValue(Files.FileColumns.DATA)
                if (data != "null") {
                    return data
                }
            }
        }
    } catch (e: Exception) {
    }
    return null
}
fun Context.getRealPathFromURI(uri: Uri): String? {
    if (uri.scheme == "file") {
        return uri.path
    }

    if (isDownloadsDocument(uri)) {
        val id = DocumentsContract.getDocumentId(uri)
        if (id.areDigitsOnly()) {
            val newUri = ContentUris.withAppendedId(Uri.parse("content://downloads/public_downloads"), id.toLong())
            val path = getDataColumn(newUri)
            if (path != null) {
                return path
            }
        }
    } else if (isExternalStorageDocument(uri)) {
        val documentId = DocumentsContract.getDocumentId(uri)
        val parts = documentId.split(":")
        if (parts[0].equals("primary", true)) {
            return "${Environment.getExternalStorageDirectory().absolutePath}/${parts[1]}"
        }
    } else if (isMediaDocument(uri)) {
        val documentId = DocumentsContract.getDocumentId(uri)
        val split = documentId.split(":").dropLastWhile { it.isEmpty() }.toTypedArray()
        val type = split[0]

        val contentUri = when (type) {
            "video" -> Video.Media.EXTERNAL_CONTENT_URI
            "audio" -> Audio.Media.EXTERNAL_CONTENT_URI
            else -> Images.Media.EXTERNAL_CONTENT_URI
        }

        val selection = "_id=?"
        val selectionArgs = arrayOf(split[1])
        val path = getDataColumn(contentUri, selection, selectionArgs)
        if (path != null) {
            return path
        }
    }

    return getDataColumn(uri)
}


val Context.baseConfig: BaseConfig get() = BaseConfig.newInstance(this)
val Context.sdCardPath: String get() = baseConfig.sdCardPath
fun Context.getInternalStoragePath() =
    if (File("/storage/emulated/0").exists()) "/storage/emulated/0" else Environment.getExternalStorageDirectory().absolutePath.trimEnd('/')
fun Context.getStorageDirectories(): Array<String> {
    val paths = HashSet<String>()
    val rawExternalStorage = System.getenv("EXTERNAL_STORAGE")
    val rawSecondaryStoragesStr = System.getenv("SECONDARY_STORAGE")
    val rawEmulatedStorageTarget = System.getenv("EMULATED_STORAGE_TARGET")
    if (TextUtils.isEmpty(rawEmulatedStorageTarget)) {
        getExternalFilesDirs(null).filterNotNull().map { it.absolutePath }
            .mapTo(paths) { it.substring(0, it.indexOf("Android/data")) }
    } else {
        val path = Environment.getExternalStorageDirectory().absolutePath
        val folders = Pattern.compile("/").split(path)
        val lastFolder = folders[folders.size - 1]
        var isDigit = false
        try {
            Integer.valueOf(lastFolder)
            isDigit = true
        } catch (ignored: NumberFormatException) {
        }

        val rawUserId = if (isDigit) lastFolder else ""
        if (TextUtils.isEmpty(rawUserId)) {
            paths.add(rawEmulatedStorageTarget!!)
        } else {
            paths.add(rawEmulatedStorageTarget + File.separator + rawUserId)
        }
    }

    if (!TextUtils.isEmpty(rawSecondaryStoragesStr)) {
        val rawSecondaryStorages = rawSecondaryStoragesStr!!.split(File.pathSeparator.toRegex()).dropLastWhile(String::isEmpty).toTypedArray()
        Collections.addAll(paths, *rawSecondaryStorages)
    }
    return paths.map { it.trimEnd('/') }.toTypedArray()
}

fun Context.getSDCardPath(): String {
    val directories = getStorageDirectories().filter {
        !it.equals(getInternalStoragePath()) && !it.equals(
            "/storage/emulated/0",
            true
        ) && (baseConfig.OTGPartition.isEmpty() || !it.endsWith(baseConfig.OTGPartition))
    }

    val fullSDpattern = Pattern.compile(SD_OTG_PATTERN)
    var sdCardPath = directories.firstOrNull { fullSDpattern.matcher(it).matches() }
        ?: directories.firstOrNull { !physicalPaths.contains(it.lowercase(Locale.getDefault())) } ?: ""

    // on some devices no method retrieved any SD card path, so test if its not sdcard1 by any chance. It happened on an Android 5.1
    if (sdCardPath.trimEnd('/').isEmpty()) {
        val file = File("/storage/sdcard1")
        if (file.exists()) {
            return file.absolutePath
        }

        sdCardPath = directories.firstOrNull() ?: ""
    }

    if (sdCardPath.isEmpty()) {
        val SDpattern = Pattern.compile(SD_OTG_SHORT)
        try {
            File("/storage").listFiles()?.forEach {
                if (SDpattern.matcher(it.name).matches()) {
                    sdCardPath = "/storage/${it.name}"
                }
            }
        } catch (e: Exception) {
        }
    }

    val finalPath = sdCardPath.trimEnd('/')
    baseConfig.sdCardPath = finalPath
    return finalPath
}

fun Context.hasExternalSDCard() = sdCardPath.isNotEmpty()

fun Context.hasOTGConnected(): Boolean {
    return try {
        (getSystemService(Context.USB_SERVICE) as UsbManager).deviceList.any {
            it.value.getInterface(0).interfaceClass == UsbConstants.USB_CLASS_MASS_STORAGE
        }
    } catch (e: Exception) {
        false
    }
}

val Context.windowManager: WindowManager get() = getSystemService(Context.WINDOW_SERVICE) as WindowManager
val Context.usableScreenSize: Point
    get() {
        val size = Point()
        windowManager.defaultDisplay.getSize(size)
        return size
    }

val Context.realScreenSize: Point
    get() {
        val size = Point()
        windowManager.defaultDisplay.getRealSize(size)
        return size
    }
fun Context.isPathOnSD(path: String) = sdCardPath.isNotEmpty() && path.startsWith(sdCardPath)
fun Context.isSDCardSetAsDefaultStorage() = sdCardPath.isNotEmpty() && Environment.getExternalStorageDirectory().absolutePath.equals(sdCardPath, true)
fun Context.hasProperStoredTreeUri(isOTG: Boolean): Boolean {
    val uri = if (isOTG) baseConfig.OTGTreeUri else baseConfig.sdTreeUri
    val hasProperUri = contentResolver.persistedUriPermissions.any { it.uri.toString() == uri }
    if (!hasProperUri) {
        if (isOTG) {
            baseConfig.OTGTreeUri = ""
        } else {
            baseConfig.sdTreeUri = ""
        }
    }
    return hasProperUri
}
fun Context.canManageMedia(): Boolean {
    return isSPlus() && MediaStore.canManageMedia(this)
}
val Context.config: Config get() = Config.newInstance(applicationContext)
val Context.portrait get() = resources.configuration.orientation == Configuration.ORIENTATION_PORTRAIT
val Context.navigationBarOnSide: Boolean get() = usableScreenSize.x < realScreenSize.x && usableScreenSize.x > usableScreenSize.y
val Context.navigationBarOnBottom: Boolean get() = usableScreenSize.y < realScreenSize.y
val Context.navigationBarHeight: Int get() = if (navigationBarOnBottom && navigationBarSize.y != usableScreenSize.y) navigationBarSize.y else 0
val Context.navigationBarWidth: Int get() = if (navigationBarOnSide) navigationBarSize.x else 0
fun Context.openDeviceSettings() {
    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
        data = Uri.fromParts("package", packageName, null)
    }

    try {
        startActivity(intent)
    } catch (e: Exception) {
        showErrorToast(e)
    }
}
val Context.navigationBarSize: Point
    get() = when {
        navigationBarOnSide -> Point(newNavigationBarHeight, usableScreenSize.y)
        navigationBarOnBottom -> Point(usableScreenSize.x, newNavigationBarHeight)
        else -> Point()
    }

val Context.newNavigationBarHeight: Int
    get() {
        var navigationBarHeight = 0
        val resourceId = resources.getIdentifier("navigation_bar_height", "dimen", "android")
        if (resourceId > 0) {
            navigationBarHeight = resources.getDimensionPixelSize(resourceId)
        }
        return navigationBarHeight
    }
fun Context.getOutputMediaFilePath(isPhoto: Boolean): String {
    val mediaStorageDir = File(config.savePhotosFolder)

    if (!mediaStorageDir.exists()) {
        if (!mediaStorageDir.mkdirs()) {
            return ""
        }
    }

    val mediaName = getRandomMediaName(isPhoto)
    return if (isPhoto) {
        "${mediaStorageDir.path}/$mediaName.jpg"
    } else {
        "${mediaStorageDir.path}/$mediaName.mp4"
    }
}
fun Context.getOutputMediaFileName(isPhoto: Boolean): String {
    val mediaName = getRandomMediaName(isPhoto)
    return if (isPhoto) {
        "$mediaName.jpg"
    } else {
        "$mediaName.mp4"
    }
}

fun Context.getFileOutputStreamSync(path: String, mimeType: String, parentDocumentFile: DocumentFile? = null): OutputStream? {
    val targetFile = File(path)
    return createCasualFileOutputStream(targetFile)
}
private fun Context.createCasualFileOutputStream(targetFile: File): OutputStream? {
    if (targetFile.parentFile?.exists() == false) {
        targetFile.parentFile?.mkdirs()
    }

    return try {
        FileOutputStream(targetFile)
    } catch (e: Exception) {
        showErrorToast(e)
        null
    }
}

fun Context.hasPermission(permId: Int) = ContextCompat.checkSelfPermission(this, getPermissionString(permId)) == PackageManager.PERMISSION_GRANTED
private fun Context.queryCursorDesc(
    uri: Uri,
    projection: Array<String>,
    sortColumn: String,
    limit: Int,
): Cursor? {
    return if (isRPlus()) {
        val queryArgs = bundleOf(
            ContentResolver.QUERY_ARG_LIMIT to limit,
            ContentResolver.QUERY_ARG_SORT_DIRECTION to ContentResolver.QUERY_SORT_DIRECTION_DESCENDING,
            ContentResolver.QUERY_ARG_SORT_COLUMNS to arrayOf(sortColumn),
        )
        contentResolver.query(uri, projection, queryArgs, null)
    } else {
        val sortOrder = "$sortColumn DESC LIMIT $limit"
        contentResolver.query(uri, projection, null, null, sortOrder)
    }
}
fun Context.getLatestMediaId(uri: Uri = Files.getContentUri("external")): Long {
    val projection = arrayOf(
        BaseColumns._ID
    )
    try {
        val cursor = queryCursorDesc(uri, projection, BaseColumns._ID, 1)
        cursor?.use {
            if (cursor.moveToFirst()) {
                return cursor.getLongValue(BaseColumns._ID)
            }
        }
    } catch (ignored: Exception) {
        
    }
    return 0
}


fun getRandomMediaName(isPhoto: Boolean): String {
    val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
    return if (isPhoto) {
        "IMG_$timestamp"
    } else {
        "VID_$timestamp"
    }
}
@ChecksSdkIntAtLeast(api = Build.VERSION_CODES.P)
fun isPiePlus() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P

@ChecksSdkIntAtLeast(api = Build.VERSION_CODES.Q)
fun isQPlus() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

@ChecksSdkIntAtLeast(api = Build.VERSION_CODES.R)
fun isRPlus() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R

@ChecksSdkIntAtLeast(api = Build.VERSION_CODES.S)
fun isSPlus() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S

@ChecksSdkIntAtLeast(api = Build.VERSION_CODES.TIRAMISU)
fun isTiramisuPlus() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU

@ChecksSdkIntAtLeast(api = Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
fun isUpsideDownCakePlus() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE

fun Context.checkLocationPermission(): Boolean {
    return hasPermission(PERMISSION_ACCESS_FINE_LOCATION) || hasPermission(PERMISSION_ACCESS_COARSE_LOCATION)
}

val Context.areSystemAnimationsEnabled: Boolean get() = Settings.Global.getFloat(contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 0f) > 0f

fun Context.toast(id: Int, length: Int = Toast.LENGTH_SHORT) {
    toast(getString(id), length)
}

fun Context.toast(msg: String, length: Int = Toast.LENGTH_SHORT) {
    try {
        if (isOnMainThread()) {
            doToast(this, msg, length)
        } else {
            Handler(Looper.getMainLooper()).post {
                doToast(this, msg, length)
            }
        }
    } catch (e: Exception) {
    }
}

private fun doToast(context: Context, message: String, length: Int) {
    if (context is Activity) {
        if (!context.isFinishing && !context.isDestroyed) {
            Toast.makeText(context, message, length).show()
        }
    } else {
        Toast.makeText(context, message, length).show()
    }
}

fun Context.showErrorToast(msg: String, length: Int = Toast.LENGTH_LONG) {
    toast(msg, length)
}
fun Context.getFastDocumentFile(path: String): DocumentFile? {


    if (baseConfig.sdCardPath.isEmpty()) {
        return null
    }

    val relativePath = Uri.encode(path.substring(baseConfig.sdCardPath.length).trim('/'))
    val externalPathPart = baseConfig.sdCardPath.split("/").lastOrNull(String::isNotEmpty)?.trim('/') ?: return null
    val fullUri = "${baseConfig.sdTreeUri}/document/$externalPathPart%3A$relativePath"
    return DocumentFile.fromSingleUri(this, Uri.parse(fullUri))
}
fun Context.isPathOnOTG(path: String) = otgPath.isNotEmpty() && path.startsWith(otgPath)

fun Context.getDocumentFile(path: String): DocumentFile? {
    val isOTG = isPathOnOTG(path)
    var relativePath = path.substring(if (isOTG) otgPath.length else sdCardPath.length)
    if (relativePath.startsWith(File.separator)) {
        relativePath = relativePath.substring(1)
    }

    return try {
        val treeUri = Uri.parse(if (isOTG) baseConfig.OTGTreeUri else baseConfig.sdTreeUri)
        var document = DocumentFile.fromTreeUri(applicationContext, treeUri)
        val parts = relativePath.split("/").filter { it.isNotEmpty() }
        for (part in parts) {
            document = document?.findFile(part)
        }
        document
    } catch (ignored: Exception) {
        null
    }
}
fun Context.needsStupidWritePermissions(path: String) = !isRPlus() && (isPathOnSD(path) || isPathOnOTG(path)) && !isSDCardSetAsDefaultStorage()
fun Context.saveExifRotation(exif: ExifInterface, degrees: Int) {
    val orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
    val orientationDegrees = (orientation.degreesFromOrientation() + degrees) % 360
    exif.setAttribute(ExifInterface.TAG_ORIENTATION, orientationDegrees.orientationFromDegrees())
    exif.saveAttributes()
}

fun Context.getSomeDocumentFile(path: String) = getFastDocumentFile(path) ?: getDocumentFile(path)

@RequiresApi(Build.VERSION_CODES.N)
fun Context.saveImageRotation(path: String, degrees: Int): Boolean {
    if (!needsStupidWritePermissions(path)) {
        saveExifRotation(ExifInterface(path), degrees)
        return true
    } else if (isNougatPlus()) {
        val documentFile = getSomeDocumentFile(path)
        if (documentFile != null) {
            val parcelFileDescriptor = contentResolver.openFileDescriptor(documentFile.uri, "rw")
            val fileDescriptor = parcelFileDescriptor!!.fileDescriptor
            saveExifRotation(ExifInterface(fileDescriptor), degrees)
            return true
        }
    }
    return false
}

fun Context.showErrorToast(exception: Exception, length: Int = Toast.LENGTH_LONG) {
    showErrorToast(exception.toString(), length)
}

fun Context.hasAllPermissions(permIds: Collection<Int>) = permIds.all(this::hasPermission)

fun Context.getPermissionString(id: Int) = when (id) {
    PERMISSION_READ_STORAGE -> Manifest.permission.READ_EXTERNAL_STORAGE
    PERMISSION_WRITE_STORAGE -> Manifest.permission.WRITE_EXTERNAL_STORAGE
    PERMISSION_CAMERA -> Manifest.permission.CAMERA
    PERMISSION_RECORD_AUDIO -> Manifest.permission.RECORD_AUDIO
    PERMISSION_READ_CONTACTS -> Manifest.permission.READ_CONTACTS
    PERMISSION_WRITE_CONTACTS -> Manifest.permission.WRITE_CONTACTS
    PERMISSION_READ_CALENDAR -> Manifest.permission.READ_CALENDAR
    PERMISSION_WRITE_CALENDAR -> Manifest.permission.WRITE_CALENDAR
    PERMISSION_CALL_PHONE -> Manifest.permission.CALL_PHONE
    PERMISSION_READ_CALL_LOG -> Manifest.permission.READ_CALL_LOG
    PERMISSION_WRITE_CALL_LOG -> Manifest.permission.WRITE_CALL_LOG
    PERMISSION_GET_ACCOUNTS -> Manifest.permission.GET_ACCOUNTS
    PERMISSION_READ_SMS -> Manifest.permission.READ_SMS
    PERMISSION_SEND_SMS -> Manifest.permission.SEND_SMS
    PERMISSION_READ_PHONE_STATE -> Manifest.permission.READ_PHONE_STATE
    PERMISSION_MEDIA_LOCATION -> if (isQPlus()) Manifest.permission.ACCESS_MEDIA_LOCATION else ""
    PERMISSION_POST_NOTIFICATIONS -> Manifest.permission.POST_NOTIFICATIONS
    PERMISSION_READ_MEDIA_IMAGES -> Manifest.permission.READ_MEDIA_IMAGES
    PERMISSION_READ_MEDIA_VIDEO -> Manifest.permission.READ_MEDIA_VIDEO
    PERMISSION_READ_MEDIA_AUDIO -> Manifest.permission.READ_MEDIA_AUDIO
    PERMISSION_READ_MEDIA_VISUAL_USER_SELECTED -> Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED
    PERMISSION_ACCESS_COARSE_LOCATION -> Manifest.permission.ACCESS_COARSE_LOCATION
    PERMISSION_ACCESS_FINE_LOCATION -> Manifest.permission.ACCESS_FINE_LOCATION
    PERMISSION_READ_MEDIA_VISUAL_USER_SELECTED -> Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED
    else -> ""
}