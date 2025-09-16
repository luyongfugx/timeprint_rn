package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog

import android.util.SparseArray
import android.view.View
import android.widget.TextView

/**
 * dialog viewHolder
 *
 * @param view
 */
class GpViewHolder private constructor(view: View) {
    private val views = SparseArray<View?>()
    val convertView: View? = view

    fun <T : View?> getView(viewId: Int): T? {
        var view = views[viewId]
        if (view == null && convertView != null) {
            view = convertView.findViewById(viewId)
            views.put(viewId, view)
        }
        return view as T?
    }

    fun clearView() {
//        if (views != null){
//            if (views.size() > 0){
//                views.clear();
//            }
//            views = null;
//        }
//        convertView = null;
    }

    fun setText(viewId: Int, text: String?) {
        val textView = getView<TextView>(viewId)!!
        textView.text = text
    }

    fun setText(viewId: Int, textId: Int) {
        val textView = getView<TextView>(viewId)!!
        textView.setText(textId)
    }

    fun setTextColor(viewId: Int, colorId: Int) {
        val textView = getView<TextView>(viewId)!!
        textView.setTextColor(colorId)
    }

    fun setOnClickListener(viewId: Int, clickListener: View.OnClickListener?) {
        val view = getView<View>(viewId)!!
        view.setOnClickListener(clickListener)
    }

    fun setBackgroundResource(viewId: Int, resId: Int) {
        val view = getView<View>(viewId)!!
        view.setBackgroundResource(resId)
    }

    fun setBackgroundColor(viewId: Int, colorId: Int) {
        val view = getView<View>(viewId)!!
        view.setBackgroundColor(colorId)
    }

    companion object {
        fun create(view: View): GpViewHolder {
            return GpViewHolder(view)
        }
    }
}