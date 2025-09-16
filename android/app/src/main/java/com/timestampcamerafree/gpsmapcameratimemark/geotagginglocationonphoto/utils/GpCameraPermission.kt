package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils

import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.util.Consumer
import androidx.fragment.app.FragmentActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.PermissionFragment

/**
 * 权限管理类
 */
object  GpCameraPermission {
    var READ_MEDIA_IMAGES = "android.permission.READ_MEDIA_IMAGES"
    var READ_MEDIA_VIDEO = "android.permission.READ_MEDIA_VIDEO"
    val readExternalStoragePermissions: Array<String> by lazy(LazyThreadSafetyMode.NONE) {
        arrayOf(
            READ_MEDIA_IMAGES,
            READ_MEDIA_VIDEO
        )
    }

    fun requestReadGalleryPermission(activity: FragmentActivity, callback: Consumer<Boolean>) {
        val permissionCheckerFragment = PermissionFragment().apply {
            permissionCallback = { permissons, grantedResult ->
                if (grantedResult.count { it == PackageManager.PERMISSION_GRANTED } == permissons.size) {
                    callback.accept(true)
                } else {
                    callback.accept(false)
                }
            }
        }
        activity.supportFragmentManager.beginTransaction().add(permissionCheckerFragment, "PermissionFragment").commitAllowingStateLoss()
        permissionCheckerFragment.postRequestPermission(GpCameraPermission.readExternalStoragePermissions)
    }
    fun checkPermission(context: Context?, permission: String?): Boolean {
        return ActivityCompat.checkSelfPermission(context!!, permission!!) == PackageManager.PERMISSION_GRANTED
    }



}