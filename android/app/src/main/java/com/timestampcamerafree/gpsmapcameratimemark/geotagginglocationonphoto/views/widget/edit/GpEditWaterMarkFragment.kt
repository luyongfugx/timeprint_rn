package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit

import android.content.Context
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpViewConvertListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpViewHolder
import android.annotation.SuppressLint
import android.app.Activity
import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import android.text.TextUtils
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.ViewGroup.MarginLayoutParams
import android.view.inputmethod.EditorInfo
import android.widget.TextView
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.widget.AppCompatImageView
import androidx.appcompat.widget.AppCompatTextView
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.lifecycle.Observer
import androidx.recyclerview.widget.LinearLayoutManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.databinding.ActivityEditWatermarkBinding
//import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.UserInputContentSecurityHelper
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store.GpDataStores
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store.GpStoreKeys
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpDialogUtil
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpKits
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpSafeHandler
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpUiUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.toPxInt
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.BaseFragment
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GPBaseDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.EditClickFrom
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.WatermarkManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.logo.LogoPosition
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItemID
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.logo.WatermarkLogoItem
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

/**
 * 水印编辑类
 *
 */
class GpEditWaterMarkFragment : BaseFragment(), View.OnClickListener {
    private val TAG = "GpEditWaterMarkFragment"
    private lateinit var viewBinding: ActivityEditWatermarkBinding
    private val tv_edit_complete by lazy { viewBinding.editComplete }
    private val rv_edit by lazy { viewBinding.editRecyclerView }
    private var colorSizeBtn: AppCompatTextView? = null
    private var handler: GpSafeHandler? = null
    //正在编辑的item
    private var editIngItem: WatermarkItem? = null
    var itemIdEdit = -1
    private var from: String = "watermark"
   var viewModel: EditViewModel? =null

    /**
     * 图片选择器
     */
    private val pickImages = registerForActivityResult(ActivityResultContracts.PickVisualMedia()) { uris ->
        if (uris != null) {
            val imageFile = context?.let { copyImageToInternalStorage(it, uris) }

            if (imageFile != null && editIngItem !=null) {
                // 使用 imageFile 进行后续操作
                // 用户选择了媒体文件
                if( editIngItem?.logoInfo == null){
                    editIngItem?.logoInfo = WatermarkLogoItem().apply {
                        scale = 1f
                        position = LogoPosition.ON_WATER_MARK
                        selectLogoPath = imageFile.toString()
                    }
                }
                editIngItem?.logoInfo?.selectLogoPath = imageFile.toString()
                editIngItem?.logoInfo?.originLogoPath = imageFile.toString()
                editIngItem?.logoInfo?.isRemoveBg = false
                editIngItem?.let { viewModel?.saveItem(it, true) }
                //通知activity
                activity?.let {
                    GpDataStores.put(GpStoreKeys.KEY_WATERMARK_UPDATE, it, Boolean::class.java, true)
                }
                //修改了图片调到设置logo
                showEditLogoDialog(editIngItem!!,  0, ::saveItem)
            }

        } else {
            // 用户取消了选择，不做任何改动

        }

    }

    private fun copyImageToInternalStorage(context: Context, uri: Uri): File? {
        val contentResolver: ContentResolver = context.contentResolver
        val inputStream: InputStream? = contentResolver.openInputStream(uri)

        if (inputStream != null) {
            val fileName: String = getFileName(contentResolver, uri) ?: "image.jpg"
            val imageFile = File(context.filesDir, fileName)

            try {
                val outputStream = FileOutputStream(imageFile)
                val buffer = ByteArray(4096)
                var bytesRead: Int
                while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                    outputStream.write(buffer, 0, bytesRead)
                }
                outputStream.close()
                inputStream.close()
                return imageFile
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        return null
    }
    private fun getFileName(contentResolver: ContentResolver, uri: Uri): String? {
        val cursor = contentResolver.query(uri, null, null, null, null)
        cursor?.use {
            if (it.moveToFirst()) {
                val displayName = it.getString(it.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME))
                return displayName
            }
        }
        return null
    }
    private val adapter = EditItemAdapter().apply {
        onItemClickListener = { item, position, _, isRecentlyEditedItem ->
            //如果可以编辑，则弹出编辑框
            when {
                item.isTitleEditable() || item.isContentEditable() -> showEditDialog(item, false, position, ::saveItem)
                item.id == WatermarkItemID.time.id -> showTimeFormatDialog(item,  position, ::saveItem)
                item.id == WatermarkItemID.address.id -> showAddressFormatDialog(item,  position, ::saveItem)
                item.id == WatermarkItemID.map.id -> showMapTypeDialog(item,  position, ::saveItem)
                item.id == WatermarkItemID.logo.id -> showEditLogoDialog(item,  position, ::saveItem)
                item.id == WatermarkItemID.coordinate.id -> showCoordinateFormatDialog(item,  position, ::saveItem)
                item.id == WatermarkItemID.weather.id -> showWeatherStyleDialog(item,  position, ::saveItem)
            }
        }
        onOptionSelectedListener = { item, _ ->
            saveItem(item)
        }
        onItemCheckedChangeListener = { item, position->
            saveItem(item)
            when {
                //若果是logo,并且还没有上传图片，则弹出图片选择器
                item.id == WatermarkItemID.logo.id -> {
                    if(item.logoInfo == null || item.logoInfo?.selectLogoPath.isNullOrEmpty()) {
                        showEditLogoDialog(item, position, ::saveItem)
                    }
                }
                //如果是编辑框，并且没有编辑内容的时候
                item.isTitleEditable() || item.isContentEditable() ->{
                    if(item.content.isNullOrEmpty()) {
                        showEditDialog(item, false, position, ::saveItem)
                    }
                }
            }
        }
        addCustomItem = ::clickAddCustomItem
    }


