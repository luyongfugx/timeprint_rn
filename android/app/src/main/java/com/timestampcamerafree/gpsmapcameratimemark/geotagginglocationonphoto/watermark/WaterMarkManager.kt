package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark


import android.annotation.SuppressLint
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.RelativeLayout
import androidx.annotation.LayoutRes
import androidx.asynclayoutinflater.view.AsyncLayoutInflater
import androidx.core.content.ContextCompat
import androidx.core.util.Consumer
import androidx.databinding.DataBindingUtil
import androidx.databinding.ViewDataBinding
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.MutableLiveData
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.gson.Gson
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App.Companion.context
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.BR
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.BitmapUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.ServiceConfig
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpUiUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpUiUtils.runOnUiThread
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.LocalStorageManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.WaterMarkMapWidget
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.BaseWatermarkModel
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.BaseWatermarkViewModel
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkBaseID
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkCoverModel
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkID
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItemID
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.address.WatermarkAddressItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.coordinate.WatermarkCoordinateItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.logo.LogoPosition
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.logo.WatermarkLogoItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.views.BaseItemRecyclerViewAdapter
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.views.GridItemRecyclerViewAdapter
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.views.NoTitleItemRecyclerViewAdapter
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.InputStream
import java.util.concurrent.CopyOnWriteArrayList


/**
 *
 *WatermarkManager 管理类
 */
class WatermarkManager {

