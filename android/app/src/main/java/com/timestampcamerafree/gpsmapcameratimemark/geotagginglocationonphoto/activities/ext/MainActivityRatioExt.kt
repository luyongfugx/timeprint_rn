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
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.ResolutionOption

/**
 * 设置ratio相关
 *
 * @param linearLayout
 * @param onClick
 * @param settings
 * @param context
 */


fun MainActivity.getImageSizeMenu(linearLayout: LinearLayout, onClick: (clickedViewId: Int) -> Unit, resolutions: List<ResolutionOption>, selectedResolution: ResolutionOption, context: Context) {
    linearLayout.removeAllViews()
    val inflater = LayoutInflater.from(context)
    for (resolutionOption in resolutions) {
        val view = inflater.inflate(R.layout.pop_item, linearLayout, false)
        view.id = resolutionOption.buttonViewId
        val imageView = view.findViewById<ImageView>(R.id.ratio_image)
        val textView = view.findViewById<TextView>(R.id.ratio_text)
        imageView.setImageResource(resolutionOption.imageDrawableResId)
        textView.text = resolutionOption.resolution
        if( selectedResolution.buttonViewId == resolutionOption.buttonViewId){
            // val color= Color.parseColor("#1d7fdf")
            val color = ContextCompat.getColor(this,R.color.color_0093ff)
            textView.setTextColor(color)
            imageView.setColorFilter(color)
        }
        else {
            textView.setTextColor(Color.BLACK)
            imageView.setColorFilter(Color.BLACK)
        }
        // 设置点击事件
        view.setOnClickListener {
            onClick(resolutionOption.buttonViewId)
        }
        linearLayout.addView(view)
    }
}

fun MainActivity.doShowImageSizes(
    selectedResolution: ResolutionOption,
    resolutions: List<ResolutionOption>,
    isPhotoCapture: Boolean,
    isFrontCamera: Boolean,
    onSelect: (index: Int, changed: Boolean) -> Unit
) {
    val popupView =
        layoutInflater.inflate(R.layout.layout_pop_right_menu, null, false)
    val popupWindow = PopupWindow(
        popupView,
        ViewGroup.LayoutParams.WRAP_CONTENT,
        ViewGroup.LayoutParams.WRAP_CONTENT,
        true // This sets both isFocusable and isOutsideTouchable to true
    ).apply {
        setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
    }
    val onItemClick =  { clickedViewId: Int ->
        val index = resolutions.indexOfFirst { it.buttonViewId == clickedViewId }
        onSelect.invoke(index, selectedResolution.buttonViewId != clickedViewId)
        popupWindow.dismiss()
    }
    popupView.measure(View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
        View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED))

    val popupWidth = popupView.measuredWidth
    val offsetX =  popupWidth
    var finalOffsetX = -offsetX*2
    val finalOffsetY =  -36
    if (!isPhotoCapture){
        finalOffsetX = -offsetX
    }
    getImageSizeMenu(popupWindow.contentView.findViewById(R.id.pop_menu), onItemClick, resolutions,  selectedResolution,this)
    //Log.d(TAG,"doShowImageSizes ${selectedResolution} isPhotoCapture：$isPhotoCapture isFrontCamera: ${isFrontCamera} $finalOffsetX $finalOffsetY")
    // 显示在按钮下方，并根据需要调整偏移量
    popupWindow.showAsDropDown(binding.layoutTop.changeResolution, finalOffsetX, finalOffsetY)
}

