package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.egl


import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.opengl.GLES20
import android.opengl.GLUtils
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import java.text.SimpleDateFormat
import java.util.*
import android.opengl.Matrix.orthoM
import android.util.Log
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.ShaderUtil


class FboRender(private val context: Context) {
    private val TAG ="FboRender"
    private val projectionMatrix = FloatArray(16)
    private var uMatrixLocation = 0
    private var lastWatermarkUpdateTime = 0L

    private lateinit var vertexBuffer: FloatBuffer
    private lateinit var fragmentBuffer: FloatBuffer
    private lateinit var vertexData: FloatArray
    private lateinit var fragmentData: FloatArray

    private var program = 0
    private var vPosition = 0
    private var fPosition = 0
    private var vboId = 0

    private  var currentWidth: Int = 0
    private  var currentHeight: Int = 0
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd hh:mm:ss", Locale.getDefault())
    private val watermarks = mutableListOf<Watermark>()
    init {
        initBuffers()
        // Add default date watermark
        // 假设默认屏幕尺寸为1080x1920，实际会在onChange中更新
//        addWatermark(
//            text = dateFormat.format(Date()),
//            textSize = 50,
//            textColor = "#ffeedd",
//            bgColor = "#00000000",
//            pixelX = 50,  // 距离左侧50像素
//            pixelY = 50,  // 距离顶部50像素
//            pixelHeight = 100 // 高度100像素
//        )
//        // 图片水印 (timeprint.png)
//        addImageWatermark(
//            imageResId = R.drawable.timeprint,
//            pixelX = 300,  // 距离左侧100像素
//            pixelY = 100,  // 距离顶部100像素
//            pixelHeight = 150 // 高度150像素
//        )
    }

    data class Watermark(
        var bitmap: Bitmap? = null,
        var imageResId: Int = 0,
        var textureId: Int = 0,
        val pixelX: Int,
        val pixelY: Int,
        val pixelHeight: Int,
        var screenWidth: Int,
        var screenHeight: Int
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
            // 将像素X坐标转换为OpenGL坐标系(-1到1)
            return (pixelX.toFloat() / screenWidth.toFloat()) * 2f - 1f
        }

        fun getNormalizedY(): Float {
            // 将像素Y坐标转换为OpenGL坐标系(-1到1)，注意Y轴方向相反
            return 1f - (pixelY.toFloat() / screenHeight.toFloat()) * 2f
        }

        fun getNormalizedHeight(): Float {
            // 将像素高度转换为OpenGL坐标系中的高度(0到2)
            return pixelHeight.toFloat() / screenHeight.toFloat() * 2f
        }
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
        var watermark = Watermark(
            imageResId = imageResId,
            pixelX = pixelX,
            pixelY = pixelY,
            pixelHeight = pixelHeight,
            screenWidth = currentWidth,
            screenHeight = currentHeight
        )
        var bitmap = BitmapFactory.decodeResource(context.resources, imageResId).apply {
            GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, this, 0)
            // recycle()
        }
        watermark.bitmap = bitmap
        watermarks.add(watermark)
        initBuffers()
    }

    private fun initBuffers() {
        // Each watermark needs 4 vertices (x,y) * 4 + main texture (4 vertices)
        vertexData = FloatArray(8 * (watermarks.size + 1))
        fragmentData = FloatArray(8 * (watermarks.size + 1))
        vertexData[0] = -1f; vertexData[1] = -1f
        vertexData[2] = 1f; vertexData[3] = -1f
        vertexData[4] = -1f; vertexData[5] = 1f
        vertexData[6] = 1f; vertexData[7] = 1f

        fragmentData[0] = 0f;
        fragmentData[1] = 0f
        fragmentData[2] = 1f;
        fragmentData[3] = 0f
        fragmentData[4] = 0f;
        fragmentData[5] = 1f
        fragmentData[6] = 1f;
        fragmentData[7] = 1f

        // Set vertices and texture coordinates for each watermark
        watermarks.forEachIndexed { i, watermark ->
            val baseIndex = 8 * (i + 1)
            // 更新屏幕尺寸
            watermark.screenWidth = currentWidth
            watermark.screenHeight = currentHeight

            // 获取实际像素尺寸的比例
            val pixelRatio = 1.0f * watermark.bitmap!!.width / watermark.bitmap!!.height

            // 计算归一化高度和宽度
            val height = watermark.getNormalizedHeight()
            val width = height * pixelRatio * (currentHeight.toFloat() / currentWidth.toFloat())

            // 计算归一化坐标
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

            // Corrected texture coordinates (flipped vertically to match OpenGL)
            // ✅ 正确坐标（与 Bitmap 坐标一致）
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

        // 更新VBO数据
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

    fun onCreate() {
        try {
            GLES20.glEnable(GLES20.GL_BLEND)
            GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)
// 修改ShaderUtil.loadBitmapTexture()或添加以下代码：
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
//            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
//            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
            val vertexSource = ShaderUtil.readRawTExt(context, R.raw.vertex_shader_screen)
            val fragmentSource = ShaderUtil.readRawTExt(context, R.raw.fragment_shader_screen)
//            val vertexSource = ShaderUtil.readRawTExt(context, R.raw.vertex_shader)
//            val fragmentSource = ShaderUtil.readRawTExt(context, R.raw.fragment_shader)
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

    private fun updateWatermarks() {
        watermarks.forEach { watermark ->
            //if (watermark.bitmap.isRecycled) {
            val currentDate = dateFormat.format(Date())
            if (watermark.imageResId > 0) {
                //  watermark.bitmap = ShaderUtil.crateTextImage(currentDate, 50, "#ffeedd", "#00000000", 0)
                watermark.textureId = ShaderUtil.loadBitmapTexture(watermark.bitmap!!)
            } else {
                watermark.bitmap =
                    ShaderUtil.crateTextImage(currentDate, 50, "#ffeedd", "#00000000", 0)
                watermark.textureId = ShaderUtil.loadBitmapTexture(watermark.bitmap!!)
            }

            // }
        }
        initBuffers()
    }

    fun onChange(width: Int, height: Int) {
        if (currentWidth!= width && currentHeight!=height){
            currentWidth = width
            currentHeight = height
            // 更新所有水印的屏幕尺寸
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
            initBuffers() // 屏幕尺寸变化时重新计算坐标
        }

    }

    fun onDraw(textureId: Int) {
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastWatermarkUpdateTime >= 1000) {
            updateWatermarks()
            lastWatermarkUpdateTime = currentTime
        }

        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
        GLES20.glClearColor(0f, 0f, 0f, 1f)
    // GLES20.glClearColor(1f, 0f, 0f, 1f)
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