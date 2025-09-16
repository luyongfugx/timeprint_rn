package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions

import androidx.annotation.DrawableRes
import com.google.android.material.button.MaterialButton
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.ShadowDrawable

fun MaterialButton.setShadowIcon(@DrawableRes drawableResId: Int) {
    icon = ShadowDrawable(context, drawableResId, R.style.TopIconShadow)
}
