package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit

import android.app.Dialog
import android.content.DialogInterface
import android.graphics.Color
import android.graphics.Rect
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import android.util.Log
import android.view.*
import android.widget.FrameLayout
import androidx.coordinatorlayout.widget.CoordinatorLayout
import androidx.core.view.children
import androidx.core.view.contains
import androidx.lifecycle.*
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.databinding.LayoutBottomSheetContainerBinding
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store.GpDataStores
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store.GpStoreKeys
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GPAppUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpKits
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.toPxInt
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.BaseBottomSheetDialogFragment
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.SimpleWindowCallback
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.BaseWatermarkModel

// 水印view
var watermarkView:View? = null

class PreviewWatermarkEditFragment: BaseBottomSheetDialogFragment() {

    private val TAG = "PreviewWatermarkEditFragment"

    var callback:(MutableLiveData<BaseWatermarkModel>)-> Unit = {}

    override fun isWindowDim(): Boolean = true

    private val viewModel by lazy { ViewModelProvider(this).get(EditViewModel::class.java) }

    private lateinit var viewBinding: LayoutBottomSheetContainerBinding

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        updateHeight()
        viewBinding = LayoutBottomSheetContainerBinding.inflate(inflater, container,false)
        return viewBinding.root
    }
    private lateinit var buttonRect:Rect
    private lateinit var buttonLayout:View
    private lateinit var logoRect:Rect
    private lateinit var logoLayout:View
    private var itemId = -1
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        val transaction = childFragmentManager.beginTransaction()
        val bundle = arguments
        transaction.add(R.id.bottom_sheet_container, GpTabsEditFragment().apply {
            arguments = bundle
            itemGpTabsIdEdit = itemId
        },"GpTabsEditFragmentTag").commitAllowingStateLoss()
        outsideClickListener = {rawX,rawY ->
            if (!::buttonRect.isInitialized){
                buttonRect = Rect()
                try {
                    if(::buttonLayout.isInitialized){
                        buttonLayout.getGlobalVisibleRect(buttonRect)
                        buttonRect.top -= 20f.toPxInt()
                        buttonRect.bottom += 10f.toPxInt()
                    }
                }catch (e:Exception){

                }
            }
            if (!::logoRect.isInitialized){
                logoRect = Rect()
                try {
                    if(::logoLayout.isInitialized){
                        logoLayout.getGlobalVisibleRect(logoRect)
                        logoRect.top -= 10f.toPxInt()
                        logoRect.bottom += 10f.toPxInt()
                    }
                }catch (e:Exception){

                }
            }
            if (buttonRect.contains(rawX.toInt(), rawY.toInt() - GPAppUtils.getStatusBarHeight(requireActivity())) ||
                logoRect.contains(rawX.toInt(), rawY.toInt() - GPAppUtils.getStatusBarHeight(requireActivity()))
            ) {
                false
            } else {
                viewModel.clickOutside()
                true
            }
        }


        viewBinding.bottomSheetContainer.viewTreeObserver.addOnGlobalLayoutListener {
            val bottomSheet = (dialog as BottomSheetDialog).delegate.findViewById<FrameLayout>(com.google.android.material.R.id.design_bottom_sheet)
            val location = IntArray(2)
            bottomSheet?.getLocationInWindow(location)
            val rect = Rect()
            bottomSheet?.getGlobalVisibleRect(rect)
            watermarkView?.let {
                if (it.parent === dialog?.window?.decorView) {
                    val lp = it.layoutParams as FrameLayout.LayoutParams
                   // Log.i(TAG,"screenHeight:${GpKits.Device.getScreenRealHeight(activity)},bottomSheetTop:${location[1]}")
                    val newBottomMargin = GpKits.Device.getScreenRealHeight(activity) - location[1] + 2f.toPxInt()
                    if (lp.bottomMargin != newBottomMargin) {
                        lp.bottomMargin = newBottomMargin
                        it.requestLayout()
                    }
                    getHeight()[0] + 2f.toPxInt()
                }
            }
            true
        }
        val window = dialog?.window
        window?.let {
            val rawCallback = window.callback
            window.callback = object: SimpleWindowCallback(rawCallback){
                override fun dispatchTouchEvent(event: MotionEvent?): Boolean {
//                    if (event?.action == ACTION_UP){
//                        if (GroupWaterStatus.getSingletonInstance().isShowOpen){
//                            GroupWaterStatus.getSingletonInstance().isShowOpen = false
//                            return true
//                        }
//                    }
                    return super.dispatchTouchEvent(event)
                }
            }
        }
    }

    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        activity?.let {
            GpDataStores.put(GpStoreKeys.KEY_PREVIEW_TITLE_VISIBILITY, it, Int::class.java, View.INVISIBLE)
        }
        val dialog = super.onCreateDialog(savedInstanceState)
        dialog.window?.decorView?.background = ColorDrawable(Color.BLACK).apply { alpha = 0x99 }
        return dialog
    }

    override fun onActivityCreated(savedInstanceState: Bundle?) {
        super.onActivityCreated(savedInstanceState)
        viewModel.watermarkContentLive.observe(viewLifecycleOwner, object:Observer<BaseWatermarkModel>{
            override fun onChanged(watermarkContent: BaseWatermarkModel) {
                watermarkContent?.let {
                    dialog?.let {
                        addWatermarkView(dialog as BottomSheetDialog)
                        viewModel.watermarkContentLive.removeObserver(this)
                    }
                }
            }
        })

        viewModel.pageAction.observe(viewLifecycleOwner, Observer {
            if (it == PageAction.CLOSE){
                tryDismiss()
            }
        })

        viewModel.switchStatusChanged.observe(viewLifecycleOwner, Observer {
            val shownItemNumber = viewModel.watermarkContentLive.value?.items?.count { it?.isOpen == true } ?: 0
            swipeDownCloseEnable = shownItemNumber != 0
        })
    }

    private fun updateHeight() {
        activeAreaPercent = 0.49f
        topOffset = 0
    }



    override fun onResume() {
        super.onResume()
//        val scale = getWatermarkScale(getCurrentSelectWaterMark())
//        (watermarkView as? RotateLayout)?.setWatermarkScale(scale)
    }

    private var watermarkViewRawTranslationY = 0f
    private var watermarkViewRawParent:ViewGroup? = null
    private var rawLayoutParam :ViewGroup.LayoutParams? = null
    // 占位的View
    private lateinit var watermarkViewRawIndexPlaceHolder:View

    fun onWatermarkViewChanged(watermarView: View) {
        if (watermarkViewRawParent != null) {
            watermarkViewRawParent?.indexOfChild(watermarkViewRawIndexPlaceHolder)?.let { index ->
                if (index >= 0) {
                    watermarkViewRawParent?.removeView(watermarkViewRawIndexPlaceHolder)
                    watermarkViewRawParent = watermarView.parent as ViewGroup
                    watermarkViewRawParent?.addView(watermarkViewRawIndexPlaceHolder,index)
                }
            }
        }
    }

    // 把水印的view加到页面上
    private fun addWatermarkView(dialog: BottomSheetDialog){
        watermarkView?.let {
            if (it.parent == null) return@let
            val container = dialog.delegate.findViewById<CoordinatorLayout>(com.google.android.material.R.id.coordinator) ?: return@let
            val left = it.left
            rawLayoutParam = it.layoutParams
            watermarkViewRawParent = it.parent as ViewGroup
            val watermarkViewRawIndex = watermarkViewRawParent!!.children.indexOf(it)
            if (!::watermarkViewRawIndexPlaceHolder.isInitialized){
                watermarkViewRawIndexPlaceHolder = View(it.context).apply { visibility = View.INVISIBLE }
            }
            watermarkViewRawParent?.addView(watermarkViewRawIndexPlaceHolder,watermarkViewRawIndex)
            watermarkViewRawParent?.removeView(it)
            watermarkViewRawTranslationY = it.translationY
            it.isClickable = false
            val lp = CoordinatorLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT,ViewGroup.LayoutParams.WRAP_CONTENT)
            lp.marginStart = left
            lp.gravity = Gravity.BOTTOM
            var height = getHeight()[0]
            lp.bottomMargin = height + 2f.toPxInt()
            it.translationY = 0f
            container.addView(it,1,lp)
            //强制刷新布局
            it.requestLayout()
        }
    }


    // 把水印View放回拍照页
    private fun resetWatermarkView(){
        watermarkView?.let {
            if (watermarkViewRawParent == null) return@let
            (it.parent as ViewGroup).removeView(it)
            val watermarkViewRawIndex = if (!::watermarkViewRawIndexPlaceHolder.isInitialized)
                watermarkViewRawParent!!.childCount - 1
            else {
                watermarkViewRawParent!!.children.indexOf(watermarkViewRawIndexPlaceHolder).let {
                    if (it < 0) watermarkViewRawParent!!.childCount - 1 else it
                }
            }
            watermarkViewRawParent?.addView(it,watermarkViewRawIndex,rawLayoutParam)
            watermarkViewRawParent?.removeView(watermarkViewRawIndexPlaceHolder)
            it.isClickable = true
            it.invalidate()
            it.translationY = watermarkViewRawTranslationY

        }
    }

    override fun onDismiss(dialog: DialogInterface) {
        resetWatermarkView()
        super.onDismiss(dialog)
    }

    private fun tryDismiss(){
        dismissAllowingStateLoss()
    }

}

