package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.dragableview

import android.view.View

/**
 * waynelu
 *
 */
interface PosChangeCallback {
    /**
     * start
     */
    fun onViewCaptured(captureView: View):Unit


    /**
     * on move
     */
    fun onViewPositionChanged(changedView: View, left: Int, top: Int, dx: Int, dy: Int): Unit


    /**
     * on stop
     */
    fun onViewReleased(releasedView: View, left: Int, top: Int): Unit
}