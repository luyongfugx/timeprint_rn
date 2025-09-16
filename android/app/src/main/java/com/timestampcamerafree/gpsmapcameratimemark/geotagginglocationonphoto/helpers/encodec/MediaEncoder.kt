package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.encodec

import android.content.Context
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.implementations.GpGlCameraPreview

class MediaEncoder(context: Context, textureId:Int, cameraPreview: GpGlCameraPreview): BaseMediaEncoder(context) {

    private val mediaEncodeRender: MediaEncodeRender = MediaEncodeRender(context,textureId,cameraPreview)

    init {
        setRender(mediaEncodeRender)
        setRenderMode(RENDERMODE_CONTINUOUSLY)
    }
}