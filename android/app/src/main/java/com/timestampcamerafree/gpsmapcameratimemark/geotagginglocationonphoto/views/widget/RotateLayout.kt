package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget

import android.content.Context
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.RectF
import android.util.AttributeSet
import android.util.Log
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.ViewParent
import android.widget.RelativeLayout
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.dragableview.IDragAble
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sin



open class RotateLayout @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : RelativeLayout(context, attrs), IDragAble {
    private val TAG = "RotateLayout" // 定义日志标签
    private var angle: Int

    private val rotateMatrix = Matrix()

    private val viewRectRotated = Rect()

    private val tempRectF1 = RectF()
    private val tempRectF2 = RectF()

    private var dragEnable = true
    private val viewTouchPoint = FloatArray(2)
    private val childTouchPoint = FloatArray(2)

    private var angleChanged = true

    private var enableRotate = true

    private var tempAngle = Int.MAX_VALUE

    private var enableScale = false
    private var watermarkScale = 1.0f

    private var mIsMatchParent = false

    init {
        val a = context.obtainStyledAttributes(attrs, R.styleable.RotateLayout)
        angle = a.getInt(R.styleable.RotateLayout_angle, 0)
        dragEnable = a.getBoolean(R.styleable.RotateLayout_dragEnable, true)
        a.recycle()
        setWillNotDraw(false)
    }

    override fun enableRotate(enableRotate: Boolean) {
        this.enableRotate = enableRotate
        if (enableRotate && tempAngle != Int.MAX_VALUE) {
            setAngle(tempAngle)
            tempAngle = Int.MAX_VALUE
        }
    }

    override fun enableRotate(): Boolean {
        return enableRotate
    }

    /**
     * Returns current angle of this layout
     */
    override fun getAngle(): Int {
        return angle
    }

    override fun getView(): View {
        return this
    }

    /**
     * Sets current angle of this layout.
     */
    fun setAngle(angle: Int) {
        Log.d(TAG, "setAngle:$angle,enableRotate:$enableRotate")
        if (!enableRotate) {
            tempAngle = angle
            return
        }
        if (this.angle != angle) {
            this.angle = angle
            angleChanged = true
            requestLayout()
            invalidate()
        }
    }

    /**
     *
     * 忽略 enableRotate
     */
    fun forceSetAngle(angle: Int) {
        if (this.angle != angle) {
            this.angle = angle
            angleChanged = true
            requestLayout()
            invalidate()
        }
    }

    /**
     * 设置位置
     *
     * @param x
     * @param y
     */
    fun setPos(top: Int, left: Int) {
        this.top = top
        this.left = left
    }
    fun setScale(scale: Float) {
        watermarkScale = scale
        enableScale = scale != 1.0f

        val child = onlyChild
        if (child != null) {
            child.scaleX = watermarkScale
            child.scaleY = watermarkScale
        }
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val child = onlyChild
        var maxHeight = 0
        var maxWidth = 0
        var childState = 0

        if (child != null) {
            if (abs((angle % 180)) == 90) {
                if (watermarkScale < 1.0) {
                    measureChildWithMargins(
                        child,
                        MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED),
                        0,
                        MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED),
                        0
                    )
                } else {

                    if (mIsMatchParent) {
                        child.layoutParams.width = ViewGroup.LayoutParams.WRAP_CONTENT
                    }
                    measureChildWithMargins(child, heightMeasureSpec, 0, widthMeasureSpec, 0)
                }
                val lp = child.layoutParams as LayoutParams
                maxWidth = max(
                    maxWidth.toDouble(),
                    (child.measuredWidth + lp.topMargin + lp.bottomMargin).toDouble()
                ).toInt()
                maxHeight = max(
                    maxHeight.toDouble(),
                    (child.measuredHeight + lp.leftMargin + lp.rightMargin).toDouble()
                ).toInt()
                val realWidth = (maxWidth * watermarkScale).toInt()
                val realHeight = (maxHeight * watermarkScale).toInt()

                setMeasuredDimension(realHeight, realWidth)
            } else if (abs((angle % 180)) == 0) {
                if (watermarkScale < 1.0) {
                    measureChildWithMargins(
                        child,
                        MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED),
                        0,
                        heightMeasureSpec,
                        0
                    )
                } else {
                    measureChildWithMargins(child, widthMeasureSpec, 0, heightMeasureSpec, 0)
                }
                val lp = child.layoutParams as LayoutParams
                maxWidth = max(
                    maxWidth.toDouble(),
                    (child.measuredWidth + lp.leftMargin + lp.rightMargin).toDouble()
                ).toInt()
                maxHeight = max(
                    maxHeight.toDouble(),
                    (child.measuredHeight + lp.topMargin + lp.bottomMargin).toDouble()
                ).toInt()
                childState = combineMeasuredStates(childState, child.measuredState)
                var resolveWidthAndState =
                    resolveSizeAndState(maxWidth, widthMeasureSpec, childState)
                var resolveHeightAndState = resolveSizeAndState(
                    maxHeight, heightMeasureSpec,
                    childState shl MEASURED_HEIGHT_STATE_SHIFT
                )
                if (MeasureSpec.getMode(widthMeasureSpec) == MeasureSpec.AT_MOST) {
                    val realWidth =
                        ((resolveWidthAndState and MEASURED_SIZE_MASK) * watermarkScale).toInt()
                    resolveWidthAndState = realWidth or (childState and MEASURED_STATE_MASK)
                }

