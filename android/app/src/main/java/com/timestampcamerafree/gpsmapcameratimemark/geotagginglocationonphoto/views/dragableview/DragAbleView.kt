package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.dragableview

import android.content.Context
import android.util.AttributeSet
import android.view.View
import android.widget.RelativeLayout

/**
 * TODO
 * @param context
 * @param attrs
 * @param defStyleAttr
 */
class DragAbleView @JvmOverloads constructor(context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0)
    : RelativeLayout(context, attrs, defStyleAttr), IDragAble {
    override fun getAngle(): Int {
        return 0
    }

    override fun getView(): View {
        return this
    }

    override fun enableRotate(enable: Boolean) {

    }

    override fun enableRotate(): Boolean {
        return true
    }

    override fun dragEnable(): Boolean {
        return true
    }

    override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
        super.onLayout(changed, l, t, r, b)
    }

}