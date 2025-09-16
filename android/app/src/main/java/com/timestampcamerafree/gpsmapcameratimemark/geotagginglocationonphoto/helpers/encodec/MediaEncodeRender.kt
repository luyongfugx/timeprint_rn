package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.encodec


import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.opengl.GLES20
import android.opengl.Matrix.orthoM
import android.opengl.Matrix.rotateM
import android.util.Log
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.egl.GpGlSurfaceView
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.implementations.GpGlCameraPreview
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.ShaderUtil
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.min

class MediaEncodeRender(val context: Context, private val textureId: Int, private val cameraPreview: GpGlCameraPreview) : GpGlSurfaceView.CustomRender {
    private val TAG = "MediaEncodeRender"
    private val projectionMatrix = FloatArray(16)
    private var uMatrixLocation = 0

    private lateinit var vertexBuffer: FloatBuffer
    private lateinit var fragmentBuffer: FloatBuffer
    private lateinit var vertexData: FloatArray
    private lateinit var fragmentData: FloatArray
    //val timeprintBitmap = BitmapFactory.decodeResource(context.resources, R.drawable.timeprint)
    private var program = 0
    private var vPosition = 0
    private var fPosition = 0
    private var vboId = 0

    private var currentWidth: Int = 0
    private var currentHeight: Int = 0

    private val dateFormat = SimpleDateFormat("yyyy-MM-dd hh:mm:ss", Locale.getDefault())
    private val watermarks = mutableListOf<Watermark>()
   private var lastWatermarkUpdateTime = 0L
    data class Watermark(
        var bitmap: Bitmap? = null,
        var imageResId: Int = 0,
        var textureId: Int = 0,
        val pixelX: Int,
        val pixelY: Int,
        val pixelHeight: Int,
        var screenWidth: Int,
        var screenHeight: Int,
        var shouldUpdate:Boolean = false
    ) {
        fun getAspectRatio(context: Context): Float {
            return if (bitmap != null) {
                1.0f * bitmap!!.width / bitmap!!.height
            } else {
                val options = BitmapFactory.Options().apply {
                    inJustDecodeBounds = true
                }
                BitmapFactory.decodeResource(context.resources, imageResId, options)
                1.0f * options.outWidth / options.outHeight
            }
        }

        fun getNormalizedX(): Float {
            return (pixelX.toFloat() / screenWidth.toFloat()) * 2f - 1f
        }

        fun getNormalizedY(): Float {
            return 1f - (pixelY.toFloat() / screenHeight.toFloat()) * 2f
        }

        fun getNormalizedHeight(): Float {
            return pixelHeight.toFloat() / screenHeight.toFloat() * 2f
        }
    }

