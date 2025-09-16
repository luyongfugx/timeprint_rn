package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.util.AttributeSet
import android.view.Gravity.CENTER
import android.view.LayoutInflater
import android.widget.LinearLayout
import android.widget.TextView
import androidx.annotation.ColorInt
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
class ScaleCircleView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : LinearLayout(context, attrs, defStyleAttr) {

    private val textView: TextView
    private var showBorder: Boolean = true
    private var textSize: Float = 12f
    @ColorInt
    private var textColor: Int = Color.WHITE
    @ColorInt
    private var borderColor: Int = Color.WHITE
    private var circleSize: Int = dpToPx(24f)
    init {
        orientation = VERTICAL
        gravity = CENTER
        // 加载布局
        val view = LayoutInflater.from(context).inflate(R.layout.view_scale_circle, this, true)
        textView = view.findViewById(R.id.circleText)

        // 获取自定义属性
        attrs?.let {
            val typedArray = context.obtainStyledAttributes(it, R.styleable.ScaleCircleView)
            showBorder = typedArray.getBoolean(R.styleable.ScaleCircleView_showBorder, true)
            textView.text = typedArray.getString(R.styleable.ScaleCircleView_circleText) ?: ""
            textColor = typedArray.getColor(
                R.styleable.ScaleCircleView_textColor,
                Color.WHITE
            )
            circleSize = typedArray.getDimensionPixelSize(
                R.styleable.ScaleCircleView_circleSize,
                dpToPx(24f)
            )
            textSize = typedArray.getDimension(
                R.styleable.ScaleCircleView_textSize,
                resources.getDimension(R.dimen.textSize12sp)
            )
            borderColor = typedArray.getColor(
                R.styleable.ScaleCircleView_borderColor,
                Color.WHITE
            )
            typedArray.recycle()
        }
        updateView()
    }



    fun setTextSize(sizeInSp: Float) {
        textSize = sizeInSp
        textView.textSize = sizeInSp
    }
    fun setShowBorder(show: Boolean) {
        showBorder = show
        updateView()
    }
    fun setBorderColor(@ColorInt color: Int) {
        borderColor = color
        updateView()
    }

    fun setText(text: String) {
        textView.text = text
    }

    fun setTextColor(@ColorInt color: Int) {
        textColor = color
        textView.setTextColor(color)
    }

    private fun updateView() {
        // 设置背景
        val drawable = GradientDrawable()
        drawable.shape = GradientDrawable.OVAL
        drawable.setColor(Color.parseColor("#22000000"))
       // drawable.setColor(Color.GRAY)
        if (showBorder) {
            drawable.setStroke(dpToPx(1f), borderColor)
        }
        background = drawable
        // 设置文字
        textView.setTextColor(textColor)
        textView.gravity = CENTER
    }

    private fun dpToPx(dp: Float): Int {
        return (dp * resources.displayMetrics.density).toInt()
    }
}
