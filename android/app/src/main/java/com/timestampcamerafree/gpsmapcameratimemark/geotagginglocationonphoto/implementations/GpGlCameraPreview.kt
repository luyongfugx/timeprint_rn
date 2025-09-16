package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.implementations



import android.annotation.SuppressLint
import android.content.Context
import android.graphics.BitmapFactory
import android.hardware.SensorManager
import android.hardware.camera2.CameraCharacteristics
import android.hardware.display.DisplayManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.Size
import android.view.Display
import android.view.GestureDetector
import android.view.GestureDetector.SimpleOnGestureListener
import android.view.MotionEvent
import android.view.OrientationEventListener
import android.view.ScaleGestureDetector
import android.view.Surface
import android.view.View
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.CameraState
import androidx.camera.core.DisplayOrientedMeteringPointFactory
import androidx.camera.core.FocusMeteringAction
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCapture.Builder
import androidx.camera.core.ImageCapture.CAPTURE_MODE_MAXIMIZE_QUALITY
import androidx.camera.core.ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY
import androidx.camera.core.ImageCapture.ERROR_CAPTURE_FAILED
import androidx.camera.core.ImageCapture.FLASH_MODE_AUTO
import androidx.camera.core.ImageCapture.FLASH_MODE_OFF
import androidx.camera.core.ImageCapture.FLASH_MODE_ON
import androidx.camera.core.ImageCapture.Metadata
import androidx.camera.core.ImageCapture.OnImageCapturedCallback
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.core.UseCase
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.FallbackStrategy
import androidx.camera.video.FileDescriptorOutputOptions
import androidx.camera.video.FileOutputOptions
import androidx.camera.video.MediaStoreOutputOptions
import androidx.camera.video.Quality
import androidx.camera.video.QualitySelector
import androidx.camera.video.Recorder
import androidx.camera.video.Recording
import androidx.camera.video.VideoCapture
import androidx.camera.video.VideoRecordEvent
import androidx.camera.view.PreviewView
import androidx.camera.view.PreviewView.ScaleType
import androidx.core.content.ContextCompat
import androidx.core.view.doOnLayout
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import com.bumptech.glide.load.ImageHeaderParser.UNKNOWN_ORIENTATION
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.GpBaseSimpleActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.checkLocationPermission
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.config
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.getFilenameFromPath
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.toAppFlashMode
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.toCameraSelector
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.toCameraXFlashMode
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.toCameraXQuality
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.toLensFacing
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.AnalyticsManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.BitmapUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.CameraErrorHandler
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.CameraSelectorManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.FLASH_ALWAYS_ON
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.FLASH_ON
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.ImageQualityManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.ImageSaver
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.ImageUtil
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.MediaOutputHelper
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.MediaSizeStore
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.MediaSoundHelper
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.PERMISSION_ACCESS_FINE_LOCATION
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.PinchToZoomOnScaleGestureListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.SimpleLocationManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.VideoQualityManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.encodec.AudioRecorder
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.encodec.MediaEncoder
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.ensureBackgroundThread
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.implementations.ext.glStartRecord
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.implementations.ext.glStopRecord
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.interfaces.GpPreview
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.CaptureMode
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.MediaOutput
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.MySize
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.ResolutionOption
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.TimerModeOption
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.modelsdata.WatermarkBitmap
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.ServiceConfig
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GPAppUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpDateFormat
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.TencentCOSUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.WatermarkManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkID
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItemID
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.logo.LogoPosition
//import org.jetbrains.anko.toast
import java.util.Locale
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

