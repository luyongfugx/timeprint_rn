package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Rect
import android.hardware.SensorManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.CountDownTimer
import android.provider.MediaStore
import android.provider.Settings
import android.util.Log
import android.view.KeyEvent
import android.view.OrientationEventListener
import android.view.View
import android.view.ViewGroup
import android.view.Window
import android.view.WindowManager
import android.widget.TextView
import androidx.appcompat.widget.AppCompatButton
import androidx.asynclayoutinflater.view.AsyncLayoutInflater
import androidx.constraintlayout.widget.ConstraintSet
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.net.toUri
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.core.view.updateLayoutParams
import androidx.fragment.app.Fragment
import androidx.lifecycle.Observer
import androidx.transition.Fade
import androidx.transition.Scene
import androidx.transition.Transition
import androidx.transition.TransitionManager
import androidx.transition.TransitionSet
import com.bumptech.glide.Glide
import com.bumptech.glide.load.engine.DiskCacheStrategy
import com.bumptech.glide.load.resource.bitmap.CenterCrop
import com.bumptech.glide.load.resource.bitmap.RoundedCorners
import com.bumptech.glide.load.resource.drawable.DrawableTransitionOptions
import com.bumptech.glide.request.RequestOptions
import com.google.android.material.button.MaterialButtonToggleGroup
import com.google.android.material.tabs.TabLayout

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.BuildConfig
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ext.doOnChangeFlashMode
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ext.doSetFlashAvailable
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ext.doShowFlashOptions
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ext.doShowImageSizes
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ext.doShowTimerOptions
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ext.goGroupActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ext.initModeSwitcher
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ext.isInPhotoMode
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ext.launchSettings
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ext.selectPhotoTab
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ext.selectVideoTab
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.databinding.ActivityMainBinding
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.config
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.fadeIn
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.fadeOut
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.setShadowIcon
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.FLASH_OFF
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.MediaSoundHelper
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.ORIENT_LANDSCAPE_LEFT
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.ORIENT_LANDSCAPE_RIGHT
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.ORIENT_PORTRAIT
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.PhotoProcessor
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.TabSelectedListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.implementations.CameraPreviewListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.interfaces.GpPreview
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.BaseFiled
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.MySize
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.ResolutionOption
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.ServiceConfig
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store.GpDataStores
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store.GpStoreKey
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store.GpStoreKeys
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpCameraPermission
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpKits
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.FocusSquareView
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.dragableview.DragAbleContainerView
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.dragableview.PosChangeCallback
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.dragableview.PositionHelper
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.RotateLayout
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.PreviewWatermarkEditFragment
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.watermarkView
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.EditClickFrom
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.WatermarkManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.BaseWatermarkViewModel
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItemID

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ext.setLogoPosition
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ext.setMapPosition
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ext.setOfficialLogoPosition
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.beGone
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.beInvisible
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.beVisible
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.beVisibleIf
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.getFormattedDuration
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.getLatestMediaId
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.hasPermission
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.isVisible
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.navigationBarHeight
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.onAppLaunched
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.rescanPaths
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.toast
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.viewBinding
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.*
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.implementations.CameraGlInitializer
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.AndroidConf
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.TimerModeOption
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.receivers.CommonBroadcastReceiver
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.receivers.NetBroadcastReceiver
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.version.IGpVersionService
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.BroadcastManagerUtil
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GPAppUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.TencentCOSUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.ScaleView
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.WaterMarkMapWidget
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpNewVerDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkBaseID
import java.math.BigDecimal
import java.util.concurrent.TimeUnit
import kotlin.math.abs
import kotlin.time.times


class MainActivity : SimpleActivity(), PhotoProcessor.MediaSavedListener, CameraPreviewListener {
    companion object {
        const val CAPTURE_ANIMATION_DURATION = 500L
        const val PHOTO_MODE_INDEX = 1
        const val VIDEO_MODE_INDEX = 0
        const val MIN_SWIPE_DISTANCE_X = 100
        private const val TIMER_2_SECONDS = 2001
        const val TAG = "MainActivity"
    }
    private val REQUEST_LOCATION_PERMISSION: Int = 112321
    val binding by viewBinding(ActivityMainBinding::inflate)
    private var isFirstOnResume = true;
    private val asyncLayoutInflater by lazy {
        AsyncLayoutInflater(this)
    }
    //第一次网络状况监听
    private var netBroadcastReceiver: NetBroadcastReceiver? = null
    private var commonBroadcastReceiver: CommonBroadcastReceiver? = null
    //旋转监听
    private lateinit var defaultScene: Scene
//    private lateinit var flashModeScene: Scene
//    private lateinit var timerScene: Scene
    private lateinit var mOrientationEventListener: OrientationEventListener
    private lateinit var mFocusCircleView: FocusSquareView
    private lateinit var mediaSoundHelper: MediaSoundHelper
    //当前水印旋转角度
    var currentOrientation = 0
    private var isFirstNetConnect = true
    internal var mPreview: GpPreview? = null
    private var mediaSizeToggleGroup: MaterialButtonToggleGroup? = null
    private var mPreviewUri: Uri? = null
    private var mIsHardwareShutterHandled = false
    private var mLastHandledOrientation = 0
    private var countDownTimer: CountDownTimer? = null
    var currentFlashMode:Int = FLASH_OFF
    private var orientationField = BaseFiled<Int>(Int.MAX_VALUE)
    private var screenRotation:Int = 0
    var viewModel:BaseWatermarkViewModel? = null
    val waterMarkView: RotateLayout by lazy(LazyThreadSafetyMode.NONE) {
        binding.waterMarkView
    }
    private val watermarkContainer: DragAbleContainerView by lazy(LazyThreadSafetyMode.NONE) {
        binding.watermarkContainer
    }
    private val scaleView: ScaleView by lazy(LazyThreadSafetyMode.NONE) {
        binding.scaleView
    }
    // 选择水印按钮
    private val watermarkSelectBtn: View by lazy(LazyThreadSafetyMode.NONE) {
        binding.watermarkSelectBtn
    }
    // 地址刷新dialog按钮
    private val addressBtn: View by lazy(LazyThreadSafetyMode.NONE) {
        binding.addressBtn
    }
    //地址定位loading
    private val loadingProgressBar: View by lazy(LazyThreadSafetyMode.NONE) {
        binding.loadingProgressBar
    }

