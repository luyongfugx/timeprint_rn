package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.encodec

import android.annotation.SuppressLint
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log

/**
 * 录音类
 *
 * @property onPcmDataListener
 */
class AudioRecorder(private val onPcmDataListener: OnPcmDataListener) {
    private val TAG = AudioRecorder::class.java.simpleName

    private var audioRecord: AudioRecord? = null
    private var audioThread: Thread? = null
    private var isRecording = false

    private val audioBufferSize = AudioRecord.getMinBufferSize(
        44100,
        AudioFormat.CHANNEL_IN_MONO,
        AudioFormat.ENCODING_PCM_16BIT
    )

    @SuppressLint("MissingPermission")
    fun init() {
        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            44100,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            audioBufferSize * 2
        )
    }

    fun startRecording() {
        //检测一下
        if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
            Log.e("AudioRecord", "AudioRecord initialization failed.");
            audioRecord?.release();
            return;
        }
        audioRecord?.startRecording()
        isRecording = true
        audioThread = Thread {
            val buffer = ByteArray(audioBufferSize)
            while (isRecording) {
                val bytesRead = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                Log.d(TAG, "Audio bytes read: $bytesRead")
                if (bytesRead > 0) {
                    onPcmDataListener.onPcmData(buffer.copyOf(bytesRead))
                }
            }
        }.apply { start() }
    }

    fun stopRecording() {
        isRecording = false
        audioThread?.join()
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
    }

    interface OnPcmDataListener {
        fun onPcmData(pcmData: ByteArray)
    }
}
