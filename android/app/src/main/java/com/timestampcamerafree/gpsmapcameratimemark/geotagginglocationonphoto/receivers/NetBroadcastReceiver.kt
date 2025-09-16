package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkInfo
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App

class NetBroadcastReceiver(private val connectBack: NetConnectBack?) : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (ConnectivityManager.CONNECTIVITY_ACTION == intent.action) {
            //获取联网状态的NetworkInfo对象
            val info = intent
                .getParcelableExtra<NetworkInfo>(ConnectivityManager.EXTRA_NETWORK_INFO)
            if (info != null) {
                //如果当前的网络连接成功并且网络连接可用
                if (NetworkInfo.State.CONNECTED == info.state && info.isAvailable) {
                    if (info.type == ConnectivityManager.TYPE_WIFI
                        || info.type == ConnectivityManager.TYPE_MOBILE
                    ) {
                        App.isNetWorkConnected = true
                        connectBack?.OnConnect(true)
                    }
                } else {
                    App.isNetWorkConnected = false
                    connectBack?.OnConnect(false)
                }
            }
        }
    }

    fun interface NetConnectBack {
        fun OnConnect(con: Boolean)
    }
}