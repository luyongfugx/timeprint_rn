package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions


import android.annotation.SuppressLint
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import android.util.Log
import android.widget.Toast
import androidx.annotation.RequiresApi
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity.Companion.TAG
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.PERMISSION_READ_MEDIA_IMAGES
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.PERMISSION_READ_MEDIA_VIDEO
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.PERMISSION_READ_MEDIA_VISUAL_USER_SELECTED
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.PERMISSION_WRITE_STORAGE

abstract class GpBaseSimpleActivity : AppCompatActivity() {

    private val GENERIC_PERM_HANDLER = 100
    var actionOnPermission: ((granted: Boolean) -> Unit)? = null
    var isAskingPermissions = false
    companion object {
        var funAfterSAFPermission: ((success: Boolean) -> Unit)? = null
        var funAfterSdk30Action: ((success: Boolean) -> Unit)? = null
        var funAfterUpdate30File: ((success: Boolean) -> Unit)? = null
        var funAfterTrash30File: ((success: Boolean) -> Unit)? = null
        var funRecoverableSecurity: ((success: Boolean) -> Unit)? = null
        var funAfterManageMediaPermission: (() -> Unit)? = null
    }

    abstract fun getAppIconIDs(): ArrayList<Int>

    abstract fun getAppLauncherName(): String


    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    fun launchChangeAppLanguageIntent() {
        try {
            Intent(Settings.ACTION_APP_LOCALE_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
                startActivity(this)
            }
        } catch (e: Exception) {

            openDeviceSettings()
        }
    }
    fun handlePartialMediaPermissions(permissionIds: Collection<Int>, force: Boolean = false, callback: (granted: Boolean) -> Unit) {
        actionOnPermission = null
        Log.i(TAG, "tryInitCamera   handlePartialMediaPermissions")
        if (isUpsideDownCakePlus()) {
            Log.i(TAG, "tryInitCamera  isUpsideDownCakePlus  handlePartialMediaPermissions")
            if (hasPermission(PERMISSION_READ_MEDIA_VISUAL_USER_SELECTED) && !force) {
                callback(true)
            } else {
                isAskingPermissions = true
                actionOnPermission = callback
                ActivityCompat.requestPermissions(this, permissionIds.map { getPermissionString(it) }.toTypedArray(), GENERIC_PERM_HANDLER)
            }
        } else {
            Log.i(TAG, "tryInitCamera not isUpsideDownCakePlus  handlePartialMediaPermissions")
            if (hasAllPermissions(permissionIds)) {
                callback(true)
            } else {
                isAskingPermissions = true
                actionOnPermission = callback
                ActivityCompat.requestPermissions(this, permissionIds.map { getPermissionString(it) }.toTypedArray(), GENERIC_PERM_HANDLER)
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        isAskingPermissions = false
        if (requestCode == GENERIC_PERM_HANDLER && grantResults.isNotEmpty()) {
            actionOnPermission?.invoke(grantResults[0] == 0)
        }
    }

    fun handlePermission(permissionId: Int, callback: (granted: Boolean) -> Unit) {
        actionOnPermission = null
        if (hasPermission(permissionId)) {
            callback(true)
        } else {
            isAskingPermissions = true
            actionOnPermission = callback
            ActivityCompat.requestPermissions(this, arrayOf(getPermissionString(permissionId)), GENERIC_PERM_HANDLER)
        }
    }

     fun handleStoragePermission(callback: (granted: Boolean) -> Unit) {
        if (com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.isTiramisuPlus()) {
            val mediaPermissionIds = mutableListOf(PERMISSION_READ_MEDIA_IMAGES, PERMISSION_READ_MEDIA_VIDEO)
            if (com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.isUpsideDownCakePlus()) {
                mediaPermissionIds.add(PERMISSION_READ_MEDIA_VISUAL_USER_SELECTED)
            }

            handlePartialMediaPermissions(permissionIds = mediaPermissionIds, callback = callback)
        } else {
            handlePermission(PERMISSION_WRITE_STORAGE, callback)
        }
    }
    fun handleSAFDialog(path: String, callback: (success: Boolean) -> Unit): Boolean {
        hideKeyboard()
        callback(true)
        return  false

    }

    private fun handleSAFDialogSdk30(path: String, callback: (success: Boolean) -> Unit): Boolean {
        hideKeyboard()
        callback(true)
        return  false

    }

    fun checkManageMediaOrHandleSAFDialogSdk30(path: String, callback: (success: Boolean) -> Unit): Boolean {
        hideKeyboard()
        return if (canManageMedia()) {
            callback(true)
            false
        } else {
            handleSAFDialogSdk30(path, callback)
        }
    }

//    fun handleSAFCreateDocumentDialogSdk30(path: String, callback: (success: Boolean) -> Unit): Boolean {
//        hideKeyboard()
//        return if (!packageName.startsWith("com.simplemobiletools")) {
//            callback(true)
//            false
//        } else if (isShowingSAFCreateDocumentDialogSdk30(path)) {
//            funAfterSdk30Action = callback
//            true
//        } else {
//            callback(true)
//            false
//        }
//    }
//
//    fun handleAndroidSAFDialog(path: String, callback: (success: Boolean) -> Unit): Boolean {
//        hideKeyboard()
//        return if (!packageName.startsWith("com.simplemobiletools")) {
//            callback(true)
//            false
//        } else if (isShowingAndroidSAFDialog(path)) {
//            funAfterSAFPermission = callback
//            true
//        } else {
//            callback(true)
//            false
//        }
//    }
//
//    fun handleOTGPermission(callback: (success: Boolean) -> Unit) {
//        hideKeyboard()
//        if (baseConfig.OTGTreeUri.isNotEmpty()) {
//            callback(true)
//            return
//        }
//
//        funAfterSAFPermission = callback
//        WritePermissionDialog(this, Mode.Otg) {
//            Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
//                try {
//                    startActivityForResult(this, OPEN_DOCUMENT_TREE_OTG)
//                    return@apply
//                } catch (e: Exception) {
//                    type = "*/*"
//                }
//
//                try {
//                    startActivityForResult(this, OPEN_DOCUMENT_TREE_OTG)
//                } catch (e: ActivityNotFoundException) {
//                    toast(R.string.system_service_disabled, Toast.LENGTH_LONG)
//                } catch (e: Exception) {
//                    toast(R.string.unknown_error_occurred)
//                }
//            }
//        }
//    }
//
//    @SuppressLint("NewApi")
//    fun deleteSDK30Uris(uris: List<Uri>, callback: (success: Boolean) -> Unit) {
//        hideKeyboard()
//        if (isRPlus()) {
//            funAfterSdk30Action = callback
//            try {
//                val deleteRequest = MediaStore.createDeleteRequest(contentResolver, uris).intentSender
//                startIntentSenderForResult(deleteRequest, DELETE_FILE_SDK_30_HANDLER, null, 0, 0, 0)
//            } catch (e: Exception) {
//                showErrorToast(e)
//            }
//        } else {
//            callback(false)
//        }
//    }
//
//    @SuppressLint("NewApi")
//    fun trashSDK30Uris(uris: List<Uri>, toTrash: Boolean, callback: (success: Boolean) -> Unit) {
//        hideKeyboard()
//        if (isRPlus()) {
//            funAfterTrash30File = callback
//            try {
//                val trashRequest = MediaStore.createTrashRequest(contentResolver, uris, toTrash).intentSender
//                startIntentSenderForResult(trashRequest, TRASH_FILE_SDK_30_HANDLER, null, 0, 0, 0)
//            } catch (e: Exception) {
//                showErrorToast(e)
//            }
//        } else {
//            callback(false)
//        }
//    }
}
