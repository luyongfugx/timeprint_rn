package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.itemdialog

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Point
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.TextView
import androidx.fragment.app.FragmentActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App.Companion.context
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.databinding.DialogCoordinateFormatSelectBinding
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.SafeClickListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GPBaseDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpViewConvertListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpViewHolder
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.coordinate.WatermarkCoordinateItem

/**
 * 经纬度格式
 * author: waynelu
 */

class GpCoordinateFormatDialog(val activity: FragmentActivity, private val editItem: WatermarkItem, val listener: GpViewConvertListener, private var saveItemFunc: (WatermarkItem, Boolean) -> Unit) {
    private var editDialog: GPBaseDialog? = null
    var coordinateItem: WatermarkCoordinateItem? = editItem.extraCoordinateInfo
    private var formats: MutableList<FormatItem> = mutableListOf()
    private lateinit var recyclerView: RecyclerView
    private lateinit var adapter: FormatAdapter
    private val binding: DialogCoordinateFormatSelectBinding by lazy {
        DialogCoordinateFormatSelectBinding.inflate(LayoutInflater.from(activity), null, false)
    }


    /**
     * 重新初始化值
     *
     */
    private fun initList() {
       var formatMap  = coordinateItem?.getLatLngFormats()
        formatMap?.let {
                it.forEach({item->
                    formats.add(FormatItem(item.value,if(item.key == coordinateItem?.coordinateStyle) true else false,item.key))
                })
        }
    }
    private fun getDialogHeight(): IntArray {
        var height = 1920
        var activeAreaPercent = 0.4
        var topOffset = 20
        val point = Point()
        if (context != null) {
            val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            if (wm != null) {
                wm.defaultDisplay.getRealSize(point)
                height = (point.y * activeAreaPercent - topOffset).toInt()
            }
        }
        return intArrayOf(height,point.y - height)
    }
    fun show(onMissCallback: GPBaseDialog.OnMissCallback?, onCancelCallback: GPBaseDialog.OnCancelCallback?) {
        recyclerView = binding.recyclerView
        recyclerView.layoutManager = LinearLayoutManager(activity)
       //获取高度
        var height = getDialogHeight()[0]
        val params = recyclerView.layoutParams
        params.height = height //
        recyclerView.layoutParams = params

        initList()
        adapter = FormatAdapter(formats) { position ->
                formats.forEachIndexed { index, item ->
                        item.isChecked = index == position
                }
            try {
                val formatItem = formats[position]
                editItem.extraCoordinateInfo!!.coordinateStyle = formatItem.style
                editItem.content = formatItem.format
                saveItemFunc(editItem, true)
            }catch (e:Exception){

            }
            adapter.notifyDataSetChanged()
        }
        recyclerView.adapter = adapter
        editDialog = GpDialog.init()
            .setContentView(binding.root)
            .setConvertListener(object: GpViewConvertListener(){
                override fun convertView(holder: GpViewHolder?, dialog: GPBaseDialog?) {
                    dialog?.let {}
                    listener.convertView(holder,dialog)
                }
            })
            .setDimAmount(0.5f)
            .setMargin(0)
            .setOutCancel(true)
            .setShowBottom(true)
            .setHeight(ViewGroup.LayoutParams.WRAP_CONTENT)
        editDialog?.setMissCallback(onMissCallback)
        binding.backIv.setOnClickListener(SafeClickListener(View.OnClickListener { v: View? ->
            onCancelCallback?.onCancel()
            editDialog?.dismissAllowingStateLoss()
        }))
        editDialog?.show(activity.supportFragmentManager)
    }

    data class FormatItem(val format: String,
                          var isChecked: Boolean,
                          var style: Int
    )

    inner class FormatAdapter(private val formats: List<FormatItem>, private val onItemClick: (Int) -> Unit) :
        RecyclerView.Adapter<FormatAdapter.FormatViewHolder>() {
        @SuppressLint("ResourceAsColor")
        inner class FormatViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
            val textView: TextView = itemView.findViewById(R.id.text_view)
            val checkView: View = itemView.findViewById(R.id.check_view)
            init {
                itemView.setOnClickListener {
                    onItemClick(adapterPosition)
                }
            }
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): FormatViewHolder {
            val view = LayoutInflater.from(parent.context).inflate(R.layout.item_address_format_select, parent, false) // 创建item_format.xml布局文件
            return FormatViewHolder(view)
        }

        @SuppressLint("ResourceAsColor")
        override fun onBindViewHolder(holder: FormatViewHolder, position: Int) {
            try {
                val formatItem = formats[position]
                holder.textView.text = formatItem.format
                holder.checkView.visibility =
                    if (formatItem.isChecked) View.VISIBLE else View.GONE
                holder.textView.setTextColor(activity.resources.getColor(if (formatItem.isChecked) R.color.color_0093ff else R.color.black))
            }
            catch (e:Exception){

            }
        }


        override fun getItemCount(): Int = formats.size
    }
}