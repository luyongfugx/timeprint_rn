package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget

import android.content.Context
import android.graphics.Canvas
import android.util.AttributeSet
import android.view.View
import android.view.ViewGroup
import androidx.annotation.IdRes
import androidx.annotation.LayoutRes
import androidx.asynclayoutinflater.view.AsyncLayoutInflater
import androidx.core.util.Consumer
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R


/**
 * A copy ViewStub is an invisible, zero-sized View that can be used to lazily inflate
 * layout resources at runtime, and support inflate with asyncInflater.
 *
 * @attr ref android.R.styleable#ViewStub_inflatedId
 * @attr ref android.R.styleable#ViewStub_layout
 *
 */
class AsyncView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet?,
    defStyleAttr: Int = 0,
    defStyleRes: Int = 0
) :
    View(context) {
    /**
     * Returns the id taken by the inflated view. If the inflated id is
     * [View.NO_ID], the inflated view keeps its original id.
     *
     * @return A positive integer used to identify the inflated view or
     * [.NO_ID] if the inflated view should keep its id.
     *
     * @see .setInflatedId
     * @attr ref android.R.styleable#ViewStub_inflatedId
     */
    /**
     * Defines the id taken by the inflated view. If the inflated id is
     * [View.NO_ID], the inflated view keeps its original id.
     *
     * @param inflatedId A positive integer used to identify the inflated view or
     * [.NO_ID] if the inflated view should keep its id.
     *
     * @see .getInflatedId
     * @attr ref android.R.styleable#ViewStub_inflatedId
     */
    @get:IdRes
    var inflatedId: Int = 0
    /**
     * Returns the layout resource that will be used by [.setVisibility] or
     * [.inflate]  to replace this StubbedView
     * in its parent by another view.
     *
     * @return The layout resource identifier used to inflate the new View.
     *
     * @see .setLayoutResource
     * @see .setVisibility
     * @see .inflate
     * @attr ref android.R.styleable#ViewStub_layout
     */
    /**
     * Specifies the layout resource to inflate when this StubbedView becomes visible or invisible
     * or when [.inflate] is invoked. The View created by inflating the layout resource is
     * used to replace this StubbedView in its parent.
     *
     * @param layoutResource A valid layout resource identifier (different from 0.)
     *
     * @see .getLayoutResource
     * @see .setVisibility
     * @see .inflate
     * @attr ref android.R.styleable#ViewStub_layout
     */
    @get:LayoutRes
    var layoutResource: Int

    /**
     * Creates a new ViewStub with the specified layout resource.
     *
     * @param context The application's environment.
     * @param layoutResource The reference to a layout resource that will be inflated.
     */
    @JvmOverloads
    constructor(context: Context, @LayoutRes layoutResource: Int = 0) : this(context, null) {
        this.layoutResource = layoutResource
    }

    /** @hide
     */
    fun setInflatedIdAsync(@IdRes inflatedId: Int): Runnable? {
        this.inflatedId = inflatedId
        return null
    }

    /** @hide
     */
    fun setLayoutResourceAsync(@LayoutRes layoutResource: Int): Runnable? {
        this.layoutResource = layoutResource
        return null
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        setMeasuredDimension(0, 0)
    }

    private val noDraw = true

    init {
        val a = context.obtainStyledAttributes(
            attrs,
            R.styleable.AsyncView, defStyleAttr, defStyleRes
        )
        id = a.getResourceId(R.styleable.AsyncView_asyncId, NO_ID)
        inflatedId = a.getResourceId(R.styleable.AsyncView_asyncInflatedId, NO_ID)
        layoutResource = a.getResourceId(R.styleable.AsyncView_asyncLayout, 0)
        a.recycle()
        visibility = GONE
        setWillNotDraw(true)
    }

    override fun draw(canvas: Canvas) {
        if (noDraw) {
            return
        }
        super.draw(canvas)
    }

    override fun dispatchDraw(canvas: Canvas) {
    }

    private fun inflateViewNoAdd(
        asyncLayoutInflater: AsyncLayoutInflater,
        parent: ViewGroup,
        onInflateListener: Consumer<View>?
    ) {
        asyncLayoutInflater.inflate(layoutResource, parent, object :
            AsyncLayoutInflater.OnInflateFinishedListener {
            override fun onInflateFinished(view: View, resid: Int, parent: ViewGroup?) {
                if (inflatedId != NO_ID) {
                    view.id = inflatedId
                    replaceSelfWithView(view, parent!!)
                    onInflateListener?.accept(view)
                }
            }
        })
    }

    private fun replaceSelfWithView(view: View, parent: ViewGroup) {
        val index = parent.indexOfChild(this)
        parent.removeViewInLayout(this)

        val layoutParams = layoutParams
        if (layoutParams != null) {
            parent.addView(view, index, layoutParams)
        } else {
            parent.addView(view, index)
        }
    }

    /**
     * Inflates the layout resource identified by [.getLayoutResource]
     * and replaces this StubbedView in its parent by the inflated layout resource.
     *
     * @return The inflated layout resource.
     */
    fun inflate(asyncLayoutInflater: AsyncLayoutInflater, onInflateListener: Consumer<View>?) {
        val viewParent = parent

        if (viewParent != null && viewParent is ViewGroup) {
            if (layoutResource != 0) {
                inflateViewNoAdd(asyncLayoutInflater, viewParent, onInflateListener)
            } else {
                throw IllegalArgumentException("ViewStub must have a valid layoutResource")
            }
        } else {
            throw IllegalStateException("ViewStub must have a non-null ViewGroup viewParent")
        }
    }
}