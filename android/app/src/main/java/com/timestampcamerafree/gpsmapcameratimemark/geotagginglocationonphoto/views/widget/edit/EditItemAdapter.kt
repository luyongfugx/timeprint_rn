package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit

import android.content.Context
import android.view.*

import androidx.appcompat.widget.AppCompatTextView
import androidx.recyclerview.widget.RecyclerView
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.toPxInt
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.itemview.WaterMarkItemEditViewHolder
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItem


const val TYPE_EDIT_ITEM_NORMAL = 0 // 普通编辑项
const val TYPE_EDIT_ITEM_ADD = 1    // 添加自定义
const val TYPE_EDIT_ITEM_TIPS = 2   // 尾部tips，
const val TYPE_EMPTY = 4
const val TYPE_EDIT_ITEM_NORMAL_SINGLE_LINE = 5 // 普通编辑项的单行形式
const val TYPE_EDIT_ITEM_ADD_SINGLE_LINE = 6 // 添加自定义项的单行形式


// 九种水印统一的编辑页面adapter
class EditItemAdapter(): RecyclerView.Adapter<RecyclerView.ViewHolder>() {
    private val TAG = "EditItemAdapter"
    var data = ArrayList<WatermarkItem>()
    private var showAddCustom = true

    // 条目点击
    var onItemClickListener =   { _:WatermarkItem,_:Int,_:Boolean,_:Boolean -> Unit}
    // 选中预设选项
    var onOptionSelectedListener : (WatermarkItem,String) -> Unit = {_,_ -> }
    // 开关状态变化
    var onItemCheckedChangeListener = { _:WatermarkItem,_:Int -> Unit}

    var addCustomItem = { }

    var singleLine = false
    private var customTip = ""

    private var onNotifyItemChanged: ((Int) -> Unit)? = null
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        onNotifyItemChanged = {position:Int->notifyItemChanged(position)}
        return when(viewType){
            TYPE_EDIT_ITEM_NORMAL_SINGLE_LINE -> { // 普通单行条目  - 开关：标题：内容
              val holder =  WaterMarkItemEditViewHolder(parent, onItemClickListener,
                onOptionSelectedListener, onItemCheckedChangeListener,
                  onNotifyItemChanged!!, data )
                return holder
            }
//            TYPE_EDIT_ITEM_ADD -> { // 添加自定义项
//                AddCustomViewHolder(parent)
//            }
            TYPE_EDIT_ITEM_ADD_SINGLE_LINE -> {
                SingleLineAddCustomViewHolder(parent)
            }
            TYPE_EMPTY -> {
                EmptyHolder(parent.context)
            }
            else -> {
                EmptyHolder(parent.context)
            }
        }
    }

    override fun getItemCount(): Int {
        var count = data.size
        if (showAddCustom){
            count++
        }
        return count + 1
    }

    override fun getItemViewType(position: Int): Int {
        return if (position < data.size){    // 前data.size个是数据
            if (data[position] is WatermarkItem) { // 真正的数据
                if (singleLine) TYPE_EDIT_ITEM_NORMAL_SINGLE_LINE else TYPE_EDIT_ITEM_NORMAL
            } else{                                      // 分组个数
                TYPE_EDIT_ITEM_NORMAL_SINGLE_LINE
            }
        } else if (showAddCustom && position == data.size){// 显示添加自定义
            if (singleLine) TYPE_EDIT_ITEM_ADD_SINGLE_LINE else TYPE_EDIT_ITEM_ADD
        } else TYPE_EDIT_ITEM_TIPS
    }

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {

        when(getItemViewType(position)){
            TYPE_EDIT_ITEM_NORMAL -> {
            }
            TYPE_EDIT_ITEM_NORMAL_SINGLE_LINE -> {
                val item = data[position]
                (holder as WaterMarkItemEditViewHolder).bind(position,item,onItemClickListener,onOptionSelectedListener,onItemCheckedChangeListener)
            }
            TYPE_EDIT_ITEM_ADD, TYPE_EDIT_ITEM_ADD_SINGLE_LINE -> {
                holder.itemView.setOnClickListener { addCustomItem() }
                if (singleLine) {
                    val customText: AppCompatTextView? = holder.itemView.findViewById(R.id.atvAddCustomItem)
                    if (customTip.isNotEmpty()) {
                        customText?.let {
                            it.text = customTip
                        }
                    }
                }
            }
        }

    }

    class SingleLineAddCustomViewHolder(parent:ViewGroup):RecyclerView.ViewHolder(LayoutInflater.from(parent.context).inflate(R.layout.item_add_custom_item,parent,false))

    class EmptyHolder(context: Context):RecyclerView.ViewHolder(View(context).apply {
        layoutParams = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,74f.toPxInt())
    }),IGpDivider{
        override fun drawDivider(): Boolean {
            return false
        }
    }



}

