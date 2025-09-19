package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions

//import com.simplemobiletools.commons.views.MyTextView


import android.annotation.SuppressLint
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.view.WindowManager
import android.view.inputmethod.InputMethodManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.ensureBackgroundThread
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.isOnMainThread
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpRateStarsDialog
import java.io.File

fun Activity.onAppLaunched(appId: String) {
    baseConfig.appId = appId

    baseConfig.appRunCount++
    Log.d("Activity","baseConfig.appRunCount ${baseConfig.appRunCount}")
    //应用内购买先不弹出
//    if (baseConfig.appRunCount % 30 == 0 && !isAProApp()) {
//        if (!resources.getBoolean(R.bool.hide_google_relations)) {
//            showDonateOrUpgradeDialog()
//        }
//    }
//    GpRateStarsDialog(this).show()
   //每打开次弹出一次，如果没有点评过的话
    if (baseConfig.appRunCount % 33 == 0 && !baseConfig.wasAppRated) {
        if (!resources.getBoolean(R.bool.hide_google_relations)) {
           GpRateStarsDialog(this).show()
        }
    }
}

fun Activity.checkUpdateNewVersion(){

}
// avoid calling this multiple times in row, it can delete whole folder contents
fun Context.rescanPaths(paths: List<String>, callback: (() -> Unit)? = null) {
    if (paths.isEmpty()) {
        callback?.invoke()
        return
    }

    for (path in paths) {
        Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE).apply {
            data = Uri.fromFile(File(path))
            sendBroadcast(this)
        }
    }

    var cnt = paths.size
    MediaScannerConnection.scanFile(applicationContext, paths.toTypedArray(), null) { s, uri ->
        if (--cnt == 0) {
            callback?.invoke()
        }
    }
}
fun Activity.rescanPaths(paths: List<String>, callback: (() -> Unit)? = null) {
    applicationContext.rescanPaths(paths, callback)
}


fun Activity.launchViewIntent(url: String) {
    hideKeyboard()
    ensureBackgroundThread {
        Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
            try {
                startActivity(this)
            } catch (e: ActivityNotFoundException) {
                toast(e.toString())
            } catch (e: Exception) {
                toast(e.toString())
            }
        }
    }
}
fun Activity.getSession(): String? {
    var namespace = "supabase"
    val prefs = getSharedPreferences(namespace, Context.MODE_PRIVATE)
    val sessionJson = prefs.getString("session", null)
    return sessionJson
}
fun Activity.getTeamInfo(): String? {
    var namespace = "supabase"
    val prefs = getSharedPreferences(namespace, Context.MODE_PRIVATE)
    val teamInfo = prefs.getString("teamInfo", null)
    return teamInfo
}

fun Activity.doToast(content: String) {
    toast(content)
}

