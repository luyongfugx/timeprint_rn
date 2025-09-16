package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.views

import android.view.View
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.CircularCharacterView


open class BaseItemViewHolder(view: View) : RecyclerView.ViewHolder(view) {
    var textView: TextView = view.findViewById(R.id.water_mark_item_text)
    var dotView: View? = view.findViewById(R.id.water_mark_item_dot)
    var dotWrapper: View? = view.findViewById(R.id.water_mark_item_dot_wrapper)
    var iconWrapper: View? = view.findViewById(R.id.water_mark_item_icon_wrapper)
    var iconView: ImageView? = view.findViewById(R.id.water_mark_item_icon)
    var circularCharacterViewWrapper: View? = view.findViewById(R.id.water_mark_item_text_circleView_wrapper)
    var circularCharacterView: CircularCharacterView? = view.findViewById(R.id.water_mark_item_text_circleView)
    var titleView: TextView? = view.findViewById(R.id.water_mark_item_title)
    var lineVerticalView: View? = view.findViewById(R.id.water_mark_item_line_vertical)
    var lineView: View? = view.findViewById(R.id.water_mark_item_line)
    var wrapperView: LinearLayout? = view.findViewById(R.id.water_mark_item_wrapper)
}