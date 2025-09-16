package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.ImageFormat
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.util.Log
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.CameraSelector.LENS_FACING_BACK
import androidx.camera.core.impl.CameraInfoInternal
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.config
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.toCameraSelector
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.CameraSelectorImageQualities
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.ImageQuality
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.MySize

class ImageQualityManager(private val activity: AppCompatActivity) {
    private val TAG = "ImageQualityManager" // 定义日志标签
    companion object {
        fun getSupportedImageQualities(): List<ImageQuality> {
            val qualities = arrayListOf(
                ImageQuality.STANDARD,
                ImageQuality.LOW,
                ImageQuality.NORMAL,
                ImageQuality.HEIGHT,
                ImageQuality.ULTRA

            )
            return  qualities
        }
        private val CAMERA_LENS = arrayOf(CameraCharacteristics.LENS_FACING_FRONT, CameraCharacteristics.LENS_FACING_BACK)
    }

    private val cameraManager = activity.getSystemService(Context.CAMERA_SERVICE) as CameraManager
    private val imageQualities = mutableListOf<CameraSelectorImageQualities>()
    private val mediaSizeStore = MediaSizeStore(activity.config)

    /**
     * 初始化后摄像头，取最广的广角摄像头
     *
     */
    @SuppressLint("RestrictedApi")
    fun createCameraSelectorForId(cameraId: String): CameraSelector {
        return CameraSelector.Builder()
            .addCameraFilter { cameraInfos -> cameraInfos.filter { (it as? CameraInfoInternal)?.cameraId == cameraId } }
            .build()
    }
    fun initWideAngleCameraSelects() {
        var lastMinFocal = 100f;
        for (cameraId in cameraManager.cameraIdList) {
            try {
                val characteristics = cameraManager.getCameraCharacteristics(cameraId)
                val lensFacing = characteristics.get(CameraCharacteristics.LENS_FACING) ?: continue
                //找后置摄像头里
                if (lensFacing == LENS_FACING_BACK) {
                    val focalLengths = characteristics.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)
                    var cur = focalLengths?.minOrNull() ?: 0f;
                    if (cur<= lastMinFocal)  {
                        lastMinFocal  = cur
                        val minFocalLength = focalLengths?.minOrNull() ?: -1f
                        //说明有广角
                        if (minFocalLength < 3.0f) { // Adjust threshold as needed
                            Log.d(TAG,"initBackCameraSelects 3.0f cameraId ${cameraId}   lensFacing:${lensFacing} focalLengths minOrNull ${focalLengths?.minOrNull()}")
                            CameraSelectorManager.maxWideAngleCamera =    createCameraSelectorForId(cameraId)
                            CameraSelectorManager.supportWideAngel =  true
                        }
                    }
                }
            } catch (e: Exception) {
                Toast.makeText(activity, e.message, Toast.LENGTH_SHORT).show()
            }
        }
    }
    /**
     * 获取各个相机支持的分辨率
     *
     */
    fun initSupportedQualities() {
        Log.d(TAG,"CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP :${CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP}")
        if (imageQualities.isEmpty()) {
            for (cameraId in cameraManager.cameraIdList) {
                try {
                    val characteristics = cameraManager.getCameraCharacteristics(cameraId)
                    val lensFacing = characteristics.get(CameraCharacteristics.LENS_FACING) ?: continue
                    if (lensFacing in CAMERA_LENS) {
                        val configMap = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP) ?: continue
                        val imageSizes = configMap.getOutputSizes(ImageFormat.JPEG).map { MySize(it.width, it.height) }
                        val cameraSelector = lensFacing.toCameraSelector()
                        var imageQualitie = CameraSelectorImageQualities(cameraSelector, imageSizes)
                        imageQualities.add(imageQualitie)
                    }
                } catch (e: Exception) {
                    Toast.makeText(activity, e.message, Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    private fun getCameraDeviceMinZoom(camera: Camera?): Float {
        if (camera == null) return 1f
        val minZoom: Float = camera.cameraInfo.zoomState.getValue()!!.getMinZoomRatio()
        return minZoom
    }
    /**
     * 是否支持广角
     *
     * @param cameraId
     * @return
     */
    @SuppressLint("RestrictedApi")
    fun isSupportWideAngel(camera: Camera?):Boolean {
        try {
            val cameraId = (camera?.cameraInfo as CameraInfoInternal).cameraId
            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
            val focalLengths = characteristics.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)
            if (focalLengths != null && focalLengths.isNotEmpty()) {
                val minFocalLength = focalLengths.minOrNull() ?: -1f
                if (minFocalLength < 3.0f) { // 阈值需要根据测试调整
                    // 支持广角
                    return true
                }
                else {
                    return false
                }
            }
            else {
                return false
            }
        }
        catch (e:Exception){
            Log.d(TAG,"isSupportWideAngel error: ${e.message}")
            return false
        }

    }

    fun getUserSelectedResolution(cameraSelector: CameraSelector): MySize {
        val resolutions =  getSupportedResolutions(cameraSelector)
        if (resolutions.isEmpty()) {
            // Return a default resolution if none are available
            return MySize(1920, 1080) // Default to 1080p
        }
        
        val isFrontCamera = cameraSelector == CameraSelector.DEFAULT_FRONT_CAMERA
        var index = mediaSizeStore.getCurrentSizeIndex(isPhotoCapture = true, isFrontCamera = isFrontCamera)
        index = index.coerceAtMost(resolutions.lastIndex).coerceAtLeast(0)

        return resolutions[index]
    }

    /**
     * 获取相机支持的比例
     *
     * @param cameraSelector
     * @return
     */
    fun getSupportedResolutions(cameraSelector: CameraSelector): List<MySize> {
        var realCameraSelector = cameraSelector
        if (cameraSelector == CameraSelectorManager.maxWideAngleCamera){
            realCameraSelector = CameraSelectorManager.backCamera
        }
        val fullScreenSize = getFullScreenResolution(realCameraSelector) ?: return ArrayList()
        var supportedResolutions =  imageQualities.asSequence().filter { it.camSelector == realCameraSelector }
            .flatMap { it.qualities }
            .distinctBy { it.getAspectRatio(activity) }
            .sortedByDescending { it.getSortId() } //通过sor
            .filter { it.isSupported(fullScreenSize.isSixteenToNine()) }.toList() +listOf(fullScreenSize)
        return supportedResolutions
    }

    private fun getFullScreenResolution(cameraSelector: CameraSelector): MySize? {
        var fullsize = imageQualities.filter { it.camSelector == cameraSelector }
            .flatMap { it.qualities }
            .sortedByDescending { it.width }
            .firstOrNull { it.isSupported(false) }
            ?.copy(isFullScreen = false)//设置为false，表示不支持全屏

        //兜底
        if (fullsize == null){
             fullsize = imageQualities.filter { it.camSelector == CameraSelectorManager.backCamera }
                .flatMap { it.qualities }
                .sortedByDescending { it.width }
                .firstOrNull { it.isSupported(false) }
                ?.copy(isFullScreen = false)
        }
        return fullsize
    }



}