    override fun onResume() {
        super.onResume()
    }

    fun singleLineItem(singleLineItem: Boolean) {
        adapter.singleLine = singleLineItem
    }

    override fun onClick(v: View?) {
        when (v) {
            tv_edit_complete -> {
                viewModel?.clickComplete()
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {

        val view = inflater.inflate(R.layout.activity_edit_watermark, container, false)
        viewBinding = ActivityEditWatermarkBinding.bind(view)
        from = arguments?.getString("from") ?: "" // 获取字符串参数
        return view
    }

    @SuppressLint("NotifyDataSetChanged")
    override fun onActivityCreated(savedInstanceState: Bundle?) {
        super.onActivityCreated(savedInstanceState)
        handler = GpSafeHandler(viewLifecycleOwner)
        viewModel?.onUiStart()
        val layoutManager = LinearLayoutManager(activity)
        rv_edit.layoutManager = layoutManager
        rv_edit.adapter = adapter
        rv_edit.itemAnimator?.changeDuration = 0// 去掉动画
        viewModel?.editItemList?.observe(viewLifecycleOwner, Observer {
            adapter.data = it
            adapter.notifyDataSetChanged()
        })
        viewModel?.getData {
            //对点击事件判断来源
            when(from){
                EditClickFrom.Logo.id -> {
                  var logoItem =  it.find { watermarkItem -> watermarkItem.id == WatermarkItemID.logo.id }
                    if (logoItem != null) {
                        showEditLogoDialog(logoItem,0, ::saveItem)
                    }
                }
                EditClickFrom.Map.id -> {
                    var mapItem =  it.find { watermarkItem -> watermarkItem.id == WatermarkItemID.map.id }
                    if (mapItem != null) {
                        showMapTypeDialog(mapItem,0, ::saveItem)
                    }
                }
                else ->{

                }
            }
        }
        //完成按钮
        tv_edit_complete.setOnClickListener { viewModel?.clickClose() }

    }

    private  fun intiColorSizeBtn (){
        colorSizeBtn?.setOnClickListener({
            GpDialogUtil.showColorSizeDialog(activity,  object : GpViewConvertListener() {
                override fun convertView(holder: GpViewHolder?, dialog: GPBaseDialog?) {
                    if (holder != null) {
                        if (holder.convertView == null) {
                            dialog?.dismissAllowingStateLoss()
                            return
                        }
                    }
                }
            },{  activity?.let {
                viewModel?.watermarkContentLive.let {
                    var cur = it?.value?.clone()
                    var currentWatermarkModel =    WatermarkManager.getSelectWatermarkModel()
                   // Log.d(TAG,"colorSizeBtn on click currentWatermarkModel.templateColorStr ${currentWatermarkModel.templateColorStr}")
                    cur?.templateColorStr =  currentWatermarkModel.templateColorStr
                    cur?.textColorStr =  currentWatermarkModel.textColorStr
                    cur?.templateScale =  currentWatermarkModel.templateScale

                    it?.value = cur
                }
                GpDataStores.put(GpStoreKeys.KEY_WATERMARK_UPDATE, it, Boolean::class.java, true)
            }},null,null)
        })
    }
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        colorSizeBtn = view.findViewById(R.id.color_size_btn)
//        val tvTitle = view.findViewById<TextView>(R.id.tv_edit_title)
//        tvTitle.text = GpUiUtils.getString(R.string.i_edit_stamp)
        intiColorSizeBtn()

    }
    // 保存修改过的item,并通知更新
    private fun saveItem(item: WatermarkItem, contentChanged: Boolean = false) {
        viewModel?.saveItem(item, contentChanged)
        //通知activity
        activity?.let {
            GpDataStores.put(GpStoreKeys.KEY_WATERMARK_UPDATE, it, Boolean::class.java, true)
        }
    }

    // 点击添加新条目
    private fun clickAddCustomItem() {
        viewModel?.createNewCustomItem()?.let {
            showEditDialog(it, true, adapter.itemCount, ::saveItem)
        }
    }

    //编辑文本dialog
    private fun showEditDialog(
        item: WatermarkItem,
        isNew: Boolean,
        position: Int,
        saveItemFunc: (WatermarkItem, Boolean) -> Unit
    ) {
        GpDialogUtil.showEditDialogTop(activity, item,
            object : GpViewConvertListener() {
                override fun convertView(holder: GpViewHolder?, dialog: GPBaseDialog?) {
                    if (holder != null) {
                        if (holder.convertView == null) {
                            dialog?.dismissAllowingStateLoss()
                            return
                        }
                    }
                    val clToolBar = holder?.convertView?.findViewById<ConstraintLayout>(R.id.clToolBar)
                    val backIv = holder?.convertView?.findViewById<AppCompatImageView>(R.id.backIv)
                    val titleLayout = holder?.convertView?.findViewById<ViewGroup>(R.id.titleLayout)
                    val contentLayout = holder?.convertView?.findViewById<ConstraintLayout>(R.id.contentConstraintLayout)
                    val titleEdit = holder?.convertView?.findViewById<GpInputTextView>(R.id.titleEdit)
                    val contentEdit = holder?.convertView?.findViewById<GpInputTextView>(R.id.contentEdit)
                    val operation = holder?.convertView?.findViewById<ViewGroup>(R.id.operation)
                    val confirm = holder?.convertView?.findViewById<TextView>(R.id.confirm)

                    val layoutParams = backIv?.layoutParams
                    layoutParams?.height = GpUiUtils.dp2px(56f)
                    clToolBar?.visibility = View.VISIBLE
                    titleLayout?.visibility = if (item.isTitleEditable())
                        View.VISIBLE
                    else
                        View.GONE
                    if (item.isContentEditable()){
                        contentLayout?.visibility = View.VISIBLE
                    }
                    else {
                        contentLayout?.visibility = View.GONE
                    }
                    contentEdit?.setImeOptions(EditorInfo.IME_NULL)

                    titleEdit?.setText(item.title)
                    (operation?.layoutParams as MarginLayoutParams).topMargin = 8f.toPxInt()
                    contentEdit?.setEditFocusableInTouchMode(item.isContentEditable())
                    contentLayout?.postDelayed(Runnable {
                        if (item.isTitleEditable() && item.title!!.isBlank()) {
                            titleEdit?.requestFocus()
                            titleEdit?.setSelection(titleEdit.getText()!!.length)
                            GpKits.KeyBoard.showSoftInput(
                                App.context,
                                titleEdit
                            )
                        } else if (item.isContentEditable()) {
                            if (contentEdit != null) {
                                contentEdit.setEditFocusable(true)
                                contentEdit.requestFocus()
                                contentEdit.setSelection(contentEdit.getText()!!.length)
                                GpKits.KeyBoard.showSoftInput(
                                    App.context,
                                    contentEdit
                                )
                            }

                        } else {
                            if (titleEdit != null) {
                                titleEdit.setEditFocusable(true)
                                titleEdit.setEditFocusableInTouchMode(true)
                                titleEdit.requestFocus()
                                titleEdit.setSelection(titleEdit.getText()!!.length)
                                GpKits.KeyBoard.showSoftInput(
                                    App.context,
                                    titleEdit
                                )
                            }

                        }
                    }, 200)

                    confirm?.setOnClickListener { v: View? ->
                        GpKits.KeyBoard.hideSoftInput(
                            holder.convertView.context,
                            holder.convertView
                        )
                        if (isNew) {
                            // 新增
                            item.title = titleEdit?.getText().toString().trim()
                            item.content = contentEdit?.getText()?.trim()
                            if (item?.title?.isNotEmpty() == true) {
                                item.isOpen = true
                                adapter.data.add(item)
                                adapter.notifyItemInserted(adapter.data.size - 1)
                                saveItemFunc(item, false)
                            } else if(item.content?.isNotEmpty() == true) {
                                item.isOpen = true
                                adapter.data.add(item)
                                adapter.notifyItemInserted(adapter.data.size - 1)
                                saveItemFunc(item, false)
                            }
                        } else {
                            // 修改
                            val titleOrContentChanged = item.title?.isNotEmpty()!!
                                    && item.content?.isNotEmpty()!! && (item.title != titleEdit?.getText()?.trim()
                                    || item.content != contentEdit?.getText()?.trim())
                            if (item.isTitleEditable()) {
                                //标题也可以修改
                                if(!TextUtils.isEmpty(titleEdit?.getText()?.trim()) || !TextUtils.isEmpty(contentEdit?.getText()?.trim())) item.title = titleEdit?.getText()?.trim()

                            }
                            if (item.isContentEditable()) {
                                if(!TextUtils.isEmpty(titleEdit?.getText()?.trim()) || !TextUtils.isEmpty(contentEdit?.getText()?.trim())) {
                                    item.content = contentEdit?.getText()?.trim()
                                }

                                item.isOpen = if( item.content?.isEmpty() == true) {
                                    false
                                } else if(TextUtils.isEmpty(titleEdit?.getText()?.trim())
                                    && TextUtils.isEmpty(contentEdit?.getText()?.trim())) {
                                    false
                                } else {
                                    true
                                }
                            }
                            adapter.notifyItemChanged(position)
                            saveItemFunc(item, titleOrContentChanged)
                        }
                        dialog?.dismiss()
                    }
                }
            }) {
            adapter.notifyItemChanged(position)
        }
    }

    /**
     * logo
     * @param item
     * @param position
     * @param saveItemFunc
     */
    private fun showEditLogoDialog(item: WatermarkItem, position: Int, saveItemFunc: (WatermarkItem, Boolean) -> Unit){
        //设置一下
        Log.d(TAG,"111111")
        editIngItem = item
        var saveItemFuncCallback =  { item: WatermarkItem, contentChanged: Boolean ->
           Log.d(TAG,"showEditLogoDialog saveItemFuncCallback ${item} $contentChanged")
            //重新弹出来

            saveItemFunc(item, contentChanged)
            adapter.notifyItemChanged(position)
            //如果是search from web,会调用这里
          //  showEditLogoDialog(editIngItem!!,  position, ::saveItem)
        }
        Log.d(TAG,"2222")
        var onChangeLogo =  { item: WatermarkItem, contentChanged: Boolean ->
            Log.d(TAG,"showEditLogoDialog saveItemFuncCallback ${item} $contentChanged")
            //重新弹出来
            //如果是search from web,会调用这里
            showEditLogoDialog(editIngItem!!,  position, ::saveItem)
        }

        Log.d(TAG,"3333")
        if(item.logoInfo?.selectLogoPath.isNullOrEmpty()){
            Log.d(TAG,"4444")
            GpDialogUtil.showEditLogoDialog(activity, item, object : GpViewConvertListener() {
                override fun convertView(holder: GpViewHolder?, dialog: GPBaseDialog?) {
                    if (holder != null) {
                        if (holder.convertView == null) {
                            dialog?.dismissAllowingStateLoss()
                            return
                        }
                    }
                }
            }, onChangeLogo,saveItemFuncCallback, {
                pickImages?.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
            }
            ) {
                adapter.notifyItemChanged(position)
            }
        }
        else {
            Log.d(TAG,"5555")
            GpDialogUtil.showLogoStyleDialog(activity, item, object : GpViewConvertListener() {
                override fun convertView(holder: GpViewHolder?, dialog: GPBaseDialog?) {
                    if (holder != null) {
                        if (holder.convertView == null) {
                            dialog?.dismissAllowingStateLoss()
                            return
                        }
                    }
                }
            },saveItemFuncCallback, {
                GpDialogUtil.showEditLogoDialog(activity, item, object : GpViewConvertListener() {
                    override fun convertView(holder: GpViewHolder?, dialog: GPBaseDialog?) {
                        if (holder != null) {
                            if (holder.convertView == null) {
                                dialog?.dismissAllowingStateLoss()
                                return
                            }
                        }
                    }
                },onChangeLogo, saveItemFuncCallback, {
                    pickImages?.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                }
                ) {
                    adapter.notifyItemChanged(position)
                }
               // pickImages?.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
            },null) {
                adapter.notifyItemChanged(position)
            }
        }


    }



    /**
     * 地图选择器
     * @param item
     * @param position
     * @param saveItemFunc
     */
    private fun showWeatherStyleDialog(item: WatermarkItem, position: Int, saveItemFunc: (WatermarkItem, Boolean) -> Unit){
        var saveItemFuncCallback =  { item: WatermarkItem, contentChanged: Boolean ->
            saveItemFunc(item, contentChanged)
            adapter.notifyItemChanged(position)
        }

        GpDialogUtil.showWeatherStyleDialog(activity, item, object : GpViewConvertListener() {
            override fun convertView(holder: GpViewHolder?, dialog: GPBaseDialog?) {
                if (holder != null) {
                    if (holder.convertView == null) {
                        dialog?.dismissAllowingStateLoss()
                        return
                    }
                }
            }
        },saveItemFuncCallback) {
            adapter.notifyItemChanged(position)
        }
    }


    /**
     * 地图选择器
     * @param item
     * @param position
     * @param saveItemFunc
     */
    private fun showMapTypeDialog(item: WatermarkItem, position: Int, saveItemFunc: (WatermarkItem, Boolean) -> Unit){
        //如果地址为空，则不显示
        if(item.extraMap == null)
            return;
        var saveItemFuncCallback =  { item: WatermarkItem, contentChanged: Boolean ->
            saveItemFunc(item, contentChanged)
            adapter.notifyItemChanged(position)
        }

        GpDialogUtil.showMapTypeDialog(activity, item, object : GpViewConvertListener() {
            override fun convertView(holder: GpViewHolder?, dialog: GPBaseDialog?) {
                if (holder != null) {
                    if (holder.convertView == null) {
                        dialog?.dismissAllowingStateLoss()
                        return
                    }
                }
            }
        },saveItemFuncCallback) {
            adapter.notifyItemChanged(position)
        }
    }



    /**
     * 经纬度格式对话框
     *
     * @param item
     * @param position
     * @param saveItemFunc
     */
    private  fun showCoordinateFormatDialog(item: WatermarkItem, position: Int, saveItemFunc: (WatermarkItem, Boolean) -> Unit){
        //如果地址为空，则不显示
//        if(item.extraAddressInfo == null)
//            return;
        var saveItemFuncCallback =  { item: WatermarkItem, contentChanged: Boolean ->
            saveItemFunc(item, contentChanged)
            adapter.notifyItemChanged(position)
        }

        GpDialogUtil.showCoordinateFormatDialog(activity, item, object : GpViewConvertListener() {
            override fun convertView(holder: GpViewHolder?, dialog: GPBaseDialog?) {
                if (holder != null) {
                    if (holder.convertView == null) {
                        dialog?.dismissAllowingStateLoss()
                        return
                    }
                }
            }
        },saveItemFuncCallback) {
            adapter.notifyItemChanged(position)
        }
    }

    /**
     * 地址格式对话框
     *
     * @param item
     * @param position
     * @param saveItemFunc
     */
    private  fun showAddressFormatDialog(item: WatermarkItem, position: Int, saveItemFunc: (WatermarkItem, Boolean) -> Unit){
       //如果地址为空，则不显示
        if(item.extraAddressInfo == null)
            return;
        var saveItemFuncCallback =  { item: WatermarkItem, contentChanged: Boolean ->
            saveItemFunc(item, contentChanged)
            adapter.notifyItemChanged(position)
        }

        GpDialogUtil.showAddressFormatDialog(activity, item, object : GpViewConvertListener() {
            override fun convertView(holder: GpViewHolder?, dialog: GPBaseDialog?) {
                if (holder != null) {
                    if (holder.convertView == null) {
                        dialog?.dismissAllowingStateLoss()
                        return
                    }
                }
            }
        },saveItemFuncCallback) {
            adapter.notifyItemChanged(position)
        }
    }

    //编辑时间格式dialog
    private fun showTimeFormatDialog(
        item: WatermarkItem,
        position: Int,
        saveItemFunc: (WatermarkItem, Boolean) -> Unit
    ) {
        //保存后，notifyItemChanged
       var saveItemFuncCallback =  { item: WatermarkItem, contentChanged: Boolean ->
           Log.i(TAG,"saveItem editItem.content saveItemFuncCallback ")
           saveItemFunc(item, contentChanged)
           adapter.notifyItemChanged(position)
        }
        GpDialogUtil.showTimeFormatDialog(activity, item, object : GpViewConvertListener() {
                override fun convertView(holder: GpViewHolder?, dialog: GPBaseDialog?) {
                    if (holder != null) {
                        if (holder.convertView == null) {
                            dialog?.dismissAllowingStateLoss()
                            return
                        }
                    }
                }
            },saveItemFuncCallback) {
            adapter.notifyItemChanged(position)
        }
    }



    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (resultCode == Activity.RESULT_OK) {
            if (data == null) return
        }
    }

    override fun onBackPressed() {
        tv_edit_complete.performClick()
    }

    override fun onPause() {
        super.onPause()
    }

}