package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget

import android.annotation.SuppressLint
import android.content.Context
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.View
import android.widget.CompoundButton
import androidx.appcompat.R
import androidx.appcompat.widget.SwitchCompat
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpUiUtils


class GpSwitch(context: Context, attrs: AttributeSet?, defStyleAttr: Int) : SwitchCompat(context, attrs, defStyleAttr) {
    private var listener: (Boolean) -> Unit = {}
    constructor(context: Context, attrs: AttributeSet?) : this(context, attrs, R.attr.switchStyle)
    constructor(context: Context):this(context,null)

    fun setCompoundButtonOnCheckedChangeListener(listener: CompoundButton.OnCheckedChangeListener) {
        setOnClickListenerByInterceptSystemEvent {
            listener.onCheckedChanged(it as CompoundButton, !isChecked)
        }
    }

    fun setCompoundButtonOnCheckedChangeListener(action: (Boolean) -> Unit) {
        setOnClickListenerByInterceptSystemEvent {
            action(!isChecked)
        }
    }
    @SuppressLint("ClickableViewAccessibility")
    private fun View.setOnClickListenerByInterceptSystemEvent(l1: (View) -> Unit) {
        setOnTouchListener { v, event ->
            when (event.action) {
                MotionEvent.ACTION_UP -> {
                    if (GpUiUtils.getViewScreenLocation(v).contains(event.rawX, event.rawY)) {
                        l1(v)
                        return@setOnTouchListener true
                    }
                }
            }

            true
        }
    }

    /**
     * 主动修改checked状态，但是listener不响应，区分用户点击
     */
    fun activeSetChecked(isCheck:Boolean){
        setOnCheckedChangeListener(null)
        isChecked = isCheck
        setOnCheckedChangeByUserListener(listener)
    }
    /**
     * checked状态监听，配合[activeSetChecked]方法，只响应用户点击，不响应主动修改
     */
    fun setOnCheckedChangeByUserListener(listener:(Boolean)->Unit){
        this.listener = listener
        setOnCheckedChangeListener { buttonView, isChecked ->
            listener(isChecked)
        }
    }
}