    init {
        initBuffers()

//        addWatermark(
//            text = dateFormat.format(Date()),
//            textSize = 50,
//            textColor = "#ffeedd",
//            bgColor = "#00000000",
//            pixelX = 50,  // 50 pixels from left
//            pixelY = 50,  // 50 pixels from top
//            pixelHeight = 100// 100 pixels height
//        )
        val staticWatermarkBitmapList =  cameraPreview.getStaticVideoWaterMarksBitMap()
         Log.d(TAG,"updateWatermarks staticWatermarkBitmapList.size :${staticWatermarkBitmapList.size}")
        staticWatermarkBitmapList.forEach{
            addBitmapWatermark(
                it.bitmap,
                pixelX = it.x.toInt(),  // 100 pixels from left
                pixelY = it.y.toInt(),  // 100 pixels from top
                pixelHeight = it.bitmap.height,
                shouldUpdate = it.shouldUpdate// 150 pixels height
            )
        }
        val realWatermarkBitmapList =  cameraPreview.getRealUpdateVideoWaterMarksBitMap()
        Log.d(TAG,"updateWatermarks realWatermarkBitmapList.size :${staticWatermarkBitmapList.size}")
        realWatermarkBitmapList.forEach{
            addBitmapWatermark(
                it.bitmap,
                pixelX = it.x.toInt(),  // 100 pixels from left
                pixelY = it.y.toInt(),  // 100 pixels from top
                pixelHeight = it.bitmap.height,
                shouldUpdate = it.shouldUpdate// 150 pixels height
                // 150 pixels height
            )
        }
       // watermarks.clear()

//        val watermarkBitmapList =  cameraPreview.getVideoWaterMarksBitMap()
//         Log.d(TAG,"updateWatermarks watermarkBitmapList.size :${watermarkBitmapList.size}")
//        watermarkBitmapList.forEach{
//            //val bitmap = it.bitmap
//            addBitmapWatermark(
//                it.bitmap,
//                pixelX = it.x.toInt(),  // 100 pixels from left
//                pixelY = it.y.toInt(),  // 100 pixels from top
//                pixelHeight = it.bitmap.height // 150 pixels height
//            )
//        }
//        val watermarkBitmapList =  cameraPreview.getWaterMarkImageList()
//       // Log.d(TAG,"updateWatermarks watermarkBitmapList.size :${watermarkBitmapList.size}")
//
//        watermarkBitmapList.forEach{
//            //val bitmap = it.bitmap
//            addBitmapWatermark(
//                it.bitmap,
//                pixelX = it.x.toInt(),  // 100 pixels from left
//                pixelY = it.y.toInt(),  // 100 pixels from top
//                pixelHeight = it.bitmap.height // 150 pixels height
//            )
//        }
        // Add default date watermark
//        addWatermark(
//            text = dateFormat.format(Date()),
//            textSize = 50,
//            textColor = "#ffeedd",
//            bgColor = "#00000000",
//            pixelX = 50,  // 50 pixels from left
//            pixelY = 50,  // 50 pixels from top
//            pixelHeight = 100// 100 pixels height
//        )
//        // Add image watermark
//        addImageWatermark(
//            imageResId = R.drawable.timeprint,
//            pixelX = 100,  // 100 pixels from left
//            pixelY = 200,  // 100 pixels from top
//            pixelHeight = 150 // 150 pixels height
//        )
//        val bitmap = BitmapFactory.decodeResource(context.resources, R.drawable.timeprint)
//        addBitmapWatermark(
//            bitmap,
//            pixelX = 100,  // 100 pixels from left
//            pixelY = 200,  // 100 pixels from top
//            pixelHeight = 150 // 150 pixels height
//        )


    }

    fun addWatermark(
        text: String,
        textSize: Int,
        textColor: String,
        bgColor: String,
        pixelX: Int,
        pixelY: Int,
        pixelHeight: Int
    ) {
        val bitmap = ShaderUtil.crateTextImage(text, textSize, textColor, bgColor, 0)
        watermarks.add(Watermark(
            bitmap = bitmap,
            pixelX = pixelX,
            pixelY = pixelY,
            pixelHeight = pixelHeight,
            screenWidth = currentWidth,
            screenHeight = currentHeight
        ))
        initBuffers()
    }

    fun addImageWatermark(
        imageResId: Int,
        pixelX: Int,
        pixelY: Int,
        pixelHeight: Int
    ) {
        val bitmap = BitmapFactory.decodeResource(context.resources, imageResId)
        watermarks.add(Watermark(
            bitmap = bitmap,
            imageResId = imageResId,
            pixelX = pixelX,
            pixelY = pixelY,
            pixelHeight = pixelHeight,
            screenWidth = currentWidth,
            screenHeight = currentHeight
        ))
        initBuffers()
    }
    fun addBitmapWatermark(
        bitmap: Bitmap,
        pixelX: Int,
        pixelY: Int,
        pixelHeight: Int,
        shouldUpdate:Boolean
    ) {
        watermarks.add(Watermark(
            bitmap = bitmap,
            textureId = ShaderUtil.loadBitmapTexture(bitmap),
            pixelX = pixelX,
            pixelY = pixelY,
            pixelHeight = pixelHeight,
            screenWidth = currentWidth,
            screenHeight = currentHeight,
            shouldUpdate = shouldUpdate

        ))
      initBuffers()
    }