                val realHeight =
                    ((resolveHeightAndState and MEASURED_SIZE_MASK) * watermarkScale).toInt()
                resolveHeightAndState =
                    realHeight or ((childState shl MEASURED_HEIGHT_STATE_SHIFT) and MEASURED_STATE_MASK)
                setMeasuredDimension(resolveWidthAndState, resolveHeightAndState)
            } else {
                val childWithMeasureSpec = MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED)
                val childHeightMeasureSpec = MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED)
                measureChild(child, childWithMeasureSpec, childHeightMeasureSpec)

                val measuredWidth = ceil(
                    child.measuredWidth * abs(cos(angle_c())) + child.measuredHeight * abs(
                        sin(angle_c())
                    )
                ).toInt()
                val measuredHeight = ceil(
                    child.measuredWidth * abs(sin(angle_c())) + child.measuredHeight * abs(
                        cos(angle_c())
                    )
                ).toInt()

                setMeasuredDimension(
                    (resolveSize(measuredWidth, widthMeasureSpec) * watermarkScale).toInt(),
                    (resolveSize(measuredHeight, heightMeasureSpec) * watermarkScale).toInt()
                )
            }
        } else {
            super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        }
    }


    override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
        val layoutWidth = r - l
        val layoutHeight = b - t
        if (angleChanged || changed) {
            val layoutRect = tempRectF1
            layoutRect[0f, 0f, layoutWidth.toFloat()] = layoutHeight.toFloat()
            val layoutRectRotated = tempRectF2
            rotateMatrix.setRotate(angle.toFloat(), layoutRect.centerX(), layoutRect.centerY())
            rotateMatrix.mapRect(layoutRectRotated, layoutRect)
            layoutRectRotated.round(viewRectRotated)
            angleChanged = false
        }

        val child = onlyChild
        if (child != null) {
            val childLeft = (layoutWidth - child.measuredWidth) / 2
            val childTop = (layoutHeight - child.measuredHeight) / 2
            val childRight = childLeft + child.measuredWidth
            val childBottom = childTop + child.measuredHeight
            child.layout(childLeft, childTop, childRight, childBottom)
        }
    }

    override fun setScaleX(scaleX: Float) {
        super.setScaleX(scaleX)
    }

    override fun setScaleY(scaleY: Float) {
        super.setScaleY(scaleY)
    }

    override fun dispatchDraw(canvas: Canvas) {
        canvas.save()
        canvas.rotate(-angle.toFloat(), width / 2f, height / 2f)
        super.dispatchDraw(canvas)
        canvas.restore()
    }
    //注销掉，否则会有华为手机崩溃问题

//    override fun invalidateChildInParent(location: IntArray, dirty: Rect): ViewParent {
//        invalidate()
//        return super.invalidateChildInParent(location, dirty)
//    }

    override fun dispatchTouchEvent(event: MotionEvent): Boolean {
        viewTouchPoint[0] = event.x
        viewTouchPoint[1] = event.y

        rotateMatrix.mapPoints(childTouchPoint, viewTouchPoint)

        event.setLocation(childTouchPoint[0], childTouchPoint[1])
        val result = super.dispatchTouchEvent(event)
        event.setLocation(viewTouchPoint[0], viewTouchPoint[1])

        return result
    }

    private val onlyChild: View?
        get() = getChildView()

    private fun getChildView(): View? {
        return if (childCount > 0) {
            getChildAt(0)
        } else {
            null
        }
    }
    /**
     * Circle angle, from 0 to TAU
     */
    private fun angle_c(): Double {
        // True circle constant, not that petty imposter known as "PI"
        val TAU = 2 * Math.PI
        return TAU * angle / 360
    }

    override fun dragEnable(): Boolean {
        return dragEnable
    }

    override fun addView(child: View) {
        if (watermarkScale != 1.0f) {
            child.scaleX = watermarkScale
            child.scaleY = watermarkScale
        }
        super.addView(child)
    }

    fun setWidthMatchParent(isMatchParent: Boolean) {
        this.mIsMatchParent = isMatchParent
    }
}