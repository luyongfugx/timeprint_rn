package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Point
import android.graphics.Rect
import android.graphics.RectF
import android.net.Uri
import android.util.Log
import android.view.View
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.MySize
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.modelsdata.WatermarkBitmap
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.sqrt

object BitmapUtils {
    private const val TAG = "BitmapUtils"
    private const val INLINE_BITMAP_MAX_PIXEL_NUM = 50 * 1024



    fun getRelativePositionRecursive(childView: View, ancestorView: View): Point? {
        if (childView == null || ancestorView == null) {
            return null
        }

        var currentView: View = childView
        var relativeX = 0
        var relativeY = 0

        // 向上遍历父视图链
        while (currentView != ancestorView && currentView.parent is View) {
            relativeX += currentView.left
            relativeY += currentView.top
            currentView = currentView.parent as View
        }

        // 如果遍历到根布局或某个不是 ancestorView 的 View，则说明 ancestorView 不是 childView 的祖先
        if (currentView != ancestorView) {
            return null // ancestorView is not an ancestor of childView
        }

        // 最后加上 ancestorView 自身的 left/top (如果需要的话，这取决于你定义“相对”的起点)
        // 通常我们希望的是 childView 相对于 ancestorView 的内容区域，所以不加 ancestorView.left/top
        // 如果 ancestorView 本身在屏幕上有偏移，那么 getLocationInWindow 是更好的选择。
        // 这里的 left/top 是相对于其直接父布局的。
        // 如果 ancestorView 是你整个屏幕的根布局，那么它的 left/top 通常是0。

        return Point(relativeX, relativeY)
    }

// 如何使用
// val childView = findViewById<View>(R.id.my_grandchild_view)
// val ancestorView = findViewById<View>(R.id.my_ancestor_view)
// val relativePos = getRelativePositionRecursive(childView, ancestorView)
// if (relativePos != null) {
//     Log.d("Position", "Child X: ${relativePos.x}, Child Y: ${relativePos.y} relative to ancestor's content area")
// }
    /**
     * 获取相对坐标
     *
     * @param childView
     * @param ancestorView
     * @return
     */
    fun getRelativePosition(childView: View, ancestorView: View): Point? {
        val childLocation = IntArray(2)
        childView.getLocationInWindow(childLocation) // 获取子View相对于窗口的坐标

        val ancestorLocation = IntArray(2)
        ancestorView.getLocationInWindow(ancestorLocation) // 获取祖先View相对于窗口的坐标
        Log.d(TAG,"childLocation ${childLocation[0]} ${childLocation[1]} ancestorLocation ${ancestorLocation[0]} ${ancestorLocation[0]}")
        val relativeX = childLocation[0] - ancestorLocation[0]
        val relativeY = childLocation[1] - ancestorLocation[1]

        return Point(relativeX, relativeY)
    }
    fun getViewBitmap(view: View,orientation:Int,resolution:MySize?): WatermarkBitmap? {
        try {
            val left = view.left
            val top = view.top
            val bitmap = Bitmap.createBitmap(view.width,
                view.height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            view.draw(canvas)
            val mutableBitmap = bitmap.copy(Bitmap.Config.ARGB_8888, true);
            return WatermarkBitmap(mutableBitmap, left.toFloat(), top.toFloat(),orientation)
        }
        catch (e:Exception){
            Log.d(TAG,"$e")
        }

        return null

    }
    /**
     * Downloads an image from the given URL and returns it as a Bitmap
     * @param imageUrl The URL of the image to download
     * @return The downloaded Bitmap or null if download failed
     */
    fun getBitmapFromUrl(imageUrl: String): Bitmap? {
        return try {
            val url = java.net.URL(imageUrl)
            val connection = url.openConnection() as java.net.HttpURLConnection
            connection.doInput = true
            connection.connect()
            val input = connection.inputStream
            BitmapFactory.decodeStream(input)
        } catch (e: Exception) {
            Log.e(TAG, "Error downloading image from URL: $imageUrl", e)
            null
        }
    }
    /**
     * 合并两个图片
     *
     * @param src
     * @param addBitmap
     * @return
     */
    fun mergeBitmap(src:WatermarkBitmap,addBitmap:WatermarkBitmap):Bitmap{
        val mutableBitmap = src.bitmap.copy(Bitmap.Config.ARGB_8888, true);
        val canvas = Canvas(mutableBitmap)
        var scaledWatermarkBitmap = addBitmap.bitmap
        // 源矩形，表示要绘制的 Bitmap 部分
        val src = Rect(0, 0, scaledWatermarkBitmap.width, scaledWatermarkBitmap.height)
        val dstR = addBitmap.x+scaledWatermarkBitmap.width.toFloat()
        val dstB = addBitmap.y+scaledWatermarkBitmap.height.toFloat()
        //目标位置
        val dst = RectF(
            addBitmap.x,
            addBitmap.y,
            dstR,
            dstB
        )
        canvas.drawBitmap(scaledWatermarkBitmap, src, dst, null)
        return mutableBitmap
    }
    fun compressBitmap2InputStream(bitmap: Bitmap, quality: Int = 50): InputStream {
        val outputStream = ByteArrayOutputStream()
       // compressedBitmap.compress(format, quality, byteArrayOutputStream)
        bitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)

        val byteArray = outputStream.toByteArray()
        return ByteArrayInputStream(byteArray)
    }
    fun makeBitmap(jpegData: ByteArray, maxNumOfPixels: Int = INLINE_BITMAP_MAX_PIXEL_NUM): Bitmap? {
        return try {
            val options = BitmapFactory.Options()
            options.inJustDecodeBounds = true

            BitmapFactory.decodeByteArray(jpegData, 0, jpegData.size, options)

            if (options.mCancel || options.outWidth == -1 || options.outHeight == -1) {
                return null
            }
            options.inSampleSize = computeSampleSize(options, -1, maxNumOfPixels)
            options.inJustDecodeBounds = false
            options.inDither = false
            options.inPreferredConfig = Bitmap.Config.ARGB_8888
            BitmapFactory.decodeByteArray(
                jpegData, 0, jpegData.size,
                options
            )
        } catch (ex: OutOfMemoryError) {
            null
        }
    }

