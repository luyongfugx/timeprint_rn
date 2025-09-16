package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.dragableview

import android.content.Context
import android.graphics.Rect
import android.util.AttributeSet
import android.util.Log
import android.view.GestureDetector.SimpleOnGestureListener
import android.view.MotionEvent
import android.view.View
import android.widget.RelativeLayout
import androidx.core.util.Consumer
import androidx.core.view.GestureDetectorCompat
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.implementations.GpGlCameraPreview
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.BaseFiled
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.RotateLayout
import java.util.LinkedList
import kotlin.math.abs

class DragAbleContainerView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) :
    RelativeLayout(context, attrs, defStyleAttr), PositionHelper.DragViewAdapter {
    private val TAG = "DragAbleLinearLayout"
    private val dragginAlpha = 0.85f
    private val releasAlpha = 1.0f
    private val dragHelper: GPViewDragHelper
    private val dragHelperCallback: ViewDragHelperCallback
    var positionStickHelper: PositionHelper? = null
        set(value) {x
            field = value
            value?.dragViewAdapter = this
        }
    var positionChageCallback: PosChangeCallback? = null
    private val positionChangeListenerList = LinkedList<PosChangeCallback>()

    var topDelta: Int = 0
    var bottomDelta: Int = 0
    var leftDelta: Int = 0
    var rightDelta: Int = 0
    var dragAble: Boolean = true


    var downPosX: Float = 200f
    var downPosY: Float = 300f

    private var isDragging = false
        set(value) {
            field = value
            isDraggingField.value = value
            isDraggingField.ifChanged()?.let {
            }
            dragView.forEach {
                it.enableRotate(!field)
            }
        }


    private var isDraggingField = BaseFiled(isDragging)

    var boundView: View? = null
    var moveViewProperty: PositionHelper.DragViewAdapter.DragViewProperty? = null

    var enableLayout = true
    var boundViewID: Int = -1
    var moveViewID: Int = -1


    var dragView: MutableList<IDragAble> = ArrayList()
    var changeLayout = false
    lateinit var consumer: Consumer<Boolean>

    var lastX = 200f
    var lastY = 200f
    var action: (Int, Int, Int, Boolean) -> Unit = { _, _, _, _ -> }

    init {
        dragHelperCallback = ViewDragHelperCallback()
        dragHelper = GPViewDragHelper.create(this, dragHelperCallback)

        val obtainStyledAttributes =
            context.obtainStyledAttributes(attrs, R.styleable.DragAbleContainerView)

        boundViewID =
            obtainStyledAttributes.getResourceId(R.styleable.DragAbleContainerView_bound_view, -1)

        moveViewID =
            obtainStyledAttributes.getResourceId(R.styleable.DragAbleContainerView_move_view, -1)
        obtainStyledAttributes.recycle()
    }

    override fun onFinishInflate() {
        super.onFinishInflate()
        boundView = findViewById<View>(boundViewID)
    }

    fun addOnPositionChangeListener(listener: PosChangeCallback) {
        positionChangeListenerList.add(listener)
    }

    fun removeOnPositionChangeListener(listener: PosChangeCallback) {
        positionChangeListenerList.remove(listener)
    }

    override fun dispatchTouchEvent(ev: MotionEvent?): Boolean {
        val x = ev?.x ?: 0f
        val y = ev?.y ?: 0f

        when (ev?.action) {
            MotionEvent.ACTION_DOWN -> {
                lastX = x
                lastY = y
                action.invoke(MotionEvent.ACTION_DOWN, x.toInt(), y.toInt(), true)
            }

            MotionEvent.ACTION_MOVE -> {
                val offX = abs(x - lastX)
                val offY = abs(y - lastY)
                if (offX != 0f && offY != 0f) {
                    action.invoke(
                        MotionEvent.ACTION_MOVE,
                        x.toInt(),
                        y.toInt(),
                        !(offX > 0 || offY > 0)
                    )
                }
            }

            MotionEvent.ACTION_UP -> {
                action.invoke(MotionEvent.ACTION_UP, x.toInt(), y.toInt(), false)
            }
        }
        return super.dispatchTouchEvent(ev)
    }

    private val gestureDetectorCompat =
        GestureDetectorCompat(getContext(), object : SimpleOnGestureListener() {

            override fun onSingleTapConfirmed(e: MotionEvent): Boolean {
                if (e.action == MotionEvent.ACTION_UP) {
                    dragView.forEach {
                        if (inViewInBounds(it.getView(), downPosX, downPosY)) {
                            it.getView().callOnClick()
                            return true
                        }
                    }
                    return true
                }
                return super.onSingleTapConfirmed(e)
            }
        })

    //将事件交给dragHelper处理
    override fun onInterceptTouchEvent(event: MotionEvent): Boolean {
        return if (dragAble) {
            try {
                var action = event.action
                var ges = gestureDetectorCompat.onTouchEvent(event)
                var should = dragHelper.shouldInterceptTouchEvent(event)
                if (action == MotionEvent.ACTION_DOWN) {
                    downPosX = event.rawX
                    downPosY = event.rawY
                }
                when (action) {
                    MotionEvent.ACTION_DOWN, MotionEvent.ACTION_UP -> {
                        dragView.forEach {
                            ges = ges && inViewInBounds(it.getView(), event.rawX, event.rawY)
                        }

                    }
                }
                return should || ges
                return ges
            } catch (e: Throwable) {
                Log.e(TAG,  e.toString())
               // e.printStackTrace()
            }
            return false
        } else {
            false
        }
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {

        val activity = (context as MainActivity)
//        if (activity.mPreview is CameraXPreview){
//            val preview =   activity.mPreview as CameraXPreview
//            preview.onTouchListener(event)
//            dragHelper.processTouchEvent(event)
//        }
        //20250614 改成GpGlCameraPreview
        if (activity.mPreview is GpGlCameraPreview){
            val preview =   activity.mPreview as GpGlCameraPreview
            preview.onTouchListener(event)
            dragHelper.processTouchEvent(event)
        }


        return true
    }


    override fun computeScroll() {
        super.computeScroll()
        if (dragHelper.continueSettling(true)) {
            invalidate()
        }
    }

    override fun onViewAdded(child: View?) {
        super.onViewAdded(child)
        try {
            if (child is IDragAble && child.dragEnable()) {
                dragView.add(child)
            }
            if (child?.id == moveViewID) {
                if (child is RotateLayout) {
                    (child as RotateLayout?)?.also {
                        moveViewProperty =
                            object : PositionHelper.DragViewAdapter.DragViewProperty {
                                override fun getView(): View {
                                    return it
                                }

                                override fun getAngle(): Int {
                                    return it.getAngle()
                                }

                                override fun enableRotate(): Boolean = it.enableRotate()
                                override fun enableRotate(enable: Boolean) {
                                    it.enableRotate(enable)
                                }

                            }
                    } // 水印的view加入的时候重新布局
                    positionChangeListenerList.forEach {
                        it.onViewReleased(child, child.left, child.top)
                    }
                }

            }
        } catch (e: Throwable) {
            e.printStackTrace()
        }

    }

    override fun onViewRemoved(child: View?) {
        super.onViewRemoved(child)
        if (child is IDragAble) {
            dragView.remove(child)
        }
        if (child?.id == moveViewID) {
            if (child is RotateLayout) {
                (child as RotateLayout?)?.also {
                    moveViewProperty = null
                }
            }
        }
    }

    /**
     * 约束可以拖拽的区域
     */
//    fun setDragBounds(topDelta: Int, bottomDelta: Int, leftDelta: Int, rightDelta: Int) {
//        this.topDelta = topDelta
//        this.bottomDelta = bottomDelta
//        this.leftDelta = leftDelta
//        this.rightDelta = rightDelta
//
//    }
//
//    fun getDragBounds(): Rect {
//        return Rect(leftDelta, topDelta, rightDelta, bottomDelta)
//    }

    override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
        if (changeLayout) {
            super.onLayout(changed, l, t, r, b)
            consumer.accept(false)
            return
        }
        if (isDragging) {
            return
        }
        if (!enableLayout) {
            return
        }
        super.onLayout(changed, l, t, r, b)
    }


    inner class ViewDragHelperCallback : GPViewDragHelper.Callback() {
        override fun tryCaptureView(child: View, pointerId: Int): Boolean {
            var flag = false
            if (child is IDragAble) {
                if (dragView.contains(child) && child.dragEnable() && inViewInBounds(
                        child,
                        downPosX,
                        downPosY
                    )
                ) {
                    flag = true
                }
            }
            if (flag) { //                dragView = child as IDragable
                child.alpha = dragginAlpha
               // positionChageCallback?.onViewCaptured(child)
                positionStickHelper?.onViewCaptured(child)
                positionChangeListenerList.forEach { it.onViewCaptured(child) }
            }
            return flag
        }


        override fun onViewPositionChanged(
            changedView: View,
            left: Int,
            top: Int,
            dx: Int,
            dy: Int
        ) {
            super.onViewPositionChanged(changedView, left, top, dx, dy)
           // positionChageCallback?.onViewPositionChanged(changedView, left, top, dx, dy)
            positionStickHelper?.onViewPositionChanged(changedView, left, top, dx, dy)
            positionChangeListenerList.forEach {
                it.onViewPositionChanged(
                    changedView,
                    left,
                    top,
                    dx,
                    dy
                )
            }
            isDragging = true
        }


        override fun getViewHorizontalDragRange(child: View): Int {
            return (measuredWidth - child.measuredWidth * child.scaleX - leftDelta - rightDelta).toInt() //容器的水平滑动范围 0 -》当前容器的剩余空间 考虑到我们的容器有缩放那么理论上空间会更大一点
        }

        override fun getViewVerticalDragRange(child: View): Int {
            return (measuredHeight - child.measuredHeight * child.scaleY - topDelta - bottomDelta).toInt()
        }

        override fun clampViewPositionHorizontal(child: View, newLeft: Int, dx: Int): Int {

            if (child.scaleX != 1f) {
                var sw = (child.measuredWidth * (1 - child.scaleX)) / 2
                if (newLeft < leftDelta - sw) {
                    return -sw.toInt() + leftDelta
                } else if (newLeft > measuredWidth - child.measuredWidth + sw - rightDelta) {
                    return (measuredWidth - child.measuredWidth + sw - rightDelta).toInt()
                } else {
                    return newLeft
                }

            } else {
                if (newLeft < leftDelta - dx) {
                    return left + leftDelta
                } else if (newLeft + child.measuredWidth + dx > measuredWidth - rightDelta) {
                    return measuredWidth - rightDelta - child.measuredWidth
                } else {
                    return newLeft
                }
            }
        }

        override fun clampViewPositionVertical(child: View, newTop: Int, dy: Int): Int {
            if (child.scaleY != 1f) {
                var sh = (child.measuredHeight * (1 - child.scaleY)) / 2
                if (newTop < topDelta - sh) {
                    return topDelta - sh.toInt()
                } else if (newTop > measuredHeight - child.measuredHeight + sh - bottomDelta) {
                    return (measuredHeight - child.measuredHeight + sh - bottomDelta).toInt()
                } else {
                    return newTop
                }

            } else {
                if (newTop + dy < topDelta) {
                    return topDelta
                } else if (newTop + dy + child.measuredHeight > measuredHeight - bottomDelta) {
                    return measuredHeight - bottomDelta - child.measuredHeight
                } else {
                    return newTop
                }
            }
        }


        override fun onViewReleased(releasedChild: View, xvel: Float, yvel: Float) {
            super.onViewReleased(releasedChild, xvel, yvel)
            positionChageCallback?.onViewReleased(
                releasedChild, releasedChild.left, releasedChild.top
            )
            positionStickHelper?.onViewReleased(
                releasedChild, releasedChild.left, releasedChild.top
            )
            positionChangeListenerList.forEach {
                it.onViewReleased(releasedChild, releasedChild.left, releasedChild.top)
            }
            releasedChild.alpha = releasAlpha
            isDragging = false
        }

        override fun getOrderedChildIndex(index: Int): Int {
            try {
                val childAt = getChildAt(index)
                if (childAt is IDragAble && dragView.contains(childAt)) {
                    return index
                }

                if (dragView.size > 0) {
                    return indexOfChild(dragView[dragView.size - 1] as View)
                }
            } catch (e: Throwable) {
                e.printStackTrace()
            }
            return index

        }
    }


    var outRect = Rect()
    var location = IntArray(2)
    private fun inViewInBounds(view: View?, x: Float, y: Float): Boolean {
        view?.let {
            it.getDrawingRect(outRect)
            it.getLocationOnScreen(location)
            outRect.offset(location[0], location[1])
            return outRect.contains(x.toInt(), y.toInt())
        }
        return false
    }

    override fun getDragViewContainer(): View? {
        return boundView
    }

    override fun getDragView(): PositionHelper.DragViewAdapter.DragViewProperty? {
        return moveViewProperty
    }

}