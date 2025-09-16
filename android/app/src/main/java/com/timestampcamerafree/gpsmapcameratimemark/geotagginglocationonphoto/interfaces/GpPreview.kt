package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.interfaces

interface GpPreview {

    fun isInPhotoMode(): Boolean

    fun setFlashlightState(state: Int)

    fun toggleFrontBackCamera()

    fun handleFlashlightClick()

    fun tryTakePicture()

    fun toggleRecording()

    fun initPhotoMode()

    fun initVideoMode()

    fun showChangeResolution()

    fun showTimerMode()

    fun changImageQuality()

    fun setZoomRatio(scale:Float)
}