    //地址定位loading
    private val locationIngTxt: TextView by lazy(LazyThreadSafetyMode.NONE) {
        binding.locationIngTxt
    }
    // logo容器
    val logoContainer: RotateLayout by lazy(LazyThreadSafetyMode.NONE) {
        binding.LogoWidgetContainer
    }
    // logo容器
    //  private val mapWidgetContainer: RotateLayout by lazy(LazyThreadSafetyMode.NONE) {
   val mapWidgetContainer: RotateLayout by lazy(LazyThreadSafetyMode.NONE) {
        binding.mapWidgetContainer
    }
    internal val mainBinding:ActivityMainBinding by  lazy(LazyThreadSafetyMode.NONE) {
        binding
    }
    internal val tabSelectedListener = object : TabSelectedListener {
        override fun onTabSelected(tab: TabLayout.Tab) {
            handlePermission(PERMISSION_RECORD_AUDIO) {
                if (it) {
                    when (tab.position) {
                        VIDEO_MODE_INDEX -> mPreview?.initVideoMode()
                        PHOTO_MODE_INDEX -> mPreview?.initPhotoMode()
                        else -> throw IllegalStateException("Unsupported tab position ${tab.position}")
                    }
                } else {
                    toast(R.string.NSMicrophoneUsageDescription)
                    selectPhotoTab()
                    if (isVideoCaptureIntent()) {
                        finish()
                    }
                }
            }
        }
    }

