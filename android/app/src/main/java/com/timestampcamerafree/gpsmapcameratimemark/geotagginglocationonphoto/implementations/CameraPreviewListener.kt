package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.implementations

import android.graphics.Bitmap
import android.net.Uri
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.MySize
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.ResolutionOption
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.TimerModeOption

interface CameraPreviewListener {
    fun onInitPhotoMode()
    fun onInitVideoMode()
    fun setCameraAvailable(available: Boolean) {}
    fun setHasFrontAndBackCamera(hasFrontAndBack: Boolean)
    fun setFlashAvailable(available: Boolean)
    fun onChangeCamera(frontCamera: Boolean)
    fun shutterAnimation()
    fun onMediaSaved(uri: Uri)
    fun onImageCaptured(bitmap: Bitmap)
    fun onChangeFlashMode(flashMode: Int)
    fun onPhotoCaptureStart()
    fun onPhotoCaptureEnd()
    fun onVideoRecordingStarted()
    fun onVideoRecordingStopped(videoPath: String)
    fun onVideoDurationChanged(durationNanos: Long)
    fun onFocusCamera(xPos: Float, yPos: Float)
    fun onTouchPreview()
    fun displaySelectedResolution(resolutionOption: ResolutionOption)
    fun showImageSizes(
        selectedResolution: ResolutionOption,
        resolutions: List<ResolutionOption>,
        isPhotoCapture: Boolean,
        isFrontCamera: Boolean,
        onSelect: (index: Int, changed: Boolean) -> Unit,
    )
    fun showTimerOptions(
        selectedTimerModeOption: TimerModeOption,
        timers: List<TimerModeOption>,
        isPhotoCapture: Boolean,
        onSelect: (index: Int, changed: Boolean) -> Unit,
    )
    fun displayTimerOptions(selectedTimerModeOption: TimerModeOption)

    fun showFlashOptions(photoCapture: Boolean)
    fun adjustPreviewView(resolution: MySize)
}
