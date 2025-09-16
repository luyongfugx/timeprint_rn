package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.views

import android.util.Log
import android.view.View
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.BaseWatermarkModel
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItem

/**
 * 隐藏标题的
 *
 * @property dataList
 * @property watermarkModel
 */

class NoTitleItemRecyclerViewAdapter(dataList: List<WatermarkItem?>, watermarkModel: BaseWatermarkModel): BaseItemRecyclerViewAdapter(dataList,watermarkModel) {
    companion object {
        private const val TAG = "NoTitleItemRecyclerViewAdapter" // 定义日志标签
    }
    //不显示标题
    override fun onBindViewHolder(holder: BaseItemViewHolder, position: Int) {
       if(position < dataList.size) {
            val item = dataList.get(position)
            //不显示标题
            var text = item?.content
            holder.textView.text = text
            holder.textView.setTextColor(watermarkModel.textColor)
        }
    }


}