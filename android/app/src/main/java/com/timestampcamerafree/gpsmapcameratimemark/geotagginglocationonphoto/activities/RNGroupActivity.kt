package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities

import android.view.WindowManager
import android.os.Bundle
import com.facebook.react.ReactActivity
import com.facebook.react.ReactActivityDelegate
import com.facebook.react.defaults.DefaultNewArchitectureEntryPoint.fabricEnabled
import com.facebook.react.defaults.DefaultReactActivityDelegate
import androidx.core.view.WindowCompat
class RNGroupActivity : ReactActivity() {

    /**
     * Returns the name of the main component registered from JavaScript. This is used to schedule
     * rendering of the component.
     */
   // "name": "com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto

    //override fun getMainComponentName(): String = "com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto"
    override fun getMainComponentName(): String = "timeprint_rn"
    /**
     * Returns the instance of the [ReactActivityDelegate]. We use [DefaultReactActivityDelegate]
     * which allows you to enable New Architecture with a single boolean flags [fabricEnabled]
     */
    override fun createReactActivityDelegate(): ReactActivityDelegate =
        DefaultReactActivityDelegate(this, mainComponentName, fabricEnabled)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setStatusBarColorBlack()
    }

    override fun onResume() {
        super.onResume()
        // 每次 Activity 恢复到前台时都设置状态栏颜色
        setStatusBarColorBlack()
    }

    private fun setStatusBarColorBlack() {
        window?.let { window ->
            // 清除默认的 SYSTEM_BARS 样式，允许自定义
            window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS)
            // 设置状态栏背景颜色为黑色
            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
            window.statusBarColor = android.graphics.Color.BLACK
            WindowCompat.getInsetsController(window, window.decorView).isAppearanceLightStatusBars =
                false
        }
    }
}
