package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.implementations

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.SurfaceTexture
import android.util.AttributeSet
import android.util.Log
import androidx.camera.core.CameraSelector
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.Config
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.egl.GpGlSurfaceView


class GpGICameraPreviewView : GpGlSurfaceView {
    private val TAG = "GpGICameraPreviewView"
    private var textureId: Int = -1
    private lateinit var cameraPreview:  GpGlCameraPreview
    private var cameraRender: CameraRender? = null

    var surfaceTexture: SurfaceTexture? = null

    private var cameraId = CameraSelector.LENS_FACING_BACK
    constructor(context: Context) : super(context) {
        initView(context)
    }
    constructor(context: Context, attrs: AttributeSet?) : super(context, attrs) {
        initView(context)
    }

    constructor(context: Context, attrs: AttributeSet?, defStyleAttr: Int) : super(context, attrs, defStyleAttr) {
        initView(context)
    }

    private fun initView(ctx: Context) {
        cameraRender = CameraRender(ctx)
        setRender(cameraRender!!)
        val config =  Config.newInstance(App.context)
        cameraId = config.lastUsedCameraLens
        previewAngle()
        cameraRender!!.onSurfaceCreatedListener = object : CameraRender.OnSurfaceCreatedListener {
            override fun onSurfaceCreated(surfaceTexture: SurfaceTexture, textureId: Int) {
                //GLSurface创建完之后，和OpenGl纹理关联的surfaceTexture再和摄像头绑定
//                Log.e(TAG, "onSurfaceCreated==== textureId ${textureId}")
               // customCamera?.initCamera(surfaceTexture, cameraId)
                this@GpGICameraPreviewView.surfaceTexture = surfaceTexture
                //纹理id保存在CameraPreviewView，随时提供给录制线程渲染使用
                this@GpGICameraPreviewView.textureId = textureId

            }
        }
    }
    @SuppressLint("RestrictedApi")
    fun changePreviewAngle(camId:Int) {
        cameraRender?.resetMatrix()
         val isFrontCamera = camId == CameraSelector.DEFAULT_FRONT_CAMERA.lensFacing
       // val defaultAngle = if (cameraId == CameraSelector.LENS_FACING_BACK) 90f else 270f
        if (isFrontCamera){
            cameraRender?.setAngle(270f, 0f, 0f, 1f)
            cameraRender?.setFlipHorizontal(true)
        }
        else {
            cameraRender?.setAngle(90f, 0f, 0f, 1f)
            cameraRender?.setFlipHorizontal(false)
        }
        cameraId = camId
    }
    fun setGpGlCameraPreview(camPreview: GpGlCameraPreview){
        cameraPreview = camPreview
        cameraRender?.setGpGlCameraPreview(camPreview)
    }
    fun getTextureId(): Int? {
        return textureId
    }

    /**
     * 预览角度
     */
    private fun previewAngle() {
        cameraRender?.resetMatrix()
       // val isFrontCamera = cameraPreview.cameraSelector == CameraSelector.DEFAULT_FRONT_CAMERA
        val defaultAngle = if (cameraId == CameraSelector.LENS_FACING_BACK) 90f else 270f
        cameraRender?.setAngle(defaultAngle, 0f, 0f, 1f)
        cameraRender?.setFlipHorizontal(cameraId != CameraSelector.LENS_FACING_BACK)
    }

}