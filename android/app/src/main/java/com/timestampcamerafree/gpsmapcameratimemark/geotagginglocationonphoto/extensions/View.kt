package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions


import android.view.View

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.SHORT_ANIMATION_DURATION

fun View.isVisible() = visibility == View.VISIBLE

fun View.fadeIn() {
    animate().alpha(1f).setDuration(SHORT_ANIMATION_DURATION).withStartAction { isClickable = true }.start()
}

fun View.fadeOut() {
    animate().alpha(0f).setDuration(SHORT_ANIMATION_DURATION).withEndAction { isClickable = false }.start()
}

fun View.beInvisibleIf(beInvisible: Boolean) = if (beInvisible) beInvisible() else beVisible()

fun View.beVisibleIf(beVisible: Boolean) = if (beVisible) beVisible() else beGone()

fun View.beGoneIf(beGone: Boolean) = beVisibleIf(!beGone)

fun View.beInvisible() {
    visibility = View.INVISIBLE
}

fun View.beVisible() {
    visibility = View.VISIBLE
}

fun View.beGone() {
    visibility = View.GONE
}




