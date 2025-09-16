package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions

import android.graphics.Color
import android.media.ExifInterface
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.CameraSelectorManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.FLASH_ALWAYS_ON
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.FLASH_AUTO
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.FLASH_OFF
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.FLASH_ON
import java.util.Locale

fun Int.toCameraXFlashMode(): Int {
    return when (this) {
        FLASH_ON -> ImageCapture.FLASH_MODE_ON
        FLASH_OFF -> ImageCapture.FLASH_MODE_OFF
        FLASH_AUTO -> ImageCapture.FLASH_MODE_AUTO
        FLASH_ALWAYS_ON -> ImageCapture.FLASH_MODE_OFF
        else -> throw IllegalArgumentException("Unknown mode: $this")
    }
}
fun Int.adjustAlpha(factor: Float): Int {
    val alpha = Math.round(Color.alpha(this) * factor)
    val red = Color.red(this)
    val green = Color.green(this)
    val blue = Color.blue(this)
    return Color.argb(alpha, red, green, blue)
}
fun Int.getFormattedDuration(forceShowHours: Boolean = false): String {
    val sb = StringBuilder(8)
    val hours = this / 3600
    val minutes = this % 3600 / 60
    val seconds = this % 60

    if (this >= 3600) {
        sb.append(String.format(Locale.getDefault(), "%02d", hours)).append(":")
    } else if (forceShowHours) {
        sb.append("0:")
    }

    sb.append(String.format(Locale.getDefault(), "%02d", minutes))
    sb.append(":").append(String.format(Locale.getDefault(), "%02d", seconds))
    return sb.toString()
}

fun Int.toAppFlashMode(): Int {
    return when (this) {
        ImageCapture.FLASH_MODE_ON -> FLASH_ON
        ImageCapture.FLASH_MODE_OFF -> FLASH_OFF
        ImageCapture.FLASH_MODE_AUTO -> FLASH_AUTO
        else -> throw IllegalArgumentException("Unknown mode: $this")
    }
}

//fun Int.toFlashModeId(): Int {
//    return when (this) {
//        FLASH_ON -> R.id.flash_on
//        FLASH_OFF -> R.id.flash_off
//        FLASH_AUTO -> R.id.flash_auto
//        FLASH_ALWAYS_ON -> R.id.flash_always_on
//        else -> throw IllegalArgumentException("Unknown mode: $this")
//    }
//}

//这里稍微有问题，因为可能有多个摄像头，所以默认的话可能不是最好的摄像头
fun Int.toCameraSelector(): CameraSelector {
    return if (this == CameraSelector.LENS_FACING_FRONT) {
        //CameraSelectorManager.frontCamera
        CameraSelector.DEFAULT_FRONT_CAMERA
    } else {
        Log.d("toCameraSelector","toCameraSelector CameraSelectorManager.curRatio ${CameraSelectorManager.curRatio}")
        //前置摄像头，则需要判断当前的zoom是不是在广角范围内，广角范围只zoomRatio在0.7以下，不能等于0.7
        //使用广角镜头
        if (CameraSelectorManager.curRatio <0.7 ){
            Log.d("toCameraSelector","toCameraSelector return CameraSelectorManager.maxWideAngleCamera")

            CameraSelectorManager.maxWideAngleCamera
        }
        else {
            CameraSelectorManager.backCamera
        }
       // CameraSelector.DEFAULT_BACK_CAMERA
    }
}

fun Int.orientationFromDegrees() = when (this) {
    270 -> ExifInterface.ORIENTATION_ROTATE_270
    180 -> ExifInterface.ORIENTATION_ROTATE_180
    90 -> ExifInterface.ORIENTATION_ROTATE_90
    else -> ExifInterface.ORIENTATION_NORMAL
}.toString()

fun Int.degreesFromOrientation() = when (this) {
    ExifInterface.ORIENTATION_ROTATE_270 -> 270
    ExifInterface.ORIENTATION_ROTATE_180 -> 180
    ExifInterface.ORIENTATION_ROTATE_90 -> 90
    else -> 0
}


