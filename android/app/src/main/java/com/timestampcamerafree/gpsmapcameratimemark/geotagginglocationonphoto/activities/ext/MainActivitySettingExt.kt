package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ext

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Build
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.PopupWindow
import android.widget.TextView
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ContactActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.SaveFolderActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.SettingsActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.config
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.ImageQualityManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.SETTING_CHANGE_LANG
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.SETTING_CONTACT
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.SETTING_MORE
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.SETTING_PHOTO_QUALITY
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.SETTING_PHOTO_SAVE_ORIGIN
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.SETTING_PLAY_SHUTTER_SOUND
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.SETTING_SAVE_FOLDER
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.SettingMenuManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.ImageQuality
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.SettingItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpUiUtils

/**
 * 设置按钮相关
 *
 * @param linearLayout
 * @param onClick
 * @param settings
 * @param context
 */

fun MainActivity.getSettingMenu(linearLayout: LinearLayout, onClick: (clickedViewId: Int) -> Unit, settings: List<SettingItem>, context: Context) {
    linearLayout.removeAllViews()
    val inflater = LayoutInflater.from(context)
    for (setting in settings) {
        val view = inflater.inflate(R.layout.pop_item, linearLayout, false)
        // view.id = setting.buttonViewId
        val imageView = view.findViewById<ImageView>(R.id.ratio_image)
        imageView.visibility = View.GONE
        val textView = view.findViewById<TextView>(R.id.ratio_text)
        textView.text = setting.title
        textView.setTextColor(Color.BLACK)
        imageView.setColorFilter(Color.BLACK)
        // 设置点击事件
        view.setOnClickListener {
            onClick(setting.id)
        }
        linearLayout.addView(view)
    }
}

@RequiresApi(Build.VERSION_CODES.TIRAMISU)
fun MainActivity.launchSettings() {
    val popupView =
        layoutInflater.inflate(R.layout.layout_pop_right_menu, null, false)
    val popupWindow = PopupWindow(
        popupView,
        ViewGroup.LayoutParams.WRAP_CONTENT,
        ViewGroup.LayoutParams.WRAP_CONTENT,
        true // This sets both isFocusable and isOutsideTouchable to true
    ).apply {
        setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
    }
    val settings = SettingMenuManager.getSettingItemList()
    val onItemClick =  { id: Int ->
        popupWindow.dismiss()
        val item = settings.first() { it.id == id }
        when(item.id){
            SETTING_PHOTO_QUALITY -> showImageQualityMenu()
            SETTING_CHANGE_LANG ->  launchChangeAppLanguageIntent()
            SETTING_CONTACT -> goContactActivity()
            SETTING_PHOTO_SAVE_ORIGIN -> saveOriginPhoto()
            SETTING_SAVE_FOLDER -> goSaveFolderActivity()
            SETTING_MORE ->  goMoreSettingActivity()
        }
    }
    getSettingMenu(popupWindow.contentView.findViewById(R.id.pop_menu), onItemClick, settings,this)
    val width = binding.layoutTop.settings.width
    val gravity = Gravity.TOP or Gravity.RIGHT
    popupWindow.showAtLocation(window.decorView, gravity, width/2-12, binding.layoutTop.defaultIcons.height*3/2)
}
fun MainActivity.goMoreSettingActivity() {
    val intent = Intent(this, SettingsActivity::class.java)
    startActivity(intent)
}
fun MainActivity.goSaveFolderActivity() {
    val intent = Intent(this, SaveFolderActivity::class.java)
    startActivity(intent)
}
fun MainActivity.goContactActivity() {
    val intent = Intent(this, ContactActivity::class.java)
    startActivity(intent)
}
fun MainActivity.saveOriginPhoto() {
    //设置存储
    config.saveOriginPhoto = !config.saveOriginPhoto
    //显示一下tip
    val tipText = if (config.saveOriginPhoto) GpUiUtils.getString(R.string.k_auto_save_two) else GpUiUtils.getString(R.string.k_auto_save_one)
    binding.saveOriginPhotoText.text = tipText
    binding.saveOriginPhotoTextView.visibility = View.VISIBLE
    binding.saveOriginPhotoTextView.postDelayed({   binding.saveOriginPhotoTextView.visibility = View.GONE},300)
}
@SuppressLint("InflateParams")
fun MainActivity.showImageQualityMenu(){
    val popupView =
        layoutInflater.inflate(R.layout.layout_pop_right_menu, null, false)
    val popupWindow = PopupWindow(
        popupView,
        ViewGroup.LayoutParams.WRAP_CONTENT,
        ViewGroup.LayoutParams.WRAP_CONTENT,
        true // This sets both isFocusable and isOutsideTouchable to true
    ).apply {
        setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
    }
    val qualities = ImageQualityManager.getSupportedImageQualities()
    val onItemClick =  { quality: ImageQuality ->
        popupWindow.dismiss()
        //设置图片质量
        config.photoQuality = quality.quality
        //重启摄像头
        mPreview?.changImageQuality()
    }
    getImageQualityMenu(popupWindow.contentView.findViewById(R.id.pop_menu), onItemClick, qualities,this)


    val width = binding.layoutTop.settings.width
    val gravity = Gravity.TOP or Gravity.END
    popupWindow.showAtLocation(window.decorView, gravity, width/2-12, binding.layoutTop.defaultIcons.height*3/2)
}


fun MainActivity.getImageQualityMenu(linearLayout: LinearLayout, onClick: (quality: ImageQuality) -> Unit?, qualities: List<ImageQuality>, context: Context) {
    linearLayout.removeAllViews()
    val inflater = LayoutInflater.from(context)
    for (quality in qualities) {
        val view = inflater.inflate(R.layout.pop_item, linearLayout, false)
        view.id = quality.getButtonViewId()
        val imageView = view.findViewById<ImageView>(R.id.ratio_image)
        imageView.visibility = View.GONE
        val textView = view.findViewById<TextView>(R.id.ratio_text)
        textView.text = quality.getText()
        //选中处理
        if( config.photoQuality== quality.quality){
            //  val color= Color.parseColor("#1d7fdf")
            val color = ContextCompat.getColor(this,R.color.color_0093ff)
            textView.setTextColor(color)
            imageView.setColorFilter(color)
        }
        else {
            textView.setTextColor(Color.BLACK)
            imageView.setColorFilter(Color.BLACK)
        }

        // 设置点击事件
        view.setOnClickListener {
            onClick(quality)
        }
        linearLayout.addView(view)
    }
}




