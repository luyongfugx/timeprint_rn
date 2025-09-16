package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models

import androidx.annotation.IdRes
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R

//图片质量
enum class ImageQuality (val quality: Int) {
    //标准
    STANDARD(90),
    LOW(50),
    NORMAL(80),
    HEIGHT(95),
    ULTRA(100);
//    @DrawableRes
//    fun getImageResId(): Int = when (this) {
//        UHD -> R.drawable.ic_video_uhd_vector
//        FHD -> R.drawable.ic_video_fhd_vector
//        HD -> R.drawable.ic_video_hd_vector
//        SD -> R.drawable.ic_video_sd_vector
//    }

    @IdRes
    fun getButtonViewId(): Int = when (this) {
        STANDARD -> R.id.image_standard
        LOW -> R.id.image_low
        NORMAL -> R.id.image_normal
        HEIGHT -> R.id.image_height
        ULTRA -> R.id.image_ultra
    }



     fun getText(): String = when (this) {
        STANDARD -> "STANDARD,4MB"
        LOW -> "LOW,100KB"
        NORMAL -> "NORMAL,400KB"
        HEIGHT -> "HEIGHT,1MB"
        ULTRA -> "ULTRA,4MB"
    }


}