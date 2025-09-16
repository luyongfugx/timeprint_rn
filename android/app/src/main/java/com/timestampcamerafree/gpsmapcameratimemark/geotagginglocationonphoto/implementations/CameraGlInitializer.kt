package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.implementations



import android.net.Uri
import androidx.camera.view.PreviewView
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.CameraErrorHandler
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.MediaOutputHelper
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.MediaSoundHelper

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.GpBaseSimpleActivity
/**
 * opengl camera initializer
 *
 */

class CameraGlInitializer(private val activity: GpBaseSimpleActivity) {
    private var TAG = "CameraGlInitializer"
    fun createCameraXPreview(
        previewView: PreviewView,
        listener: CameraPreviewListener,
        mediaSoundHelper: MediaSoundHelper,
        outputUri: Uri?,
        isThirdPartyIntent: Boolean,
        initInPhotoMode: Boolean,
        glPreviewView: GpGICameraPreviewView
    ): GpGlCameraPreview {
        val cameraErrorHandler = newCameraErrorHandler()
        val mediaOutputHelper = newMediaOutputHelper(cameraErrorHandler, outputUri, isThirdPartyIntent)
        return GpGlCameraPreview(
            activity,
            previewView,
            mediaSoundHelper,
            mediaOutputHelper,
            cameraErrorHandler,
            listener,
            isThirdPartyIntent = isThirdPartyIntent,
            initInPhotoMode = initInPhotoMode,
            glPreviewView,
        )
    }

    private fun newMediaOutputHelper(
        cameraErrorHandler: CameraErrorHandler,
        outputUri: Uri?,
        isThirdPartyIntent: Boolean,
    ): MediaOutputHelper {
        return MediaOutputHelper(
            activity,
            cameraErrorHandler,
            outputUri,
            isThirdPartyIntent,
        )
    }

    private fun newCameraErrorHandler(): CameraErrorHandler {
        return CameraErrorHandler(activity)
    }
}
