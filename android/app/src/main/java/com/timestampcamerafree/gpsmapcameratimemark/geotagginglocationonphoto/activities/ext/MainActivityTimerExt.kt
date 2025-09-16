package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ext

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.PopupWindow
import android.widget.TextView
import androidx.core.content.ContextCompat
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.TimerModeOption

/*
  增加
 */


fun MainActivity.getTimerMenu(linearLayout: LinearLayout, onClick: (clickedViewId: Int) -> Unit, timerList: List<TimerModeOption>, selectedTimerMode: TimerModeOption, context: Context) {
    linearLayout.removeAllViews()
    val inflater = LayoutInflater.from(context)
    for (timer in timerList) {
        val view = inflater.inflate(R.layout.pop_item, linearLayout, false)
        view.id = timer.buttonViewId
        val imageView = view.findViewById<ImageView>(R.id.ratio_image)
        val textView = view.findViewById<TextView>(R.id.ratio_text)
        imageView.setImageResource(timer.imageDrawableResId)
        textView.text = timer.text
        if( selectedTimerMode.value == timer.value){
            // val color= Color.parseColor("#1d7fdf")
            val color = ContextCompat.getColor(this, R.color.color_0093ff)
            textView.setTextColor(color)
            imageView.setColorFilter(color)
        }
        else {
            textView.setTextColor(Color.BLACK)
            imageView.setColorFilter(Color.BLACK)
        }
        // 设置点击事件
        view.setOnClickListener {
            onClick(timer.buttonViewId)
        }
        linearLayout.addView(view)
    }
}

fun MainActivity.doShowTimerOptions(
    selectedTimerMode: TimerModeOption,
    timerList: List<TimerModeOption>,
    isPhotoCapture: Boolean,
    onSelect: (index: Int, changed: Boolean) -> Unit
) {
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
    val onItemClick =  { clickedViewId: Int ->
        val index = timerList.indexOfFirst { it.buttonViewId == clickedViewId }
        onSelect.invoke(index, selectedTimerMode.buttonViewId != clickedViewId)
        popupWindow.dismiss()
    }
    popupView.measure(
        View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
        View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED))

    val popupWidth = popupView.measuredWidth
    val offsetX =  popupWidth
    var finalOffsetX = offsetX-60
    val finalOffsetY =  -36
//    if (!isPhotoCapture){
//        finalOffsetX = -offsetX-24
//    }
    getTimerMenu(popupWindow.contentView.findViewById(R.id.pop_menu), onItemClick, timerList,  selectedTimerMode,this)
    //Log.d(TAG,"doShowImageSizes ${selectedResolution} isPhotoCapture：$isPhotoCapture isFrontCamera: ${isFrontCamera} $finalOffsetX $finalOffsetY")
    // 显示在按钮下方，并根据需要调整偏移量
    popupWindow.showAsDropDown(binding.layoutTop.toggleTimer, finalOffsetX, finalOffsetY)
}
