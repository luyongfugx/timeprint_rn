package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.views

import android.graphics.Color
import android.graphics.Typeface
import android.view.LayoutInflater
import android.view.ViewGroup
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpKits
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.EditClickFrom
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.WatermarkManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.BaseWatermarkModel
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItem

/**
 * 表格GridItemRecyclerViewAdapter
 * @constructor
 * TODO
 *
 * @param dataList
 * @param watermarkModel
 */
 class GridItemRecyclerViewAdapter(dataList: List<WatermarkItem?>, watermarkModel: BaseWatermarkModel,maxWith:Int = 320,showDot:Boolean = false,dotColor: Int = Color.YELLOW):
    BaseItemRecyclerViewAdapter(dataList,watermarkModel,maxWith,showDot,dotColor) {
    companion object {
        private const val TAG = "GridItemRecyclerViewAdapter" // 定义日志标签
    }



    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): BaseItemViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.water_mark_grid_item, parent, false)
        //貌似必须在这里绑定事件
        view.setOnClickListener({
            if (parent.context is MainActivity) {
                (parent.context as MainActivity).showEditWaterView(EditClickFrom.Watermark)
            }
        })
        return BaseItemViewHolder(view)
    }

    override  fun onBindViewHolder(holder: BaseItemViewHolder, position: Int) {

        val item = dataList[position]
         holder.titleView?.text = item?.title
         holder.textView.text = item?.content
         holder.titleView?.setTextColor(watermarkModel.textColor)
        //第一行粗体
        if (position == 0 && WatermarkManager.isFirstItemBold()){
            holder.textView.setTypeface(Typeface.DEFAULT_BOLD);
        }
        else {
            holder.textView.setTypeface(Typeface.DEFAULT);

        }
         holder.titleView?.maxWidth = GpKits.Dimens.dpToPxInt(App.context,maxWith*0.3f*1f)
         holder.textView.setTextColor(watermarkModel.textColor)
         holder.textView.maxWidth = GpKits.Dimens.dpToPxInt(App.context,maxWith*0.7f*1f)
         holder.lineVerticalView?.setBackgroundColor(watermarkModel.templateColor)
         holder.lineView?.setBackgroundColor(watermarkModel.templateColor)
    }

    override fun getItemCount(): Int {
        val items = dataList
        return items.size
    }
}