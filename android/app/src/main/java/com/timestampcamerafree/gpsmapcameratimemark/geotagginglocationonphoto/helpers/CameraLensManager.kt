package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.CameraLensInfo
import kotlin.math.abs

/**
 * huo
 */
object CameraLensManager {
    private var cameraList: List<CameraLensInfo>  = emptyList()

    fun getAllCameraLensInfo(context: Context): List<CameraLensInfo> {
        if (cameraList.isNotEmpty()){
            return cameraList
        }
        val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val cameraIdList = cameraManager.cameraIdList
        val cameraInfos = mutableListOf<Pair<String, Float>>() // cameraId to focalLength

        // 1. 获取所有后置摄像头的焦距信息
        for (cameraId in cameraIdList) {
            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
            val lensFacing = characteristics.get(CameraCharacteristics.LENS_FACING)
            if (lensFacing != CameraCharacteristics.LENS_FACING_BACK) continue

            val focalLengths = characteristics.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)
            if (focalLengths?.isNotEmpty() == true) {
                cameraInfos.add(Pair(cameraId, focalLengths[0]))
            }
        }

        if (cameraInfos.isEmpty()) return emptyList()

        // 2. 推测主摄：取中间焦距（最接近中位数）
        val mainFocalLength = getMedianFocal(cameraInfos.map { it.second })
        val mainCameraId = cameraInfos.minByOrNull { abs(it.second - mainFocalLength) }?.first ?: return emptyList()

        // 3. 计算 zoomRatio = current / main
        cameraList= cameraInfos.map { (cameraId, focalLength) ->
            val zoomRatio = focalLength / mainFocalLength
            val label = when {
                zoomRatio < 0.75f -> String.format("%.2fx", zoomRatio)
                zoomRatio > 1.25f -> String.format("%.2fx", zoomRatio)
//                cameraId != mainCameraId -> String.format("%.2fx", zoomRatio)
                else -> "1.0x"
            }
            CameraLensInfo(cameraId, focalLength, zoomRatio, label)
        }.filter { it.label != "1.0x" || it.cameraId == mainCameraId }
            .sortedBy { it.zoomRatio }
        return cameraList
    }

    private fun getMedianFocal(focals: List<Float>): Float {
        val sorted = focals.sorted()
        val middle = sorted.size / 2
        return if (sorted.size % 2 == 0) {
            (sorted[middle - 1] + sorted[middle]) / 2
        } else {
            sorted[middle]
        }
    }
}
