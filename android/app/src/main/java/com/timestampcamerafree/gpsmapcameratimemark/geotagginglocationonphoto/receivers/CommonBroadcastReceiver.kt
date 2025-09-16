package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * 公共的消息
 *
 * @property commonBack
 */
class CommonBroadcastReceiver (private val commonBack: CommonBack?) : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        commonBack?.onMessage(intent)
    }
    fun interface CommonBack {
        fun onMessage(intent:Intent)
    }
}