    companion object {
        private const val TAG = "WatermarkManager" // 定义日志标签
        val inflater: LayoutInflater = LayoutInflater.from(context)
        //地图位图，直接用view抓取有问题，所以在地图load完成的时候，设置一下
//        var mapBitmap:Bitmap? = null
//        var waterMapBitmap :Bitmap? = null
        private var watermarkModel: MutableMap<String, BaseWatermarkModel> = mutableMapOf()

        private var _localWatermarkTemplateList: List<WatermarkCoverModel>? = null
         //如果有logo
         var officialLogoBitmap :Bitmap? = null
         var officialLogoPos ="br"


         var selectWatermarkID: String = "1"
        //当前水印的viewModel,需要从本地读取的SelectWaterModel里转换
        var currentWaterMarkViewModel: BaseWatermarkViewModel? = null

        fun getCurrentWaterMarkViewModelFromLocal(): BaseWatermarkViewModel {
            currentWaterMarkViewModel?.let {
                //重新设置一下item,
                currentWaterMarkViewModel!!.resetItem()
                return  it
            }
            currentWaterMarkViewModel = BaseWatermarkViewModel()
            currentWaterMarkViewModel!!.watermarkModel.value = getSelectWatermarkModel();
            //重新设置一下item,
            currentWaterMarkViewModel!!.resetItem()
            return currentWaterMarkViewModel as BaseWatermarkViewModel
        }
        /**
         *
         *
         * @return
         */
        fun getSelectWatermarkModel(): BaseWatermarkModel {
//            if (selectWatermarkID == WatermarkID.ID5.id ||selectWatermarkID == WatermarkID.ID6.id) {
//                selectWatermarkID = WatermarkID.ID1.id
//            }
            if (watermarkModel.keys.contains(selectWatermarkID)) {
                Log.d(TAG,"getSelectWatermarkModel watermarkModel[selectWatermarkID]:${watermarkModel[selectWatermarkID]}")
                return watermarkModel[selectWatermarkID] ?: BaseWatermarkModel()
            }
            var model = getWaterModelByID(selectWatermarkID)
            model?.let{
                watermarkModel[selectWatermarkID] = model
                return model;
            }

            //Log.d(TAG,"getSelectWatermarkModel ${watermarkTemplateList}" )
             //调用一下会load from json
             var loadWaterMark = watermarkTemplateList
            if (_localWatermarkTemplateList != null && _localWatermarkTemplateList!!.isNotEmpty()) {
                for (model in _localWatermarkTemplateList!!) {
                    if (model.watermarkModel?.id == selectWatermarkID) {
                        watermarkModel[model.watermarkModel?.id ?: "1"] = model.watermarkModel!!
                        return model.watermarkModel ?: BaseWatermarkModel()
                    }
                }
            }
            return BaseWatermarkModel()
        }

        //修改
        fun changeSelectWatermarkModel(id: String) {

            selectWatermarkID = id

            val model = getSelectWatermarkModel()
            Log.d(TAG,"changeSelectWatermarkModel ${id} ${model.hashCode()} ${model} ")
            //刷新一次地理位置
           val lastLocation =  ServiceConfig.getLocationService().getLocationInfo()
            lastLocation?.let {
                Log.d(TAG,"changeSelectWatermarkModel getLocationInfo ${id} ${model}")
                model.items.forEach {
                    when (it?.id) {
                        WatermarkItemID.address.id -> {
                            if (it.extraAddressInfo != null) {
                                it.extraAddressInfo!!.rawAddress = lastLocation.rawAddress
                            } else {
                                it.extraAddressInfo = WatermarkAddressItem().apply {
                                    rawAddress = lastLocation.rawAddress
                                }
                            }
                            //获取格式地址
                            val lText = it.extraAddressInfo!!.getShowAddress()
                            currentWaterMarkViewModel?.locationText?.value = lText
                            it.content = lText
                        }

                        WatermarkItemID.coordinate.id -> {
                            //获取经纬度格式
                            if (it.extraCoordinateInfo != null) {
                                it.extraCoordinateInfo!!.latitude = lastLocation.latitude
                                it.extraCoordinateInfo!!.longitude = lastLocation.longitude
                            } else {
                                it.extraCoordinateInfo = WatermarkCoordinateItem().apply {
                                    latitude = lastLocation.latitude
                                    longitude = lastLocation.longitude
                                }
                            }
                            val lText = it.extraCoordinateInfo?.getShowLatLng() ?: ""
                            it.content = lText
                        }
                        //最多保留6位
                        WatermarkItemID.altitude.id -> it.content =
                            "%.6f".format(lastLocation.altitude)
                    }
                }
            }
            currentWaterMarkViewModel!!.watermarkModel.value = model

        }
        /**
         * TODO
         *
         * @param model
         */
        fun saveWatermarkModel(model: BaseWatermarkModel?) {
            model?.let {
                val key = getWatermarkLocalKey(it.id ?: "1")
                val jsonString = Gson().toJson(model)
                LocalStorageManager.save(key, jsonString)
            }
        }

        /**
         * TODO
         *
         * @param watermarkID
         * @return
         */
        private fun getWaterModelByID(watermarkID: String): BaseWatermarkModel? {

            val key = getWatermarkLocalKey(watermarkID)
            val jsonString = LocalStorageManager.getString(key)
            Log.e(TAG,"getWaterModelByID watermarkID:${watermarkID} jsonString :${jsonString}")
            var model: BaseWatermarkModel?  = null
            try{
                model   = Gson().fromJson(jsonString, BaseWatermarkModel::class.java)
                Log.e(TAG,"getWaterModelByID Gson model :${model}")
            }
            catch (e:Exception){
                Log.e(TAG,"getWaterModelByID Gson error")
            }

            //如果id为空
            if (model?.id.isNullOrEmpty()||model?.name.isNullOrEmpty()){
                return null
            }

            //json文件读取的地址不可用，需要赋值为null,否则报错
            model?.items?.find { it?.id == WatermarkItemID.address.id }?.apply {
                extraAddressInfo = null
                content = ""
            }
            //经纬度也不用,
            model?.items?.find { it?.id == WatermarkItemID.coordinate.id }?.apply {
                extraCoordinateInfo?.apply {
                    longitude = 0.0
                    latitude = 0.0
                }
                content = ""
            }
            //海拔内容清楚
            model?.items?.find { it?.id == WatermarkItemID.altitude.id }?.apply {
                content = ""
            }
//            model?.items?.find { it?.id == WatermarkItemID.serviceDetail1.id }?.apply {
//                title = ""
//            }

            //如果是ID5 服务名称水印，则把baseId 改成 16
            if (model?.id == WatermarkID.ID5.id){
                model.base_id = WatermarkBaseID.ID16.id
            }

            return model
        }

        /**
         * TODO
         *
         * @param watermarkID
         * @return
         */
        private fun getWatermarkLocalKey(watermarkID: String): String {
            return LocalStorageManager.prefixLocalKey + "watermark_$watermarkID"
        }
        /**
         * 读取 watermarkTemplateList 水印列表
         * @return watermarkTemplateList
         */
        val watermarkTemplateList: List<WatermarkCoverModel>?
            get() {
                if (_localWatermarkTemplateList != null) {
                    return _localWatermarkTemplateList!!
                } else {
                    val fileName = "filtercolor.json"
                    val json = readJsonFromAssets(fileName)

                    var categorys: List<WatermarkCoverModel>? =null
                    try {
                       categorys=  Gson().fromJson(json, Array<WatermarkCoverModel>::class.java).toList()
                    }
                    catch (e:Exception){
                     Log.e(TAG,"goson error ${e}")
                    }

                    categorys?.forEach {
                        it.watermarkModel =
                            Gson().fromJson(it.watermark, BaseWatermarkModel::class.java)
                        //Log.i(TAG,"watermarkTemplateList ${it.name} ${it.watermarkModel?.id}")
                        it.watermarkModel?.name = GpUiUtils.getLocalizedText(it.name)
                        it.name = GpUiUtils.getLocalizedText(it.name)
                        //如果是15设置默认logo
                        //Log.d(TAG,"WatermarkBaseID.ID15.id: model?.base_id :${it.watermarkModel?.base_id} WatermarkBaseID.ID15.id:${WatermarkBaseID.ID15.id}")
                        if (it.watermarkModel?.base_id == WatermarkBaseID.ID15.id){
                           // Log.d(TAG,"WatermarkBaseID.ID15.id: timeprint it.watermarkModel?.base_id == WatermarkBaseID.ID15.id")
                            it.watermarkModel?.items?.find { waterItem ->
                               // Log.d(TAG,"WatermarkBaseID.ID15.id:==== timeprint it.watermarkModel?.base_id == WatermarkBaseID.ID15.id ${waterItem}")
                                waterItem?.id == WatermarkItemID.logo.id
                            }?.apply {

                                if(logoInfo == null){
                                    logoInfo = WatermarkLogoItem()
                                }
                                logoInfo?.apply {
                                   // context.filesDir,
                                  var timePrintLogoPath =  BitmapUtils.saveResourceToFile(R.drawable.timeprint,context.filesDir,"timeprint_${System.currentTimeMillis()}.png")?.path
                                   //selectLogoPath="timeprint"
                                    //originLogoPath ="timeprint"
                                    selectLogoPath = timePrintLogoPath
                                    originLogoPath = timePrintLogoPath

                                    position = LogoPosition.ON_WATER_MARK
                                }

                            }
                        }


                        val itemList = it.watermarkModel?.items?.map { item ->
                            item?.copy(
                                title = GpUiUtils.getLocalizedText(item.title),
                                content = GpUiUtils.getLocalizedText(item.content)
                            )
                        }
                        if (itemList != null) {
                            it.watermarkModel?.items = CopyOnWriteArrayList(itemList)
                        }
                    }
                    //过滤掉
                    categorys = categorys?.filter {
                        it.watermarkModel?.id == WatermarkID.ID1.id ||
                                it.watermarkModel?.id == WatermarkID.ID3.id ||
                                it.watermarkModel?.id == WatermarkID.ID2.id ||
                                it.watermarkModel?.id == WatermarkID.ID4.id ||
                                it.watermarkModel?.id == WatermarkID.ID5.id ||
                                it.watermarkModel?.id == WatermarkID.ID6.id ||
                                it.watermarkModel?.id == WatermarkID.ID7.id ||
                                it.watermarkModel?.id == WatermarkID.ID8_1.id ||
                                it.watermarkModel?.id == WatermarkID.ID9_1.id ||
                                it.watermarkModel?.id == WatermarkID.ID10_1.id ||
                                it.watermarkModel?.id == WatermarkID.ID11_1.id ||
                                it.watermarkModel?.id == WatermarkID.ID13.id ||
                                it.watermarkModel?.id == WatermarkID.ID14.id ||
                                it.watermarkModel?.id == WatermarkID.ID15_1.id ||
                                it.watermarkModel?.id == WatermarkID.ID15_2.id ||
                                it.watermarkModel?.id == WatermarkID.ID12.id
                    }
                    _localWatermarkTemplateList = categorys
                    return categorys
                }
            }

        /**
         * 哪些水印是第一行需要粗体
         *
         * @return
         */
        public fun isFirstItemBold():Boolean {
            val boldSet: MutableSet<String> = mutableSetOf(
                WatermarkID.ID15_2.id,
                WatermarkID.ID15_1.id,
                WatermarkID.ID2.id,
                WatermarkID.ID3.id,
                WatermarkID.ID4.id
                )
            return if(boldSet.contains(selectWatermarkID)){
                true
            } else {
                false
            }
        }
        /**
         * 读取json文件
         * @param fileName 文件名
         * @return json string
         */
        private fun readJsonFromAssets(fileName: String): String? {
            Log.d(TAG,"readJsonFromAssets ${fileName}")
            val inputStream: InputStream = context.assets.open(fileName)
            val buffer = ByteArray(inputStream.available())
            inputStream.read(buffer)
            inputStream.close()
            val str = String(buffer, Charsets.UTF_8)
            Log.d(TAG,"readJsonFromAssets ${fileName} str:$str")
            return str
        }

        @LayoutRes
        fun getWatermarkLayoutByBaseId(watermarkBaseId: String?): Int {
            @LayoutRes val layoutId: Int = when (watermarkBaseId) {
                WatermarkBaseID.ID1.id -> R.layout.watermark_id_1
                WatermarkBaseID.ID3.id -> R.layout.watermark_id_3
                WatermarkBaseID.ID2.id -> R.layout.watermark_id_3
                WatermarkBaseID.ID4.id -> R.layout.watermark_id_4
                WatermarkBaseID.ID5.id -> R.layout.watermark_id_5
                WatermarkBaseID.ID6.id -> R.layout.watermark_id_6
                WatermarkBaseID.ID8.id -> R.layout.watermark_id_8
                WatermarkBaseID.ID9.id -> R.layout.watermark_id_9
                WatermarkBaseID.ID10.id -> R.layout.watermark_id_10
                WatermarkBaseID.ID11.id -> R.layout.watermark_id_11
                WatermarkBaseID.ID12.id -> R.layout.watermark_id_12
                WatermarkBaseID.ID13.id -> R.layout.watermark_id_13
                WatermarkBaseID.ID14.id -> R.layout.watermark_id_14
                WatermarkBaseID.ID15.id -> R.layout.watermark_id_15
                WatermarkBaseID.ID16.id -> R.layout.watermark_id_16
                else -> R.layout.watermark_id_1
            }
            return layoutId
        }

        /**
         * 生成水印列表cover图
         *
         * @param viewModel
         * @return
         */
        @SuppressLint("InflateParams")
        fun getCoverBitmap(viewModel: BaseWatermarkViewModel?,context: FragmentActivity): Bitmap {
            var fileName = "watermark_cover_" + viewModel?.watermarkModel?.value?.id
            var bitmap = getBitmapFromFilesDir(fileName)
            //如果有bitmap
            if (bitmap !==null){
                return bitmap
            }
            val baseID = viewModel?.watermarkModel?.value?.base_id
            val layoutId  = getWatermarkLayoutByBaseId(baseID)
            val view = LayoutInflater
                .from(context)
                .inflate(
                    layoutId,
                    null,
                )
            //设置
            if (baseID == WatermarkBaseID.ID13.id ||baseID == WatermarkBaseID.ID14.id) {
                view.findViewById<WaterMarkMapWidget>(R.id.watermarkMapWidget)?.setMapImageView()
            }
            val itemsRcView = view.findViewById<RecyclerView>(R.id.recyclerItemList)
            viewModel?.watermarkModel?.let {
                setItemViewContent(itemsRcView, it)
                //如果是baseID,则需要设置一下top item
                if (baseID == WatermarkBaseID.ID4.id) {
                    val topItemsRcView = view.findViewById<RecyclerView>(R.id.topRecyclerItemList)
                    setItemViewContent(topItemsRcView, it,true)
                }
            }
            val viewDataBinding = DataBindingUtil.bind<ViewDataBinding>(view)
            viewDataBinding?.setVariable(BR.mainViewModel, viewModel)
            viewDataBinding?.executePendingBindings() // 确保数据绑定立即执行

            // 手动测量和布局 View
            view.measure(
                View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
                View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
            )
            view.layout(0, 0, view.measuredWidth, view.measuredHeight)
            bitmap = genViewBitMap(view)
            saveBitmap(fileName,bitmap)
            return bitmap
        }
        /**
         * 保存bitmap到沙盒
         * @param fileName 文件名
         * @param bitmap bitmap
         */
        private fun saveBitmap(fileName: String, bitmap: Bitmap) {
            val file = File(context.filesDir, fileName)
            val fileOutputStream = FileOutputStream(file)
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, fileOutputStream)
            fileOutputStream.close()
        }

