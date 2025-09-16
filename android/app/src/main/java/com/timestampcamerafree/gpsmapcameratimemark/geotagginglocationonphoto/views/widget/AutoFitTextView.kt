package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget

import android.content.Context
import android.graphics.Paint
import android.util.AttributeSet
import android.util.TypedValue
import androidx.appcompat.widget.AppCompatTextView
import kotlin.math.max

/**
 * 根据宽度设定
 *
 */
class AutoFitTextView : AppCompatTextView {
    private var textPaint: Paint? = null
    private var defaultTextSize = 0f
    private val minTextSize = 10f // 设置最小字体大小

    constructor(context: Context?) : super(context!!) {
        initialize()
    }

    constructor(context: Context?, attrs: AttributeSet?) : super(
        context!!, attrs
    ) {
        initialize()
    }

    constructor(context: Context?, attrs: AttributeSet?, defStyleAttr: Int) : super(
        context!!, attrs, defStyleAttr
    ) {
        initialize()
    }

    private fun initialize() {
        textPaint = Paint(paint)
        defaultTextSize = textSize
    }

    override fun onTextChanged(
        text: CharSequence,
        start: Int,
        lengthBefore: Int,
        lengthAfter: Int
    ) {
        super.onTextChanged(text, start, lengthBefore, lengthAfter)
        refitText(text.toString(), width)
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        if (w != oldw) {
            refitText(text.toString(), w)
        }
    }

    private fun refitText(text: String, textWidth: Int) {
        if (textWidth <= 0) return

        val availableWidth = textWidth - paddingLeft - paddingRight
        var targetTextSize = defaultTextSize

        textPaint!!.textSize = targetTextSize
        while (textPaint!!.measureText(text) > availableWidth && targetTextSize > minTextSize) {
            targetTextSize =
                max((targetTextSize - 1).toDouble(), minTextSize.toDouble()).toFloat()
            textPaint!!.textSize = targetTextSize
        }
        setTextSize(TypedValue.COMPLEX_UNIT_PX, targetTextSize)
    }
}