    @SuppressLint("SuspiciousIndentation")
    override fun onCreate(savedInstanceState: Bundle?) {
        //useDynamicTheme = false
        super.onCreate(savedInstanceState)
        onAppLaunched(BuildConfig.APPLICATION_ID)

        requestWindowFeature(Window.FEATURE_NO_TITLE)
        initVariables()
        tryInitCamera()
        supportActionBar?.hide()
        setupOrientationEventListener()
        binding.watermarkContainer.positionStickHelper =
            PositionHelper(this) {
                BigDecimal.valueOf((4f / 3).toDouble()).toFloat()
            }
        binding.watermarkContainer.positionStickHelper.apply {  }

        val windowInsetsController = ViewCompat.getWindowInsetsController(window.decorView)
        windowInsetsController?.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        windowInsetsController?.hide(WindowInsetsCompat.Type.statusBars())

        if (isOreoMr1Plus()) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_FULLSCREEN
            )
        }
        val initFuncRunnable = Runnable {
            //移步加载水印并开启定位
            //从本地存储获取水印id
            val defaultId = config.selectedWaterMarkId
            Log.d(TAG,"defaultId = ${defaultId}")
            WatermarkManager.selectWatermarkID = defaultId
            loadWaterMark(defaultId)
            //修改
            this.observeDataStores(GpStoreKeys.WATERMARK_ID_CHANGE,{ _: Boolean ->
                /// relod
                val waterMark = WatermarkManager.getSelectWatermarkModel()
                waterMark.id?.let { loadWaterMark(it)

                }
            })
            //监听编辑事件，编辑完成后重新赋值一下viewModel!!.watermarkModel，触发水印更新
            this.observeDataStores(GpStoreKeys.KEY_WATERMARK_UPDATE,{ _: Boolean ->
                val tempData = WatermarkManager.getSelectWatermarkModel()
                //赋值以触发更新,这里需要更新一下locationText,
                viewModel?.let {
                    it.watermarkModel.value =  tempData
                    //保存
                    WatermarkManager.saveWatermarkModel(tempData)

                    waterMarkView.setScale(tempData.templateScale ?: 1f)
                    //监听logo 位置
                    val logoItem = it.watermarkModel.value?.items?.find {
                            watermarkItem ->
                        watermarkItem?.id == WatermarkItemID.logo.id
                    }
                    setLogoPosition(logoItem?.logoInfo?.position)
                    setMapPosition()
                    setOfficialLogoPosition()
                }
            })

            logoContainer.setOnClickListener({showEditWaterView(EditClickFrom.Logo)})
            val onPositionChangeListener:PosChangeCallback = object : PosChangeCallback {
                override fun onViewCaptured(captureView: View) {
                    TODO("Not yet implemented")
                }
                override fun onViewPositionChanged(
                    changedView: View,
                    left: Int,
                    top: Int,
                    dx: Int,
                    dy: Int
                ) {

                    TODO("Not yet implemented")
                }

                override fun onViewReleased(releasedView: View, left: Int, top: Int) {
//                    修改位置
//                    val watermarkModel = WatermarkManager.getSelectWatermarkModel()
//                    watermarkModel.left = left
//                    watermarkModel.top = top
//                    WatermarkManager.saveWatermarkModel(watermarkModel)

                }
            }

            watermarkContainer.positionChageCallback = onPositionChangeListener
            watermarkSelectBtn.setOnClickListener({
                showEditWaterView(EditClickFrom.WatermarkSelectBtn)
            })

            //设置scaleView click回调
            scaleView.onScaleCallBack = ScaleView.Callback {
                Log.d(TAG,"scaleView.onScaleCallBack ${it}")
                setScale(it)
            }

            //这是威力避免focusView的click被触发
            scaleView.setOnClickListener{
                Log.d(TAG,"scaleView .click")
            }
            addressBtn.setOnClickListener({
                binding.tip.visibility =ViewGroup.GONE
                //设置一下，这样可以再显示
                App.isShowLocationTip = false
                addressBtn.visibility = View.GONE
                loadingProgressBar.visibility = View.VISIBLE
                locationIngTxt.visibility = View.VISIBLE
                locationIngTxt.setText(R.string.k_locating)
                //取消也重新定位一次
                Log.d(TAG,"locationError relocation==")
                startLocation(false)
            })
            //先不做
          // checkNewVersion()
            //获取official logo
           // getOfficialLogo()
           //获取session
            getSession()
        }
        // 初始化 logoContainer 的布局参数
        initFuncRunnable.run()
        netBroadcastReceiver = NetBroadcastReceiver {
            //Log.i(TAG, "NetBroadcastReceiver on network connect, $it")
            if (it && (!isFirstNetConnect)) {
               // Log.i(TAG, "NetBroadcastReceiver on network connected, startLocation")
                startLocation()
            }
            isFirstNetConnect = false
        }
        commonBroadcastReceiver = CommonBroadcastReceiver{
            //如果是本地消息
            Log.d(TAG,"commonBroadcastReceiver action == ${BroadcastManagerUtil.getLocalMessage(it)}")
            if(it.action.equals(BroadcastManagerUtil.getLocalAction(it))){
                //如果是时间网络错误
               if(BroadcastManagerUtil.getLocalMessage(it).equals(BroadcastManagerUtil.timeServiceError)){
                   binding.tip.visibility =ViewGroup.VISIBLE
                   val confirmBtn = binding.tip.findViewById<AppCompatButton>(R.id.confirm)
                   confirmBtn.setText(R.string.i_ok)
                   val cancelBtn = binding.tip.findViewById<View>(R.id.cancel)
                   val title = binding.tip.findViewById<TextView>(R.id.title)
                   title?.text = ""
                   cancelBtn.visibility =  ViewGroup.GONE
                   confirmBtn?.setOnClickListener({
                       startLocation(false)
                       //Log.d(TAG,"reloadLocation msg Receiver when time is not get ")
                       binding.tip.visibility =ViewGroup.GONE
                   })
                   val message = binding.tip.findViewById<TextView>(R.id.message)
                   message?.setText(R.string.k_check_network)
               }
               else if(BroadcastManagerUtil.getLocalMessage(it).equals(BroadcastManagerUtil.reloadLocation)){
                   //重新load地址
                   //Log.d(TAG,"reloadLocation msg Receiver")
                   startLocation(false)
               }
               else if(BroadcastManagerUtil.getLocalMessage(it).equals(BroadcastManagerUtil.locationSucc)){
                  Log.d(TAG,"CommonBroadcastReceiver locationSucc msg Receiver")
                   try {

                       var baseId = viewModel?.watermarkModel?.value?.base_id
                       if (baseId ==  WatermarkBaseID.ID13.id || baseId == WatermarkBaseID.ID14.id){
                        var waterMarkMapWidget =   waterMarkView.findViewById<WaterMarkMapWidget>(R.id.watermarkMapWidget)
                           if(waterMarkMapWidget != null){
                               waterMarkMapWidget.onWaterMarkChage()
                           }

                       }
                       else {
                           binding.mapWidget.onWaterMarkChage()
                       }
                       Log.d(TAG,"binding.mapWidget.onWaterMarkChage called")
                   }
                   catch (e:Exception){
                       Log.d(TAG,"binding.mapWidget.onWaterMarkChage called error :${e.message}")
                   }

                   //定位成功,则说明之前是在定位中，loadingProgressBar，加这个判断是避免在系统间隔时间自动定位成功的时候会显示定位成功
                   if (loadingProgressBar.visibility == View.VISIBLE){
                      // Log.d(TAG,"locationSucc msg Receiver iiii")
                       addressBtn.visibility = View.VISIBLE
                       loadingProgressBar.visibility = View.GONE
                       locationIngTxt.visibility = View.VISIBLE
                       locationIngTxt.setText(R.string.k_located);
                       addressBtn.postDelayed({
                           addressBtn.visibility = View.GONE
                           locationIngTxt.visibility  = View.GONE
                       }, 1000)
                   }
                   else {
                       Log.d(TAG,"locationSucc msg Receiver out--")
                   }


               }

               //如果定位权限已经开通，但是获取定位失败，弹出消息，说明无法获取定位，这时候应该关注network是否成功
               else if(BroadcastManagerUtil.getLocalMessage(it).equals(BroadcastManagerUtil.locationError)){
                   binding.tip.visibility =ViewGroup.VISIBLE
                   val confirmBtn = binding.tip.findViewById<View>(R.id.confirm)
                   val cancelBtn = binding.tip.findViewById<View>(R.id.cancel)
                   val title = binding.tip.findViewById<TextView>(R.id.title)
                   title?.setText(R.string.i_cant_get_location)
                   confirmBtn?.setOnClickListener({
                       //在重新定位一次
                      // Log.d(TAG,"locationError relocation")
                       startLocation(false)
                   })
                   cancelBtn?.setOnClickListener({
                       binding.tip.visibility =ViewGroup.GONE
                       //设置一下，这样可以再显示
                       App.isShowLocationTip = false
                       //取消也重新定位一次
                      // Log.d(TAG,"locationError relocation")
                      // startLocation(false)
                   })
                   val message = binding.tip.findViewById<TextView>(R.id.message)
                   message?.setText(R.string.k_check_network)

                   addressBtn.visibility = View.VISIBLE
                   loadingProgressBar.visibility = View.GONE
                   locationIngTxt.visibility = View.VISIBLE
                 //  locationIngTxt.text = "failed"
                   locationIngTxt.setText(R.string.k_locate_fail)
                   //显示3秒
                   locationIngTxt.postDelayed({
                       locationIngTxt.visibility = View.GONE
                   },
                       3000)
                   //点击可以重新定位
//                   addressBtn.setOnClickListener({
//                       binding.tip.visibility =ViewGroup.GONE
//                       //设置一下，这样可以再显示
//                       App.isShowLocationTip = false
//                       //取消也重新定位一次
//                       Log.d(TAG,"locationError relocation===")
//                       startLocation(true)
//                   })

               }

            }
        }
    }

    private fun forceUpdate(conf: AndroidConf){
        //如果是新版，并且强制更新，弹出强更新弹出，
        if (GPAppUtils.isNewVer(conf.appVer) ){
           //Log.d(TAG,"isNew ver $conf")
            GpNewVerDialog(this,conf.force).show()
        }
    }
    fun setScale(scale:Float) {
        scaleView.setScale(scale)
        setScaleView(scale)
        mPreview.apply {
           // Log.d(TAG,"mPreview setZoomRatio : ${scale}")
            mPreview?.setZoomRatio(scale)
        }
    }
    fun getSession(){
        val prefs = getSharedPreferences("supabase", Context.MODE_PRIVATE)
        val sessionJson = prefs.getString("session", null)
        if (sessionJson != null) {
            val jsonObj = org.json.JSONObject(sessionJson)
            val user = jsonObj.getJSONObject("user")
            val email = user.getString("email")
            val id = user.getString("id")
            println("👤 Logged in user: $email ($id)")
        }
        else {
            println("👤 Logged in user is null")
        }
    }
    private fun setScaleView(scale:Float){
        var showScale = scale
        //如果小于一，统一显示成0.6
        if (showScale<1f){
            showScale = 0.6f
        }
        val scaleTextView= this.findViewById<View>(R.id.scaleTextView)
        val scaleText = this.findViewById<TextView>(R.id.scaleText)

        val sText = if (showScale.toInt().toFloat() == showScale) {
            showScale.toInt().toString()
        } else {
            String.format("%.1f", showScale)
        }
        scaleText.text = sText+"X"
        scaleTextView.visibility = View.VISIBLE
        scaleTextView.postDelayed({
            scaleTextView.visibility = View.GONE
        }, 300)

    }
    /**
     * 调用更新
     *
     */
    private fun checkNewVersion() {

       //Log.d(TAG,"location is mock :${GPAppUtils.isMockLocationEnabled(App.context)}")
        val callback = object : IGpVersionService.Callback {
            override fun onCurrentAndroidConf(conf: AndroidConf) {
                Log.d(TAG,"checkNewVersion onCurrentAndroidConf :${conf}")

                forceUpdate(conf)
            }
            override fun onError(e: Exception) {
                val errorText ="checkNewVersion on error ${e.message}"
                TencentCOSUtils.uploadErrorLog(App.context,errorText,"checkNewVersion_error")
                Log.d(TAG,"checkNewVersion error ${e}")
            }
            override fun onComplete() {}
        }
        ServiceConfig.versionService?.start(
            this,
            callback
        )
    }

    /**
     * 启动定位
     * @param isCreate
     */
    private fun startLocation(isCreate: Boolean = false) {
           if( GpCameraPermission.checkPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) && GpCameraPermission.checkPermission(this, Manifest.permission.INTERNET)) {
               binding.tip.visibility =ViewGroup.GONE
               App.isFromPermission = true;
               if (isCreate) {
                   //显示loading
                   addressBtn.visibility = View.GONE
                   loadingProgressBar.visibility = View.VISIBLE
                   locationIngTxt.visibility = View.VISIBLE
                   locationIngTxt.setText(R.string.k_locating)
                   Log.d(TAG,"startLocation locating ")
                   val locationService = ServiceConfig.getLocationService()
                   locationService.startLocation(this)
               } else {
                   //Log.d(TAG,"startLocation refreshLocation ${isCreate}")
                   ServiceConfig.getLocationService().refreshLocation(this)
               }
           }
        else {
//               ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.ACCESS_FINE_LOCATION,Manifest.permission.INTERNET),
//                   REQUEST_LOCATION_PERMISSION)
               //如果非首次
               if(!App.isShowLocationTip){
                   //显示过了
                   App.isShowLocationTip = true
                  // Log.d(TAG,"startLocation isCreate ${isCreate} requestPermissions isFirstOnResume")
                   ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.ACCESS_FINE_LOCATION,Manifest.permission.INTERNET),
                       REQUEST_LOCATION_PERMISSION)

              }

           }

    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            REQUEST_LOCATION_PERMISSION -> {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    // 权限被授予
                    val locationService = ServiceConfig.getLocationService()
                    locationService.startLocation(this)

                    binding.tip.visibility =ViewGroup.GONE
                    App.isFromPermission = true;
                    //显示loading
                    addressBtn.visibility = View.GONE
                    loadingProgressBar.visibility = View.VISIBLE
                    locationIngTxt.visibility = View.VISIBLE
                    locationIngTxt.setText(R.string.k_locating)
                } else {
                    AnalyticsManager.logEvent("location_not_granted")
                   binding.tip.visibility =ViewGroup.VISIBLE
                    val confirmBtn = binding.tip.findViewById<View>(R.id.confirm)
                    val cancelBtn = binding.tip.findViewById<View>(R.id.cancel)
                    val title = binding.tip.findViewById<TextView>(R.id.title)
                    title?.setText(R.string.i_cant_get_location)
                    confirmBtn?.setOnClickListener({
                                    //跳转到设置权限设置页面
                                    val intent = Intent(
                                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                        Uri.fromParts("package", packageName, null)
                                    )
                                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    startActivity(intent)
                        //设置一下，这样可以再显示
                        App.isShowLocationTip = false
                        App.isFromPermission = true;
                    })
                    cancelBtn?.setOnClickListener({
                        binding.tip.visibility =ViewGroup.GONE
                        //设置一下，这样可以再显示
                        App.isShowLocationTip = false
                    })
                    val message = binding.tip.findViewById<TextView>(R.id.message)
                    message?.setText(R.string.i_please_access_location_info)

                }
                return
            }
        }
    }

    private fun handleOrientation(orientation: Int) {
        screenRotation = orientation
        orientationField.value = orientation
        orientationField.ifChanged()?.let {
            waterMarkView.setAngle(orientation)
            logoContainer.setAngle(orientation)
            mapWidgetContainer.setAngle(orientation)
            binding.officialContainerView.setAngle(orientation)
           watermarkContainer.positionStickHelper?.forceAdjustWaterMark()
            //重新设置logo位置
            viewModel?.let {
                val logoItem = it.watermarkModel.value?.items?.find {
                        watermarkItem ->
                    watermarkItem?.id == WatermarkItemID.logo.id
                }
                setLogoPosition(logoItem?.logoInfo?.position)
                setMapPosition()
                setOfficialLogoPosition()
            }
        }
    }
    override fun onResume() {
        super.onResume()
        if (hasStorageAndCameraPermissions()) {
            val isInPhotoMode = isInPhotoMode()
            setupPreviewImage(isInPhotoMode)
            toggleActionButtons(enabled = true)
            mOrientationEventListener.enable()
        }
       // startLocation(false)

        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        ensureTransparentNavigationBar()

        if (ViewCompat.getWindowInsetsController(window.decorView) == null) {
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_FULLSCREEN or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        }
        watermarkContainer.getDragView()?.getView()?.let { newWatermarkView ->
            if (newWatermarkView != watermarkView) {
                (supportFragmentManager.findFragmentByTag("watermark_edit_fragment") as? PreviewWatermarkEditFragment)?.onWatermarkViewChanged(newWatermarkView)
            }
            watermarkView = newWatermarkView
        }
        //Log.i(TAG,"isFirstOnResume not == startLOcation")
        if (!isFirstOnResume && App.isFromPermission   ) {
            App.isFromPermission = false
           // Log.i(TAG,"isFirstOnResume not startLOcation")
           startLocation(false)
        }
        isFirstOnResume = false
        handleOrientation(0)
    }
    /**
     * 监听DataStores，主要用来监听水印修改等等
     *
     * @param T
     * @param storeKey
     * @param observer
     */
    private fun<T> observeDataStores(storeKey:String, observer: Observer<T>){
        GpDataStores.observe(
            GpStoreKey.valueOf(
                storeKey,
                this
            ), observer, this
        )
    }

    /**
     * 加载水印，并回调
     *
     * @param watermarkId
     */
    private fun loadWaterMark(watermarkId: String) {
        loadWaterMark(watermarkId) {
//            var watermark = WatermarkManager.getSelectWatermarkModel()
//            val left = watermark.left
//            val top = watermark.top
//            Log.i(TAG,"loadWaterMark done callback ${watermark}")
//            if(left != 0 || top!==0){
//                watermarkContainer.dragView
//                waterMarkView.top = top
//                waterMarkView.left = left
//            }

        }
    }


    fun showEditWaterView(from: EditClickFrom) {
       val editFragment: Fragment? = this.supportFragmentManager
           .findFragmentByTag("watermark_edit_fragment")
       if (editFragment != null && editFragment.isAdded)
           return
        val bundle = Bundle()
        //传入参数
        bundle.putString("from", from.id) // 放入字符串参数
       val fragment = PreviewWatermarkEditFragment()
        fragment.arguments = bundle
       fragment.show(
           this.supportFragmentManager,
           "watermark_edit_fragment"
       )
   }

    private fun loadWaterMark(watermarkId: String, inflateRunnable: Runnable) {
        viewModel = WatermarkManager.getCurrentWaterMarkViewModelFromLocal()
        Log.d(TAG,"viewModel ${viewModel?.watermarkModel?.value}")
       var baseId = viewModel?.watermarkModel?.value?.base_id
        WatermarkManager.asyncBindWatermarkViewData(baseId, asyncLayoutInflater, this, waterMarkView, viewModel) {
            //点击水印，弹出编辑页面
            //设置scale
            val selectWatermarkModel = WatermarkManager.getSelectWatermarkModel()
            waterMarkView.setScale(selectWatermarkModel.templateScale ?: 1f)

            waterMarkView.setOnClickListener {
                showEditWaterView(EditClickFrom.Watermark)
            }
            runOnUiThread {
                inflateRunnable.run()
            }
            //需要回调一下
            val logoItem = selectWatermarkModel.items.find { watermarkItem ->
                watermarkItem?.id == WatermarkItemID.logo.id
            }

            setLogoPosition(logoItem?.logoInfo?.position)
            setMapPosition()
            setOfficialLogoPosition()
        }
    }



    override fun onPause() {
        super.onPause()
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        if (!isAskingPermissions) {
            cancelTimer()
        }

        if (!hasStorageAndCameraPermissions() || isAskingPermissions) {
            return
        }

        mOrientationEventListener.disable()
    }

    override fun onDestroy() {
        super.onDestroy()
        mPreview = null
        mediaSoundHelper.release()
    }

    override fun onBackPressed() {
        if (!closeOptions()) {
            super.onBackPressed()
        }
    }



    private fun ensureTransparentNavigationBar() {
        window.navigationBarColor = ContextCompat.getColor(this, android.R.color.transparent)
    }

    private fun initVariables() {
        mIsHardwareShutterHandled = false
        mediaSoundHelper = MediaSoundHelper(this)
        mediaSoundHelper.loadSounds()
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
        return if (keyCode == KeyEvent.KEYCODE_CAMERA && !mIsHardwareShutterHandled) {
            mIsHardwareShutterHandled = true
            shutterPressed()
            true
        } else if (!mIsHardwareShutterHandled && config.volumeButtonsAsShutter && (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN || keyCode == KeyEvent.KEYCODE_VOLUME_UP)) {
            mIsHardwareShutterHandled = true
            shutterPressed()
            true
        } else {
            super.onKeyDown(keyCode, event)
        }
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent): Boolean {
        if (keyCode == KeyEvent.KEYCODE_CAMERA || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN || keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
            mIsHardwareShutterHandled = false
        }
        return super.onKeyUp(keyCode, event)
    }

    private fun hideIntentButtons() = binding.apply {
        cameraModeHolder.beGone()
        layoutTop.settings.beGone()
        lastPhotoVideoPreview.beInvisible()
    }

    private fun tryInitCamera() {
        handlePermission(PERMISSION_CAMERA) { grantedCameraPermission ->
            if (grantedCameraPermission) {
                handleStoragePermission {
                    val isInPhotoMode = isInPhotoMode()
                    if (isInPhotoMode) {
                        initializeCamera(true)
                        AnalyticsManager.logEvent("location_request_granted")
                        startLocation(true)
                    } else {
                        handlePermission(PERMISSION_RECORD_AUDIO) { grantedRecordAudioPermission ->
                            if (grantedRecordAudioPermission) {
                                initializeCamera(false)
                                startLocation(true)
                            } else {
                                toast(R.string.NSMicrophoneUsageDescription)
                                if (isThirdPartyIntent()) {
                                    startLocation(true)
                                    //finish()
                                } else {
                                    // re-initialize in photo mode
                                    config.initPhotoMode = true
                                    tryInitCamera()
                                    startLocation(true)
                                }
                            }
                        }
                    }
                }
            } else {
                startLocation(true)
                initializeCamera(true)
                binding.tip.visibility =ViewGroup.VISIBLE
                val confirmBtn = binding.tip.findViewById<View>(R.id.confirm)
                val cancelBtn = binding.tip.findViewById<View>(R.id.cancel)
                val title = binding.tip.findViewById<TextView>(R.id.title)
                title?.text = ""
                confirmBtn?.setOnClickListener({
                    //跳转到设置权限设置页面
                    val intent = Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.fromParts("package", packageName, null)
                    )
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                })
                cancelBtn?.setOnClickListener({
                    binding.tip.visibility =ViewGroup.GONE
                })
                val message = binding.tip.findViewById<TextView>(R.id.message)
                message?.setText(R.string.NSCameraUsageDescription)
               // finish()
            }
        }
    }




    fun isThirdPartyIntent() = isVideoCaptureIntent() || isImageCaptureIntent()

    fun isImageCaptureIntent(): Boolean = intent?.action == MediaStore.ACTION_IMAGE_CAPTURE || intent?.action == MediaStore.ACTION_IMAGE_CAPTURE_SECURE

    fun isVideoCaptureIntent(): Boolean = intent?.action == MediaStore.ACTION_VIDEO_CAPTURE
    private fun initializeCamera(isInPhotoMode: Boolean) {
        setContentView(binding.root)
        initButtons()
        initModeSwitcher()
        binding.apply {
            defaultScene = Scene(topOptions, layoutTop.defaultIcons)
//            flashModeScene = Scene(topOptions, layoutFlash.flashToggleGroup)
//            timerScene = Scene(topOptions, layoutTimer.timerToggleGroup)
        }

        WindowCompat.setDecorFitsSystemWindows(window, false)
        ViewCompat.setOnApplyWindowInsetsListener(binding.viewHolder) { _, windowInsets ->
            val safeInsetBottom = windowInsets.displayCutout?.safeInsetBottom ?: 0
            val safeInsetTop = windowInsets.displayCutout?.safeInsetTop ?: 0

            binding.topOptions.updateLayoutParams<ViewGroup.MarginLayoutParams> {
                topMargin = safeInsetTop
            }

            val marginBottom = safeInsetBottom + navigationBarHeight + resources.getDimensionPixelSize(R.dimen.bigger_margin)

            binding.shutter.updateLayoutParams<ViewGroup.MarginLayoutParams> {
                bottomMargin = marginBottom
            }

            WindowInsetsCompat.CONSUMED
        }

        if (isInPhotoMode) {
            selectPhotoTab()
        } else {
            selectVideoTab()
        }

        val outputUri = intent.extras?.get(MediaStore.EXTRA_OUTPUT) as? Uri
        Log.d(TAG,"outputUri ${outputUri}")
        val isThirdPartyIntent = isThirdPartyIntent()
        Log.d(TAG,"outputUri ${outputUri} isThirdPartyIntent $isThirdPartyIntent")
        mPreview = CameraGlInitializer(this).createCameraXPreview(
            binding.previewView,
            listener = this,
            mediaSoundHelper = mediaSoundHelper,
            outputUri = outputUri,
            isThirdPartyIntent = isThirdPartyIntent,
            initInPhotoMode = isInPhotoMode,
            binding.glPreviewView
        )
        mFocusCircleView = FocusSquareView(this).apply {
            id = View.generateViewId()
        }
        binding.viewHolder.addView(mFocusCircleView)
        setupPreviewImage(true)
//        initTimerModeTransitionNames()

        if (isThirdPartyIntent) {
            hideIntentButtons()
        }
    }

