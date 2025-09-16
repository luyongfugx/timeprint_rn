package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ext

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.view.LayoutInflater
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.PopupWindow
import android.widget.TextView
import androidx.core.content.ContextCompat
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.beGone
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.beVisible
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.FLASH_AUTO

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.FLASH_OFF
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.FLASH_ON
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.FlashModeManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.FlashMode
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.IconFontType
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.IconFontTextView


/**
 * flash扩展，避免mainAtivity太大
 *
 * @param available
 */

fun MainActivity.doSetFlashAvailable(available: Boolean) {
        if (available) {
            mainBinding.layoutTop.toggleFlash.beVisible()
        } else {
            mainBinding.layoutTop.toggleFlash.beGone()
            mPreview?.setFlashlightState(FLASH_OFF)
        }
}

fun MainActivity.selectFlashMode(flashMode: Int) {
    currentFlashMode = flashMode
    mPreview?.setFlashlightState(flashMode)
}

fun MainActivity.getFlashModeMenu(linearLayout: LinearLayout, onClick: (clickedViewId: Int) -> Unit, flashModeList: List<FlashMode>, selectedFlashMode: Int, context: Context) {
    linearLayout.removeAllViews()
    val inflater = LayoutInflater.from(context)
    for (flashMode in flashModeList) {
        val view = inflater.inflate(R.layout.iconfont_pop_item, linearLayout, false)
        val imageView = view.findViewById<IconFontTextView>(R.id.ratio_image)
        val textView = view.findViewById<TextView>(R.id.ratio_text)
        textView.text = flashMode.text
        imageView.text = flashMode.iconText
        if( flashMode.mode == selectedFlashMode){
            //val color= Color.parseColor("#1d7fdf")
            val color = ContextCompat.getColor(this, R.color.color_0093ff)
            textView.setTextColor(color)
            imageView.setTextColor(color)
        }
        else {
            textView.setTextColor(Color.BLACK)
            imageView.setTextColor(Color.BLACK)
        }
        // 设置点击事件
        view.setOnClickListener {
            onClick(flashMode.mode)
        }
        linearLayout.addView(view)
    }
}

fun MainActivity.doShowFlashOptions(photoCapture: Boolean) {
    val flashModeList =   FlashModeManager.getFlashModeList()
    val popupView =
        layoutInflater.inflate(R.layout.layout_pop_left_menu, null, false)
    val popupWindow = PopupWindow(
        popupView,
        ViewGroup.LayoutParams.WRAP_CONTENT,
        ViewGroup.LayoutParams.WRAP_CONTENT,
        true // This sets both isFocusable and isOutsideTouchable to true
    ).apply {
        setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
    }
    val onItemClick =  { mode: Int ->
        selectFlashMode(mode)
        popupWindow.dismiss()
    }
    getFlashModeMenu(popupWindow.contentView.findViewById(R.id.pop_menu), onItemClick, flashModeList,  currentFlashMode,this)
    popupWindow.showAsDropDown(binding.layoutTop.toggleFlash, -12, 12)
}

fun MainActivity.doOnChangeFlashMode(flashMode: Int) {
    binding.layoutTop.apply {
        val iconText = when (flashMode) {
            FLASH_OFF -> IconFontType.BTN_FLASH_CLOSE.unicode
            FLASH_ON -> IconFontType.BTN_FLASH_OPEN.unicode
            FLASH_AUTO -> IconFontType.BTN_FLASH_AUTO.unicode
            else -> IconFontType.BTN_FLASHLIGHT.unicode
        }
        toggleFlash.text = iconText
      //  toggleFlash.transitionName = "${getString(R.string.toggle_flash)}$flashMode"
    }
}

