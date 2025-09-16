package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers

import android.util.Log
import android.view.ScaleGestureDetector
import androidx.camera.core.CameraControl
import androidx.camera.core.CameraInfo
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity

class PinchToZoomOnScaleGestureListener(
    private val cameraInfo: CameraInfo,
    private val cameraControl: CameraControl,
    private val activity: MainActivity
) : ScaleGestureDetector.SimpleOnScaleGestureListener() {
    private val TAG ="PinchToZoomOnScaleGestureListener"
    private val zoomCalculator = ZoomCalculator()

    override fun onScale(detector: ScaleGestureDetector): Boolean {

        val zoomState = cameraInfo.zoomState.value ?: return false
        var curZoomRatio =if (CameraSelectorManager.supportWideAngel ) CameraSelectorManager.curRatio else  zoomState.zoomRatio
        var minZRatio = if (CameraSelectorManager.supportWideAngel ) 0.5f else zoomState.minZoomRatio
       // val zoomRatio = zoomCalculator.calculateZoomRatio(zoomState, detector.scaleFactor)
        val zoomRatio = zoomCalculator.calculateZoomRatioNew(curZoomRatio,minZRatio,zoomState.maxZoomRatio,detector.scaleFactor)
        Log.d(TAG,"PinchToZoomOnScaleGestureListener ,detector.scaleFactor:${detector.scaleFactor} zoomState : ${zoomState.zoomRatio} caloomRatio:${zoomRatio}")
        CameraSelectorManager.curRatio = zoomRatio
       // cameraControl.setZoomRatio(zoomRatio)
        //把cameraControl.setZoomRatio放到activity.setScale里做，因为可能要换摄像头id
        activity.setScale(zoomRatio)
        return true
    }
}
