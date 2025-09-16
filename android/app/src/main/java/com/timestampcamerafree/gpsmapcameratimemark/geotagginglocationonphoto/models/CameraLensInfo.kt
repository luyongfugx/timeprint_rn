package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models

/**
 * 相机焦距
 *
 * @property cameraId
 * @property focalLength
 * @property zoomRatio
 * @property label
 */
data class CameraLensInfo(
    val cameraId: String,
    val focalLength: Float,
    val zoomRatio: Float,
    val label: String
)