    private fun initBuffers() {
        // Each watermark needs 4 vertices (x,y) * 4 + main texture (4 vertices)
        vertexData = FloatArray(8 * (watermarks.size + 1))
        fragmentData = FloatArray(8 * (watermarks.size + 1))

        // Main texture vertices
        vertexData[0] = -1f; vertexData[1] = -1f
        vertexData[2] = 1f; vertexData[3] = -1f
        vertexData[4] = -1f; vertexData[5] = 1f
        vertexData[6] = 1f; vertexData[7] = 1f

        // Main texture coordinates
        fragmentData[0] = 0f; fragmentData[1] = 0f
        fragmentData[2] = 1f; fragmentData[3] = 0f
        fragmentData[4] = 0f; fragmentData[5] = 1f
        fragmentData[6] = 1f; fragmentData[7] = 1f

        // Set vertices and texture coordinates for each watermark
        watermarks.forEachIndexed { i, watermark ->
            val baseIndex = 8 * (i + 1)
            watermark.screenWidth = currentWidth
            watermark.screenHeight = currentHeight

            val pixelRatio = watermark.getAspectRatio(context)
            val height = watermark.getNormalizedHeight()
            val width = height * pixelRatio * (currentHeight.toFloat() / currentWidth.toFloat())

            val x = watermark.getNormalizedX()
            val y = watermark.getNormalizedY()

            // Watermark vertices
            vertexData[baseIndex] = x
            vertexData[baseIndex + 1] = y
            vertexData[baseIndex + 2] = x + width
            vertexData[baseIndex + 3] = y
            vertexData[baseIndex + 4] = x
            vertexData[baseIndex + 5] = y - height
            vertexData[baseIndex + 6] = x + width
            vertexData[baseIndex + 7] = y - height

            // Texture coordinates
            fragmentData[baseIndex] = 0f
            fragmentData[baseIndex + 1] = 0f
            fragmentData[baseIndex + 2] = 1f
            fragmentData[baseIndex + 3] = 0f
            fragmentData[baseIndex + 4] = 0f
            fragmentData[baseIndex + 5] = 1f
            fragmentData[baseIndex + 6] = 1f
            fragmentData[baseIndex + 7] = 1f
        }

        vertexBuffer = ByteBuffer
            .allocateDirect(vertexData.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .apply {
                put(vertexData)
                position(0)
            }

        fragmentBuffer = ByteBuffer
            .allocateDirect(fragmentData.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .apply {
                put(fragmentData)
                position(0)
            }

        // Update VBO data
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, vboId)
        GLES20.glBufferSubData(GLES20.GL_ARRAY_BUFFER, 0, vertexData.size * 4, vertexBuffer)
        GLES20.glBufferSubData(
            GLES20.GL_ARRAY_BUFFER,
            vertexData.size * 4,
            fragmentData.size * 4,
            fragmentBuffer
        )
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, 0)
    }

