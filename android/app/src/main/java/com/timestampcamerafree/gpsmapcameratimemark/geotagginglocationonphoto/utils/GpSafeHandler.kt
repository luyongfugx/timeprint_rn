package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils


import android.os.Handler
import android.os.Looper
import android.os.Message
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LifecycleOwner
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpUiUtils.runOnUiThread


open class GpSafeHandler @JvmOverloads constructor(private val lifecycleOwner: LifecycleOwner, looper: Looper = Looper.getMainLooper()) : Handler(looper), LifecycleEventObserver {

    init {
        if (GpUiUtils.isMainThread()) {
            lifecycleOwner.lifecycle.addObserver(this)
        } else {
            runOnUiThread {
            lifecycleOwner.lifecycle.addObserver(this)
        }

        }
    }

    override fun onStateChanged(source: LifecycleOwner, event: Lifecycle.Event) {
        if (event == Lifecycle.Event.ON_DESTROY) {
            removeCallbacksAndMessages(null)

        }
    }

    override fun dispatchMessage(msg: Message) {
        if (lifecycleOwner.lifecycle.currentState == Lifecycle.State.DESTROYED || lifecycleOwner.lifecycle.currentState == Lifecycle.State.INITIALIZED){
            return
        }
        super.dispatchMessage(msg)
    }
}