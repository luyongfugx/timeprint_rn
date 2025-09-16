package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.util.AttributeSet
import android.view.View

/**
 * 圆形色块
 *
 * @constructor
 * TODO
 *
 * @param context
 * @param attrs
 */
class CircleColorView(context: Context, attrs: AttributeSet?) : View(context, attrs) {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val checkPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    var color: Int = Color.BLACK
        set(value) {
            field = value
            paint.color = value
            invalidate()
        }

    var isChecked: Boolean = false
        set(value) {
            field = value
            invalidate()
        }

    init {
        paint.style = Paint.Style.FILL
        checkPaint.color = Color.WHITE
        checkPaint.typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        checkPaint.textSize = 40f
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val centerX = width / 2f
        val centerY = height / 2f
        val radius = Math.min(centerX, centerY)
        if (color == Color.WHITE) {
            paint.color = Color.BLACK
            canvas.drawCircle(centerX, centerY, radius, paint)
            paint.color = Color.WHITE
            canvas.drawCircle(centerX, centerY, radius - 2, paint)
        } else {
            canvas.drawCircle(centerX, centerY, radius, paint)
        }
        if (isChecked) {
            canvas.drawText("✔", centerX - 10, centerY + 10, checkPaint)
        }
        if (isChecked) {
            checkPaint.color = if (color == Color.WHITE) Color.BLACK else Color.WHITE
            canvas.drawText("✔", centerX - 10, centerY + 10, checkPaint)
        }
    }
}