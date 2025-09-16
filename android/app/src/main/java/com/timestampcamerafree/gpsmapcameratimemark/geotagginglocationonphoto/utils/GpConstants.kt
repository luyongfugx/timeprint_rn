package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils

/**
 * 常量类
 *
 */
interface GpConstants {
    object Ratio {

        const val RATIO_1_1: Float = 1f
        const val RATIO_4_3: Float = 3 / 4.0f
        const val RATIO_3_4: Float = 4 / 3.0f
        const val RATIO_16_9: Float = 9 / 16.0f
    }
    companion object {
        //时间，默认是当前时间
        var currentTimeMillis:Long = System.currentTimeMillis();
    }
}