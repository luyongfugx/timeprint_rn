package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.itemdialog
import android.annotation.SuppressLint
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.FragmentActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.databinding.DialogTimeFormatSelectBinding
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpTimeManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.GpSwitch
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.SafeClickListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GPBaseDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpViewConvertListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpViewHolder
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime.GPDateExtenstionStyle
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime.GPDateStyle
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime.WatermarkTimeItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity.Companion
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpDateFormat
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.TencentCOSUtils
import java.util.Date


/**
 *  时间格式选择框
 * @property activity
 * @property editItem
 * @property listener
 */
class GpTimeFormatDialog(val activity: FragmentActivity, private val editItem: WatermarkItem, val listener: GpViewConvertListener,private var saveItemFunc: (WatermarkItem, Boolean) -> Unit) {
    private val TAG = "GpTimeFormatDialog"
    private var editDialog: GPBaseDialog? = null
    var timeItem: WatermarkTimeItem = editItem.extraTime
    private var formats = listOf<FormatItem>()
    private lateinit var recyclerView: RecyclerView
    private lateinit var adapter: FormatAdapter

    private val binding: DialogTimeFormatSelectBinding by lazy {
        DialogTimeFormatSelectBinding.inflate(LayoutInflater.from(activity), null, false)
    }

    /**
     * 根据时间格式获取字符串
     *
     * @param style
     * @return
     */
    private  fun getTimeFormat(style:GPDateStyle):String {

       // var timeContent =  GpDateFormat.getDateFormatString(realDate, style,timeItem.showWeek)
       // if (WatermarkItem.specialTimeID.contains(baseID)) {
        var timeContent = GpDateFormat.localizedDateString(Date(GpTimeManager.getExactTime()), style,  timeItem.is12Hour, timeItem.showWeek, timeItem.showTimeZone )
        return timeContent

    }