class GpGlCameraPreview (
    val activity: GpBaseSimpleActivity,
    private val previewView: PreviewView,
    private val mediaSoundHelper: MediaSoundHelper,
    private val mediaOutputHelper: MediaOutputHelper,
    private val cameraErrorHandler: CameraErrorHandler,
    val listener: CameraPreviewListener,
    private val isThirdPartyIntent: Boolean,
    initInPhotoMode: Boolean,
    val glPreviewView:GpGICameraPreviewView
) :  GpPreview,DefaultLifecycleObserver {

    companion object {
        var TAG ="GpGlCameraPreview"
        // Auto focus is 1/6 of the area.
        private const val AF_SIZE = 1.0f / 6.0f
        private const val AE_SIZE = AF_SIZE * 1.5f
        private const val CAMERA_MODE_SWITCH_WAIT_TIME = 500L
        private const val RATIO_4_3_VALUE = 4.0 / 3.0
        private const val RATIO_16_9_VALUE = 16.0 / 9.0
    }

    val config = activity.config
    private val contentResolver = activity.contentResolver
    private val mainExecutor = ContextCompat.getMainExecutor(activity)
    private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private lateinit var recordVideoWaterMarkScheduler: ScheduledExecutorService

    private val displayManager = activity.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
    private val videoQualityManager = VideoQualityManager(activity)
    private val imageQualityManager = ImageQualityManager(activity)
    private val mediaSizeStore = MediaSizeStore(config)
    private var currentSize:MySize? = null;
    private var scaleGesture: ScaleGestureDetector? =null
    private var gestureDetector: GestureDetector? =null
    private var preview: Preview? = null
//    private var glPreview:  GpGICameraPreviewView? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private var imageCapture: ImageCapture? = null
    private var videoCapture: VideoCapture<Recorder>? = null
    private var camera: Camera? = null
    private var currentRecording: Recording? = null
    var currentVideoPath:String? = null;

    private var recordingState: VideoRecordEvent? = null
    //不需要在录制的时候更新的图片，录制期间不会变化
    private var videoStaticWatermarkBitmaps: MutableList<WatermarkBitmap> = mutableListOf()
    //需要在录制的时候实时更新的水印，录制期间实时变化比如带时间的
    private var videoRealUpdateWatermarkBitmaps: MutableList<WatermarkBitmap> = mutableListOf()
    //gl 录制
    var mediaEncodec: MediaEncoder? = null
    var recordFinish = false
    var recording = false
    lateinit var audioRecorder: AudioRecorder

    //从配置里读取是前置还是后置，但是因为
    private var cameraSelector = config.lastUsedCameraLens.toCameraSelector()
    private var flashMode = FLASH_MODE_OFF
    private var isPhotoCapture = initInPhotoMode
    private var lastRotation = 0
    private var lastCameraStartTime = 0L
    private var simpleLocationManager: SimpleLocationManager? = null
    private val orientationEventListener = object : OrientationEventListener(activity, SensorManager.SENSOR_DELAY_NORMAL) {
        @SuppressLint("RestrictedApi")
        override fun onOrientationChanged(orientation: Int) {

            if (orientation == UNKNOWN_ORIENTATION) {
                return
            }

            val rotation = when (orientation) {
                in 45 until 135 -> Surface.ROTATION_270
                in 135 until 225 -> Surface.ROTATION_180
                in 225 until 315 -> Surface.ROTATION_90
                else -> Surface.ROTATION_0
            }

            if (lastRotation != rotation) {

                preview?.targetRotation = rotation
                imageCapture?.targetRotation = rotation
                videoCapture?.targetRotation = rotation
                lastRotation = rotation
                Log.d(TAG,"addWatermark onOrientationChanged set lastRotation to $lastRotation")
            }
        }
    }
    private val cameraHandler = Handler(Looper.getMainLooper())
    private val photoModeRunnable = Runnable {
        if (imageCapture == null) {
            isPhotoCapture = true
            if (!isThirdPartyIntent) { // we don't want to store the state for 3rd party intents
                config.initPhotoMode = true
            }
            startCamera()
        } else {
            listener.onInitPhotoMode()
        }
    }
    private val videoModeRunnable = Runnable {
        if (videoCapture == null) {
            isPhotoCapture = false
            if (!isThirdPartyIntent) { // we don't want to store the state for 3rd party intents
                config.initPhotoMode = false
            }
            startCamera()
        } else {
            listener.onInitVideoMode()
        }
    }

    init {
        bindToLifeCycle()
        glPreviewView.setGpGlCameraPreview(this)
    }

    private fun bindToLifeCycle() {
        activity.lifecycle.addObserver(this)
    }

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(activity.applicationContext)
        cameraProviderFuture.addListener({
            //如果重置了相机，则lastRotation 设置为0
            lastRotation = 0;
            try {
                val provider = cameraProviderFuture.get()
                cameraProvider = provider
                imageQualityManager.initWideAngleCameraSelects()
                cameraSelector = config.lastUsedCameraLens.toCameraSelector()
                imageQualityManager.initSupportedQualities()
                videoQualityManager.initSupportedQualities(provider)

                bindCameraUseCases()
                setupCameraObservers()

                //调整review角度
               // glPreviewView.initView(activity)


            } catch (e: Exception) {
                e.printStackTrace()
                Log.d(TAG,"startCamera error ",e)
                val errorMessage =  R.string.i_save_photo_failed
               // activity.toast(errorMessage)
            }
        }, mainExecutor)
    }

    @SuppressLint("RestrictedApi")
    private fun bindCameraUseCases() {
        val cameraProvider = cameraProvider ?: throw IllegalStateException("Camera initialization failed.")
        val resolution = if (isPhotoCapture) {
            imageQualityManager.getUserSelectedResolution(cameraSelector).also {
                currentSize = it
                listener.displaySelectedResolution(it.toResolutionOption())
            }
        } else {

            //如果是视频，只能根据
            val selectedQuality = videoQualityManager.getUserSelectedQuality(cameraSelector).also {
                listener.displaySelectedResolution(it.toResolutionOption())
            }
            //currentSize =  MySize(selectedQuality.width, selectedQuality.height)
            currentSize =  MySize(selectedQuality.width, selectedQuality.height)
            currentSize!!
        }
        Log.d(TAG,"isPhotoCapture $isPhotoCapture resolution:${resolution}")
        listener.adjustPreviewView(resolution)
        previewView.scaleType = if (resolution.isSquare()) ScaleType.FILL_CENTER else ScaleType.FIT_CENTER
        val rotation = previewView.display.rotation
        val rotatedResolution = getRotatedResolution(resolution, rotation)
        val previewUseCase = buildPreview(rotatedResolution, rotation)
        val captureUseCase = getCaptureUseCase(rotatedResolution, rotation)
        val imageAnalysis = ImageAnalysis.Builder()
            .setTargetRotation(rotation)
            .setTargetResolution(rotatedResolution)
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
            .build()
        Log.d(TAG,"test imageAnalysis")
//        imageAnalysis.setAnalyzer(Executors.newSingleThreadExecutor()) { image ->
//            val bitmap = image.toBitmap()
//            val rotatedBitmap = rotateBitmap(bitmap, image.imageInfo.rotationDegrees)
//            val watermarkedBitmap = addWatermark(rotatedBitmap)
//            saveBitmapToGallery(App.context,watermarkedBitmap)
//        }


        cameraProvider.unbindAll()
        camera =  cameraProvider.bindToLifecycle(
            activity,
            cameraSelector,
            previewUseCase,
            captureUseCase,
            // imageAnalysis
        )
        preview = previewUseCase
        setupZoomAndFocus()
        setFlashlightState(config.flashlightState)
        showTimerIcon()
    }
    private fun getRotatedResolution(resolution: MySize, rotationDegrees: Int): Size {
        return if (rotationDegrees == Surface.ROTATION_0 || rotationDegrees == Surface.ROTATION_180) {
            Size(resolution.height, resolution.width)
        } else {
            Size(resolution.width, resolution.height)
        }
    }
    private fun buildPreview(resolution: Size, rotation: Int): Preview {
        glPreviewView.visibility = View.VISIBLE
        val preview = Preview.Builder()
            .setTargetRotation(rotation)
            .setTargetResolution(resolution)
            .build()
            .also {
                it.setSurfaceProvider { request ->
                    //保留原来的
                   // Log.d(TAG,"setSurfaceProvider resolution ${resolution} request.resolution ${request.resolution.width} ${request.resolution.height}")
                    //cameraX 的previewView
                   previewView.surfaceProvider.onSurfaceRequested(request)
                    //opengl previewView
                    glPreviewView?.surfaceTexture?.let { texture ->
                        texture.setDefaultBufferSize(request.resolution.width,request.resolution.height)
                        val surface = Surface(texture)
                        request.provideSurface(surface, cameraExecutor) {
                        }

                    }
                }
            }
        glPreviewView.changePreviewAngle(cameraSelector.toLensFacing())
        return  preview
    }

    private fun getCaptureUseCase(resolution: Size, rotation: Int): UseCase {
        return if (isPhotoCapture) {
            buildImageCapture(resolution, rotation).also {
                imageCapture = it
                videoCapture = null
            }
        } else {
            buildVideoCapture().also {
                videoCapture = it
                imageCapture = null
            }
        }
    }

    private fun buildImageCapture(resolution: Size, rotation: Int): ImageCapture {
        return Builder()
            .setCaptureMode(getCaptureMode())
            .setFlashMode(flashMode)
            .setJpegQuality(config.photoQuality)
            .setTargetRotation(rotation)
            .setTargetResolution(resolution)
            .build()
    }

    private fun getCaptureMode(): Int {
        return when (config.captureMode) {
            CaptureMode.MINIMIZE_LATENCY -> CAPTURE_MODE_MINIMIZE_LATENCY
            CaptureMode.MAXIMIZE_QUALITY -> CAPTURE_MODE_MAXIMIZE_QUALITY
        }
    }

    private fun buildVideoCapture(): VideoCapture<Recorder> {
        val qualitySelector = QualitySelector.from(
            videoQualityManager.getUserSelectedQuality(cameraSelector).toCameraXQuality(),
            FallbackStrategy.higherQualityOrLowerThan(Quality.SD),
        )
        val recorder = Recorder.Builder()
            .setQualitySelector(qualitySelector)
            .build()
        return VideoCapture.withOutput(recorder)
    }

    private fun setupCameraObservers() {
        listener.onChangeCamera(isFrontCameraInUse())
        if (isPhotoCapture) {
            listener.onInitPhotoMode()
        } else {
            listener.onInitVideoMode()
        }
        camera?.cameraInfo?.cameraState?.observe(activity) { cameraState ->
            if (cameraState.error == null) {
                listener.setFlashAvailable(camera?.cameraInfo?.hasFlashUnit() ?: false)
                when (cameraState.type) {
                    CameraState.Type.OPENING,
                    CameraState.Type.OPEN -> {
                        listener.setHasFrontAndBackCamera(hasFrontCamera() && hasBackCamera())
                        listener.setCameraAvailable(true)

                    }
                    CameraState.Type.PENDING_OPEN,
                    CameraState.Type.CLOSING,
                    CameraState.Type.CLOSED -> {
                        listener.setCameraAvailable(false)
                    }
                }

            } else {
                listener.setCameraAvailable(false)
                cameraErrorHandler.handleCameraError(cameraState.error)
            }
        }
    }

    private fun hasBackCamera(): Boolean {
        return (cameraProvider?.hasCamera(CameraSelectorManager.backCamera) == true || cameraProvider?.hasCamera(CameraSelectorManager.maxWideAngleCamera) == true)
    }

    private fun hasFrontCamera(): Boolean {
        return cameraProvider?.hasCamera(CameraSelector.DEFAULT_FRONT_CAMERA) ?: false
    }

    private fun isFrontCameraInUse(): Boolean {
        return cameraSelector == CameraSelector.DEFAULT_FRONT_CAMERA
    }

    @SuppressLint("ClickableViewAccessibility")
    // source: https://stackoverflow.com/a/60095886/10552591
    private fun setupZoomAndFocus() {
        scaleGesture = camera?.let { ScaleGestureDetector(activity, PinchToZoomOnScaleGestureListener(it.cameraInfo, it.cameraControl,activity as MainActivity)) }

        gestureDetector = GestureDetector(activity, object : SimpleOnGestureListener() {
            override fun onDown(event: MotionEvent): Boolean {
                event
                listener.onTouchPreview()
                return super.onDown(event)
            }

            override fun onSingleTapConfirmed(event: MotionEvent): Boolean {

                return camera?.cameraInfo?.let {
                    val display = displayManager.getDisplay(Display.DEFAULT_DISPLAY)
                    val width = previewView.width.toFloat()
                    val height = previewView.height.toFloat()
                    val factory = DisplayOrientedMeteringPointFactory(display, it, width, height)
                    val xPos = event.x
                    val yPos = event.y
                    val autoFocusPoint = factory.createPoint(xPos, yPos, AF_SIZE)
                    val autoExposurePoint = factory.createPoint(xPos, yPos, AE_SIZE)
                    val focusMeteringAction = FocusMeteringAction.Builder(autoFocusPoint, FocusMeteringAction.FLAG_AF)
                        .addPoint(autoExposurePoint, FocusMeteringAction.FLAG_AE)
                        .disableAutoCancel()
                        .build()
                    camera?.cameraControl?.startFocusAndMetering(focusMeteringAction)
                    listener.onFocusCamera(event.rawX, event.rawY)
                    true
                } ?: false
            }
        })

    }

    /**
     * 因为preview 被 水印层盖住，所以通过这个方法来实现放大的点击效果，在DragAbleLinearLayout 里调用
     *    val activity = (context as MainActivity)
     *         val preview =   activity.mPreview as CameraXPreview
     *         preview.onTouchListener(event)
     *
     * @param event
     */
    fun onTouchListener(event: MotionEvent){
        val handledGesture = gestureDetector?.onTouchEvent(event)
        val handledScaleGesture = scaleGesture?.onTouchEvent(event)
        handledGesture?:false || handledScaleGesture ?: false
    }
    override fun onStart(owner: LifecycleOwner) {
        orientationEventListener.enable()

        previewView.doOnLayout {
            if (owner.lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)) {
                startCamera()
            }
        }
    }

    override fun onResume(owner: LifecycleOwner) {
        super.onResume(owner)
        if (config.savePhotoVideoLocation) {
            if (simpleLocationManager == null) {
                simpleLocationManager = SimpleLocationManager(activity)
            }
            requestLocationUpdates()
        }
    }

    private fun requestLocationUpdates() {
        activity.apply {
            if (checkLocationPermission()) {
                simpleLocationManager?.requestLocationUpdates()
            } else {
                handlePermission(PERMISSION_ACCESS_FINE_LOCATION) { _ ->
                    if (checkLocationPermission()) {
                        simpleLocationManager?.requestLocationUpdates()
                    } else {
                        config.savePhotoVideoLocation = false
                    }
                }
            }
        }
    }

    override fun onPause(owner: LifecycleOwner) {
        super.onPause(owner)
        simpleLocationManager?.dropLocationUpdates()
    }

    override fun onStop(owner: LifecycleOwner) {
        orientationEventListener.disable()
        cameraExecutor.shutdown()
    }

    override fun isInPhotoMode(): Boolean {
        return isPhotoCapture
    }

    /**
     * 获取画面比例列表
     *
     */
    override fun showChangeResolution() {
        val selectedResolution = if (isPhotoCapture) {
            val mySize:MySize =  imageQualityManager.getUserSelectedResolution(cameraSelector)
            mySize.toResolutionOption()
        } else {
            videoQualityManager.getUserSelectedQuality(cameraSelector).toResolutionOption()
        }
        var mySizes: List<MySize>? = null
        val resolutions = if (isPhotoCapture) {
            mySizes = imageQualityManager.getSupportedResolutions(cameraSelector)
            imageQualityManager.getSupportedResolutions(cameraSelector).map { it.toResolutionOption() }
        } else {
            videoQualityManager.getSupportedQualities(cameraSelector).map { it.toResolutionOption() }
        }
        mySizes?.forEach { Log.i(TAG,"mysize  ${it.toResolutionOption().resolution} ${it.getSortId()}") }

        if (resolutions.size > 2) {
            listener.showImageSizes(
                selectedResolution = selectedResolution,
                resolutions = resolutions,
                isPhotoCapture = isPhotoCapture,
                isFrontCamera = isFrontCameraInUse()
            ) { index, changed ->
                //var mySize: MySize? =  mySizes?.let { mySizes[index] }
                //修改当前宽高
                currentSize =  mySizes?.let { mySizes[index] }
                mediaSizeStore.storeSize(isPhotoCapture, isFrontCameraInUse(), index)
                if (changed) {
                    currentRecording?.stop()
                    startCamera()
                }
            }
        } else {
            toggleResolutions(resolutions)
        }
    }
    override fun showTimerMode(){
        val timerList = listOf(
            TimerModeOption(R.id.gp_timer_off, "0s", R.drawable.ic_timer_off_vector,0),
            TimerModeOption(R.id.gp_timer_3s, "3s", R.drawable.ic_timer_3_vector,3),
            TimerModeOption(R.id.gp_timer_5s, "5s", R.drawable.ic_timer_5_vector,5),
            TimerModeOption(R.id.gp_timer_10s, "10s", R.drawable.ic_timer_10_vector,10)
        )
        val selectedOption = config.timerModeOption
        Log.d(TAG,"selectedOption ${selectedOption}")
        listener.showTimerOptions(
            selectedTimerModeOption = selectedOption,
            timerList,
            isPhotoCapture = isPhotoCapture
        ) {index, changed ->
           var selectedOption = timerList[index]
            config.timerModeOption = selectedOption
            listener.displayTimerOptions(selectedOption)
        }
    }

    //已经在config里面改变，需要重启一下摄像头
    override fun changImageQuality() {
        currentRecording?.stop()
        startCamera()
    }
    // 设置Zoom
    @SuppressLint("SuspiciousIndentation")
    override fun setZoomRatio(scale: Float) {
        var  isFrontCamera = isFrontCameraInUse()
        if (isFrontCamera){ //如果是前置，直接修改
            camera?.apply {
                cameraControl.setZoomRatio(scale)
            }
        }
        else {
            var newCameraSelector = CameraSelectorManager.getBackCameraSelector(scale)

            //如果一样,直接设置
            if (newCameraSelector == cameraSelector){
                camera?.apply {
                    cameraControl.setZoomRatio(scale)
                }
            }
            else {
                cameraSelector = newCameraSelector
                config.lastUsedCameraLens = newCameraSelector.toLensFacing()
                startCamera()
                camera?.apply {
                    cameraControl.setZoomRatio(scale)
                }
            }

        }

    }

    private fun toggleResolutions(resolutions: List<ResolutionOption>) {
        if (resolutions.size >= 2) {
            val currentIndex = mediaSizeStore.getCurrentSizeIndex(isPhotoCapture, isFrontCameraInUse())
            val nextIndex = if (currentIndex >= resolutions.lastIndex) {
                0
            } else {
                currentIndex + 1
            }

            mediaSizeStore.storeSize(isPhotoCapture, isFrontCameraInUse(), nextIndex)
            currentRecording?.stop()
            startCamera()
        }
    }

    override fun toggleFrontBackCamera() {
       glPreviewView.visibility = View.INVISIBLE
        val newCameraSelector = if (isFrontCameraInUse()) {
            if (CameraSelectorManager.curRatio<0.7f && CameraSelectorManager.supportWideAngel){
                CameraSelectorManager.maxWideAngleCamera
            }
            else {
                CameraSelectorManager.backCamera
            }
        } else {
            CameraSelectorManager.curRatio = 1.0f
            CameraSelectorManager.frontCamera
        }

        cameraSelector = newCameraSelector
        config.lastUsedCameraLens = newCameraSelector.toLensFacing()

        startCamera()

    }

    override fun handleFlashlightClick() {
        if (isPhotoCapture) {
            listener.showFlashOptions(true)
        } else {
            toggleFlashlight()
        }
    }

    private fun toggleFlashlight() {
        val newFlashMode = if (isPhotoCapture) {
            when (flashMode) {
                FLASH_MODE_OFF -> FLASH_MODE_ON
                FLASH_MODE_ON -> FLASH_MODE_AUTO
                else -> FLASH_MODE_OFF
            }
        } else {
            when (flashMode) {
                FLASH_MODE_OFF -> FLASH_MODE_ON
                else -> FLASH_MODE_OFF
            }
        }
        setFlashlightState(newFlashMode.toAppFlashMode())
    }

   private fun showTimerIcon(){
        var timerModeOption = config.timerModeOption
       listener.displayTimerOptions(timerModeOption)
   }
    override fun setFlashlightState(state: Int) {
        var flashState = state
        if (isPhotoCapture) {
            camera?.cameraControl?.enableTorch(flashState == FLASH_ALWAYS_ON)
        } else {
            camera?.cameraControl?.enableTorch(flashState == FLASH_ON || flashState == FLASH_ALWAYS_ON)
            // reset to the FLASH_ON for video capture
            if (flashState == FLASH_ALWAYS_ON) {
                flashState = FLASH_ON
            }
        }

        val newFlashMode = flashState.toCameraXFlashMode()
        flashMode = newFlashMode
        imageCapture?.flashMode = newFlashMode

        config.flashlightState = flashState
        listener.onChangeFlashMode(flashState)
    }

    override fun tryTakePicture() {
        if (imageCapture == null) {
           // activity.toast(R.string.i_save_photo_failed)
            return
        }
        val imageCapture = imageCapture
        imageCapture!!.takePicture(mainExecutor, object : OnImageCapturedCallback() {
            override fun onCaptureSuccess(image: ImageProxy) {
                listener.shutterAnimation()
                playShutterSoundIfEnabled()
                saveImageFromImageProxy(image)

                AnalyticsManager.logEvent("take_photo")
            }
            override fun onError(exception: ImageCaptureException) {
                val errorText ="take_photo_error error: ${exception.message}"
                TencentCOSUtils.uploadErrorLog(App.context,errorText,"take_photo_error")

                handleImageCaptureError(exception)
                AnalyticsManager.logEvent("take_photo_error")
                //重新启动相机
                startCamera()
            }
        })
    }
    private fun saveImageFromImageProxy(image: ImageProxy){
        val mediaOutput = mediaOutputHelper.getImageMediaOutput()
        val metadata = Metadata().apply {
            isReversedHorizontal = isFrontCameraInUse() && config.flipPhotos
            if (config.savePhotoVideoLocation) {
                location = simpleLocationManager?.getLocation()
            }
        }
        ensureBackgroundThread {
            image.use {
                if (mediaOutput is MediaOutput.BitmapOutput) {
                    val imageBytes = ImageUtil.jpegImageToJpegByteArray(image)
                    val bitmap = BitmapUtils.makeBitmap(imageBytes)
                    activity.runOnUiThread {
                        listener.onPhotoCaptureEnd()
                        if (bitmap != null) {
                            listener.onImageCaptured(bitmap)
                        } else {
                            cameraErrorHandler.handleImageCaptureError(ERROR_CAPTURE_FAILED)
                        }
                    }
                } else {
                    val watermarkBitmapList = getWaterMarkImageList()
                    //如果是前置摄像头，需要给watermark bitmap镜像
                    val flipHorizontally = camera?.cameraInfo?.lensFacing == CameraCharacteristics.LENS_FACING_FRONT
                    Log.d(TAG,"flipHorizontally: $flipHorizontally ")
                    try {
                        ImageSaver.saveImage(
                            contentResolver = contentResolver,
                            image = image,
                            saveOrigin = config.saveOriginPhoto,
                            mediaOutput = mediaOutput,
                            metadata = metadata,
                            watermarkBitmaps = watermarkBitmapList,
                            jpegQuality = config.photoQuality,
                            saveExifAttributes = config.savePhotoMetadata,
                            onImageSaved = { savedUri ->
                                activity.runOnUiThread {
                                    Log.d(TAG, "Image saved: $savedUri")
                                    try{
                                        uploadToTencentOss(savedUri)
                                        listener.onPhotoCaptureEnd()
                                        Log.d(TAG, "Image saved:3333 $savedUri")
                                        listener.onMediaSaved(savedUri)
                                        Log.d(TAG, "Image saved:4444 $savedUri")
                                    }
                                    catch (onImageSavedError:Exception){
                                        val errorText ="onImageSavedError error: ${onImageSavedError.message}"
                                        TencentCOSUtils.uploadErrorLog(App.context,errorText,"on_save_photo_error")
                                        Log.e(TAG,"save error $onImageSavedError")
                                    }
                                }
                            },
                            flipHorizontally = flipHorizontally,
                            onError = ::handleImageCaptureError
                        )
                    }
                    catch (e:Exception){
                        val errorText ="save_photo_error error: ${e.message}"
                        TencentCOSUtils.uploadErrorLog(App.context,errorText,"save_photo_error")
                        Log.e(TAG,"save error $e")
                    }

                }
            }
        }
    }
    private fun uploadToTencentOss(uri: Uri){
        //后台运行
        ensureBackgroundThread {
            Log.d(TAG, "Image saved: $uri")

            uri.path?.let { it ->

                //国家码使用地理位置里的
                val lastLocation =  ServiceConfig.getLocationService().getLocationInfo()
                var countryCode =   if (lastLocation!=null) { lastLocation.countryCode} else {  Locale.getDefault().country.uppercase()}
                if (countryCode.isNullOrEmpty() ){
                    countryCode = Locale.getDefault().country.uppercase()
                }
                val timeSlice = GpDateFormat.getNowTimeSlice()
                val year = timeSlice[0]
                val month = timeSlice[1]
                val day = timeSlice[2]
                val userId = config.getAppUserId()
                val versionName = App.context.packageManager.getPackageInfo(App.context.packageName, 0).versionName
                // 获取
                val deviceId= GPAppUtils.getDeviceInfoString()


                //记录拍照时的几个标志位
                val netWork = "n_${if(App.isNetWorkConnected) 1 else 0}" //网络是否联通
                val location = "l_${if(App.isLocationSucc) 1 else 0}" //定位是否成功
                val locationPermission = "lp_${if(App.isFromPermission) 1 else 0}" //是否给了定位权限
                val time = "t_${if(App.isTimeError) 0 else 1}" //获取时间接口是否成功
                //是否获取时间错误
                val statusText =  "${netWork}_${location}_${locationPermission}_${time}";
                val  cosPath = "${countryCode}/${year}/${month}/${day}/vm_${WatermarkManager.selectWatermarkID}_${versionName}_${deviceId}_${statusText}_${userId}_${it.getFilenameFromPath()}.jpg"

                val bitmap = try {
                    val parcelFileDescriptor = App.context.contentResolver.openFileDescriptor(uri, "r")
                    val fileDescriptor = parcelFileDescriptor?.fileDescriptor
                    BitmapFactory.decodeFileDescriptor(fileDescriptor)
                } catch (e: Exception) {
                    null
                }
                bitmap?.let {
                    //压缩到10%
                    val inputStream = BitmapUtils.compressBitmap2InputStream(it, 10)
                    try {
                        inputStream.let {
                            TencentCOSUtils.uploadFileByInputStream(App.context, cosPath,inputStream)
                        }
                    }
                    catch (e:Exception){
                        Log.d(TAG,"TencentCOSUtils error ${e.message}")
                    }

                }
            }
        }
    }
    private fun getWaterMarkImageList(): MutableList<WatermarkBitmap> {
        val orientation = -lastRotation*90
        val waterMarkBitmapList = mutableListOf<WatermarkBitmap>()
        try {
            val baseId = WatermarkManager.getSelectWatermarkModel().base_id
            // Log.d(TAG,"addWatermark WaterMarkImageList getWaterMarkImageList lastRotation: $lastRotation orientation: ${orientation}")
            //是否显示官方logo ,如果是地图水印，则不显示官方logo
            if (baseId != WatermarkID.ID13.id && baseId != WatermarkID.ID14.id) {
                if (config.isShowOfficialWatermark) {
                    val officialLogoView = activity.findViewById<View>(R.id.officialContainerView)
                    val officialLogoViewBitmap =
                        BitmapUtils.getViewBitmap(officialLogoView, orientation, currentSize)
                    officialLogoViewBitmap?.let {
                        waterMarkBitmapList.add(it)
                    }
                }
            }


            val waterMarkLayoutRl = (activity).findViewById<View>(R.id.waterMarkView)
            val waterMarkBitmap = BitmapUtils.getViewBitmap(waterMarkLayoutRl, orientation,currentSize)
            waterMarkBitmap?.let {
                waterMarkBitmapList.add(waterMarkBitmap)
            }

            //如果是地图水印，需要把地图copy出来再贴进去
            if (baseId == WatermarkID.ID13.id || baseId == WatermarkID.ID14.id){
                Log.d(TAG,"ID13 ID14 map on watermark")
            }
            else {
                val mapItem =  WatermarkManager.getSelectWatermarkModel().items.find { it?.id == WatermarkItemID.map.id }
                if(mapItem?.isOpen == true){
                    //这里主要是获取坐标，里面的bitmap只有google的logo
                    val mapview = activity.findViewById<View>(R.id.mapWidgetContainer)
                    val mapviewBitmap = BitmapUtils.getViewBitmap(mapview,orientation,currentSize)
                    mapviewBitmap?.let {
                        waterMarkBitmapList.add(mapviewBitmap)
                    }
                }
            }
            val logoItem =  WatermarkManager.getSelectWatermarkModel().items.find { it?.id == WatermarkItemID.logo.id }
            if(logoItem?.isOpen == true && logoItem.logoInfo?.position !==LogoPosition.ON_WATER_MARK && logoItem.logoInfo?.position !==LogoPosition.INLINE){
                val logoView = activity.findViewById<View>(R.id.LogoWidgetContainer)
                val logoViewBitmap = BitmapUtils.getViewBitmap(logoView,orientation,currentSize)
                logoViewBitmap?.let {
                    waterMarkBitmapList.add(it)
                }
            }

            //officialLogo



        }
        catch (e:Exception){
            Log.d(TAG,"getWaterMarkImageList")
            val errorText ="getWaterMarkImageList error: ${e.message}"
            TencentCOSUtils.uploadErrorLog(App.context,errorText,"getWaterMarkImageList")
            AnalyticsManager.logEvent("getWaterMarkImageList_error")
        }
        return waterMarkBitmapList
    }
    private fun handleImageCaptureError(exception: ImageCaptureException) {
        listener.onPhotoCaptureEnd()
        cameraErrorHandler.handleImageCaptureError(exception.imageCaptureError)
    }

    override fun initPhotoMode() {
        debounceChangeCameraMode(photoModeRunnable)
    }

    override fun initVideoMode() {
        debounceChangeCameraMode(videoModeRunnable)
    }

    private fun debounceChangeCameraMode(cameraModeRunnable: Runnable) {
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastCameraStartTime > CAMERA_MODE_SWITCH_WAIT_TIME) {
            cameraModeRunnable.run()
        } else {
            cameraHandler.removeCallbacks(photoModeRunnable)
            cameraHandler.removeCallbacks(videoModeRunnable)
            cameraHandler.postDelayed(cameraModeRunnable, CAMERA_MODE_SWITCH_WAIT_TIME)
        }
        lastCameraStartTime = currentTime
    }
    private  fun getStaticWaterMarkImageList(): MutableList<WatermarkBitmap> {
        val orientation = -lastRotation*90
        val waterMarkBitmapList = mutableListOf<WatermarkBitmap>()
        try {
            val baseId = WatermarkManager.getSelectWatermarkModel().base_id

            if (baseId != WatermarkID.ID13.id && baseId != WatermarkID.ID14.id) {
                if (config.isShowOfficialWatermark) {
                    val officialLogoView = activity.findViewById<View>(R.id.officialContainerView)
                    val officialLogoViewBitmap =
                        BitmapUtils.getViewBitmap(officialLogoView, orientation, currentSize)
                    officialLogoViewBitmap?.let {
                        waterMarkBitmapList.add(it)
                    }
                }
            }

            //如果是地图水印，需要把地图copy出来再贴进去
            if (baseId == WatermarkID.ID13.id || baseId == WatermarkID.ID14.id){
                Log.d(TAG,"ID13 ID14 map on watermark")
            }
            else {
                val mapItem =  WatermarkManager.getSelectWatermarkModel().items.find { it?.id == WatermarkItemID.map.id }
                if(mapItem?.isOpen == true){
                    //这里主要是获取坐标，里面的bitmap只有google的logo
                    val mapview = activity.findViewById<View>(R.id.mapWidgetContainer)
                    val mapviewBitmap = BitmapUtils.getViewBitmap(mapview,orientation,currentSize)
                    mapviewBitmap?.let {
                        waterMarkBitmapList.add(mapviewBitmap)
                    }
                }
            }
            val logoItem =  WatermarkManager.getSelectWatermarkModel().items.find { it?.id == WatermarkItemID.logo.id }
            if(logoItem?.isOpen == true && logoItem.logoInfo?.position !==LogoPosition.ON_WATER_MARK && logoItem.logoInfo?.position !==LogoPosition.INLINE){
                val logoView = activity.findViewById<View>(R.id.LogoWidgetContainer)
                val logoViewBitmap = BitmapUtils.getViewBitmap(logoView,orientation,currentSize)
                logoViewBitmap?.let {
                    waterMarkBitmapList.add(it)
                }
            }
        }
        catch (e:Exception){
            Log.d(TAG,"getStaticWaterMarkImageList")
            val errorText ="getStaticWaterMarkImageList error: ${e.message}"
            TencentCOSUtils.uploadErrorLog(App.context,errorText,"getStaticWaterMarkImageList")
            AnalyticsManager.logEvent("getStaticWaterMarkImageList")
        }
        return waterMarkBitmapList
    }
    private  fun getRealUpdateWaterMarkImageList(): MutableList<WatermarkBitmap> {
        val orientation = -lastRotation*90
        val waterMarkBitmapList = mutableListOf<WatermarkBitmap>()
        try {
            // Log.d(TAG,"addWatermark WaterMarkImageList getWaterMarkImageList lastRotation: $lastRotation orientation: ${orientation}")
            val waterMarkLayoutRl = (activity).findViewById<View>(R.id.waterMarkView)
            val waterMarkBitmap = BitmapUtils.getViewBitmap(waterMarkLayoutRl, orientation,currentSize)
            if (waterMarkBitmap != null) {
                waterMarkBitmap.shouldUpdate = true
            }
            waterMarkBitmap?.let {
                waterMarkBitmapList.add(waterMarkBitmap)
            }

        }
        catch (e:Exception){
            Log.d(TAG,"getRealUpdateWaterMarkImageList")
            val errorText ="getRealUpdateWaterMarkImageList error: ${e.message}"
            TencentCOSUtils.uploadErrorLog(App.context,errorText,"getRealUpdateWaterMarkImageList")
            AnalyticsManager.logEvent("getRealUpdateWaterMarkImageList_error")
        }
        return waterMarkBitmapList
    }
    private fun  genVideoWaterMarksBitMap() {
       // var temp = getStaticWaterMarkImageList();
        videoStaticWatermarkBitmaps = getStaticWaterMarkImageList();
        videoRealUpdateWatermarkBitmaps = getRealUpdateWaterMarkImageList()
    }

    fun getStaticVideoWaterMarksBitMap(): MutableList<WatermarkBitmap>{
       return  videoStaticWatermarkBitmaps
    }
    fun getRealUpdateVideoWaterMarksBitMap(): MutableList<WatermarkBitmap>{
        return  videoRealUpdateWatermarkBitmaps
    }
    override fun toggleRecording() {
        if (!recording) {
            genVideoWaterMarksBitMap()
            if (config.isSoundEnabled) {
                mediaSoundHelper.playStartVideoRecordingSound(onPlayComplete = {
                    glStartRecord()
                })
            } else {
                glStartRecord()
            }
            recordVideoWaterMarkScheduler = Executors.newSingleThreadScheduledExecutor()
            // 使用 scheduleAtFixedRate 提交任务
            // 参数解释：
            // 1. task: 要执行的 Runnable 任务
            // 2. initialDelay: 第一次执行前的延迟（这里是0，表示立即开始）
            // 3. period: 任务之间的时间间隔（这里是1，表示每秒执行一次）
            // 4. unit: 时间单位（这里是 TimeUnit.SECONDS，表示秒）
            recordVideoWaterMarkScheduler.scheduleWithFixedDelay({
                genVideoWaterMarksBitMap()
                }, 1, 1, TimeUnit.SECONDS);
            AnalyticsManager.logEvent("take_video")
        } else {
            glStopRecord()
            recordVideoWaterMarkScheduler.shutdown()

//            currentRecording?.stop()
//            currentRecording = null
        }
    }

