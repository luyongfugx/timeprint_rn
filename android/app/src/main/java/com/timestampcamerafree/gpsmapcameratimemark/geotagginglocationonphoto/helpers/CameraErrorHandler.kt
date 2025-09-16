package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers

import android.content.Context
import androidx.camera.core.CameraState
import androidx.camera.core.ImageCapture
import androidx.camera.video.VideoRecordEvent
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.toast


class CameraErrorHandler(
    private val context: Context,
) {

    fun handleCameraError(error: CameraState.StateError?) {
//        when (error?.code) {
//            CameraState.ERROR_MAX_CAMERAS_IN_USE,
//            CameraState.ERROR_CAMERA_IN_USE -> context.toast(R.string., Toast.LENGTH_LONG)
//            CameraState.ERROR_CAMERA_FATAL_ERROR -> context.toast(R.string.camera_unavailable)
//            CameraState.ERROR_STREAM_CONFIG -> context.toast(R.string.camera_configure_error)
//            CameraState.ERROR_CAMERA_DISABLED -> context.toast(R.string.camera_disabled_by_admin_error)
//            CameraState.ERROR_DO_NOT_DISTURB_MODE_ENABLED -> context.toast(R.string.camera_dnd_error, Toast.LENGTH_LONG)
//            CameraState.ERROR_OTHER_RECOVERABLE_ERROR -> {}
//        }
    }

    fun handleImageCaptureError(imageCaptureError: Int) {
        when (imageCaptureError) {
            ImageCapture.ERROR_FILE_IO -> context.toast(R.string.i_save_photo_failed)
            else -> context.toast(R.string.i_save_photo_failed)
        }
    }

    fun handleVideoRecordingError(error: Int) {
        when (error) {
            VideoRecordEvent.Finalize.ERROR_INSUFFICIENT_STORAGE -> context.toast(R.string.i_save_photo_failed)
            VideoRecordEvent.Finalize.ERROR_NONE -> {}
            else -> context.toast(R.string.i_save_photo_failed)
        }
    }

    fun showSaveToInternalStorage() {
        context.toast(R.string.i_save_photo_failed)
    }
}
