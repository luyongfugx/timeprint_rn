package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models

import androidx.annotation.StringRes
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R

enum class CaptureMode(@StringRes val stringResId: Int) {
    MINIMIZE_LATENCY(R.string.i_photo_quality),
    MAXIMIZE_QUALITY(R.string.i_photo_quality)
}
