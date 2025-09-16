package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget

import android.content.Context
import android.util.AttributeSet
import android.util.TypedValue
import android.view.ViewGroup
import android.widget.HorizontalScrollView
import android.widget.LinearLayout
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.ColorData

/**
 * 滚动选择器
 *
 * @constructor
 * TODO
 *
 * @param context
 * @param attrs
 */
class ColorSelectScrollView(context: Context, attrs: AttributeSet?) : HorizontalScrollView(context, attrs) {

    private val colorLinearLayout: LinearLayout = LinearLayout(context)
    private var onColorSelectedListener: ((ColorData) -> Unit)? = null

    init {
        colorLinearLayout.orientation = LinearLayout.HORIZONTAL
        addView(colorLinearLayout, ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        isHorizontalScrollBarEnabled = false // 隐藏水平滚动条
        clipToPadding = false // 允许子视图超出内边距
    }

    fun setColors(colors: List<ColorData>,defaultColor:ColorData) {
        colorLinearLayout.removeAllViews()
        val size = dpToPx(36) // 圆形大小
        val margin = dpToPx(5) // 圆形间隔

        colors.forEach { color ->
            val circleColorView = CircleColorView(context, null)
            circleColorView.color = color.getColor()
            if (color.getColor() == defaultColor.getColor()){
                circleColorView.isChecked = true
            }
            else {
                circleColorView.isChecked = false
            }

            val layoutParams = LinearLayout.LayoutParams(size, size)
            layoutParams.marginStart = margin
            layoutParams.marginEnd = margin
            circleColorView.layoutParams = layoutParams
            circleColorView.setOnClickListener { circleColorView
                colors.forEach { it.isChecked = false }
                color.isChecked = true
                val childCount = colorLinearLayout.childCount
                for (i in 0 until childCount) {
                    // 对 childView 进行操作
                    val childView = colorLinearLayout.getChildAt(i) as CircleColorView
                    childView.isChecked = false
                }
                circleColorView.isChecked = true;
                onColorSelectedListener?.invoke(color)
            }
            colorLinearLayout.addView(circleColorView)
        }
    }

    fun setOnColorSelectedListener(listener: (ColorData) -> Unit) {
        onColorSelectedListener = listener
    }

    private fun dpToPx(dp: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP, dp.toFloat(), resources.displayMetrics
        ).toInt()
    }
}