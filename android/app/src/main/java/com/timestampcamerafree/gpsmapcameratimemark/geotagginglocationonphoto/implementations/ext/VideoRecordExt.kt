package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.implementations.ext

import android.util.Log
import android.widget.Toast
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.encodec.AudioRecorder
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.encodec.BaseMediaEncoder
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.encodec.MediaEncoder
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.implementations.GpGlCameraPreview
import java.io.File
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.min

fun GpGlCameraPreview.glStartRecord() {
        recordFinish = false
        recording = true
        listener.onVideoRecordingStarted()
        audioRecorder = AudioRecorder(object : AudioRecorder.OnPcmDataListener {
            override fun onPcmData(pcmData: ByteArray) {
                if (!recordFinish) {
                    onPcmDataInput(pcmData)
                }
            }
        })
        audioRecorder.init()
        //准备写入数据
        if (mediaEncodec == null) {
            try {

                val fileName = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date()) + ".mp4"
               // val mediaStorageDir = getExternalFilesDir(Environment.DIRECTORY_DCIM)?.let { File(it, "VideoRecorder") }
                val mediaStorageDir = File(config.savePhotosFolder)
                if (!mediaStorageDir.exists()) {
                    if (!mediaStorageDir.mkdirs()) {
                        Log.e(GpGlCameraPreview.TAG, "Failed to create directory: ${mediaStorageDir.absolutePath}")
                        Toast.makeText(activity, "Failed to create recording directory.", Toast.LENGTH_SHORT).show()
                        return
                    }
                }
                val outputPath = File(mediaStorageDir, fileName).absolutePath
                currentVideoPath = outputPath
                //Log.d(GpGlCameraPreview.TAG,"file:"+outputPath)
                //获得OpenGL的FBO渲染的纹理id，通过共享纹理id的方式将图像数据写入MediaCodec
                mediaEncodec = MediaEncoder(
                    activity,
                    glPreviewView.getTextureId()!!,
                    this
                )
               // Log.d(GpGlCameraPreview.TAG,"mediaEncodec size width ${glPreviewView.width} height ${glPreviewView.height}")
               val eglContext = glPreviewView.getEglContext()
                if (eglContext != null){
                    mediaEncodec!!.initEncoder(
                        glPreviewView.getEglContext()!!,
                        outputPath,
                        glPreviewView.width,
                        glPreviewView.height,
                        44100,  // 采样率
                        // 声道数(单声道)
                    )
                    mediaEncodec!!.setOnMediaInfoListener(object :
                        BaseMediaEncoder.OnMediaInfoListener {
                        override fun onMediaTime(times: Long) {
                            //更新时间
                            listener.onVideoDurationChanged(times)
                            Log.d(GpGlCameraPreview.TAG, "time is : $times")
                        }
                    })
                }

                mediaEncodec!!.startRecord()
                //录音
                audioRecorder.startRecording()
            } catch (e: IOException) {
                e.printStackTrace()
                Log.d(GpGlCameraPreview.TAG, "IOException is : $e")
            }
        }

    }



fun GpGlCameraPreview.glStopRecord() {
        audioRecorder.stopRecording()

         recordFinish = true
        recording = false
        //停止写入数据
        mediaEncodec!!.stopRecord()
        mediaEncodec = null
        currentVideoPath?.let { listener.onVideoRecordingStopped(it) }
    }


fun GpGlCameraPreview.onPcmDataInput(pcmData: ByteArray) {
        if (recordFinish) {
            return
        }
        // 分块处理音频数据，确保每块不超过缓冲区大小
        val chunkSize = 1024  // 适当的分块大小
        var offset = 0
        while (offset < pcmData.size) {
            val remaining = pcmData.size - offset
            val currentChunkSize = min(chunkSize, remaining)
            val chunk = ByteArray(currentChunkSize)
            System.arraycopy(pcmData, offset, chunk, 0, currentChunkSize)
            if (mediaEncodec != null) {
                mediaEncodec!!.putPcmData(chunk, chunk.size)
            }
            offset += currentChunkSize
        }
    }
