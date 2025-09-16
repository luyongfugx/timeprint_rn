package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models

import androidx.camera.core.CameraSelector

data class CameraSelectorVideoQualities(
    val camSelector: CameraSelector,
    val qualities: List<VideoQuality>,
)