//    private fun initTimerModeTransitionNames() = binding.layoutTimer.apply {
//        val baseName = getString(R.string.toggle_timer)
//        timerOff.transitionName = "$baseName${TimerMode.OFF.name}"
//        timer3s.transitionName = "$baseName${TimerMode.TIMER_3.name}"
//        timer5s.transitionName = "$baseName${TimerMode.TIMER_5.name}"
//        timer10S.transitionName = "$baseName${TimerMode.TIMER_10.name}"
//    }

    @SuppressLint("InflateParams")
    private fun initButtons() = binding.apply {
        timerText.setFactory { layoutInflater.inflate(R.layout.timer_text, null) }
        toggleCamera.setOnClickListener { mPreview!!.toggleFrontBackCamera() }
        lastPhotoVideoPreview.setOnClickListener { showLastMediaPreview() }
        group.setOnClickListener {
            goGroupActivity()
        }
        layoutTop.apply {
            toggleFlash.setOnClickListener {
                mPreview!!.handleFlashlightClick()
            }
            toggleTimer.setOnClickListener {
                mPreview!!.showTimerMode()
//                val transitionSet = createTransition()
//                TransitionManager.go(timerScene, transitionSet)
//                layoutTimer.timerToggleGroup.beVisible()
//                layoutTimer.timerToggleGroup.check(config.timerMode.getTimerModeResId())
//                layoutTimer.timerToggleGroup.children.forEach { setButtonColors(it as MaterialButton) }
            }
            logoButton.setOnClickListener {
                showEditWaterView(EditClickFrom.Logo)
            }
          //  settings.setShadowIcon(R.drawable.ic_settings_vector)
            settings.setOnClickListener { if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                launchSettings()
            }
            }
            changeResolution.setOnClickListener {
               mPreview?.showChangeResolution()
            }
        }

        shutter.setOnClickListener { shutterPressed() }


