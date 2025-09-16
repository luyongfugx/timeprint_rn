package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils


import android.content.Context
import android.graphics.*
import android.opengl.GLES20
import android.opengl.GLUtils
import android.util.Log
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.nio.ByteBuffer

object ShaderUtil {

    @Throws(IOException::class)
    fun readRawTExt(context: Context, rawId: Int): String {
        context.resources.openRawResource(rawId).use { inputStream ->
            BufferedReader(InputStreamReader(inputStream)).use { reader ->
                val stringBuilder = StringBuilder()
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    stringBuilder.append(line).append("\n")
                }
                return stringBuilder.toString()
            }
        }
    }

    fun loadShader(shaderType: Int, source: String): Int {
        val shader = GLES20.glCreateShader(shaderType)
        if (shader != 0) {
            GLES20.glShaderSource(shader, source)
            GLES20.glCompileShader(shader)
            val compile = IntArray(1)
            GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compile, 0)
            if (compile[0] != GLES20.GL_TRUE) {
                val info = GLES20.glGetShaderInfoLog(shader)
                Log.d("ShaderUtil", "shader compile error: $info")
                GLES20.glDeleteShader(shader)
                return 0
            }
        }
        return shader
    }

    fun createProgram(vertexSource: String, fragmentSource: String): Int {
        val vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, vertexSource)
        if (vertexShader == 0) {
            return 0
        }

        val fragmentShader = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource)
        if (fragmentShader == 0) {
            return 0
        }

        val program = GLES20.glCreateProgram()
        if (program != 0) {
            GLES20.glAttachShader(program, vertexShader)
            GLES20.glAttachShader(program, fragmentShader)
            GLES20.glLinkProgram(program)

            val linkStatus = IntArray(1)
            GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, linkStatus, 0)
            if (linkStatus[0] != GLES20.GL_TRUE) {
                Log.d("ShaderUtil", "link shader error")
                GLES20.glDeleteProgram(program)
                return 0
            }
        }
        Log.d("ShaderUtil", "link shader success")
        return program
    }

    /**
     * 根据传入的文字和颜色以及尺寸生成一张对应的带文字的Bitmap
     * @param text 文字内容
     * @param textSize 文字尺寸
     * @param textColor 文字颜色
     * @param bgColor 背景颜色
     * @param padding 内边距
     * @return 生成的Bitmap
     */
    fun crateTextImage(
        text: String,
        textSize: Int,
        textColor: String,
        bgColor: String,
        padding: Int
    ): Bitmap {
        return Paint().apply {
            isAntiAlias = true
            style = Paint.Style.FILL
            this.textSize = textSize.toFloat()
            color = Color.parseColor(textColor)
        }.let { paint ->
            val textWidth = paint.measureText(text, 0, text.length)
            val top = paint.fontMetrics.top
            val bottom = paint.fontMetrics.bottom
            Bitmap.createBitmap(
                (textWidth + 2 * padding).toInt(),
                (bottom - top + 2 * padding).toInt(),
                Bitmap.Config.ARGB_4444
            ).apply {
                Canvas(this).apply {
                    drawColor(Color.parseColor(bgColor))
                    // padding, -top + padding是基于当前的Canvas的坐标系指定的文字的baseline的最左边的点的坐标
                    drawText(text, padding.toFloat(), -top + padding, paint)
                }
            }
        }
    }

    /**
     * 根据传入的Bitmap生成一个新的纹理对象
     * @param bitmap 要生成纹理的Bitmap
     * @return 纹理ID
     */
    fun loadBitmapTexture(flippedBitmap: Bitmap): Int {
        val textureIds = IntArray(1)
        GLES20.glGenTextures(1, textureIds, 0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureIds[0])
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_REPEAT)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_REPEAT)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
//        val bitmap = Bitmap.createBitmap(flippedBitmap, 0, 0, flippedBitmap.width, flippedBitmap.height, Matrix().apply {
//            preScale(1f, -1f)
//        }, true)
        val bitmap = flippedBitmap
        ByteBuffer.allocate(bitmap.width * bitmap.height * 4).apply {
            bitmap.copyPixelsToBuffer(this)
            flip()
            GLES20.glTexImage2D(
                GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA, bitmap.width, bitmap.height, 0,
                GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, this
            )
        }
        return textureIds[0]
    }

    fun loadTexrute(src: Int, context: Context): Int {
        val textureIds = IntArray(1)
        GLES20.glGenTextures(1, textureIds, 0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureIds[0])

        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_REPEAT)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_REPEAT)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)

        BitmapFactory.decodeResource(context.resources, src).apply {
            GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, this, 0)
            recycle()
        }
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
        return textureIds[0]
    }
}