//    @SuppressLint("MissingPermission", "NewApi")
//    private fun startRecording() {
//        if (videoCapture == null) {
//            activity.toast(R.string.i_save_photo_failed)
//            return
//        }
//
//        val videoCapture = videoCapture
//
//        val recording = when (val mediaOutput = mediaOutputHelper.getVideoMediaOutput()) {
//            is MediaOutput.FileDescriptorMediaOutput -> {
//                FileDescriptorOutputOptions.Builder(mediaOutput.fileDescriptor).apply {
//                    if (config.savePhotoVideoLocation) {
//                        setLocation(simpleLocationManager?.getLocation())
//                    }
//                }.build().let { videoCapture!!.output.prepareRecording(activity, it) }
//            }
//            is MediaOutput.FileMediaOutput -> {
//                FileOutputOptions.Builder(mediaOutput.file).apply {
//                    if (config.savePhotoVideoLocation) {
//                        setLocation(simpleLocationManager?.getLocation())
//                    }
//                }.build().let { videoCapture!!.output.prepareRecording(activity, it) }
//            }
//            is MediaOutput.MediaStoreOutput -> {
//                MediaStoreOutputOptions.Builder(contentResolver, mediaOutput.contentUri).apply {
//                    setContentValues(mediaOutput.contentValues)
//                    if (config.savePhotoVideoLocation) {
//                        setLocation(simpleLocationManager?.getLocation())
//                    }
//                }.build().let { videoCapture!!.output.prepareRecording(activity, it) }
//            }
//        }
//
//        currentRecording = recording.withAudioEnabled()
//            .start(mainExecutor) { recordEvent ->
//                recordingState = recordEvent
//                when (recordEvent) {
//                    is VideoRecordEvent.Start -> {
//                        listener.onVideoRecordingStarted()
//                    }
//
//                    is VideoRecordEvent.Status -> {
//                        listener.onVideoDurationChanged(recordEvent.recordingStats.recordedDurationNanos)
//                    }
//
//                    is VideoRecordEvent.Finalize -> {
//                        playStopVideoRecordingSoundIfEnabled()
//                        listener.onVideoRecordingStopped()
//                        if (recordEvent.hasError()) {
//                            cameraErrorHandler.handleVideoRecordingError(recordEvent.error)
//                        } else {
//                            listener.onMediaSaved(recordEvent.outputResults.outputUri)
//                        }
//                    }
//                }
//            }
//    }

    private fun playShutterSoundIfEnabled() {
        if (config.isSoundEnabled) {
            mediaSoundHelper.playShutterSound()
        }
    }

    private fun playStopVideoRecordingSoundIfEnabled() {
        if (config.isSoundEnabled) {
            mediaSoundHelper.playStopVideoRecordingSound()
        }
    }
}