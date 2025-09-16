package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers

import android.annotation.SuppressLint
import android.content.ContentResolver
import android.content.ContentValues
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.RectF
import android.net.Uri
import android.provider.MediaStore
import android.util.Log
import android.webkit.WebStorage.Origin
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCapture.Metadata
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.ImageProxy
import androidx.camera.core.internal.compat.workaround.ExifRotationAvailability
import androidx.exifinterface.media.ExifInterface
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.copyTo
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.ImageUtil.CodecFailedException
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.ImageUtil.bitmapToJpegByteArray
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.ImageUtil.imageToJpegByteArray
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.ImageUtil.jpegImageToJpegByteArray
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.MediaOutput
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.modelsdata.WatermarkBitmap
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpKits


import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.TencentCOSUtils
import java.io.*
import java.util.*
import kotlin.math.abs

/**
 * Inspired by
 * @see androidx.camera.core.ImageSaver
 * */
class ImageSaver private constructor(
    private val contentResolver: ContentResolver,
    private val image: ImageProxy?,
    private val watermarkBitmaps: List<WatermarkBitmap>?,
    private val mediaOutput: MediaOutput.ImageCaptureOutput,
    private val metadata: Metadata,
    private val jpegQuality: Int,
    private val saveExifAttributes: Boolean,
    private val onImageSaved: (Uri) -> Unit,
    private val flipHorizontally: Boolean? = false,
    private val saveOrigin: Boolean? = false,
    private val onError: (ImageCaptureException) -> Unit,
) {

    companion object {
        private const val TEMP_FILE_PREFIX = "Timeprint"
        private const val TEMP_FILE_SUFFIX = ".tmp"
        private const val COPY_BUFFER_SIZE = 1024
        private const val PENDING = 1
        private const val NOT_PENDING = 0
        private const val TAG = "ImageSaver"
        fun saveImage(
            contentResolver: ContentResolver,
            image: ImageProxy,
            mediaOutput: MediaOutput.ImageCaptureOutput,
            metadata: Metadata,
            jpegQuality: Int,
            saveOrigin: Boolean ?= false,
            saveExifAttributes: Boolean,
            watermarkBitmaps : MutableList<WatermarkBitmap>?,
            onImageSaved: (Uri) -> Unit,
            flipHorizontally: Boolean? = false,
            onError: (ImageCaptureException) -> Unit,
        ) = ImageSaver(
            contentResolver = contentResolver,
            image = image,
            mediaOutput = mediaOutput,
            metadata = metadata,
            jpegQuality = jpegQuality,
            saveOrigin = saveOrigin,
            saveExifAttributes = saveExifAttributes,
            onImageSaved = onImageSaved,
            flipHorizontally = flipHorizontally,
            onError = onError,
            watermarkBitmaps = watermarkBitmaps
        ).saveImage()
    }

    fun saveImage() {
        ensureBackgroundThread {
            // Save the image to a temp file first. This is necessary because ExifInterface only
            // supports saving to File.
            //保存原图
            if (saveOrigin == true){
                val originTempFIle = saveOriginToTempFile()
                if (originTempFIle != null) {
                    copyTempFileToDestination(originTempFIle)
                }
            }

            val tempFile = saveImageToTempFile()
            if (tempFile != null) {
                copyTempFileToDestination(tempFile)
            }
        }
    }

    private fun flipVertically(bitmap: Bitmap): Bitmap {
        // 创建一个 Matrix 对象
        val matrix = Matrix()

        // 设置垂直翻转的缩放变换
        matrix.postScale(1f, -1f, bitmap.width / 2f, bitmap.height / 2f)

        // 使用变换后的 Matrix 创建新的 Bitmap 对象
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }
    //获取图片镜像，前置摄像头使用
    private  fun flipBitmapHorizontally(bitmap: Bitmap): Bitmap {
        val matrix = Matrix()
        matrix.postScale(-1f, 1f, bitmap.width / 2f, bitmap.height / 2f)
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }
    private fun addWatermark(sBitmap: Bitmap, watermarkBitmaps: List<WatermarkBitmap>,rotateDegree:Int?,metadata: Metadata): Bitmap {
        //如果需要镜像，前置

        // Log.d(TAG,"addWatermark isReversedHorizontal ${metadata.isReversedHorizontal} isReversedVertical ${metadata.isReversedVertical}")
        var flipImage = if (metadata.isReversedHorizontal) flipBitmapHorizontally(sBitmap) else sBitmap
        flipImage = if (metadata.isReversedVertical) flipVertically(flipImage) else flipImage
        val matrix = Matrix()
        // Log.d(TAG,"addWatermark rotateDegree ${rotateDegree} watermarkBitmaps[0].rotateDegree!! ${watermarkBitmaps[0].rotateDegree!!}")
//        val errorText ="addWatermark rotateDegree ${rotateDegree} watermarkBitmaps[0].rotateDegree!! ${watermarkBitmaps[0].rotateDegree!!}"
//        TencentCOSUtils.uploadErrorLog(App.context,errorText,"addWatermark_rotate")
        val imageDegree = watermarkBitmaps[0].rotateDegree!!
        if (metadata.isReversedHorizontal){
            rotateDegree?.toFloat()?.let { matrix.postRotate((0f-rotateDegree-imageDegree)) }
        }
        else {
            rotateDegree?.toFloat()?.let { matrix.postRotate(rotateDegree.toFloat()-imageDegree) }
        }


        val rotateBitmap = Bitmap.createBitmap(flipImage, 0, 0, flipImage.width, flipImage.height, matrix, true)
        val mutableBitmap = rotateBitmap.copy(Bitmap.Config.ARGB_8888, true);
        val canvas = Canvas(mutableBitmap)
        val srcImgWidth = mutableBitmap.width.toFloat()
        //计算一下比率
        val scale =  srcImgWidth/GpKits.Device.getScreenWidth(App.context)
        watermarkBitmaps.forEach { watermarkBitmap ->
            val scaledWatermarkBitmap = watermarkBitmap.bitmap
            // 源矩形，表示要绘制的 Bitmap 部分
            val src = Rect(0, 0, scaledWatermarkBitmap.width, scaledWatermarkBitmap.height)
            val x = watermarkBitmap.x*scale
            val y = watermarkBitmap.y*scale
            val dstR = x+scaledWatermarkBitmap.width.toFloat()*scale
            val dstB = y+scaledWatermarkBitmap.height.toFloat()*scale
            //目标位置
            val dst = RectF(
                x,
                y,
                dstR,
                dstB
            )
            canvas.drawBitmap(scaledWatermarkBitmap, src, dst, null)
        }
        return mutableBitmap
    }
    @SuppressLint("RestrictedApi")
    private fun saveOriginToTempFile():File?{
        var saveError: SaveError? = null
        var errorMessage: String? = null
        var exception: Exception? = null
        val tempFile = try {
            if (mediaOutput is MediaOutput.FileMediaOutput) {
                // For saving to file, write to the target folder and rename for better performance.
                File(
                    mediaOutput.file.parent,
                    TEMP_FILE_PREFIX + UUID.randomUUID().toString() + TEMP_FILE_SUFFIX
                )
            } else {
                File.createTempFile(TEMP_FILE_PREFIX, TEMP_FILE_SUFFIX)
            }

        } catch (e: IOException) {
            Log.d(TAG,"saveImageToTempFile tempfile error")
            postError(SaveError.FILE_IO_FAILED, "Error saving temp file", e)
            return null
        }

        try {
            val output = FileOutputStream(tempFile)
            val byteArray: ByteArray? = image?.let { imageToJpegByteArray(it, jpegQuality) }


            output.write(byteArray)

            if (saveExifAttributes) {
                val exifInterface = ExifInterface(tempFile)
                val imageByteArray = image?.let { jpegImageToJpegByteArray(it) }
                val inputStream: InputStream = ByteArrayInputStream(imageByteArray)
                ExifInterface(inputStream).copyTo(exifInterface)
//                if (image?.imageInfo?.rotationDegrees != 0 || metadata.isReversedHorizontal || metadata.isReversedVertical) {
//                    exifInterface.rotate(image?.imageInfo?.rotationDegrees!!)
//                }
                if (!ExifRotationAvailability().shouldUseExifOrientation(image!!)) {
                    exifInterface.rotate(image!!.imageInfo!!.rotationDegrees)
                }
                if (metadata.isReversedHorizontal) {
                    exifInterface.flipHorizontally()
                }

                if (metadata.isReversedVertical) {
                    exifInterface.flipVertically()
                }
                if (metadata.location != null) {
                    exifInterface.setGpsInfo(metadata.location)
                }
                exifInterface.saveAttributes()
            }
        } catch (e: IOException) {

            saveError = SaveError.FILE_IO_FAILED
            errorMessage = "Failed to write temp file"
            exception = e
        } catch (e: IllegalArgumentException) {
            saveError = SaveError.FILE_IO_FAILED
            errorMessage = "Failed to write temp file"
            exception = e
        } catch (e: CodecFailedException) {
            when (e.failureType) {
                CodecFailedException.FailureType.ENCODE_FAILED -> {
                    saveError = SaveError.ENCODE_FAILED
                    errorMessage = "Failed to encode Image"
                }
                CodecFailedException.FailureType.DECODE_FAILED -> {
                    saveError = SaveError.CROP_FAILED
                    errorMessage = "Failed to crop Image"
                }
                CodecFailedException.FailureType.UNKNOWN -> {
                    saveError = SaveError.UNKNOWN
                    errorMessage = "Failed to transcode Image"
                }
            }
            exception = e
        }

        if (saveError != null) {
            postError(saveError, errorMessage, exception)
            tempFile.delete()
            return null
        }

        return tempFile
    }
    @SuppressLint("RestrictedApi")
    private fun saveImageToTempFile(): File? {
        var saveError: SaveError? = null
        var errorMessage: String? = null
        var exception: Exception? = null
        val tempFile = try {
            if (mediaOutput is MediaOutput.FileMediaOutput) {
                // For saving to file, write to the target folder and rename for better performance.
                File(
                    mediaOutput.file.parent,
                    TEMP_FILE_PREFIX + UUID.randomUUID().toString() + TEMP_FILE_SUFFIX
                )
            } else {
                File.createTempFile(TEMP_FILE_PREFIX, TEMP_FILE_SUFFIX)
            }

        } catch (e: IOException) {
            Log.d(TAG,"saveImageToTempFile tempfile error")
            postError(SaveError.FILE_IO_FAILED, "Error saving temp file", e)
            return null
        }

        try {
            val output = FileOutputStream(tempFile)
            val rotateDegree = image?.imageInfo?.rotationDegrees
            val byteArray: ByteArray? = watermarkBitmaps?.let {
                image?.toBitmap()?.let { it1 ->
                    addWatermark(it1,watermarkBitmaps,rotateDegree,metadata=metadata)?.let {
                        bitmapToJpegByteArray(it, jpegQuality)
                    }
                }
            } ?: run {
                image?.let { imageToJpegByteArray(it, jpegQuality) }
            }

            output.write(byteArray)

            if (saveExifAttributes) {
                val exifInterface = ExifInterface(tempFile)
                val imageByteArray = image?.let { jpegImageToJpegByteArray(it) }
                val inputStream: InputStream = ByteArrayInputStream(imageByteArray)
                ExifInterface(inputStream).copyTo(exifInterface)
                if (image?.imageInfo?.rotationDegrees != 0 || metadata.isReversedHorizontal || metadata.isReversedVertical) {
                    exifInterface.rotate(0- image?.imageInfo?.rotationDegrees!!)
                }
//                if (metadata.isReversedHorizontal) {
//                    exifInterface.flipHorizontally()
//                }

//                if (metadata.isReversedVertical) {
//                    exifInterface.flipVertically()
//                }

                if (metadata.location != null) {
                    exifInterface.setGpsInfo(metadata.location)
                }
                exifInterface.saveAttributes()
            }
        } catch (e: IOException) {

            saveError = SaveError.FILE_IO_FAILED
            errorMessage = "Failed to write temp file"
            exception = e
        } catch (e: IllegalArgumentException) {
            saveError = SaveError.FILE_IO_FAILED
            errorMessage = "Failed to write temp file"
            exception = e
        } catch (e: CodecFailedException) {
            when (e.failureType) {
                CodecFailedException.FailureType.ENCODE_FAILED -> {
                    saveError = SaveError.ENCODE_FAILED
                    errorMessage = "Failed to encode Image"
                }
                CodecFailedException.FailureType.DECODE_FAILED -> {
                    saveError = SaveError.CROP_FAILED
                    errorMessage = "Failed to crop Image"
                }
                CodecFailedException.FailureType.UNKNOWN -> {
                    saveError = SaveError.UNKNOWN
                    errorMessage = "Failed to transcode Image"
                }
            }
            exception = e
        }

        if (saveError != null) {
            postError(saveError, errorMessage, exception)
            tempFile.delete()
            return null
        }

        return tempFile
    }

    /**
     * Copy the temp file to user specified destination.
     *
     *
     *  The temp file will be deleted afterwards.
     */
    private fun copyTempFileToDestination(tempFile: File) {
        var saveError: SaveError? = null
        var errorMessage: String? = null
        var exception: java.lang.Exception? = null
        var outputUri: Uri? = null
        try {
            when (mediaOutput) {
                is MediaOutput.MediaStoreOutput -> {
                    val values = mediaOutput.contentValues
                    setContentValuePending(values, PENDING)
                    outputUri = contentResolver.insert(
                        mediaOutput.contentUri, values
                    )
                    if (outputUri == null) {
                        saveError = SaveError.FILE_IO_FAILED
                        errorMessage = "Failed to insert URI."
                    } else {
                        if (!copyTempFileToUri(tempFile, outputUri)) {
                            saveError = SaveError.FILE_IO_FAILED
                            errorMessage = "Failed to save to URI."
                        }
                        setUriNotPending(outputUri)
                    }
                }

                is MediaOutput.OutputStreamMediaOutput -> {
                    copyTempFileToOutputStream(tempFile, mediaOutput.outputStream)
                    outputUri = mediaOutput.uri
                }

                is MediaOutput.FileMediaOutput -> {
                    val targetFile: File = mediaOutput.file
                    // Normally File#renameTo will overwrite the targetFile even if it already exists.
                    // Just in case of unexpected behavior on certain platforms or devices, delete the
                    // target file before renaming.
                    if (targetFile.exists()) {
                        targetFile.delete()
                    }
                    if (!tempFile.renameTo(targetFile)) {
                        saveError = SaveError.FILE_IO_FAILED
                        errorMessage = "Failed to rename file."
                    }
                    outputUri = Uri.fromFile(targetFile)
                }

                MediaOutput.BitmapOutput -> throw UnsupportedOperationException("Bitmap output cannot be saved to disk")
            }
        } catch (e: IOException) {
            saveError = SaveError.FILE_IO_FAILED
            errorMessage = "Failed to write destination file."
            exception = e
        } catch (e: IllegalArgumentException) {
            saveError = SaveError.FILE_IO_FAILED
            errorMessage = "Failed to write destination file."
            exception = e
        } finally {
            tempFile.delete()
        }
        Log.d(TAG,"outputUri ${outputUri} onImageSaved ${onImageSaved}")
        outputUri?.let(onImageSaved) ?: postError(saveError!!, errorMessage, exception)
    }

    private fun postError(saveError: SaveError, errorMessage: String?, exception: Exception?) {
        val imageCaptureError = if (saveError == SaveError.FILE_IO_FAILED) {
            ImageCapture.ERROR_FILE_IO
        } else {
            ImageCapture.ERROR_UNKNOWN
        }

        onError.invoke(ImageCaptureException(imageCaptureError, errorMessage!!, exception!!))
    }

    /**
     * Removes IS_PENDING flag during the writing to [Uri].
     */
    private fun setUriNotPending(outputUri: Uri) {
        if (isQPlus()) {
            val values = ContentValues()
            setContentValuePending(values, NOT_PENDING)
            contentResolver.update(outputUri, values, null, null)
        }
    }

    /** Set IS_PENDING flag to [ContentValues].  */
    private fun setContentValuePending(values: ContentValues, isPending: Int) {
        if (isQPlus()) {
            values.put(MediaStore.Images.Media.IS_PENDING, isPending)
        }
    }

    /**
     * Copies temp file to [Uri].
     *
     * @return false if the [Uri] is not writable.
     */
    @Throws(IOException::class)
    private fun copyTempFileToUri(tempFile: File, uri: Uri): Boolean {
        contentResolver.openOutputStream(uri).use { outputStream ->
            if (outputStream == null) {
                // The URI is not writable.
                return false
            }
            copyTempFileToOutputStream(tempFile, outputStream)
        }
        return true
    }

    @Throws(IOException::class)
    private fun copyTempFileToOutputStream(tempFile: File, outputStream: OutputStream) {
        FileInputStream(tempFile).use { inputStream ->
            val buf = ByteArray(COPY_BUFFER_SIZE)
            var len: Int
            while (inputStream.read(buf).also { len = it } > 0) {
                outputStream.write(buf, 0, len)
            }
        }
    }

    /** Type of error that occurred during save  */
    enum class SaveError {
        /** Failed to write to or close the file  */
        FILE_IO_FAILED,

        /** Failure when attempting to encode image  */
        ENCODE_FAILED,

        /** Failure when attempting to crop image  */
        CROP_FAILED, UNKNOWN
    }
}