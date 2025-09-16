package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.itemview

import android.annotation.SuppressLint
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.View.GONE
import android.view.View.VISIBLE
import android.view.ViewGroup
import android.view.ViewGroup.MarginLayoutParams
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.widget.AppCompatButton
import androidx.appcompat.widget.AppCompatTextView
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity.Companion
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.receivers.CommonBroadcastReceiver
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.BroadcastManagerUtil
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpUiUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.toPxInt
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.GpSwitch
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.SafeClickListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.WaterMarkMapWidget
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkBaseID
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItemID

class WaterMarkItemEditViewHolder(parent: ViewGroup,
                                  onItemClickListener : (WatermarkItem, Int, Boolean, Boolean) -> Unit,
                                  onOptionSelectedListener : (WatermarkItem,String) -> Unit,
                                  onItemCheckedChangeListener :  (WatermarkItem,Int) -> Unit,
                                  onNotifyItemChanged:(Int)->Unit,
                                  data :ArrayList<WatermarkItem>,
) : RecyclerView.ViewHolder(
    LayoutInflater.from(parent.context).inflate(
        R.layout.item_edit_normal,parent,false)) {
    private var TAG = "WaterMarkItemEditViewHolder"
    private val onItemClickListener = onItemClickListener
    private val onItemCheckedChangeListener = onItemCheckedChangeListener
    private val clEditSingleLine = itemView.findViewById<ConstraintLayout>(R.id.clEditSingleLine)
    private val tvContent = itemView.findViewById<TextView>(R.id.tv_edit_item_content)
    private val switch = itemView.findViewById<GpSwitch>(R.id.switch_edit)
    private val ivLogo = itemView.findViewById<ImageView>(R.id.iv_edit_item_logo)
    private val clAddLogo = itemView.findViewById<ConstraintLayout>(R.id.cl_edit_item_add_logo)
    private val ivArrow = itemView.findViewById<ImageView>(R.id.iv_edit_arrow)
    private val iTryAgain = itemView.findViewById<AppCompatTextView>(R.id.tryAgain)
    //用来监听消息
    private var commonBroadcastReceiver: CommonBroadcastReceiver? = null

    fun bind(position: Int, item: WatermarkItem, onItemClickListener: (WatermarkItem, Int, Boolean, Boolean) -> Unit, onOptionSelectedListener : (WatermarkItem, String) -> Unit, onItemCheckedChangeListener:(WatermarkItem, Int)->Unit) {
        bindItem(position, item, item)
        if (item.id == WatermarkItemID.address.id){
            initReceiver(item)
        }
    }

    private fun initReceiver(item: WatermarkItem){
        Log.d(TAG,"commonBroadcastReceiver action initReceiver ==")
        commonBroadcastReceiver = CommonBroadcastReceiver{
            //如果是本地消息
            Log.d(TAG,"commonBroadcastReceiver action ${BroadcastManagerUtil.getLocalMessage(it)}")
            if(it.action.equals(BroadcastManagerUtil.getLocalAction(it))){
                Log.d(TAG,"commonBroadcastReceiver action ${it}")
                 //如果获取地址成功
                 if(BroadcastManagerUtil.getLocalMessage(it).equals(BroadcastManagerUtil.locationSucc)){
                     //隐藏iTryAgain，设置内容
                     iTryAgain.visibility = GONE
                     setContent(item)
                }

                //如果定位权限已经开通，但是获取定位失败，弹出消息，说明无法获取定位，这时候应该关注network是否成功
                else if(BroadcastManagerUtil.getLocalMessage(it).equals(BroadcastManagerUtil.locationError)){
                     iTryAgain.text = "Try again"
                 }
            }
        }
        BroadcastManagerUtil.registerLocalMessageReceiver(commonBroadcastReceiver)

    }

    private fun bindItem(position: Int, item: WatermarkItem, reallyItem: WatermarkItem) {
        if (item.id!! < 0) {
            itemView.visibility = GONE
            itemView.findViewById<View>(R.id.vDividerLine).visibility = View.GONE
            clEditSingleLine.visibility = GONE
            return
        }
         itemView.findViewById<View>(R.id.vDividerLine).visibility = View.VISIBLE
        if(GpUiUtils.isRtl()) {
            tvContent.setPadding(GpUiUtils.dp2px(30F), 0, 0, 0)
            ivArrow.rotationY = 180F
        } else {
            tvContent.setPadding(0, 0, 0, 0)
            ivArrow.rotationY = 0F
        }
        itemView.visibility = VISIBLE
        clEditSingleLine.visibility = VISIBLE
        switch.isClickable = reallyItem.switchEnable
        switch.alpha = if (reallyItem.switchEnable ) 1f else 0.3f
        if (switch.isChecked != reallyItem.isOpen) {
            switch.activeSetChecked(reallyItem.isOpen == true)
        }
        ivArrow.visibility = if (reallyItem.clickable) VISIBLE else View.INVISIBLE
        ivArrow.setImageResource(R.drawable.arrow_right_gray)
        if (reallyItem.id == WatermarkItemID.logo.id) {
            ivLogo.visibility = VISIBLE
            clAddLogo.visibility = VISIBLE
            ivArrow.visibility = GONE
            //如果有url,则loadLogo
            item.logoInfo?.selectLogoPath?.let {
                loadLogo(ivLogo, it)
            }

        }
        else {
            ivLogo.visibility = GONE
            clAddLogo.visibility = GONE
        }

        if (ivArrow.visibility == VISIBLE) {
            ivArrow.setImageResource(R.drawable.arrow_right_gray)
            (ivArrow.layoutParams as MarginLayoutParams).marginEnd = 18f.toPxInt()
        }
        setItemActionAndContent(position, item, reallyItem)
    }

    @SuppressLint("SuspiciousIndentation")
    private fun setItemActionAndContent(position: Int, item: WatermarkItem, reallyItem: WatermarkItem) {
        //如果是地址，并且地址为空，则显示重试按钮，并且隐藏箭头
        Log.d(TAG,"setItemActionAndContent pos ${position} ${reallyItem}")
        iTryAgain.visibility = GONE

        if (reallyItem.switchEnable){ // 开关可打开关闭
            switch.setOnCheckedChangeByUserListener { isChecked ->
                if (isChecked){
                        reallyItem.isOpen = true
                        onItemCheckedChangeListener.invoke(reallyItem,position)
                        setContent(item)
                }else{
                    reallyItem.isOpen = false
                    onItemCheckedChangeListener.invoke(reallyItem,position)
                    setContent(item)
                }
                bindItem(position, item, reallyItem)
            }
        }


        setContent(item)
        itemView.setOnClickListener(SafeClickListener(View.OnClickListener {
            onItemClickListener.invoke(reallyItem, 0, true, false)
            bindItem(position, item, reallyItem)
        }))
        itemView.isClickable = reallyItem.clickable
        itemView.findViewById<View>(R.id.switch_edit).visibility = VISIBLE
        if (reallyItem.id == WatermarkItemID.address.id){

            if (reallyItem.extraAddressInfo == null || reallyItem.extraAddressInfo?.getShowAddress().isNullOrEmpty()) {

                ivArrow.visibility = GONE
                iTryAgain.visibility = VISIBLE
                Log.d(TAG,"setItemActionAndContent iTryAgain show  pos ${position} ${reallyItem}")

                tvContent.text = "${item.title}:${GpUiUtils.getString(R.string.k_locate_fail)}"

                iTryAgain.setOnClickListener({
                    Log.d(TAG,"send reloadLocation msg ")
                    BroadcastManagerUtil.sendLocalMessage(BroadcastManagerUtil.reloadLocation)
                    iTryAgain.text = "${GpUiUtils.getString(R.string.k_locating)}..."
                    tvContent.text = "${item.title}:${GpUiUtils.getString(R.string.k_locating)}..."
                })
            }
            else {
                ivArrow.visibility = VISIBLE
                iTryAgain.visibility = GONE
                // BroadcastManagerUtil.sendLocalMessage(BroadcastManagerUtil.reloadLocation)
            }
        }
    }
    private fun setContent(item: WatermarkItem){
        tvContent.isSelected = item.isOpen == true
        var content = item.content
        if (item.title.isNullOrEmpty()){
            tvContent.text = "$content"
        }else {
            tvContent.text = "${item.title}:$content"
        }

      //  tvContent.text = "${item.title}${GpUiUtils.getString(R.string.i_colon)}$content"
    }


    private fun loadLogo(ivLogo: ImageView, logoUrl: String) {
        if (logoUrl == "timeprint"){
            ivLogo.setImageResource(R.drawable.timeprint)
        }
        else {
            Glide.with(itemView.context)
                .load(logoUrl)
                .into(ivLogo)
        }

    }



}
