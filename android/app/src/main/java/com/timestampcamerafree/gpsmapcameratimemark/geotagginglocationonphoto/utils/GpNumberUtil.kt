package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils

import kotlin.math.abs

/**
 * 数字操作类
 */
object GpNumberUtil {
    private const val THRESHOLD = .0001

    private const val THRESHOLD_F = .001f


    fun equals(a: Double, b: Double): Boolean {
        return abs(a - b) <= THRESHOLD
    }

    fun equals(a: Float, b: Float): Boolean {
        return abs((a - b).toDouble()) <= THRESHOLD_F
    }
}