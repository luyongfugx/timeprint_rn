package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers

import androidx.camera.core.CameraSelector

/**
 * 相机管理器，其实就是取前后摄像头分别是哪个，对于后置摄像头取角度最广的
 *
 */
object CameraSelectorManager {
    var frontCamera: CameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA
    var backCamera: CameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
    var maxWideAngleCamera:CameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
    var supportWideAngel:Boolean = false
    var curRatio:Float = 1f

    /**
     * 根据比率获取广角还是主摄像头
     *
     * @param ratio
     * @return
     */
    fun getBackCameraSelector(ratio:Float): CameraSelector{
        return if (ratio<0.7 && supportWideAngel){
            maxWideAngleCamera
        } else{
            backCamera
        }
    }
}