    /**
     * 重新初始化值
     *
     */
    private fun initList() {
        formats =  listOf(
            FormatItem(getTimeFormat(GPDateStyle.dayMonthYear),
                if(timeItem.style == GPDateStyle.dayMonthYear) true else false,
                isSwitchOn = false,
                formatItemType = FormatItemType.checkItem,
                dateStyle = GPDateStyle.dayMonthYear,
                extStyle =GPDateExtenstionStyle.hour
            ),
            FormatItem(getTimeFormat(GPDateStyle.yearMonthDateSpecialCountry),
                if(timeItem.style == GPDateStyle.yearMonthDateSpecialCountry) true else false,
                isSwitchOn = false,
                formatItemType = FormatItemType.checkItem,
                dateStyle = GPDateStyle.yearMonthDateSpecialCountry,
                extStyle =GPDateExtenstionStyle.hour
            ),
            FormatItem(getTimeFormat(GPDateStyle.monthDayYear),

                if(timeItem.style == GPDateStyle.monthDayYear) true else false,
                isSwitchOn = false,
                formatItemType = FormatItemType.checkItem,
                dateStyle = GPDateStyle.monthDayYear,
                extStyle =GPDateExtenstionStyle.hour
            ),
            FormatItem(GPDateExtenstionStyle.week.getText(),
                timeItem.showWeek,
                 timeItem.showWeek,
                formatItemType = FormatItemType.switchItem,
                dateStyle = GPDateStyle.monthDayYear,
                extStyle =GPDateExtenstionStyle.week),
            FormatItem(GPDateExtenstionStyle.hour.getText(), !timeItem.is12Hour,!timeItem.is12Hour,formatItemType = FormatItemType.switchItem,     dateStyle = GPDateStyle.monthDayYear,
                extStyle =GPDateExtenstionStyle.hour),
            FormatItem(GPDateExtenstionStyle.timezone.getText(), timeItem.showTimeZone,timeItem.showTimeZone,formatItemType = FormatItemType.switchItem  ,   dateStyle = GPDateStyle.monthDayYear,
                extStyle =GPDateExtenstionStyle.timezone),
        )
    }
    @SuppressLint("NotifyDataSetChanged")
    fun show(onMissCallback: GPBaseDialog.OnMissCallback?, onCancelCallback: GPBaseDialog.OnCancelCallback?) {
        recyclerView = binding.recyclerView
        recyclerView.layoutManager = LinearLayoutManager(activity)
        try {
            initList()
            adapter = FormatAdapter(formats) { position ->
                try {
                if(position<3){
                    formats.forEachIndexed { index, item ->
                        if(item.formatItemType == FormatItemType.checkItem){
                            item.isChecked = index == position
                        }
                    }
                    var formatItem = formats[position]
                    editItem.extraTime.style = formatItem.dateStyle
                    editItem.content = getTimeFormat(formatItem.dateStyle)
                    saveItemFunc(editItem,true)
                }
                adapter.notifyDataSetChanged()
                }
                catch (ex:Exception){
                    var format= ""
                    formats.forEachIndexed {
                            _, item ->
                        format+=item.format
                    }
                    val errorText =" $TAG FormatAdapter.onclick error: ${ex.message} position:${position}  formats.size:${formats.size} formats:${format} time:${GpTimeManager.getExactTime()}"
                    TencentCOSUtils.uploadErrorLog(App.context,errorText,"time_format_dialog_click_error")
                    Log.d(TAG,"time_format_dialog_click_error error ${ex}")
                }
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
        catch (e:Exception){
            val errorText =" $TAG initList error ${e.message} ${GpTimeManager.getExactTime()}"
            TencentCOSUtils.uploadErrorLog(App.context,errorText,"time_format_dialog_initList_error")
            Log.d(TAG,"initList error ${e}")
        }

    }

    data class FormatItem(val format: String,
                          var isChecked: Boolean,
                          var isSwitchOn: Boolean = false,
                          var formatItemType:FormatItemType,
                          var dateStyle: GPDateStyle,
                          var extStyle: GPDateExtenstionStyle
    )
    enum class FormatItemType(var id: Int) {
        checkItem(1),
        switchItem(2)
    }
    inner class FormatAdapter(private val formats: List<FormatItem>, private val onItemClick: (Int) -> Unit) :
        RecyclerView.Adapter<FormatAdapter.FormatViewHolder>() {
        @SuppressLint("ResourceAsColor")
        inner class FormatViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
            val textView: TextView = itemView.findViewById(R.id.text_view)
            val checkView: View = itemView.findViewById(R.id.check_view)
            val switchView: GpSwitch = itemView.findViewById(R.id.switch_view)
            init {
                itemView.setOnClickListener {
                    onItemClick(adapterPosition)
                }
            }
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): FormatViewHolder {
            val view = LayoutInflater.from(parent.context).inflate(R.layout.item_time_format_select, parent, false) // 创建item_format.xml布局文件
            return FormatViewHolder(view)
        }

        @SuppressLint("ResourceAsColor", "NotifyDataSetChanged")
        override fun onBindViewHolder(holder: FormatViewHolder, position: Int) {
            try {
                val formatItem = formats[position]
                if (formatItem.formatItemType == FormatItemType.checkItem) {
                    holder.textView.text = getTimeFormat(formatItem.dateStyle)
                    holder.switchView.visibility = View.GONE;
                    holder.checkView.visibility =
                        if (formatItem.isChecked) View.VISIBLE else View.GONE
                    holder.textView.setTextColor(activity.resources.getColor(if (formatItem.isChecked) R.color.color_0093ff else R.color.black))
                }
                else if (formatItem.formatItemType == FormatItemType.switchItem) {
                    holder.textView.text = formatItem.format
                    holder.switchView.visibility = View.VISIBLE;
                    holder.checkView.visibility = View.GONE;
                    holder.switchView.activeSetChecked(formatItem.isSwitchOn)
                    holder.switchView.setOnCheckedChangeByUserListener { switchOn ->
                        holder.switchView.activeSetChecked(switchOn)
                        //设置timeItem
                        when(formatItem.extStyle) {
                            GPDateExtenstionStyle.week -> {
                                timeItem.showWeek = switchOn
                            }
                            GPDateExtenstionStyle.hour -> {
                                timeItem.is12Hour = !switchOn
                            }
                            GPDateExtenstionStyle.timezone -> {
                                timeItem.showTimeZone = switchOn
                            }
                        }
                        //设置watermarkitem
                        editItem.extraTime = timeItem
                        editItem.content = getTimeFormat(formatItem.dateStyle)
                        formatItem.isSwitchOn = switchOn
                        saveItemFunc(editItem,true)
                        //修改数据
                        this.notifyDataSetChanged();
                    }
                }
            }
            catch (e:Exception){
                val errorText =" $TAG onBindViewHolder error ${e.message} ${GpTimeManager.getExactTime()}"
                TencentCOSUtils.uploadErrorLog(App.context,errorText,"time_format_dialog_onBindViewHolder_error")
                Log.d(TAG,"onBindViewHolder error ${e}")
            }
        }

        override fun getItemCount(): Int = formats.size
    }
}
