package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.AttributeSet
import android.util.Log
import android.util.TypedValue
import android.view.View
import kotlin.math.max

class CircularCharacterView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    private var text: String = ""

    private var characterBackgroundColor: Int = Color.BLUE // 默认颜色
    private var characterBackgroundColors: List<Int>? = null // 多颜色支持
    private var textColor: Int = Color.WHITE
    private  var circlePadding:Int = 2
    private  var circleSpacing:Int = 2
    private var textSizePx: Float = spToPx(12f)
    private val backgroundPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
    }
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textAlign = Paint.Align.CENTER
    }

    //region Public API
     fun setText(text: String) {

        //this.text = text.replace("\\D".toRegex(), "")
         this.text = text.replace("⃣\uFE0F", "")//去掉原来的那个文字的背景和空格
        requestLayout()
        invalidate()
    }

    fun setCharacterBackgroundColor(color: Int) {
        this.characterBackgroundColor = color
        this.characterBackgroundColors = null // 清除每字符颜色
        invalidate()
    }

    fun setCharacterBackgroundColors(colors: List<Int>) {
        this.characterBackgroundColors = colors
        invalidate()
    }
// 默认 16sp
    private fun spToPx(sp: Float): Float {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_SP,
            sp,
            resources.displayMetrics
        )
    }
    fun setTextColor(color: Int) {
        this.textColor = color
        invalidate()
    }
    //endregion

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val desiredWidth = calculateDesiredWidth()
        val desiredHeight = calculateDesiredHeight()
        //Log.d("calculateDesiredWidth","calculateDesiredWidth ${desiredWidth} ")
        setMeasuredDimension(
            resolveSize(desiredWidth, widthMeasureSpec),
            resolveSize(desiredHeight, heightMeasureSpec)
        )
    }

//    private fun calculateDesiredHeight(): Int {
//        val padding = 6 * resources.displayMetrics.density
//        textPaint.textSize = 48f
//        val fontMetrics = textPaint.fontMetrics
//        val textHeight = fontMetrics.bottom - fontMetrics.top
//        val radius = (textHeight / 2 + padding)
//        return (radius * 2).toInt()
//    }
    private fun calculateRadius(): Float {
        val padding = circlePadding * resources.displayMetrics.density
        val fontMetrics = textPaint.fontMetrics
        val textHeight = fontMetrics.bottom - fontMetrics.top
        return (max(textSizePx, textHeight) / 2 + padding)
    }
    private fun calculateDesiredWidth(): Int {
        if (text.isEmpty()) return 0

        val radius = calculateRadius()
        val spacing = circleSpacing
        val diameter = radius * 2
        val characterSpace = diameter + spacing

        return (text.length * characterSpace).toInt()
    }
    private fun calculateDesiredHeight(): Int {
        val radius = calculateRadius()
        return (radius * 2).toInt()
    }

    fun setTextSize(sp: Float) {
        this.textSizePx = spToPx(sp)
        textPaint.textSize = textSizePx
        requestLayout()
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        if (text.isEmpty()) return

        textPaint.color = textColor
        textPaint.textSize = textSizePx
        val radius = calculateRadius()
        val spacing = circleSpacing
        val diameter = radius * 2
        val characterSpace = diameter + spacing
        val startX = (width - (text.length * characterSpace) + spacing) / 2 + radius
        val centerY = height / 2f
        text.forEachIndexed { index, char ->
            val centerX = startX + (index * characterSpace)
            // 设置背景颜色：每字符颜色优先，没有则用默认色
            backgroundPaint.color = characterBackgroundColors?.getOrNull(index) ?: characterBackgroundColor

            canvas.drawCircle(centerX, centerY, radius, backgroundPaint)

            val textY = centerY - ((textPaint.descent() + textPaint.ascent()) / 2)
            canvas.drawText(char.toString(), centerX, textY, textPaint)
        }
    }
}
