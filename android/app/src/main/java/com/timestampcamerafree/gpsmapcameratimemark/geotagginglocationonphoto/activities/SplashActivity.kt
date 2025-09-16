package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities

import android.content.Intent
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.GpBaseSplashActivity

class SplashActivity : GpBaseSplashActivity() {
   override fun initActivity() {
        startActivity(Intent(this, MainActivity::class.java))
        finish()
    }
}
