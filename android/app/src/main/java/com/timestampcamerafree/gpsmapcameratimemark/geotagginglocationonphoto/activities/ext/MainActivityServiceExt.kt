package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ext

import android.util.Log
import android.view.View
import android.widget.RelativeLayout
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity.Companion.TAG
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.BitmapUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.OfficialLogoConfig
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.officialLogo.IGpOfficialLogoService
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GPLanguageManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpWidgetPosManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.TencentCOSUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.WatermarkManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkBaseID
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.logo.LogoPosition

fun MainActivity.getOfficialLogo() {
    //Log.d(TAG,"location is mock :${GPAppUtils.isMockLocationEnabled(App.context)}")
    val callback = object : IGpOfficialLogoService.Callback {
        override fun onCurrentOfficialLogo(logoConfig: OfficialLogoConfig) {
            val lang =  GPLanguageManager.currentLanguageOny
            val baseLogoUrl = logoConfig.getLogoUrlForLanguage(lang);
            //如果显示
            if (baseLogoUrl!=null && logoConfig.show){
                val logoUrl = "${baseLogoUrl}$lang.png"
                try {
                    val officialLogo =BitmapUtils.getBitmapFromUrl(logoUrl)
                    WatermarkManager.officialLogoBitmap = officialLogo
                    WatermarkManager.officialLogoPos = logoConfig.getLogoPos(lang)
                    runOnUiThread {
                       // binding.officialLogo.setImageBitmap(officialLogo)
                      //  binding.officialContainerView.visibility = View.VISIBLE
                    }
                    Log.d(TAG,"onCurrentOfficialLogo baseLogoUrl ===")
                }
                catch (e:Exception){
                    Log.d(TAG,"onCurrentOfficialLogo getBitmapFromUrl error : ${e.toString()}")
                }
            }
            Log.d(TAG,"onCurrentOfficialLogo succ in MainActivity ${logoConfig}  $lang ${baseLogoUrl}")
        }
        override fun onError(e: Exception) {
            val errorText ="getOfficialLogo on error ${e.message}"
            TencentCOSUtils.uploadErrorLog(App.context,errorText,"getOfficialLogo_error")
            Log.d(TAG,"getOfficialLogo error ${e}")
        }
        override fun onComplete() {

        }
    }
//    ServiceConfig.getOfficialLogoService().start(
//        this,
//        callback
//    )
}


fun MainActivity.setOfficialLogoPosition() {
    val currentOrientation = currentOrientation

    if (currentOrientation == null) {
        return
    }
    val margin = 16
    val layoutParams =  RelativeLayout.LayoutParams(
        RelativeLayout.LayoutParams.WRAP_CONTENT,
        RelativeLayout.LayoutParams.WRAP_CONTENT
    )
    layoutParams.setMargins(margin,margin,margin,margin)
    val rules =  GpWidgetPosManager.getLayoutRulesByPosAndOrientation(LogoPosition.RIGHT_BOTTOM,currentOrientation)
    rules.forEach {
        layoutParams.addRule(it)
    }
    binding.officialContainerView.layoutParams = layoutParams
    binding.officialContainerView.requestLayout()
}

fun MainActivity.setMapPosition() {
    //如果mapid 是13，14 应该不显示这个map
    var baseId = viewModel?.watermarkModel?.value?.base_id
    if (baseId ==  WatermarkBaseID.ID13.id || baseId == WatermarkBaseID.ID14.id){
        mapWidgetContainer.visibility = View.GONE
        return
    }
    else {
        mapWidgetContainer.visibility = View.VISIBLE
    }
    val currentOrientation = currentOrientation
    if (currentOrientation == null) {
        return
    }
    val margin = 30
    val layoutParams =  RelativeLayout.LayoutParams(
        RelativeLayout.LayoutParams.WRAP_CONTENT,
        RelativeLayout.LayoutParams.WRAP_CONTENT
    )
    layoutParams.setMargins(margin,margin,margin,margin)
    val rules =  GpWidgetPosManager.getLayoutRulesByPosAndOrientation(LogoPosition.LEFT_TOP,currentOrientation)
    rules.forEach {
        layoutParams.addRule(it)
    }
    mapWidgetContainer.layoutParams = layoutParams
    mapWidgetContainer.requestLayout()
}
fun MainActivity.setLogoPosition(position: LogoPosition?) {
    val coverLogoView = waterMarkView.findViewById<View>(R.id.coverLogoWidget)
    val margin = 60
    val layoutParams =  RelativeLayout.LayoutParams(
        RelativeLayout.LayoutParams.WRAP_CONTENT,
        RelativeLayout.LayoutParams.WRAP_CONTENT
    )
    layoutParams.setMargins(margin,margin,margin,margin)
    val rules =  GpWidgetPosManager.getLayoutRulesByPosAndOrientation(position,currentOrientation)
    //Log.d(TAG,"setLogoPosition position:${position} currentOrientation:${currentOrientation} rules:${rules}")
    when(position){
        LogoPosition.LEFT_TOP, LogoPosition.RIGHT_TOP,LogoPosition.CENTER -> {
            logoContainer.visibility =  View.VISIBLE
            rules.forEach {
                layoutParams.addRule(it)
            }
            logoContainer.layoutParams = layoutParams
            // Log.d(TAG,"setLogoPosition position:${position} currentOrientation:${currentOrientation} layoutParams : ${layoutParams}")
            logoContainer.requestLayout()
            if(coverLogoView!=null){
                coverLogoView.visibility = View.GONE
            }
            waterMarkView.requestLayout()
        }
        //如果是在水银上的则隐藏logoContainer
        LogoPosition.ON_WATER_MARK ->{
            logoContainer.visibility =  View.GONE
            if(coverLogoView!=null){
                //如果是baseId 为15，并且是是跟随状态，则不显示logo,因为logo在title里面了
                if (viewModel?.watermarkModel?.value?.base_id == WatermarkBaseID.ID15.id ){
                    coverLogoView.visibility = View.GONE
                }
                else {
                    coverLogoView.visibility = View.VISIBLE
                }
            }
            waterMarkView.requestLayout()
        }
        //如果是内嵌的则隐藏logoContainer
        LogoPosition.INLINE ->{
            logoContainer.visibility =  View.GONE
            if(coverLogoView!=null){
                coverLogoView.visibility = View.GONE
            }
            waterMarkView.requestLayout()
        }
        else ->{
        }
    }
}