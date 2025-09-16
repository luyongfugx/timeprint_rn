package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog

import android.os.Bundle
import android.view.View
import androidx.annotation.LayoutRes


class GpDialog<T> : GPBaseDialog() {
    private var convertListener: GpViewConvertListener? = null
    private var holder: GpViewHolder? = null

    override fun intLayoutId(): Int {
        return layoutId
    }

    override val layoutView: View?
        get() = contentView

    val viewHolder: GpViewHolder?
        get() = holder

    override fun convertView(holder: GpViewHolder?, dialog: GPBaseDialog?) {
        this.holder = holder
        convertListener?.convertView(holder, dialog)
    }

    fun setContentView(contentView: View): GpDialog<*> {
        this.contentView = contentView
        return this
    }

    fun setLayoutId(@LayoutRes layoutId: Int): GpDialog<*> {
        this.layoutId = layoutId
        return this
    }

    fun setConvertListener(convertListener: GpViewConvertListener?): GpDialog<*> {
        this.convertListener = convertListener
        return this
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
    }

    override fun onDestroyView() {
        super.onDestroyView()
        convertListener = null
    }

    companion object {
        fun init(): GpDialog<*> {
            return GpDialog<Any?>()
        }
    }
}