    override fun onSurfaceCreated() {
        try {
            GLES20.glEnable(GLES20.GL_BLEND)
            GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)

            val vertexSource = ShaderUtil.readRawTExt(context, R.raw.vertex_shader_screen)
            val fragmentSource = ShaderUtil.readRawTExt(context, R.raw.fragment_shader_screen)
            program = ShaderUtil.createProgram(vertexSource, fragmentSource)

            vPosition = GLES20.glGetAttribLocation(program, "av_Position")
            fPosition = GLES20.glGetAttribLocation(program, "af_Position")
            uMatrixLocation = GLES20.glGetUniformLocation(program, "u_Matrix")

            val vbos = IntArray(1)
            GLES20.glGenBuffers(1, vbos, 0)
            vboId = vbos[0]

            GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, vboId)
            GLES20.glBufferData(
                GLES20.GL_ARRAY_BUFFER,
                vertexData.size * 4 + fragmentData.size * 4,
                null,
                GLES20.GL_STATIC_DRAW
            )
            GLES20.glBufferSubData(GLES20.GL_ARRAY_BUFFER, 0, vertexData.size * 4, vertexBuffer)
            GLES20.glBufferSubData(
                GLES20.GL_ARRAY_BUFFER,
                vertexData.size * 4,
                fragmentData.size * 4,
                fragmentBuffer
            )
            GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, 0)

            // Create textures for all watermarks
            watermarks.forEach { watermark ->
                watermark.textureId = if (watermark.bitmap != null) {
                    ShaderUtil.loadBitmapTexture(watermark.bitmap!!)
                } else {
                    ShaderUtil.loadTexrute(watermark.imageResId, context)
                }
            }
        } catch (e: IOException) {
            e.printStackTrace()
        }
    }

    override fun onSurfaceChanged(width: Int, height: Int) {
       // Log.d(TAG,"watermarkbit onSurfaceChanged")
        currentWidth = width
        currentHeight = height

        // Update all watermarks' screen dimensions
        watermarks.forEach {
            it.screenWidth = width
            it.screenHeight = height
        }

        GLES20.glViewport(0, 0, width, height)
        val aspectRatio = if (width > height) width.toFloat() / height.toFloat()
        else height.toFloat() / width.toFloat()

        if (width > height) {
            orthoM(projectionMatrix, 0, -aspectRatio, aspectRatio, -1f, 1f, -1f, 1f)
        } else {
            orthoM(projectionMatrix, 0, -1f, 1f, -aspectRatio, aspectRatio, -1f, 1f)
        }

        rotateM(projectionMatrix, 0, 180f, 1f, 0f, 0f)
        initBuffers() // Recalculate coordinates when screen size changes
    }

    private fun updateWatermarks() {
        watermarks.forEach { watermark ->
            if (watermark.bitmap == null){
                if (watermark.imageResId > 0) {
                    watermark.bitmap = BitmapFactory.decodeResource(context.resources, watermark.imageResId)
                }else {
                    val currentDate = dateFormat.format(Date())
                    // Update text watermark
                    watermark.bitmap = ShaderUtil.crateTextImage(currentDate, 50, "#ffeedd", "#00000000", 0)
                }
            }
            watermark.textureId = ShaderUtil.loadBitmapTexture(watermark.bitmap!!)
            Log.d(TAG," watermark.textureId ${ watermark.textureId}")
        }
        initBuffers()
      //  initBuffers()
    }
    private fun updateWatermarks1() {
        watermarks.forEach { watermark ->
             if (watermark.shouldUpdate){ //更新
               val updateBitmaps =  cameraPreview.getRealUpdateVideoWaterMarksBitMap()
                 if (updateBitmaps.size >0){
                     watermark.textureId = ShaderUtil.loadBitmapTexture(updateBitmaps[0].bitmap)
                 }
             }
        }
        initBuffers()
    }
    override fun onDrawFrame() {
       // Log.d(TAG,"watermarkbit onDrawFrame")
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastWatermarkUpdateTime >= 1000) {
           // Log.d(TAG,"call watermarkbit onDrawFrame")
            updateWatermarks1()
            lastWatermarkUpdateTime = currentTime
        }

        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
        GLES20.glClearColor(1f, 0f, 0f, 1f)

        GLES20.glUseProgram(program)
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, vboId)

        // Draw main texture
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
        GLES20.glEnableVertexAttribArray(vPosition)
        GLES20.glVertexAttribPointer(vPosition, 2, GLES20.GL_FLOAT, false, 8, 0)
        GLES20.glEnableVertexAttribArray(fPosition)
        GLES20.glVertexAttribPointer(fPosition, 2, GLES20.GL_FLOAT, false, 8, vertexData.size * 4)
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)

        // Draw each watermark
        watermarks.forEachIndexed { i, watermark ->
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, watermark.textureId)
            GLES20.glEnableVertexAttribArray(vPosition)
            GLES20.glVertexAttribPointer(vPosition, 2, GLES20.GL_FLOAT, false, 8, (i + 1) * 8 * 4)
            GLES20.glEnableVertexAttribArray(fPosition)
            GLES20.glVertexAttribPointer(
                fPosition,
                2,
                GLES20.GL_FLOAT,
                false,
                8,
                vertexData.size * 4
            )
            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
        }

        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, 0)
    }
}
