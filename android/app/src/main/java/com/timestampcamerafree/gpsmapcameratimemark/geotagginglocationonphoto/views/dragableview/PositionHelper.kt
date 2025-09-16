package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.dragableview


import android.graphics.Point
import android.util.Log
import android.util.Size
import android.util.SizeF
import android.view.View
import android.view.ViewTreeObserver
import android.widget.RelativeLayout
import android.widget.RelativeLayout.*
import androidx.core.util.Supplier
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpConstants
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpNumberUtil
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.RotateLayout

import java.util.*

/**
 * PositionHelper,水印位置
 */

var waterMarkOffsetX = 200
var waterMarkOffsetY = 300

class PositionHelper(
    var activity: MainActivity,
    private val ratioSupplier: Supplier<Float>
) : PosChangeCallback {
    private val TAG = "PositionHelper"
    var dragViewAdapter: DragViewAdapter? = null
        set(value) {
            field = value
            value?.getDragView()?.getView()
                ?.addOnLayoutChangeListener { v, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom ->
                    if (bottom - top != oldBottom - oldTop || right - left != oldRight - oldLeft) {
                        adjustWithRotation(false)
                    }
                }
        }


    interface DragViewAdapter {
        fun getDragViewContainer(): View?
        fun getDragView(): DragViewProperty?
        interface DragViewProperty {
            fun getView(): View
            fun getAngle(): Int
            fun enableRotate(enable: Boolean)
            fun enableRotate(): Boolean
        }
    }


    private fun getDragViewArea(): Float {
//        return dragViewAdapter?.getDragViewContainer()?.let {
//            it.measuredHeight.toFloat() / it.measuredWidth
//        }?:Constants.Ratio.RATIO_4_3
        return ratioSupplier.get()
    }


    private var waterMarkName = ""

    private var deltaYStack = ArrayDeque<Float>()
    private var recordLastDY: Float = 0f

    // 水印拖拽后各方向 距离边界最近的距离
    var markLayoutMargins = arrayOf(
        WaterMarkLayoutPosition(LEFT_BOTTOM),
        WaterMarkLayoutPosition(RIGHT_BOTTOM),
        WaterMarkLayoutPosition(RIGHT_TOP),
        WaterMarkLayoutPosition(LEFT_TOP)
    )

    fun forceAdjustWaterMark() {
        adjustWithRotation(false)
    }

    fun reset() {
        for (i in markLayoutMargins.indices) {
            markLayoutMargins[i].reset(i)
        }
    }


    fun getMarkPositionIndex(screenRotation: Int): Int {
        var screenRotation = screenRotation
        screenRotation = screenRotation % 360
        val index = screenRotation / 90
        return index
    }


    fun adjustWithRotation(isDragMode: Boolean) { // 调整一下View的位置参数
        dragViewAdapter?.getDragView()?.also {
           // Log.d(TAG,"not isDragMode adjustWithRotation ${isDragMode}")
            var screenRotation = getOrientation()
            val calcPoint = getWaterPositionByScreenRotation(it.getView(), screenRotation)
             if ((it.getView().scaleX != 1f || it.getView().scaleY != 1f) && !isDragMode) {

                val scaleSurplusSpace = it.getView().getScaleSurplusSpace()
                it.getView().setMargins(
                    calcPoint.align,
                    calcPoint.point.x - scaleSurplusSpace.width / 2,
                    calcPoint.point.y - scaleSurplusSpace.height / 2
                )
            } else {
               it.getView().setMargins(calcPoint.align, calcPoint.point.x, calcPoint.point.y)
            }

        }

    }

    /*
    *
    * 矫正
    * */
    fun getWaterPositionByScreenRotation(view: View, screenRotation: Int): WaterMarkLayoutPosition {
        var screenRotation = screenRotation % 360
        val index = screenRotation / 90
        return getWaterPositionByIndex(view, index)
    }

    fun getDragViewAlign(): Int {
        return dragViewAdapter?.getDragView()?.getView()?.getAlign() ?: LEFT_BOTTOM
    }


    fun getPositionIndex(align: Int): Int {
        var index = 0
        if (align == LEFT_BOTTOM) {
            index = 0
        } else if (align == RIGHT_BOTTOM) {
            index = 1
        } else if (align == RIGHT_TOP) {
            index = 2
        } else {
            index = 3
        }
        return index
    }


    fun getWaterPositionByIndex(view: View, index: Int): WaterMarkLayoutPosition {

        val point = markLayoutMargins[index].point // 某种方位下的容器的大小
        if (view.scaleX == 1f && view.scaleY == 1f) {
            if (point.x < 0) {
                point.x = 0
            }
            if (point.y < 0) {
                point.y = 0
            }
        } else {
            val scaleSurplusSpace = view.getScaleSurplusSpace()
            var sw = scaleSurplusSpace.width / 2
            var sh = scaleSurplusSpace.height / 2
            if (point.x < -sw) {
                point.x = -sw.toInt()
            }
            if (point.y < -sh) {
                point.y = -sh.toInt()
            }
        }
        return markLayoutMargins[index]
    }


    var startLeft = 300
    var startTop = 300
    override fun onViewCaptured(captureView: View) {
        //Log.d(TAG,"onViewCaptured startTop:${startTop} startLeft: ${startLeft}")
        if (startLeft == -1) {
            startLeft = captureView.left
        }
        if (startTop == -1) {
            startTop = captureView.top
        }
    }

    override fun onViewPositionChanged(changedView: View, left: Int, top: Int, dx: Int, dy: Int) {

    }

    override fun onViewReleased(releasedView: View, left: Int, top: Int) {
        refreshWaterMarkLayoutParams(
            (releasedView.left + releasedView.right) / 2,
            (releasedView.top + releasedView.bottom) / 2, left, top
        ) // 释放View 计算一下View的位置
        adjustWithRotation(true)
        waterMarkOffsetX = Math.abs(left - startLeft)
        waterMarkOffsetY = Math.abs(top - startTop)
    }

    private fun refreshWaterMarkLayoutParams(pivotX: Int, pivotY: Int, left: Int, top: Int) {
        markLayoutMargins[getMarkPositionIndex(getOrientation())].evaluate(
            pivotX,
            pivotY,
            left,
            top
        )
    }

    private fun getOrientation(): Int {
        var screenRotation = dragViewAdapter?.getDragView()?.getAngle() ?: 0
        return screenRotation
    }

    inner class WaterMarkLayoutPosition(align: Int) {
        var dragged = false

        // 0-3  对齐的
        var align = LEFT_BOTTOM
        var point1_1: Point
        var point4_3: Point
        var point16_9: Point
        fun reset(align: Int) {
            this.align = align
            refreshPoint(0, 0)
        }

        fun evaluate(pivotX: Int, pivotY: Int, left: Int, top: Int) {
            dragViewAdapter?.getDragViewContainer()?.also { container ->
                val rootPivotX = (container.right - container.left) / 2
                val rootPivotY = (container.bottom - container.top) / 2
                align = if (pivotX < rootPivotX && pivotY > rootPivotY) {
                    LEFT_BOTTOM
                } else if (pivotX >= rootPivotX && pivotY >= rootPivotY) {
                    RIGHT_BOTTOM
                } else if (pivotX > rootPivotX) {
                    RIGHT_TOP
                } else {
                    LEFT_TOP
                }
                evaluateWithAlign(align, left, top)
            }
        }

        private fun evaluateWithAlign(align: Int, left: Int, top: Int) {
            dragViewAdapter?.getDragView()?.getView()?.also { targetView ->
                dragViewAdapter?.getDragViewContainer()?.also { container ->
                    this.align = align
                    if (align == LEFT_BOTTOM) {
                        refreshPoint(
                            left,
                            container.measuredHeight - top - targetView.measuredHeight
                        )
                    } else if (align == RIGHT_BOTTOM) {
                        refreshPoint(
                            container.measuredWidth - left - targetView.measuredWidth,
                            container.measuredHeight - top - targetView.measuredHeight
                        )
                    } else if (align == RIGHT_TOP) {
                        refreshPoint(container.measuredWidth - left - targetView.measuredWidth, top)
                    } else if (align == LEFT_TOP) {
                        refreshPoint(left, top)
                    }
                }
            }

        }

        val point: Point
            get() {
                return if (GpNumberUtil.equals(getDragViewArea(), GpConstants.Ratio.RATIO_4_3)
                ) {
                    return point4_3
                } else {
                    return point16_9
                }
            }

        fun refreshPoint(x: Int, y: Int) {
            if (getDragViewArea() == GpConstants.Ratio.RATIO_4_3) {
                point4_3.x = x
                point4_3.y = y
                point16_9.x = x
                point16_9.y = (y * 4 / 3f).toInt()
                point1_1.x = x
                point1_1.y = (y * 4 / 3f).toInt()
            } else {
                point16_9.x = x
                point16_9.y = y
                point1_1.x = x
                point1_1.y = y
                point4_3.x = x
                point4_3.y = y * 3 / 4
            }
        }

        init {
            point4_3 = Point(0, 0)
            point16_9 = Point(0, 0)
            point1_1 = Point(0, 0)
            this.align = align
        }
    }

    companion object {
        const val LEFT_BOTTOM = 0
        const val RIGHT_BOTTOM = 1
        const val RIGHT_TOP = 2
        const val LEFT_TOP = 3

        fun View.setMargins(align: Int, marginX: Int, marginY: Int) {
            if (this.layoutParams is RelativeLayout.LayoutParams) {
                var params = this.layoutParams as RelativeLayout.LayoutParams
                if (align == LEFT_BOTTOM) { // 左下
                    params.removeRule(RelativeLayout.ALIGN_PARENT_RIGHT)
                    params.removeRule(RelativeLayout.ALIGN_PARENT_TOP)
                    params.addRule(RelativeLayout.ALIGN_PARENT_LEFT)
                    params.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM)
                    params.setMargins(marginX, 0, 0, marginY)
                } else if (align == RIGHT_BOTTOM) { // 右下
                    params.removeRule(RelativeLayout.ALIGN_PARENT_LEFT)
                    params.removeRule(RelativeLayout.ALIGN_PARENT_TOP)
                    params.addRule(RelativeLayout.ALIGN_PARENT_RIGHT)
                    params.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM)
                    params.setMargins(0, 0, marginX, marginY)
                } else if (align == RIGHT_TOP) { // 右上
                    params.removeRule(RelativeLayout.ALIGN_PARENT_BOTTOM)
                    params.removeRule(RelativeLayout.ALIGN_PARENT_LEFT)
                    params.addRule(RelativeLayout.ALIGN_PARENT_TOP)
                    params.addRule(RelativeLayout.ALIGN_PARENT_RIGHT)
                    params.setMargins(0, marginY, marginX, 0)
                } else if (align == LEFT_TOP) { // 左上
                    params.removeRule(RelativeLayout.ALIGN_PARENT_BOTTOM)
                    params.removeRule(RelativeLayout.ALIGN_PARENT_RIGHT)
                    params.addRule(RelativeLayout.ALIGN_PARENT_LEFT)
                    params.addRule(RelativeLayout.ALIGN_PARENT_TOP)
                    params.setMargins(marginX, marginY, 0, 0)
                }
                this.requestLayout()
            }
        }

        fun View.getScaleSurplusSpace(): Size {
            val w = this.measuredWidth * (1 - this.scaleX)
            val h = this.measuredHeight * (1 - this.scaleY)
            return Size(w.toInt(), h.toInt())
        }

        fun View.getScaleSurplusSpace(scaleX: Float, scaleY: Float): Size {
            val w = this.measuredWidth * (1 - scaleX)
            val h = this.measuredHeight * (1 - scaleY)
            return Size(w.toInt(), h.toInt())
        }

        fun RelativeLayout.LayoutParams.hasRule(r: Int): Boolean {
            return this.rules[r] == -1
        }


        fun View?.getMargins(): Point {
            var p = Point()
            if (this == null) {
                return p
            }
            if (this.layoutParams is RelativeLayout.LayoutParams) {
                var params = this.layoutParams as RelativeLayout.LayoutParams
                if (params.hasRule(ALIGN_PARENT_LEFT) && params.hasRule(ALIGN_PARENT_BOTTOM)) {
                    p = Point(params.leftMargin, params.bottomMargin)
                } else if (params.hasRule(ALIGN_PARENT_RIGHT) && params.hasRule(ALIGN_PARENT_BOTTOM)) {
                    p = Point(params.rightMargin, params.bottomMargin)
                } else if (params.hasRule(ALIGN_PARENT_TOP) && params.hasRule(ALIGN_PARENT_RIGHT)) {
                    p = Point(params.rightMargin, params.topMargin)
                } else if (params.hasRule(ALIGN_PARENT_LEFT) && params.hasRule(ALIGN_PARENT_TOP)) {
                    p = Point(params.leftMargin, params.topMargin)
                }
            }
            return p
        }


        fun View.getScaleSize(): SizeF {

            return SizeF(this.measuredWidth * scaleX, measuredHeight * scaleY)
        }


        /**
         *
         * 转换坐标
         * */
        fun View.getAlign(): Int {
            var align = LEFT_BOTTOM
            if (this.layoutParams is RelativeLayout.LayoutParams) {
                var params = this.layoutParams as RelativeLayout.LayoutParams

                if (params.rules[RelativeLayout.ALIGN_PARENT_LEFT] == RelativeLayout.TRUE
                    && params.rules[RelativeLayout.ALIGN_PARENT_BOTTOM] == RelativeLayout.TRUE
                ) {
                    align = LEFT_BOTTOM
                } else if (params.rules[RelativeLayout.ALIGN_PARENT_RIGHT] == RelativeLayout.TRUE
                    && params.rules[RelativeLayout.ALIGN_PARENT_BOTTOM] == RelativeLayout.TRUE
                ) {
                    align = RIGHT_BOTTOM
                } else if (params.rules[RelativeLayout.ALIGN_PARENT_TOP] == RelativeLayout.TRUE
                    && params.rules[RelativeLayout.ALIGN_PARENT_RIGHT] == RelativeLayout.TRUE
                ) {
                    align = RIGHT_TOP
                } else if (params.rules[RelativeLayout.ALIGN_PARENT_LEFT] == RelativeLayout.TRUE
                    && params.rules[RelativeLayout.ALIGN_PARENT_TOP] == RelativeLayout.TRUE
                ) {
                    align = LEFT_TOP
                } else {
                    align = LEFT_BOTTOM
                }
            }
            return align
        }


        fun landscapeToPortraitAlign(origin: Int, landspcaeAlign: Int): Int {
            if (origin == 90) {
                if (landspcaeAlign == PositionHelper.LEFT_TOP) {
                    return PositionHelper.RIGHT_TOP
                } else if (landspcaeAlign == PositionHelper.LEFT_BOTTOM) {
                    return PositionHelper.LEFT_TOP
                } else if (landspcaeAlign == PositionHelper.RIGHT_TOP) {
                    return PositionHelper.RIGHT_BOTTOM
                } else {
                    return PositionHelper.LEFT_BOTTOM
                }
            } else {
                if (landspcaeAlign == PositionHelper.LEFT_TOP) {
                    return PositionHelper.LEFT_BOTTOM
                } else if (landspcaeAlign == PositionHelper.LEFT_BOTTOM) {
                    return PositionHelper.RIGHT_BOTTOM
                } else if (landspcaeAlign == PositionHelper.RIGHT_TOP) {
                    return PositionHelper.LEFT_TOP
                }
            }
            return PositionHelper.RIGHT_TOP
        }
    }

    init {
        reset()
        // forceAdjustWaterMark()
        // 是否需要有偏移
//            activity.put(KEY_SHOW_WATERMARK_PANEL_HEIGHT, activity.get<Int>(KEY_SHOW_WATERMARK_PANEL_HEIGHT)?:0)
        dragViewAdapter?.getDragView()?.getView()?.also {
            it.translationY = recordLastDY
        }
    }

    var isConfirmMode = false


    private var upViewEnableRotate: Boolean? = null

    private var originTranslationY = 0f
    private var lastDragViewTreeObserver: ViewTreeObserver.OnGlobalLayoutListener? = null
    private fun setDragViewTreeOvserver(runnable: Runnable) {
        removeDragViewTreeOvserver()
        dragViewAdapter?.getDragView()?.getView()?.also {
            it.viewTreeObserver?.addOnGlobalLayoutListener(object :
                ViewTreeObserver.OnGlobalLayoutListener {
                override fun onGlobalLayout() {
                    if (it is RotateLayout) {
                        val angle = it.getAngle()
                        if (angle % 180 == 0) {
                            runnable.run()
                            it.viewTreeObserver.removeOnGlobalLayoutListener(this)
                        } else {
                            Log.d(TAG, "wait for screen 0 or 180 ,angle=$angle")
                        }
                    } else {
                        it.viewTreeObserver.removeOnGlobalLayoutListener(this)
                    }
                }

            }.also {
                lastDragViewTreeObserver = it
            })
        }
    }

    private fun removeDragViewTreeOvserver() {
        lastDragViewTreeObserver?.also {
            dragViewAdapter?.getDragView()
                ?.getView()?.viewTreeObserver?.removeOnGlobalLayoutListener(lastDragViewTreeObserver)
        }
    }
}