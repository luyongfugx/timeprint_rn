package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.itemdialog

import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.appcompat.widget.AppCompatButton
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import com.google.android.material.slider.Slider
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.databinding.DialogLogoStyleBinding
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.AnalyticsManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.BitmapUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.BackgroundRemoverUtil
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpCameraPermission
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpDialogUtil
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpUiUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.SafeClickListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GPBaseDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpViewConvertListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpViewHolder
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.logo.LogoPosition
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.logo.WatermarkLogoItem
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * 设置logo样式
 *
 * @property activity
 * @property editItem
 * @property listener
 * @property saveItemFunc
 */
class GpLogoStyleDialog(val activity: FragmentActivity, private val editItem: WatermarkItem, val listener: GpViewConvertListener, private var saveItemFunc: (WatermarkItem, Boolean) -> Unit) {
    private val TAG = "GpLogoStyleDialog"
    private var editDialog: GPBaseDialog? = null
    private var logoItem: WatermarkLogoItem? = editItem.logoInfo

    private val binding: DialogLogoStyleBinding by lazy {
        DialogLogoStyleBinding.inflate(LayoutInflater.from(activity), null, false)
    }

    /**
     * logo 大小
     */
    private val logoSizeSlider: Slider  by lazy {
        binding.logoSize
    }
    /**
     * logo 透明度
     */
    private val logoAlphaSlider: Slider  by lazy {
        binding.logoAlphaSlider
    }
    private val replaceLogo: TextView  by lazy {
        binding.replaceLogo
    }
    private val bgRemove: TextView  by lazy {
        binding.bgRemove
    }

    private fun getCheckedStyle():GradientDrawable{
        val border = GradientDrawable()
        border.setColor(Color.WHITE) // 设置背景颜色
        val color = ContextCompat.getColor(App.context,R.color.color_0093ff)
        border.setStroke(3, color ) // 设置边框宽度和颜色
        border.cornerRadius = 8f // 设置圆角半径
        return border
    }
    private fun getUnCheckedStyle():GradientDrawable{
        val border = GradientDrawable()
        border.setColor(Color.WHITE) // 设置背景颜色
        border.setStroke(3, Color.BLACK) // 设置边框宽度和颜色
        border.cornerRadius = 8f // 设置圆角半径
        return border
    }
    private fun setBtnStyleByStatus(bth: AppCompatButton,checked: Boolean){
        if(checked){
            bth.background = getCheckedStyle()
            val color = ContextCompat.getColor(App.context,R.color.color_0093ff)
            bth.setTextColor(color )
        } else {
            bth.background = getUnCheckedStyle()
            bth.setTextColor(Color.BLACK)
        }
    }
    private fun updateButtonStyles(selectedButton: AppCompatButton) {
        val buttons = listOf(binding.follow, binding.upperLeft, binding.upperRight, binding.middle)
        buttons.forEach { button ->
            setBtnStyleByStatus(button, button == selectedButton)
        }
    }

