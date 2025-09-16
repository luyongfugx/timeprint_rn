package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity


abstract class GpBaseSplashActivity : AppCompatActivity() {
    abstract fun initActivity()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
            initActivity()
        }
}

