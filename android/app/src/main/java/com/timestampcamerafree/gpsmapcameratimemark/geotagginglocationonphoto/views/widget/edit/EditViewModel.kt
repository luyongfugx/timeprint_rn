package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit
import android.annotation.SuppressLint
import android.util.Log
import androidx.core.util.Consumer
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpTimeManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.WatermarkManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.BaseWatermarkModel
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItemID
import java.util.concurrent.CopyOnWriteArrayList

/**
 * 水印编辑viewmodel
 *
 */
class EditViewModel : GpLocationViewModel()  {

    private val TAG = "EditViewModel"
    private val watermarkName = MutableLiveData<String?>()
    val watermarkContentLive = MutableLiveData<BaseWatermarkModel>()
    // 列表数据，可能包含分组数据GroupData
    val editItemList = MutableLiveData<ArrayList<WatermarkItem>>()
    // 原始列表数据(肯定未分组)
    private val rawList = ArrayList<WatermarkItem>()
    val error = MutableLiveData<String>()
    private val _pageAction = MutableLiveData<PageAction>()
    val pageAction:LiveData<PageAction> = _pageAction
    val switchStatusChanged = MutableLiveData<Boolean>()
    // 条目id和watermarkContent的ItemsBean的映射关系，方便修改watermarkContent
    private lateinit var map: HashMap<Int, WatermarkItem>

    /**
     * 读取数据
     *
     * @param itemResult
     */
    fun getData(itemResult: Consumer<ArrayList<WatermarkItem>>? = null) {
        val watermarkViewModel = WatermarkManager.getCurrentWaterMarkViewModelFromLocal();

        val baseModel =  watermarkViewModel.watermarkModel.value


        baseModel?.let  {
            watermarkName.value = it.name
            watermarkContentLive.value = it
            val allEditItemList = ArrayList<WatermarkItem>()
            map = convertToEditItemList(it, allEditItemList)
            filterData(allEditItemList)
            itemResult?.accept(allEditItemList)
        }
    }

    /**
     * 过滤掉不显示的条目。如果开关不可关闭，并且不可编辑（editType == NOT_EDITABLE），条目不显示。
     */
    private fun filterData(list: List<WatermarkItem>) {
        if (list != rawList) {
            rawList.clear()
            rawList.addAll(list)
        }
        editItemList.value = ArrayList(list)
    }

    /**
     * 保存条目数据
     * @param itemChanged 标题或内容改变
     */
    fun saveItem(item: WatermarkItem,itemChanged:Boolean) {
        var switchChanged = true
        map[item.id]?.let {
            switchChanged = item.isOpen == true
            it.isOpen = item.isOpen
            it.title = item.title
            it.content = item.content
            it.logoInfo = item.logoInfo
            it.weatherStyle =  item.weatherStyle
            //修改水印内容,另一侧需要监听内容变化
            WatermarkManager.currentWaterMarkViewModel?.let {
                val curMarkViewModel = it.watermarkModel.value
                curMarkViewModel?.let {
                        curMarkViewModel.items.forEach{im ->
                            if (im != null) {
                                if(im.id == item.id){
                                    im.isOpen = item.isOpen
                                    im.content = item.content
                                    im.logoInfo = item.logoInfo
                                }
                            }
                        }
                    //修改edititemList,更新修改列表
                    val allEditItemList = ArrayList<WatermarkItem>()
                    map = convertToEditItemList(it, allEditItemList)
                    filterData(allEditItemList)
                }
                val newBaseWatermarkModel = curMarkViewModel?.clone()
                it.watermarkModel.value = newBaseWatermarkModel
            }
        } ?: run {
            if (item.idType == WatermarkItemID.customItem) {
                // map中没找到说明是新增的自定义条目
                watermarkContentLive.value?.let {
                    val newItemBean = item.clone()
                    it.items.add(newItemBean)
                    rawList.add(item)
                    map[item.id!!] = newItemBean
                }
            }
            switchChanged = true
        }

        if (switchChanged) switchStatusChanged.value = switchChanged
    }

    /**
     * 保存数据
     */
    fun save(watermarkContent: BaseWatermarkModel) {
//        WaterMarkDataProcessor.get().saveOneWatermark(watermarkContent)
        Log.i(TAG, "save() save watermark, watermarkContent: $watermarkContent")
    }

    @SuppressLint("WrongConstant")
    public fun convertToEditItemList(
        watermarkContent: BaseWatermarkModel,
        result: ArrayList<WatermarkItem>
    ): HashMap<Int, WatermarkItem> {
        val map = HashMap<Int, WatermarkItem>()
        watermarkContent.items.forEach { item ->
            //先把 map 过滤了,因为现在不能使用mapkey 25.5.18 去掉，因为申请到key了
            //if (item?.id != WatermarkItemID.map.id) {
                item?.let {
                    val id = item.id
                    id?.let {
                        map[id] = item
                        // 编辑页面要用的条目数据
                        var editItem = item.clone()
                        editItem.apply {
                        }
                        result.add(editItem)
                    }
                }

           // }
        }
        return map
    }


    fun createNewCustomItem(): WatermarkItem? {
        val watermarkContent = watermarkContentLive.value
        return watermarkContent?.let {
            // 自定义item以时间戳作为id，
            WatermarkItem(
                (GpTimeManager.getExactTime() / 1000).toInt(),
                true,
                "",
                "",
            )
        }
    }
    // 点击外部关闭
    fun clickOutside(){
        complete()
        _pageAction.value = PageAction.CLOSE
    }
    // 点击关闭
    fun clickClose(){
        complete()
        _pageAction.value = PageAction.CLOSE
    }
    // 点击完成
    fun clickComplete(){
        complete()
        _pageAction.value = PageAction.CLOSE
    }
    private fun complete(shareClick: Boolean = false){
        watermarkContentLive.value?.let {
            save(it)
        }
    }
}

enum class PageAction{
    CLOSE
}