        private fun getBitmapFromFilesDir(fileName: String): Bitmap? {
            val file = File(context.filesDir, fileName)
            if (file.exists()){
                val inputStream: InputStream = FileInputStream(file)
                return BitmapFactory.decodeStream(inputStream)
            }
            else {
                return null
            }
        }


        /**
         *
         *
         * @param view
         * @return
         */
        private fun genViewBitMap(view: View): Bitmap {
            val bitmap = Bitmap.createBitmap(view.width, view.height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            view.draw(canvas)
            return bitmap
        }

        fun asyncBindWatermarkViewData(baseID: String? ,asyncLayoutInflater: AsyncLayoutInflater, lifecycleOwner: LifecycleOwner,
                                 container: ViewGroup,
                                 viewModel: BaseWatermarkViewModel?,
                                 consumer: Consumer<ViewDataBinding?>?) {
            asyncLayoutInflater.inflate(R.layout.watermark_logo, container) { view, resid, parent ->
                container.removeAllViews() //先删除原views
                val relativeLayout = RelativeLayout(context)
                val topLayoutParams = RelativeLayout.LayoutParams(
                    RelativeLayout.LayoutParams.WRAP_CONTENT,
                    RelativeLayout.LayoutParams.WRAP_CONTENT
                )
                view.visibility = View.VISIBLE
                relativeLayout.addView(view,topLayoutParams)


                container.addView(relativeLayout)
                //真正的水印
                doAsyncBindWatermarkViewData(baseID, asyncLayoutInflater, lifecycleOwner, relativeLayout,
                viewModel,
                    view,
                consumer)
            }
        }
        /**
         * 绑定水印数据
         */
        private fun doAsyncBindWatermarkViewData(baseID: String?, asyncLayoutInflater: AsyncLayoutInflater, lifecycleOwner: LifecycleOwner,
                                       container: ViewGroup,
                                       viewModel: BaseWatermarkViewModel?, logoView:  View,
                                       consumer: Consumer<ViewDataBinding?>?) {
            @LayoutRes val layoutId = getWatermarkLayoutByBaseId(baseID)
            Log.d(TAG,"doAsyncBindWatermarkViewData ${baseID} ")
            asyncLayoutInflater.inflate(layoutId, container) { view, resid, parent ->
                //地图
                if (baseID == WatermarkBaseID.ID13.id||baseID == WatermarkBaseID.ID14.id){
                    var watermarkMapWidget = view.findViewById<WaterMarkMapWidget>(R.id.watermarkMapWidget)
                    // 但此时调用 onCreate 可能已经晚了，且仍会阻塞主线程
                    runOnUiThread {
                        Log.d(TAG,"watermarkMapWidget init")
                        watermarkMapWidget.initMap()
                    }
                }

                //多个item
                val itemsRcView = view.findViewById<RecyclerView>(R.id.recyclerItemList)

                viewModel?.watermarkModel?.let {
                    setItemViewContent(itemsRcView, it)
                    //如果是baseID,则需要设置一下top item
                    if (baseID == WatermarkBaseID.ID4.id || baseID == WatermarkBaseID.ID16.id) {
                        val topItemsRcView = view.findViewById<RecyclerView>(R.id.topRecyclerItemList)
                         setItemViewContent(topItemsRcView, it,true)
                    }
                }

                val layoutParams =  RelativeLayout.LayoutParams(
                    RelativeLayout.LayoutParams.WRAP_CONTENT,
                    RelativeLayout.LayoutParams.WRAP_CONTENT
                )
                layoutParams.addRule(RelativeLayout.BELOW, logoView.id)
                layoutParams.topMargin = 20
                container.addView(view,layoutParams)
                val viewDataBinding = DataBindingUtil.bind<ViewDataBinding>(view)
                viewDataBinding?.setVariable(BR.mainViewModel, viewModel)

                viewDataBinding?.setLifecycleOwner(lifecycleOwner);
                try {
                    consumer?.accept(viewDataBinding)
                    container.requestLayout()

                } catch (e: Throwable) {
                    e.printStackTrace()
                }

            }

        }
        fun getDigitDrawable(index:Int): Int {
            return when(index){
                0 -> R.drawable.grey_0
                1 -> R.drawable.grey_1
                2 -> R.drawable.grey_2
                3 -> R.drawable.grey_3
                4 -> R.drawable.grey_4
                5 -> R.drawable.grey_5
                6 -> R.drawable.grey_6
                7 -> R.drawable.grey_7
                8 -> R.drawable.grey_8
                9 -> R.drawable.grey_9
                else -> R.drawable.grey_colon
            }
        }
        fun getClockDrawable(index:Int,isColon: Boolean = true): Int {
            return when(index){
                0 -> R.drawable.clock_0
                1 -> R.drawable.clock_1
                2 -> R.drawable.clock_2
                3 -> R.drawable.clock_3
                4 -> R.drawable.clock_4
                5 -> R.drawable.clock_5
                6 -> R.drawable.clock_6
                7 -> R.drawable.clock_7
                8 -> R.drawable.clock_8
                9 -> R.drawable.clock_9
                else -> if (isColon) R.drawable.clock_colon else R.drawable.clock_point
            }
        }




        /**
         * 根据watermark可能会获取不同的item列表
         *
         * @param watermarkModel
         * @return
         */
        private fun getRecyclerViewAdapter(watermarkModel: BaseWatermarkModel): BaseItemRecyclerViewAdapter {
            var newItemList = WatermarkItemManager.getBottomItemList(watermarkModel)
            //过滤掉底部
            when (watermarkModel.id) {
                WatermarkID.ID1.id,WatermarkID.ID13.id,WatermarkID.ID14.id -> {
                    val notEmptyItems = WatermarkItemManager.filterEmptyContentItemList(newItemList)
                    return NoTitleItemRecyclerViewAdapter(notEmptyItems!!,watermarkModel)
                }
                WatermarkID.ID6.id-> {
                    val dotColor = ContextCompat.getColor(context, R.color.color_ffe)
                    return BaseItemRecyclerViewAdapter(newItemList,watermarkModel, 160, false, dotColor, showIcon = true,true)
                }
                 WatermarkID.ID5.id -> {
                    val dotColor = ContextCompat.getColor(context, R.color.color_ffe)
                    return BaseItemRecyclerViewAdapter(newItemList,watermarkModel, 280, false, dotColor, showIcon = true,true)
                }
                //清洁和签收
                WatermarkID.ID10_1.id,  WatermarkID.ID11_1.id -> {
                    val dotColor = ContextCompat.getColor(context, R.color.color_ffe)
                    return BaseItemRecyclerViewAdapter(newItemList,watermarkModel, 160, false, dotColor)
                }
                WatermarkID.ID7.id-> {
                    val dotColor = ContextCompat.getColor(context, R.color.color_ffe)
                    return  GridItemRecyclerViewAdapter(newItemList,watermarkModel, 160, false, dotColor)
                }


                else ->{
                    return BaseItemRecyclerViewAdapter(newItemList,watermarkModel)
                }
            }

        }



        //设置底部itemView
        private fun setItemViewContent(recyclerView: RecyclerView, watermarkModel: MutableLiveData<BaseWatermarkModel>,isTop: Boolean = false) {
            recyclerView.layoutManager = LinearLayoutManager(recyclerView.context)
            val adapter = watermarkModel.value?.items?.let {
                getRecyclerViewAdapter(watermarkModel.value!!)
            }
            // 设置Adapter
            recyclerView.adapter = adapter
            //监听变化
            watermarkModel.observe(recyclerView.context as LifecycleOwner) {
                //过滤掉关闭的item和地图item,logo
                var newItemList: List<WatermarkItem?>? = null
                watermarkModel.value?.let {
                     newItemList = if (isTop) WatermarkItemManager.getTopItemList(it) else WatermarkItemManager.getBottomItemList(it)
                }

                newItemList?.let {
                    //如果是NoTitleItemRecyclerViewAdapter 则过滤掉没内容的item
                    if (recyclerView.adapter is NoTitleItemRecyclerViewAdapter){
                        var notEmptyItems = WatermarkItemManager.filterEmptyContentItemList(newItemList)
                        if (notEmptyItems != null) {
                            (recyclerView.adapter as BaseItemRecyclerViewAdapter).setData(notEmptyItems,watermarkModel.value!!)
                        }
                    }
                    else if (recyclerView.adapter is GridItemRecyclerViewAdapter){
                        (recyclerView.adapter as GridItemRecyclerViewAdapter).setData(newItemList!!,watermarkModel.value!!)
                    }
                    else {
                        (recyclerView.adapter as BaseItemRecyclerViewAdapter).setData(newItemList!!,watermarkModel.value!!)
                    }


                }
            }
        }

    }

}
