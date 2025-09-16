package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.views

import android.annotation.SuppressLint
import android.graphics.Color
import android.graphics.Typeface
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpKits
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.EditClickFrom
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.WatermarkItemManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.WatermarkManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.BaseWatermarkModel
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkBaseID
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItemID

/**
 *@author waynelu
 * 自定义item列表
 * @property dataSet
 */
open class BaseItemRecyclerViewAdapter() : RecyclerView.Adapter<BaseItemViewHolder>() {
    companion object {
        private const val TAG = "BaseItemRecyclerViewAdapter" // 定义日志标签
    }
    protected lateinit var dataList: List<WatermarkItem?>;
    protected lateinit var watermarkModel: BaseWatermarkModel;
    //默认
    protected var maxWith = 420;
    protected var showDot = false;
    protected var dotColor = Color.YELLOW;
    protected var showIcon = false;
    protected var isIconColorAsTextColor = true

    constructor(dataList: List<WatermarkItem?>, watermarkModel: BaseWatermarkModel,maxWith:Int = 320,showDot:Boolean = false,dotColor: Int = Color.YELLOW,showIcon:Boolean = false,isIconColorAsTextColor:Boolean= true) : this() {
        this.dataList = dataList
        this.watermarkModel = watermarkModel
        this.maxWith = maxWith
        this.showDot = showDot
        this.dotColor = dotColor
        this.showIcon = showIcon
        this.isIconColorAsTextColor = isIconColorAsTextColor
    }


//    open class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
//        var textView: TextView = view.findViewById(R.id.water_mark_item_text)
//        var dotView: View = view.findViewById(R.id.water_mark_item_dot)
//        var dotWrapper: View = view.findViewById(R.id.water_mark_item_dot_wrapper)
//    }

     fun setData(newDataList: List<WatermarkItem?>, newWatermarkModel: BaseWatermarkModel) {
         watermarkModel = newWatermarkModel
        dataList = newDataList
        notifyDataSetChanged()
    }
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): BaseItemViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.water_mark_item, parent, false)
        //貌似必须在这里绑定事件
        view.setOnClickListener({
            if (parent.context is MainActivity) {
                (parent.context as MainActivity).showEditWaterView(EditClickFrom.Watermark)
            }
        })
        return BaseItemViewHolder(view)
    }

    @SuppressLint("SuspiciousIndentation")
    override fun onBindViewHolder(holder: BaseItemViewHolder, position: Int) {
            val item = dataList[position]
           // Log.d(TAG,"item id ${item?.id}")
            var text = item?.title + " : " + item?.content
            //如果显示icon，则不显示标题
            if(showIcon && item?.id!! <10000){
                text = item.content.toString()
            }

            holder.circularCharacterView?.setCharacterBackgroundColor(watermarkModel.templateColor)
        holder.circularCharacterView?.setTextColor(watermarkModel.textColor)
             holder.circularCharacterView?.setText(text)
        //如果是16
        if (item?.id == WatermarkItemID.phoneNumber1.id || item?.id == WatermarkItemID.phoneNumber2.id){
            holder.textView.visibility = View.GONE
            holder.circularCharacterViewWrapper?.visibility = View.VISIBLE
            Log.d(TAG,"circularCharacterViewWrapper width ${ holder.circularCharacterViewWrapper?.width} ${ holder.circularCharacterView?.width}")
        }
        else {
            holder.textView.visibility = View.VISIBLE
            holder.circularCharacterViewWrapper?.visibility = View.GONE
            holder.textView.maxWidth = GpKits.Dimens.dpToPxInt(App.context,maxWith*1f)
            holder.textView.text = text
            //第一行粗体
            if (position == 0 && WatermarkManager.isFirstItemBold()){
                holder.textView.setTypeface(Typeface.DEFAULT_BOLD);
            }
            else {
                holder.textView.setTypeface(Typeface.DEFAULT);
            }
            holder.textView.setTextColor(watermarkModel.textColor)
        }


            if (showIcon  && item?.id!! <10000){
                holder.iconWrapper?.visibility = View.VISIBLE
                val iconId = item.id?.let { getIcon(it) }
                if (iconId != null) {
                    holder.iconView?.setImageResource(iconId)
                    if (isIconColorAsTextColor){
                        holder.iconView?.setColorFilter(watermarkModel.textColor)
                    }
                    else {
                        holder.iconView?.setColorFilter(watermarkModel.templateColor)
                    }

                }
            }else{
                holder.iconWrapper?.visibility = View.GONE
            }
            if (showDot){
                holder.dotWrapper?.visibility = View.VISIBLE
                holder.dotView?.setBackgroundColor(dotColor)
            }else{
                holder.dotWrapper?.visibility = View.GONE
            }
    }
    private fun getIcon(itemID: Int): Int{
     var d =   when(itemID){
            WatermarkItemID.address.id -> {
                R.drawable.clock_location_white
            }
            WatermarkItemID.customItem.id -> {
                R.drawable.note
            }
            WatermarkItemID.logo.id -> {
                R.drawable.circle_white_border
            }
            WatermarkItemID.time.id -> {
                R.drawable.time
            }
            WatermarkItemID.coordinate.id -> {
                R.drawable.latlng
            }
            WatermarkItemID.map.id -> {
                R.drawable.latlng
            }
            WatermarkItemID.weather.id -> {
                R.drawable.weather
            }
            WatermarkItemID.altitude.id -> {
                R.drawable.altitude
            }
            WatermarkItemID.note.id -> {
                R.drawable.note
            }
         WatermarkItemID.phoneNumber1.id -> {
             R.drawable.phone
         }
         WatermarkItemID.phoneNumber2.id -> {
             R.drawable.phone
         }
            WatermarkItemID.watermarkTitle.id -> {
                R.drawable.edit
            }
            WatermarkItemID.watermarkSubtitle.id -> {
                R.drawable.edit
            }
            WatermarkItemID.wm7_project.id -> {
                R.drawable.circle_white_border
            }
            WatermarkItemID.wm7_developer.id -> {
                R.drawable.people
            }
            WatermarkItemID.wm7_description.id -> {
                R.drawable.note
            }
            WatermarkItemID.wm7_area.id -> {
                R.drawable.circle_white_border
            }
            WatermarkItemID.wm7_operator.id -> {
                R.drawable.people
            }
            WatermarkItemID.wm7_inspectior.id -> {
                R.drawable.circle_white_border
            }
            WatermarkItemID.wm7_inspection.id -> {
                R.drawable.circle_white_border
            }
            WatermarkItemID.wm8_meeting_title.id -> {
                R.drawable.note
            }
            WatermarkItemID.wm10_clean_title.id -> {
                R.drawable.note
            }

         else -> {
             R.drawable.note
         }
     }
        return d
    }
    override fun getItemCount(): Int {
        val items = dataList
        return items.size
    }

}