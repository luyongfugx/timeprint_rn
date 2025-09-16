package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget

import android.app.Activity
import android.content.Context
import android.util.AttributeSet
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import com.bumptech.glide.Glide
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store.GpDataStores
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store.GpStoreKey
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store.GpStoreKeys
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpUiUtils.runOnUiThread
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.WatermarkManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItemID


/**
 * GpLogoWidget
 *
 * @constructor
 * TODO
 *
 * @param context
 * @param attrs
 * @param defStyleAttr
 */
class GpLogoWidget @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null, defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr){
    private val TAG = "GpLogoWidget"
    private var logoImageView: GpImageView
    private var defaultWidth = 240f
    init {
        LayoutInflater.from(context).inflate(R.layout.layout_logo_widget, this, true)
        logoImageView = findViewById(R.id.logo_image)
        initLogoImage()
        observeEvent()
    }

    var scale = 1.0f
    private fun getLifecycleOwner(): LifecycleOwner? {
        if (context is Activity && context is LifecycleOwner) {
            return context as LifecycleOwner
        }
        return null
    }


    /**
     * 设置logo图片
     *
     */
   private  fun initLogoImage(){
       var logoItem =  WatermarkManager.getSelectWatermarkModel().items.find { it?.id == WatermarkItemID.logo.id }
      //  Log.d(TAG,"setLogoPosition init33311 initLogoImage logoImage: ${logoItem}")
       if(logoItem?.isOpen == true && !logoItem.logoInfo?.selectLogoPath.isNullOrEmpty()){
           val layoutParams = logoImageView.layoutParams
           layoutParams.width = ((defaultWidth*(logoItem.logoInfo?.scale ?: 1f)).toInt()) // 设置宽度
           layoutParams.height = ViewGroup.LayoutParams.WRAP_CONTENT // 设置高度自适应
           logoImageView.layoutParams = layoutParams
           //设置透明度

          // Log.d(TAG," setLogoPosition init3333 initLogoImage logoImage: ${logoItem}")
           runOnUiThread {
               if (logoItem.logoInfo?.selectLogoPath == "timeprint"){
                   logoImageView.setImageResource(R.drawable.timeprint)
               }
               else {
                   Glide.with(context)
                   .load(logoItem.logoInfo?.selectLogoPath)
                   .into(logoImageView)
               }
               logoImageView.visibility = View.VISIBLE
               logoImageView.alpha = 1f-(logoItem.logoInfo?.alpha ?: 0f)
               Log.d(TAG,"setLogoPosition init3333 initLogoImage logoImage: logoImageView.alpha ${logoImageView.alpha}")
               logoImageView.parent.requestLayout()
           }


       }
       else {
          // Log.d(TAG,"setLogoPosition hidden initLogoImage logoImage: ${logoItem}")
           logoImageView.visibility = View.GONE
       }
   }
    private fun<T> observeDataStores(storeKey:String, observer: Observer<T>){
        var lifecycleOwner = getLifecycleOwner()
        if (lifecycleOwner != null) {
            runOnUiThread { // 切换到主线程
                GpDataStores.observe(
                    GpStoreKey.valueOf(
                        storeKey,
                        lifecycleOwner,
                    ), observer, lifecycleOwner)
            }

        }
    }

    private fun observeEvent() {
        //监听修改
        this.observeDataStores(GpStoreKeys.KEY_WATERMARK_UPDATE,{ updateValue: Boolean ->
            initLogoImage()
        })
        this.observeDataStores(GpStoreKeys.WATERMARK_ID_CHANGE,{ updateValue: Boolean ->
            initLogoImage()
        })
    }

}