    /**
     * 根据logo初始化位置，设置btn样式
     *
     */
    private fun initButtonStyles(){
        when(logoItem?.position){
            LogoPosition.ON_WATER_MARK -> updateButtonStyles(binding.follow)
            LogoPosition.LEFT_TOP -> updateButtonStyles(binding.upperLeft)
            LogoPosition.CENTER -> updateButtonStyles(binding.middle)
            LogoPosition.RIGHT_TOP -> updateButtonStyles(binding.upperRight)
            else ->  updateButtonStyles(binding.follow)
        }
    }
    fun show(onMissCallback: GPBaseDialog.OnMissCallback?, onCancelCallback: GPBaseDialog.OnCancelCallback?,showPickerDialog: (() -> Unit)?) {

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
        initButtonStyles()
        val buttons = listOf(binding.follow, binding.upperLeft, binding.upperRight, binding.middle)
        buttons.forEach { button ->
            button.setOnClickListener {
                updateButtonStyles(button)
                //根据点击设置
                when(button){
                    binding.follow -> logoItem?.position = LogoPosition.ON_WATER_MARK
                    binding.upperLeft -> logoItem?.position = LogoPosition.LEFT_TOP
                    binding.middle -> logoItem?.position = LogoPosition.CENTER
                    binding.upperRight -> logoItem?.position = LogoPosition.RIGHT_TOP
                }
                saveItemFunc(editItem,true)
            }
        }
        Log.d(TAG,"1000")
        //修改大小
        logoSizeSlider.value = logoItem?.scale ?: 1f
        binding.bgRemove.text = if (logoItem?.isRemoveBg == true) GpUiUtils.getString(R.string.k_recover_bg) else GpUiUtils.getString(R.string.k_remove_bg)

        logoSizeSlider.addOnChangeListener(Slider.OnChangeListener { slider, value, fromUser -> // 处理滑块值变化
            logoItem?.scale = value
            saveItemFunc(editItem,true)
        })
        Log.d(TAG,"1111")
        //修改透明度
        logoAlphaSlider.value =  (logoItem?.alpha ?: 0f)
        //Log.d(TAG,"logoAlphaSlider.value: ${logoAlphaSlider.value} logoImageView.alpha::${logoItem?.alpha}")
        logoAlphaSlider.addOnChangeListener(Slider.OnChangeListener { slider, value, fromUser -> // 处理滑块值变化
            logoItem?.alpha = value
           // Log.d(TAG,"logoAlphaSlider.value: ${logoAlphaSlider.value} logoImageView.alpha::${logoItem?.alpha}")
            saveItemFunc(editItem,true)
        })

        editDialog?.setMissCallback(onMissCallback)
        binding.backIv.setOnClickListener(SafeClickListener(View.OnClickListener { v: View? ->
            onCancelCallback?.onCancel()
            editDialog?.dismissAllowingStateLoss()
        }))
        replaceLogo.setOnClickListener(SafeClickListener(View.OnClickListener { v: View? ->
            activity?.let {
                if (showPickerDialog != null) {
                    onCancelCallback?.onCancel()
                    editDialog?.dismissAllowingStateLoss()
                    showPickerDialog()
                }
            }
        }))
        //删除背景
        bgRemove.setOnClickListener(SafeClickListener(View.OnClickListener { v: View? ->
                // 显示加载状态
                if (editItem.logoInfo?.isRemoveBg == true){
                    editItem.logoInfo?.selectLogoPath =    editItem.logoInfo?.originLogoPath
                    editItem.logoInfo?.isRemoveBg = false
                    binding.logoImageView.setImageURI(Uri.fromFile(editItem.logoInfo?.selectLogoPath?.let { File(it) }))
                    binding.bgRemove.text = GpUiUtils.getString(R.string.k_remove_bg)
                    saveItemFunc(editItem, true)
                    AnalyticsManager.logEvent("recover_bg")
                    return@OnClickListener
                }
            AnalyticsManager.logEvent("remove_bg")
                binding.progressBar.visibility = View.VISIBLE
                bgRemove.isEnabled = false

                val bgRemoverExecutor: ExecutorService = Executors.newSingleThreadExecutor()
                val bgRemover = BackgroundRemoverUtil(bgRemoverExecutor)
                val imageFile = editItem.logoInfo?.selectLogoPath?.let { File(it) }

                val imageFileUri = Uri.fromFile(imageFile)
               // Log.d(TAG,"removeBackground imageFileUri ${imageFileUri}")
                bgRemover.removeBackground(activity, imageFileUri,
                    object : BackgroundRemoverUtil.Callback {
                        override fun onSuccess(
                            imageUri: Uri,
                            foregroundToDisplay: Bitmap,
                            foregroundToSave: Bitmap
                        ) {
                            //Log.d(TAG,"removeBackground onSuccess")
                            activity.runOnUiThread {
                                binding.progressBar.visibility = View.GONE
                                bgRemove.isEnabled = true
                                // 保存处理后的图片
                                val resultUri = BitmapUtils.saveProcessedBitmap(foregroundToDisplay,activity.dataDir,"processed_logo_${System.currentTimeMillis()}.png")
                                editItem.logoInfo?.selectLogoPath = resultUri.path
                                editItem.logoInfo?.isRemoveBg = true
                                binding.bgRemove.text = GpUiUtils.getString(R.string.k_recover_bg)
                                binding.logoImageView.setImageURI(Uri.fromFile(editItem.logoInfo?.selectLogoPath?.let { File(it) }))
                                saveItemFunc(editItem, true)
                            }
                        }

                        override fun onFailure(imageUri: Uri, e: Exception) {
                           // Log.d(TAG,"removeBackground onFailure ${e.message}")
                            activity.runOnUiThread {
                                binding.progressBar.visibility = View.GONE
                                bgRemove.isEnabled = true
                                //Toast.makeText(activity, "背景去除失败: $error", Toast.LENGTH_SHORT).show()
                            }
                        }
                    })
            }))
            //onCancelCallback?.onCancel()
            //editDialog?.dismissAllowingStateLoss()
        editDialog?.show(activity.supportFragmentManager)
        binding.logoImageView.setImageURI(Uri.fromFile(logoItem?.selectLogoPath?.let { File(it) }))
    }
}