package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.itemdialog


import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.FragmentActivity
import com.google.android.material.slider.Slider
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.databinding.DialogColorSizeBinding
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.ColorSelectScrollView
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.SafeClickListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GPBaseDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpViewConvertListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpViewHolder
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.WatermarkManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.ColorData

/**
 * GpColorSizeDialog
 *
 * @property activity
 * @property listener
 * @property saveFunc
 */
class GpColorSizeDialog(val activity: FragmentActivity, val listener: GpViewConvertListener, private var saveFunc: (Boolean) -> Unit) {
    private val TAG = "GpColorSizeDialog"
    private var editDialog: GPBaseDialog? = null
    private val binding: DialogColorSizeBinding by lazy {
        DialogColorSizeBinding.inflate(LayoutInflater.from(activity), null, false)
    }


    /**
     * 主题色
     */
    private val templateColorView: ColorSelectScrollView  by lazy {
        binding.templateColorRecyclerView
    }

    /**
     * 字体颜色
     */
    private val textColorView: ColorSelectScrollView  by lazy {
        binding.textColorRecyclerView
    }
    /**
     * templateSizeSlider 大小silder
     */
    private val templateSizeSlider: Slider by lazy {
        binding.templateSizeSlider
    }

    
    /**
     * 输入一个颜色值字符串数组，返回一个ColorData  类的list,其中
     * @param colorStrs
     * @return
     */
    private fun colorsStrs2ColorData(colorStrs: List<String>): List<ColorData> {
        val colorDataList = mutableListOf<ColorData>()
        colorStrs.forEach {
            colorDataList.add(ColorData(false,it))
        }
        return colorDataList
    }
   

    fun show(onMissCallback: GPBaseDialog.OnMissCallback?, onCancelCallback: GPBaseDialog.OnCancelCallback?) {
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
        val colorStrs = listOf(
            "#FFFFFF", "#0060FF",
            "#19C0BF",
            "#00A80D",
            "#FF7800",
            "#D80007",
            "#A901AB",
            "#00BCFF",
            "#1DE9B6",
            "#64DD17",
            "#FFC233",
            "#FF5252",
            "#CE48FF",
            "#43E8FF",
            "#64FFDA",
            "#76FF03",
            "#FFEF40",
            "#FFAB91",
            "#ED84FF",
            "#000000"
        )
        var currentWatermarkModel =    WatermarkManager.getSelectWatermarkModel()

        //默认Color
        var defaultTemplatesColor = ColorData(true,currentWatermarkModel.templateColorStr ?: "#FFFFFF")
        var defaultTextColor = ColorData(true,currentWatermarkModel.textColorStr ?: "#FFFFFF")
        var defaultScale = currentWatermarkModel.templateScale ?: 1f
        var tempColors = colorsStrs2ColorData(colorStrs)
        val textColors = colorsStrs2ColorData(colorStrs)

        templateColorView.setColors(tempColors,defaultTemplatesColor)
        templateColorView.setOnColorSelectedListener { color ->
            currentWatermarkModel.templateColorStr = color.colorStr
            saveFunc.invoke(true)
        }
        textColorView.setColors(textColors,defaultTextColor)
        textColorView.setOnColorSelectedListener { color ->
            currentWatermarkModel.textColorStr = color.colorStr
            saveFunc.invoke(true)
        }
        //修改放大值
        templateSizeSlider.value =  defaultScale
        templateSizeSlider.addOnChangeListener(Slider.OnChangeListener { _, value, _ -> // 处理滑块值变化
            currentWatermarkModel.templateScale = value
            saveFunc.invoke(true)

        })

        editDialog?.setMissCallback(onMissCallback)
        binding.backIv.setOnClickListener(SafeClickListener(View.OnClickListener { v: View? ->
            onCancelCallback?.onCancel()
            editDialog?.dismissAllowingStateLoss()
        }))
        editDialog?.show(activity.supportFragmentManager)
    }
}