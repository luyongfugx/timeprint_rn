package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget

import android.content.Context
import android.util.AttributeSet
import android.view.MotionEvent
import androidx.annotation.AttrRes

class GpImageView : androidx.appcompat.widget.AppCompatImageView {

    constructor(context: Context) : super(context)

    constructor(context: Context, attrs: AttributeSet?) : super(context, attrs)

    constructor(context: Context, attrs: AttributeSet?, @AttrRes defStyleAttr: Int) : super(context, attrs, defStyleAttr)

    override fun onTouchEvent(event: MotionEvent?): Boolean {
        return if (drawable == null)
            false
        else
            super.onTouchEvent(event)
    }
}