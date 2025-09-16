package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers

import android.util.Log
import androidx.camera.core.ZoomState

class ZoomCalculator {
   private val TAG = "ZoomCalculator"
    fun calculateZoomRatio(zoomState: ZoomState, pinchToZoomScale: Float): Float {
       var minZoomRatio = if (CameraSelectorManager.supportWideAngel ) 0.5f else zoomState.minZoomRatio
        val clampedRatio = zoomState.zoomRatio * speedUpZoomBy2X(pinchToZoomScale)
        Log.d(TAG,"pinchToZoomScale :${pinchToZoomScale} clampedRatio:${clampedRatio} minZoomRatio:${minZoomRatio} zoomState.zoomRatio :${zoomState.zoomRatio} ")
        return clampedRatio.coerceAtLeast(minZoomRatio).coerceAtMost(zoomState.maxZoomRatio)
    }

    fun calculateZoomRatioNew(zoomRatio: Float,minZoomRatio:Float, maxZoomRatio:Float, pinchToZoomScale: Float): Float {
        var minZRatio = if (CameraSelectorManager.supportWideAngel ) 0.5f else minZoomRatio
        val clampedRatio = zoomRatio * speedUpZoomBy2X(pinchToZoomScale)
        Log.d(TAG,"pinchToZoomScale :${pinchToZoomScale} clampedRatio:${clampedRatio} minZoomRatio:${minZRatio} zoomState.zoomRatio :${zoomRatio} ")
        return clampedRatio.coerceAtLeast(minZRatio).coerceAtMost(maxZoomRatio)
    }

    private fun speedUpZoomBy2X(scaleFactor: Float): Float {
        return if (scaleFactor > 1f) {
            1.0f + (scaleFactor - 1.0f) * 2
        } else {
            1.0f - (1.0f - scaleFactor) * 2
        }
    }
}