//fun GpBaseSimpleActivity.isShowingSAFDialog(path: String): Boolean {
//    return if ((!isRPlus() && isPathOnSD(path) && !isSDCardSetAsDefaultStorage() && (baseConfig.sdTreeUri.isEmpty() || !hasProperStoredTreeUri(false)))) {
//        runOnUiThread {
//            if (!isDestroyed && !isFinishing) {
//                WritePermissionDialog(this, WritePermissionDialogMode.SdCard) {
//                    Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
//                        putExtra(EXTRA_SHOW_ADVANCED, true)
//                        try {
//                            startActivityForResult(this, OPEN_DOCUMENT_TREE_SD)
//                            checkedDocumentPath = path
//                            return@apply
//                        } catch (e: Exception) {
//                            type = "*/*"
//                        }
//
//                        try {
//                            startActivityForResult(this, OPEN_DOCUMENT_TREE_SD)
//                            checkedDocumentPath = path
//                        } catch (e: ActivityNotFoundException) {
//                            toast(R.string.system_service_disabled, Toast.LENGTH_LONG)
//                        } catch (e: Exception) {
//                            toast(R.string.unknown_error_occurred)
//                        }
//                    }
//                }
//            }
//        }
//        true
//    } else {
//        false
//    }
//}
//
//@SuppressLint("InlinedApi")
//fun GpBaseSimpleActivity.isShowingSAFDialogSdk30(path: String): Boolean {
//    return if (isAccessibleWithSAFSdk30(path) && !hasProperStoredFirstParentUri(path)) {
//        runOnUiThread {
//            if (!isDestroyed && !isFinishing) {
//                val level = getFirstParentLevel(path)
//                WritePermissionDialog(this, WritePermissionDialogMode.OpenDocumentTreeSDK30(path.getFirstParentPath(this, level))) {
//                    Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
//                        putExtra(EXTRA_SHOW_ADVANCED, true)
//                        putExtra(DocumentsContract.EXTRA_INITIAL_URI, createFirstParentTreeUriUsingRootTree(path))
//                        try {
//                            startActivityForResult(this, OPEN_DOCUMENT_TREE_FOR_SDK_30)
//                            checkedDocumentPath = path
//                            return@apply
//                        } catch (e: Exception) {
//                            type = "*/*"
//                        }
//
//                        try {
//                            startActivityForResult(this, OPEN_DOCUMENT_TREE_FOR_SDK_30)
//                            checkedDocumentPath = path
//                        } catch (e: ActivityNotFoundException) {
//                            toast(R.string.system_service_disabled, Toast.LENGTH_LONG)
//                        } catch (e: Exception) {
//                            toast(R.string.unknown_error_occurred)
//                        }
//                    }
//                }
//            }
//        }
//        true
//    } else {
//        false
//    }
//}
//
//@SuppressLint("InlinedApi")
//fun GpBaseSimpleActivity.isShowingSAFCreateDocumentDialogSdk30(path: String): Boolean {
//    return if (!hasProperStoredDocumentUriSdk30(path)) {
//        runOnUiThread {
//            if (!isDestroyed && !isFinishing) {
//                WritePermissionDialog(this, WritePermissionDialogMode.CreateDocumentSDK30) {
//                    Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
//                        type = DocumentsContract.Document.MIME_TYPE_DIR
//                        putExtra(EXTRA_SHOW_ADVANCED, true)
//                        addCategory(Intent.CATEGORY_OPENABLE)
//                        putExtra(DocumentsContract.EXTRA_INITIAL_URI, buildDocumentUriSdk30(path.getParentPath()))
//                        putExtra(Intent.EXTRA_TITLE, path.getFilenameFromPath())
//                        try {
//                            startActivityForResult(this, CREATE_DOCUMENT_SDK_30)
//                            checkedDocumentPath = path
//                            return@apply
//                        } catch (e: Exception) {
//                            type = "*/*"
//                        }
//
//                        try {
//                            startActivityForResult(this, CREATE_DOCUMENT_SDK_30)
//                            checkedDocumentPath = path
//                        } catch (e: ActivityNotFoundException) {
//                            toast(R.string.system_service_disabled, Toast.LENGTH_LONG)
//                        } catch (e: Exception) {
//                            toast(R.string.unknown_error_occurred)
//                        }
//                    }
//                }
//            }
//        }
//        true
//    } else {
//        false
//    }
//}
//
//fun GpBaseSimpleActivity.isShowingAndroidSAFDialog(path: String): Boolean {
//    return if (isRestrictedSAFOnlyRoot(path) && (getAndroidTreeUri(path).isEmpty() || !hasProperStoredAndroidTreeUri(path))) {
//        runOnUiThread {
//            if (!isDestroyed && !isFinishing) {
//                ConfirmationAdvancedDialog(this, "", R.string.confirm_storage_access_android_text, R.string.ok, R.string.cancel) { success ->
//                    if (success) {
//                        Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
//                            putExtra(EXTRA_SHOW_ADVANCED, true)
//                            putExtra(DocumentsContract.EXTRA_INITIAL_URI, createAndroidDataOrObbUri(path))
//                            try {
//                                startActivityForResult(this, OPEN_DOCUMENT_TREE_FOR_ANDROID_DATA_OR_OBB)
//                                checkedDocumentPath = path
//                                return@apply
//                            } catch (e: Exception) {
//                                type = "*/*"
//                            }
//
//                            try {
//                                startActivityForResult(this, OPEN_DOCUMENT_TREE_FOR_ANDROID_DATA_OR_OBB)
//                                checkedDocumentPath = path
//                            } catch (e: ActivityNotFoundException) {
//                                toast(R.string.system_service_disabled, Toast.LENGTH_LONG)
//                            } catch (e: Exception) {
//                                toast(R.string.unknown_error_occurred)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        true
//    } else {
//        false
//    }
//}
//
//fun GpBaseSimpleActivity.isShowingOTGDialog(path: String): Boolean {
//    return if (!isRPlus() && isPathOnOTG(path) && (baseConfig.OTGTreeUri.isEmpty() || !hasProperStoredTreeUri(true))) {
//        showOTGPermissionDialog(path)
//        true
//    } else {
//        false
//    }
//}
//
//fun GpBaseSimpleActivity.showOTGPermissionDialog(path: String) {
//    runOnUiThread {
//        if (!isDestroyed && !isFinishing) {
//            WritePermissionDialog(this, WritePermissionDialogMode.Otg) {
//                Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
//                    try {
//                        startActivityForResult(this, OPEN_DOCUMENT_TREE_OTG)
//                        checkedDocumentPath = path
//                        return@apply
//                    } catch (e: Exception) {
//                        type = "*/*"
//                    }
//
//                    try {
//                        startActivityForResult(this, OPEN_DOCUMENT_TREE_OTG)
//                        checkedDocumentPath = path
//                    } catch (e: ActivityNotFoundException) {
//                        toast(R.string.system_service_disabled, Toast.LENGTH_LONG)
//                    } catch (e: Exception) {
//                        toast(R.string.unknown_error_occurred)
//                    }
//                }
//            }
//        }
//    }
//}

fun Activity.redirectToRateUs() {
    hideKeyboard()
    try {
        launchViewIntent("market://details?id=${packageName.removeSuffix(".debug")}")
    } catch (ignored: ActivityNotFoundException) {
        launchViewIntent("market://details?id=${baseConfig.appId.removeSuffix(".debug")}")
    }
}


























fun Activity.hideKeyboard() {
    if (isOnMainThread()) {
        hideKeyboardSync()
    } else {
        Handler(Looper.getMainLooper()).post {
            hideKeyboardSync()
        }
    }
}

fun Activity.hideKeyboardSync() {
    val inputMethodManager = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
    inputMethodManager.hideSoftInputFromWindow((currentFocus ?: View(this)).windowToken, 0)
    window!!.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_HIDDEN)
    currentFocus?.clearFocus()
}



//fun Activity.performSecurityCheck(
//    protectionType: Int,
//    requiredHash: String,
//    successCallback: ((String, Int) -> Unit)? = null,
//    failureCallback: (() -> Unit)? = null
//) {
//    if (protectionType == PROTECTION_FINGERPRINT && com.simplemobiletools.commons.helpers.isRPlus()) {
//        showBiometricPrompt(successCallback, failureCallback)
//    } else {
//        SecurityDialog(
//            activity = this,
//            requiredHash = requiredHash,
//            showTabIndex = protectionType,
//            callback = { hash, type, success ->
//                if (success) {
//                    successCallback?.invoke(hash, type)
//                } else {
//                    failureCallback?.invoke()
//                }
//            }
//        )
//    }
//}