    private fun computeSampleSize(options: BitmapFactory.Options, minSideLength: Int, maxNumOfPixels: Int): Int {
        val initialSize = computeInitialSampleSize(
            options, minSideLength,
            maxNumOfPixels
        )
        var roundedSize: Int
        if (initialSize <= 8) {
            roundedSize = 1
            while (roundedSize < initialSize) {
                roundedSize = roundedSize shl 1
            }
        } else {
            roundedSize = (initialSize + 7) / 8 * 8
        }
        return roundedSize
    }

    private fun computeInitialSampleSize(options: BitmapFactory.Options, minSideLength: Int, maxNumOfPixels: Int): Int {
        val w = options.outWidth.toDouble()
        val h = options.outHeight.toDouble()
        val lowerBound = if (maxNumOfPixels < 0) 1 else ceil(sqrt(w * h / maxNumOfPixels)).toInt()
        val upperBound = if (minSideLength < 0) 128 else floor(w / minSideLength).coerceAtMost(floor(h / minSideLength)).toInt()
        if (upperBound < lowerBound) {
            // return the larger one when there is no overlapping zone.
            return lowerBound
        }
        return if (maxNumOfPixels < 0 && minSideLength < 0) {
            1
        } else if (minSideLength < 0) {
            lowerBound
        } else {
            upperBound
        }
    }
    fun saveProcessedBitmap(bitmap: Bitmap,dir:File,fileName:String): Uri {
        val file = File(dir, fileName)
        try {
            FileOutputStream(file).use { out ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            }
        } catch (e: IOException) {
            Log.e(TAG, "Error saving processed bitmap", e)
        }
        return Uri.fromFile(file)
    }
    /**
     * 将资源图片保存到指定目录
     * @param resId 资源ID (如R.drawable.timeprint)
     * @param dir 保存目录
     * @param fileName 保存文件名（包含扩展名）
     * @return 保存后的图片Uri，如果转换失败返回null
     */
    fun saveResourceToFile(resId: Int, dir: File, fileName: String): Uri? {
        return try {
            // 从资源加载Bitmap
            val bitmap = BitmapFactory.decodeResource(App.context.resources, resId)
                ?: return null

            // 确保目录存在
            if (!dir.exists()) {
                dir.mkdirs()
            }

            // 创建目标文件
            val outputFile = File(dir, fileName)

            // 保存图片
            FileOutputStream(outputFile).use { out ->
                if (!bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)) {
                    throw IOException("Failed to compress bitmap")
                }
            }

            // 回收Bitmap内存
            bitmap.recycle()

            Uri.fromFile(outputFile)
        } catch (e: Exception) {
            Log.e(TAG, "Error saving resource to file", e)
            null
        }
    }
    /**
     * 将Base64字符串转换为图片并保存
     * @param base64String Base64编码的图片字符串
     * @param dir 保存目录
     * @param fileName 保存文件名（不需要包含扩展名）
     * @return 保存后的图片Uri，如果转换失败返回null
     */
    fun saveBase64ToImage(base64String: String, dir: File, fileName: String): Uri? {
        return try {
            // 移除可能的Base64前缀(如"data:image/png;base64,")
            val pureBase64 = if (base64String.contains(",")) {
                base64String.substringAfterLast(",")
            } else {
                base64String
            }

            // 解码Base64字符串
            val decodedBytes = android.util.Base64.decode(pureBase64, android.util.Base64.DEFAULT)

            // 创建Bitmap
            val options = BitmapFactory.Options().apply {
                inPreferredConfig = Bitmap.Config.ARGB_8888
            }
            val bitmap = BitmapFactory.decodeByteArray(decodedBytes, 0, decodedBytes.size, options)
                ?: return null

            // 创建目标文件（自动添加.png扩展名）
            val outputFile = File(dir, "$fileName")

            // 保存图片
            FileOutputStream(outputFile).use { out ->
                if (!bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)) {
                    throw IOException("Failed to compress bitmap")
                }
            }

            // 回收Bitmap内存
            bitmap.recycle()

            Uri.fromFile(outputFile)
        } catch (e: Exception) {
            Log.e(TAG, "Error converting base64 to image", e)
            null
        }
    }
}