//        layoutTimer.apply {
//            timerOff.setShadowIcon(R.drawable.ic_timer_off_vector)
//            timerOff.setOnClickListener { selectTimerMode(TimerMode.OFF) }
//
//            timer3s.setShadowIcon(R.drawable.ic_timer_3_vector)
//            timer3s.setOnClickListener { selectTimerMode(TimerMode.TIMER_3) }
//
//            timer5s.setShadowIcon(R.drawable.ic_timer_5_vector)
//            timer5s.setOnClickListener { selectTimerMode(TimerMode.TIMER_5) }
//
//            timer10S.setShadowIcon(R.drawable.ic_timer_10_vector)
//            timer10S.setOnClickListener { selectTimerMode(TimerMode.TIMER_10) }
//        }
//
//        setTimerModeIcon(config.timerMode)
    }

//    private fun selectTimerMode(timerMode: TimerMode) {
//        config.timerMode = timerMode
//        setTimerModeIcon(timerMode)
//        closeOptions()
//    }

//    private fun setTimerModeIcon(timerMode: TimerMode) = binding.layoutTop.toggleTimer.apply {
//        setShadowIcon(timerMode.getTimerModeDrawableRes())
//        transitionName = "${getString(R.string.toggle_timer)}${timerMode.name}"
//    }






    private fun showLastMediaPreview() {
        if (mPreviewUri != null) {
            //去相册页
            val intent = Intent(this, GalleryActivity::class.java)
            startActivity(intent)
//            val path = applicationContext.getRealPathFromURI(mPreviewUri!!) ?: mPreviewUri!!.toString()
//            openPathIntent(path, false, BuildConfig.APPLICATION_ID)
        }
    }

    private fun shutterPressed() {
        if (countDownTimer != null) {
            cancelTimer()
        } else if (isInPhotoMode()) {
            val timerMode = config.timerModeOption
            //没有设置时间
            if (timerMode.value == 0) {
                mPreview?.tryTakePicture()
            } else {
                scheduleTimer(timerMode)
            }
        } else {
            //增加录音权限判断
            handlePermission(PERMISSION_RECORD_AUDIO) { grantedRecordAudioPermission ->
                if (grantedRecordAudioPermission) {
                    mPreview?.toggleRecording()
                } else {
                    toast(R.string.NSMicrophoneUsageDescription)
                }
            }

        }
    }

    private fun cancelTimer() {
        mediaSoundHelper.stopTimerCountdown2SecondsSound()
        countDownTimer?.cancel()
        countDownTimer = null
        resetViewsOnTimerFinish()
    }

    override fun onInitPhotoMode() {
        binding.apply {
            shutter.setImageResource(R.drawable.ic_shutter_animated)
        }
        setupPreviewImage(true)
        selectPhotoTab()
    }

    override fun onInitVideoMode() {
        binding.apply {
            shutter.setImageResource(R.drawable.ic_video_rec_animated)
//            layoutTop.toggleTimer.fadeOut()
//            layoutTop.toggleTimer.beGone()
        }
        setupPreviewImage(false)
        selectVideoTab()
    }

    private fun setupPreviewImage(isPhoto: Boolean) {
    //val uri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
       // val uri = config.savePhotosFolder.toUri()
          val uri = MediaStore.Files.getContentUri("external")
        //Log.d(TAG,"setupPreviewImage uri:${uri}")
        val lastMediaId = getLatestMediaId(uri)
        if (lastMediaId == 0L) {
            return
        }
        mPreviewUri = Uri.withAppendedPath(uri, lastMediaId.toString())
        loadLastTakenMedia(mPreviewUri)
    }

    private fun loadLastTakenMedia(uri: Uri?) {
        mPreviewUri = uri
        runOnUiThread {
            if (!isDestroyed) {
                val options = RequestOptions()
                    .transforms(CenterCrop(), RoundedCorners(25))
                    .diskCacheStrategy(DiskCacheStrategy.NONE)
                Glide.with(this)
                    .load(uri)
                    .apply(options)
                    .transition(DrawableTransitionOptions.withCrossFade())
                    .into(binding.lastPhotoVideoPreview)
            }
        }
    }

    private fun hasStorageAndCameraPermissions(): Boolean {
        return if (isInPhotoMode()) hasPhotoModePermissions() else hasVideoModePermissions()
    }

    private fun hasPhotoModePermissions(): Boolean {
        return if (isTiramisuPlus()) {
            var hasMediaPermission = hasPermission(PERMISSION_READ_MEDIA_IMAGES) || hasPermission(PERMISSION_READ_MEDIA_VIDEO)
            if (isUpsideDownCakePlus()) {
                hasMediaPermission = hasMediaPermission || hasPermission(PERMISSION_READ_MEDIA_VISUAL_USER_SELECTED)
            }
            hasMediaPermission && hasPermission(PERMISSION_CAMERA)
        } else {
            hasPermission(PERMISSION_WRITE_STORAGE) && hasPermission(PERMISSION_CAMERA)
        }
    }

    private fun hasVideoModePermissions(): Boolean {
        return if (isTiramisuPlus()) {
            var hasMediaPermission = hasPermission(PERMISSION_READ_MEDIA_VIDEO)
            if (isUpsideDownCakePlus()) {
                hasMediaPermission = hasMediaPermission || hasPermission(PERMISSION_READ_MEDIA_VISUAL_USER_SELECTED)
            }
            hasMediaPermission && hasPermission(PERMISSION_CAMERA) && hasPermission(PERMISSION_RECORD_AUDIO)
        } else {
            hasPermission(PERMISSION_WRITE_STORAGE) && hasPermission(PERMISSION_CAMERA) && hasPermission(PERMISSION_RECORD_AUDIO)
        }
    }


    private fun setupOrientationEventListener() {
        mOrientationEventListener = object : OrientationEventListener(this, SensorManager.SENSOR_DELAY_NORMAL) {
            override fun onOrientationChanged(sennsorOrientation: Int) {
                if (isDestroyed) {
                    mOrientationEventListener.disable()
                    return
                }
                //水印角度
                var orientation = sennsorOrientation;
                if (orientation == ORIENTATION_UNKNOWN) return
                var diff:Int = abs(orientation - currentOrientation)
                if (diff > 180) diff = 360 - diff
                if (diff > 60) {
                    orientation = (orientation + 45) / 90 * 90
                    orientation %= 360
                    if (orientation != currentOrientation) {
                        currentOrientation = orientation
                    }
                }
                handleOrientation(currentOrientation)

                val currOrient = when (sennsorOrientation) {
                    in 75..134 -> ORIENT_LANDSCAPE_RIGHT
                    in 225..289 -> ORIENT_LANDSCAPE_LEFT
                    else -> ORIENT_PORTRAIT
                }
                if (currOrient != mLastHandledOrientation) {
                    val degrees = when (currOrient) {
                        ORIENT_LANDSCAPE_LEFT -> 90
                        ORIENT_LANDSCAPE_RIGHT -> -90
                        else -> 0
                    }
                    animateViews(degrees)
                    mLastHandledOrientation = currOrient
                }
            }
        }
    }

    private fun animateViews(degrees: Int) = binding.apply {
        val views = arrayOf(
            toggleCamera,
            layoutTop.toggleFlash,
            layoutTop.changeResolution,
            shutter,
            layoutTop.settings,
            lastPhotoVideoPreview
        )
        for (view in views) {
            rotate(view, degrees)
        }
    }

    private fun rotate(view: View, degrees: Int) = view.animate().rotation(degrees.toFloat()).start()

    override fun setHasFrontAndBackCamera(hasFrontAndBack: Boolean) {
        binding.toggleCamera.beVisibleIf(hasFrontAndBack)
    }



    override fun onChangeCamera(frontCamera: Boolean) {
//        binding.toggleCamera.setImageResource(if (frontCamera) R.drawable.ic_camera_rear_vector else R.drawable.ic_camera_front_vector)
    }

    override fun onPhotoCaptureStart() {
        toggleActionButtons(enabled = false)
    }

    override fun onPhotoCaptureEnd() {
        Log.d(TAG,"onPhotoCaptureEnd")
        toggleActionButtons(enabled = true)
    }

    private fun toggleActionButtons(enabled: Boolean) = binding.apply {
        runOnUiThread {
            shutter.isClickable = enabled
            previewView.isEnabled = enabled
            layoutTop.changeResolution.isEnabled = enabled
            toggleCamera.isClickable = enabled
            layoutTop.toggleFlash.isClickable = enabled
        }
    }

    override fun shutterAnimation() {
        binding.shutterAnimation.alpha = 1.0f
        binding.shutterAnimation.animate().alpha(0f).setDuration(CAPTURE_ANIMATION_DURATION).start()
    }

    override fun onMediaSaved(uri: Uri) {
        binding.layoutTop.changeResolution.isEnabled = true
        loadLastTakenMedia(uri)
        mediaSaved(uri.path!!)

    }

    override fun onImageCaptured(bitmap: Bitmap) {
        if (isImageCaptureIntent()) {
            Intent().apply {
                putExtra("data", bitmap)
                setResult(RESULT_OK, this)
            }
            finish()
        }
    }



    override fun onVideoRecordingStarted() {
        binding.apply {
            cameraModeHolder.beInvisible()
            videoRecCurrTimer.beVisible()

            toggleCamera.fadeOut()
            lastPhotoVideoPreview.fadeOut()

            layoutTop.changeResolution.isEnabled = false
            layoutTop.settings.isEnabled = false
            shutter.post {
                if (!isDestroyed) {
                    shutter.isSelected = true
                }
            }
        }
    }
    private fun rescanVideoSaved(currentVideoPath:String) {
        mPreviewUri = currentVideoPath.toUri()
        var path  = currentVideoPath
        Log.d(TAG,"rescanVideoSaved $path")
        rescanPaths(arrayListOf(path)) {
            setupPreviewImage(false)
//            Log.d(TAG,"rescanVideoSaved rescanPaths $path")
//            Intent(BROADCAST_REFRESH_MEDIA).apply {
//                putExtra(REFRESH_PATH, path)
//                `package` = "com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto"
//                sendBroadcast(this)
//            }
        }

    }
    override fun onVideoRecordingStopped(currentVideoPath:String) {
        binding.apply {
            cameraModeHolder.beVisible()
            toggleCamera.fadeIn()
            lastPhotoVideoPreview.fadeIn()

            videoRecCurrTimer.text = 0.getFormattedDuration()
            videoRecCurrTimer.beGone()

            shutter.isSelected = false
            layoutTop.changeResolution.isEnabled = true
            layoutTop.settings.isEnabled = true
            Log.d(TAG,"onVideoRecordingStopped rescanVideoSaved")
            rescanVideoSaved(currentVideoPath)
        }
    }

    override fun onVideoDurationChanged(durationNanos: Long) {
        runOnUiThread {

           // val seconds = TimeUnit.NANOSECONDS.toSeconds(durationNanos).toInt()
            val seconds = durationNanos.toInt()
            Log.d(TAG,"onVideoDurationChanged durationNanos:${durationNanos} seconds:${seconds}")
            binding.videoRecCurrTimer.text = seconds.getFormattedDuration()
        }
    }

    override fun onFocusCamera(xPos: Float, yPos: Float) {
        mFocusCircleView.drawFocusSquare(xPos, yPos)
    }

    override fun onTouchPreview() {
        closeOptions()
    }

    private fun closeOptions(): Boolean {
        binding.apply {
            if (mediaSizeToggleGroup?.isVisible() == true
            ) {
                val transitionSet = createTransition()
                TransitionManager.go(defaultScene, transitionSet)
                mediaSizeToggleGroup?.beGone()
//                layoutTimer.timerToggleGroup.beGone()
                layoutTop.defaultIcons.beVisible()
                return true
            }

            return false
        }
    }

    override fun displaySelectedResolution(resolutionOption: ResolutionOption) {
        val imageRes = resolutionOption.imageDrawableResId
        binding.layoutTop.changeResolution.setShadowIcon(imageRes)
        binding.layoutTop.changeResolution.transitionName = "${resolutionOption.buttonViewId}"
    }
    override fun displayTimerOptions(selectedTimerModeOption: TimerModeOption) {
        val imageRes = selectedTimerModeOption.imageDrawableResId
        binding.layoutTop.toggleTimer.setShadowIcon(imageRes)
        binding.layoutTop.toggleTimer.transitionName = "${selectedTimerModeOption.buttonViewId}"
    }

    @SuppressLint("ResourceType")
    override fun showImageSizes(
        selectedResolution: ResolutionOption,
        resolutions: List<ResolutionOption>,
        isPhotoCapture: Boolean,
        isFrontCamera: Boolean,
        onSelect: (index: Int, changed: Boolean) -> Unit
    ) {
      //Log.d(TAG,"showImageSizes ${selectedResolution} isPhotoCapture：$isPhotoCapture isFrontCamera: ${isFrontCamera}")
      doShowImageSizes(selectedResolution, resolutions, isPhotoCapture, isFrontCamera, onSelect)
    }

    override fun showTimerOptions(
        selectedTimerModeOption: TimerModeOption,
        timers: List<TimerModeOption>,
        isPhotoCapture: Boolean,
        onSelect: (index: Int, changed: Boolean) -> Unit
    ) {
        doShowTimerOptions(selectedTimerModeOption,timers,isPhotoCapture,onSelect)
    }

    private fun createTransition(): Transition {
        val fadeTransition = Fade()
        return TransitionSet().apply {
            addTransition(fadeTransition)
            this.duration = resources.getInteger(R.integer.icon_anim_duration).toLong()
        }
    }

    //flash相关

    override fun showFlashOptions(photoCapture: Boolean) {
        doShowFlashOptions(photoCapture)
    }

    override fun onChangeFlashMode(flashMode: Int) {
        doOnChangeFlashMode(flashMode)
    }
    override fun setFlashAvailable(available: Boolean) {
        doSetFlashAvailable(available)
    }

    private fun calculateDistance(view1: ViewGroup, view2: ViewGroup): Int {
        val rect1 = Rect()
        view1.getGlobalVisibleRect(rect1) // 获取 view1 在屏幕上的可见矩形

        val rect2 = Rect()
        view2.getGlobalVisibleRect(rect2) // 获取 view2 在屏幕上的可见矩形

        // 计算距离
        val distance = rect2.top - rect1.bottom
        return distance
    }
    /**
     * 在这里调整画幅
     *
     * @param resolution
     */
    override fun adjustPreviewView(resolution: MySize) {
        binding.apply {
            val constraintSet = ConstraintSet()
            constraintSet.clone(viewHolder)
            //计算
            val screenWidth = GpKits.Device.getScreenWidth(App.context)
            val ratio = resolution.width.toFloat() / resolution.height.toFloat()
            val height = (screenWidth * ratio).toInt()
            Log.d(TAG,"adjustPreviewView ${resolution} screenWidth:$screenWidth ratio:$ratio height$height")
            constraintSet.constrainWidth(previewViewContainer.id, screenWidth)
            constraintSet.constrainHeight(previewViewContainer.id, height)
            if(resolution.isSixteenToNine()){
                Log.d(TAG,"adjustPreviewView isSixteenToNine ${resolution}")
                val topMargin = 0
                constraintSet.setMargin(previewViewContainer.id, ConstraintSet.TOP, topMargin)
                constraintSet.connect(previewViewContainer.id, ConstraintSet.TOP, ConstraintSet.PARENT_ID, ConstraintSet.TOP)
            }
            else {
                val distance = calculateDistance(topOptions,cameraModeHolder)
                val topMargin = (distance - height) / 2
                Log.d(TAG,"adjustPreviewView not SixteenToNine distance:$distance topMargin:$topMargin ${resolution}")
                constraintSet.connect(previewViewContainer.id, ConstraintSet.TOP, topOptions.id, ConstraintSet.BOTTOM)
                constraintSet.setMargin(previewViewContainer.id, ConstraintSet.TOP, topMargin)
            }
            constraintSet.connect(watermarkContainer.id, ConstraintSet.TOP, previewViewContainer.id, ConstraintSet.TOP)
            constraintSet.connect(watermarkContainer.id, ConstraintSet.BOTTOM, previewViewContainer.id, ConstraintSet.BOTTOM)
            constraintSet.applyTo(viewHolder)
        }

        //设置一下
       scaleView.setScale(CameraSelectorManager.curRatio)
    }

    override fun mediaSaved(path: String) {
        //Log.d(TAG,"mediaSaved path ${path}")
        rescanPaths(arrayListOf(path)) {
            setupPreviewImage(true)
//            Intent(BROADCAST_REFRESH_MEDIA).apply {
//                putExtra(REFRESH_PATH, path)
//                `package` = "com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto"
//                sendBroadcast(this)
//            }

        }

        if (isImageCaptureIntent()) {
            setResult(RESULT_OK)
            finish()
        }
    }

    private fun scheduleTimer(timerMode: TimerModeOption) {
        hideViewsOnTimerStart()
        binding.shutter.setImageState(intArrayOf(R.attr.state_timer_cancel), true)
        binding.timerText.beVisible()
        var playSound = true
        countDownTimer = object : CountDownTimer((timerMode.value*1000).toLong(), 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val seconds = (TimeUnit.MILLISECONDS.toSeconds(millisUntilFinished) + 1).toString()
                binding.timerText.setText(seconds)
                if (playSound && config.isSoundEnabled) {
                    if (millisUntilFinished <= TIMER_2_SECONDS) {
                        mediaSoundHelper.playTimerCountdown2SecondsSound()
                        playSound = false
                    } else {
                        mediaSoundHelper.playTimerCountdownSound()
                    }
                }
            }

            override fun onFinish() {
                cancelTimer()
                mPreview!!.tryTakePicture()
            }
        }.start()
    }

    private fun hideViewsOnTimerStart() = binding.apply {
        arrayOf(topOptions, toggleCamera, lastPhotoVideoPreview, cameraModeHolder).forEach {
            it.fadeOut()
            it.beInvisible()
        }
    }

    private fun resetViewsOnTimerFinish() = binding.apply {
        arrayOf(topOptions, toggleCamera, lastPhotoVideoPreview, cameraModeHolder).forEach {
            it.fadeIn()
            it.beVisible()
        }
        timerText.beGone()
        shutter.setImageState(intArrayOf(-R.attr.state_timer_cancel), true)
    }

    override fun onStart() {
        super.onStart()
        BroadcastManagerUtil.registerNetWorkBroadcastReceiver(this, netBroadcastReceiver)
        BroadcastManagerUtil.registerLocalMessageReceiver(commonBroadcastReceiver)
    }
    override fun onStop() {
        super.onStop()

        BroadcastManagerUtil.unregisterNetWorkBroadcastReceiver(this, netBroadcastReceiver)
        BroadcastManagerUtil.unregisterLocalMessageReceiver(commonBroadcastReceiver)
    }

}
