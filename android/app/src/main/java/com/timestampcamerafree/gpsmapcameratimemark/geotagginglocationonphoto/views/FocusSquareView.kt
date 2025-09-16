package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.os.Handler
import android.view.ViewGroup

class FocusSquareView(context: Context) : ViewGroup(context) {
    private val SQUARE_SIZE = 160f
    private val SQUARE_DURATION = 500L

    private var mDrawSquare = false
    private var mHandler: Handler
    private var mPaint: Paint
    private var mLastCenterX = 0f
    private var mLastCenterY = 0f

    init {
        setWillNotDraw(false)
        mHandler = Handler()
        mPaint = Paint().apply {
            style = Paint.Style.STROKE
            color = Color.YELLOW
            strokeWidth = 5f
        }
    }

    fun drawFocusSquare(x: Float, y: Float) {
        mLastCenterX = x
        mLastCenterY = y
        toggleSquare(true)

        mHandler.removeCallbacksAndMessages(null)
        mHandler.postDelayed({
            toggleSquare(false)
        }, SQUARE_DURATION)
    }

    private fun toggleSquare(show: Boolean) {
        mDrawSquare = show
        invalidate()
    }

    override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {}

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        if (mDrawSquare) {
            val left = mLastCenterX - SQUARE_SIZE / 2
            val top = mLastCenterY - SQUARE_SIZE / 2
            val right = mLastCenterX + SQUARE_SIZE / 2
            val bottom = mLastCenterY + SQUARE_SIZE / 2
            canvas.drawRect(left, top, right, bottom, mPaint)
        }
    }
}
