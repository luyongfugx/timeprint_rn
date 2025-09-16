package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.appcompat.widget.AppCompatImageView
import androidx.appcompat.widget.AppCompatTextView
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.fragment.app.FragmentActivity
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.WatermarkManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.BaseWatermarkViewModel
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkCoverModel
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItem
import java.util.concurrent.CopyOnWriteArrayList

/**
 * 选择item
 *
 * @property formats
 * @property onItemClick
 */


class GpSelectStampAdapter(val list: List<WatermarkCoverModel>,val context: FragmentActivity) :
RecyclerView.Adapter<RecyclerView.ViewHolder>() {

    val TAG: String = "GpLocationViewModel"
    var action: (isClick: Boolean, wm: WatermarkCoverModel, position: Int, isAutoClick: Boolean) -> Unit = { _, _, _, _ -> }
    inner class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val cover: AppCompatImageView = view.findViewById(R.id.cover_bg)
        val name: AppCompatTextView = view.findViewById(R.id.vm_name_text)
        val editCover: AppCompatImageView = view.findViewById(R.id.editCover)
        val clWMShareAndEdit: ConstraintLayout = view.findViewById(R.id.shareAndEdit)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
                val view = LayoutInflater
                    .from(parent.context)
                    .inflate(
                        R.layout.layout_select_stamp_item,
                        parent,
                        false
                    )
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        when (holder) {
            is ViewHolder -> {
                val wm = list[position]
                   //Log.i(TAG,"onBindViewHolder wm:${wm.hashCode()}  ")
                    holder.name.text = wm.name
                   //转换一下
                var wmModel:BaseWatermarkViewModel? = BaseWatermarkViewModel()
                wmModel?.watermarkModel?.value = wm.watermarkModel?.clone();
                wmModel?.watermarkModel?.value?.items = CopyOnWriteArrayList<WatermarkItem?>()
                wm.watermarkModel?.items?.forEach {
                    wmModel?.watermarkModel?.value?.items?.add(it?.clone())
                }
                     //设置
                 wmModel?.resetItem(true)
                //生成截图
                val bitmap =   WatermarkManager.getCoverBitmap(wmModel,context)
                 Glide.with(App.context)
                .load(bitmap)
                .into(holder.cover)
                //Log.i(TAG,"onBindViewHolder wm:${wm}  wmModel:${wmModel?.watermarkModel}")
                //清除定时
                wmModel?.clean()
//                wmModel = null;

                val aivWMEdit = holder.clWMShareAndEdit.findViewById<AppCompatImageView>(R.id.wm_edit)
               if (wm.isSelect == true) {
                        holder.clWMShareAndEdit.visibility = View.VISIBLE
                        holder.editCover.visibility = View.GONE
                        aivWMEdit.setPadding(0, 0, 0, 0)
                        holder.itemView.setBackgroundResource(R.drawable.bg_radius_3_0093ff_line)
                } else {
                    holder.editCover.visibility = View.GONE
                    holder.clWMShareAndEdit.visibility = View.GONE
                    holder.itemView.setBackgroundResource(R.color.transparent)
                }


                holder.cover.setOnClickListener {
                   // Log.i(TAG,"setOnClickListener  cover.setOnClickListener:${wm}")
                    action.invoke(true, wm, position, false)
                }

                aivWMEdit.setOnClickListener {
                   // Log.i(TAG,"setOnClickListener  aivWMEdit.setOnClickListener:${wm}")
                    action.invoke(true, wm, position, false)
                }
            }
        }
    }

    override fun getItemCount(): Int {
        return list.size
    }

}