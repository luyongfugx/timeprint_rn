package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ext

import android.view.MotionEvent
import androidx.core.view.GestureDetectorCompat
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity.Companion.MIN_SWIPE_DISTANCE_X
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity.Companion.PHOTO_MODE_INDEX
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity.Companion.VIDEO_MODE_INDEX
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.config
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.isVisible
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.GestureDetectorListener
import kotlin.math.abs

/**
 * video or photo
 *
 */


fun MainActivity.initModeSwitcher() {
    val gestureDetector = GestureDetectorCompat(this, object : GestureDetectorListener() {
        override fun onDown(e: MotionEvent): Boolean {
            // we have to return true here so ACTION_UP (and onFling) can be dispatched
            return true
        }

        override fun onFling(event1: MotionEvent?, event2: MotionEvent?, velocityX: Float, velocityY: Float): Boolean {
            if (event1 == null || event2 == null) {
                return true
            }

            val deltaX = event1.x - event2.x
            val deltaXAbs = abs(deltaX)

            if (deltaXAbs >= MIN_SWIPE_DISTANCE_X) {
                if (deltaX > 0) {
                    onSwipeLeft()
                } else {
                    onSwipeRight()
                }
            }

            return true
        }
    })

    binding.cameraModeTab.setOnTouchListener { _, event ->
        gestureDetector.onTouchEvent(event)
    }
}
fun MainActivity.onSwipeLeft() {
    if (!isThirdPartyIntent() && binding.cameraModeHolder.isVisible()) {
        selectPhotoTab(triggerListener = true)
    }
}

fun MainActivity.onSwipeRight() {
    if (!isThirdPartyIntent() && binding.cameraModeHolder.isVisible()) {
        selectVideoTab(triggerListener = true)
    }
}

fun MainActivity.selectPhotoTab(triggerListener: Boolean = false) {
    if (!triggerListener) {
        removeTabListener()
    }

    binding.cameraModeTab.getTabAt(PHOTO_MODE_INDEX)?.select()
    setTabListener()
}

fun MainActivity.selectVideoTab(triggerListener: Boolean = false) {
    if (!triggerListener) {
        removeTabListener()
    }
    binding.cameraModeTab.getTabAt(VIDEO_MODE_INDEX)?.select()
    setTabListener()
}

fun MainActivity.setTabListener() {
    binding.cameraModeTab.addOnTabSelectedListener(tabSelectedListener)
}

fun MainActivity.removeTabListener() {
    binding.cameraModeTab.removeOnTabSelectedListener(tabSelectedListener)
}


fun MainActivity.isInPhotoMode(): Boolean {
    return mPreview?.isInPhotoMode() ?: if (isVideoCaptureIntent()) {
        false
    } else if (isImageCaptureIntent()) {
        true
    } else {
        config.initPhotoMode
    }
}

