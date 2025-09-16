package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities


import android.graphics.Color
import android.os.Bundle
import android.widget.ImageButton
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.databinding.ActivitySettingsBinding
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.config
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.viewBinding
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.AnalyticsManager

/**
 * 设置
 *
 */
class SettingsActivity : SimpleActivity() {
    private val binding by viewBinding(ActivitySettingsBinding::inflate)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val windowInsetsController = ViewCompat.getWindowInsetsController(window.decorView)
        windowInsetsController?.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        windowInsetsController?.hide(WindowInsetsCompat.Type.statusBars())
        binding.apply {
            setContentView(root)
        }
        findViewById<ImageButton>(R.id.btnClose).setOnClickListener {
            //onBackPressed()
            finish()
        }
    }

    override fun onResume() {
        super.onResume()
        //setupToolbar(binding.settingsToolbar, NavigationIcon.Arrow)
        setupSound()
        setupVolumeButtonsAsShutter()
        setShowOfficialWatermark()
//        binding.apply {
//            arrayListOf(
//                settingsShutterLabel,
//            ).forEach {
//                it.setTextColor(Color.WHITE)
//            }
//        }
    }

    private fun setShowOfficialWatermark () = binding.apply {
        showOfficialWatermark.isChecked = config.isShowOfficialWatermark
        showOfficialWatermarkHolder.setOnClickListener {
            showOfficialWatermark.toggle()
            config.isShowOfficialWatermark = showOfficialWatermark.isChecked
            if (config.isShowOfficialWatermark){
                AnalyticsManager.logEvent("show_official_watermark_on")
            }
            else {
                AnalyticsManager.logEvent("show_official_watermark_off")
            }

        }
    }
    private fun setupSound() = binding.apply {
        settingsSound.isChecked = config.isSoundEnabled
        settingsSoundHolder.setOnClickListener {
            settingsSound.toggle()
            config.isSoundEnabled = settingsSound.isChecked
        }
    }

    private fun setupVolumeButtonsAsShutter() = binding.apply {
        settingsVolumeButtonsAsShutter.isChecked = config.volumeButtonsAsShutter
        settingsVolumeButtonsAsShutterHolder.setOnClickListener {
            settingsVolumeButtonsAsShutter.toggle()
            config.volumeButtonsAsShutter = settingsVolumeButtonsAsShutter.isChecked
        }
    }

}
