package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget

import android.app.Dialog
import android.content.Context
import android.graphics.Point
import android.graphics.Rect
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.ActionMode
import android.view.KeyEvent
import android.view.LayoutInflater
import android.view.Menu
import android.view.MenuItem
import android.view.MotionEvent
import android.view.SearchEvent
import android.view.View
import android.view.ViewGroup
import android.view.Window
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.FrameLayout
import androidx.annotation.FloatRange
import androidx.coordinatorlayout.widget.CoordinatorLayout
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.google.android.material.bottomsheet.BottomSheetDialogFragment
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GPAppUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpKits

open class BaseBottomSheetDialogFragment: BottomSheetDialogFragment() {

    private val TAG = "BaseBottomSheetDialogFragment"

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        return inflater.inflate(R.layout.layout_bottom_sheet_container,container,false)
    }


    open fun isWindowDim(): Boolean = false

    var outsideClickListener = {rawX:Float,rawY:Float -> false}
    var topOffset = 0
    @FloatRange(from=0.0,to=1.0)
    var activeAreaPercent = 1f
    var fixedHeight = 0
    var heightWrapContent = false
    var swipeDownCloseEnable = true
        set(value) {
            field = value
            if (dialog is BottomSheetDialog) {
                val bottomSheet = (dialog as BottomSheetDialog).delegate.findViewById<FrameLayout>(com.google.android.material.R.id.design_bottom_sheet)
                if (bottomSheet != null) {
                    val behavior = BottomSheetBehavior.from(bottomSheet)
                    behavior.isHideable = value
                }
            }
        }

    protected open var cancelOnTouchOutside = true


    fun getContainerBehavior(): BottomSheetBehavior<View>? {
        if (dialog?.window?.decorView != null) {
            var dview = dialog!!.window!!.decorView!!.findViewById<View>(com.google.android.material.R.id.design_bottom_sheet)
            if (dview != null) {
                return BottomSheetBehavior.from(dview)
            }
        }
        return null
    }

    private var behavior: BottomSheetBehavior<FrameLayout>? = null
    private var lastDisplayHeight = 0

    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        val dialog = if (context == null) {
            super.onCreateDialog(savedInstanceState)
        } else BottomSheetDialog(requireContext(), R.style.CustomBottomSheetDialogTheme)
        dialog.setCanceledOnTouchOutside(cancelOnTouchOutside)
        if (isWindowDim()) {
            val window = dialog.window
            if (window != null) {
                window.setFlags(
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL)
                window.clearFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
            }
        }
        val window = dialog.window
        window?.let {
            val rawCallback = window.callback
            window.callback = object:SimpleWindowCallback(rawCallback){
                override fun dispatchTouchEvent(event: MotionEvent?): Boolean {
                    if (event?.action == MotionEvent.ACTION_UP){
                        val bottomSheetRect = getBottomSheetRect()
                       // Log.i(TAG,"window touch event is action_up,bottom sheet bounds is $bottomSheetRect,touch position is rawX:${event.rawX} rawY:${event.rawY}")
                        if (!bottomSheetRect.contains(event.rawX.toInt(),event.rawY.toInt())) { // bottomSheet之外的点击处理交给outsideClickListener
                            if (outsideClickListener(event.rawX, event.rawY)) return true
                        }
                    }
                    return super.dispatchTouchEvent(event)
                }
            }
        }
        var windowHeight = 0
        val rect = Rect()
        window?.decorView?.addOnLayoutChangeListener { v, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom ->
            dialog.window?.decorView?.getWindowVisibleDisplayFrame(rect)
            if (lastDisplayHeight > 0){
                if (windowHeight == 0){
                    windowHeight = getWindowHeight()
                }
                if (lastDisplayHeight > rect.height() && lastDisplayHeight == windowHeight){
                    softInputChangedListener?.onSoftInputShow()
                }else if (lastDisplayHeight < rect.height() && rect.height() == windowHeight){
                    softInputChangedListener?.onSoftInputHide()
                }
            }
            lastDisplayHeight = rect.height()
        }

        return dialog
    }


    private fun getWindowHeight():Int{
        if (isDetached){
            return 0
        }
        return activity?.window?.let {
            var height = it.decorView.measuredHeight
            if (it.attributes.flags and WindowManager.LayoutParams.FLAG_FULLSCREEN != WindowManager.LayoutParams.FLAG_FULLSCREEN){
                height -= GPAppUtils.getStatusBarHeight(requireActivity())
            }
            val activityContent = requireActivity().findViewById<View>(android.R.id.content)
            if (height > activityContent.measuredHeight){
                height -= GpKits.Device.getNavigationBarHeight(activity)
            }
            height
        }?:0
    }

    private var softInputChangedListener:OnSoftInputChangedListener? = null

    fun setOnSoftInputChangedListener(softInputChangedListener:OnSoftInputChangedListener){
        this.softInputChangedListener = softInputChangedListener
    }

    override fun onStart() {
        super.onStart()
        dialog?.window?.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_HIDDEN)
        val dialog = dialog as? BottomSheetDialog ?: return
        val bottomSheet = dialog.delegate.findViewById<FrameLayout>(com.google.android.material.R.id.design_bottom_sheet) ?: return
        
        if (!heightWrapContent) {
            val layoutParams = bottomSheet.layoutParams
            if (layoutParams is CoordinatorLayout.LayoutParams) {
                layoutParams.height = getHeight()[0]
                behavior = BottomSheetBehavior.from(bottomSheet)
                behavior?.state = BottomSheetBehavior.STATE_EXPANDED
                behavior?.peekHeight = layoutParams.height
                bottomSheet.layoutParams = layoutParams
            } else {
                Log.w(TAG, "Unexpected layout params type: ${layoutParams.javaClass.simpleName}")
            }
        }
    }

    protected fun resetHeight() {
        val dialog = dialog as? BottomSheetDialog ?: return
        val bottomSheet = dialog.delegate.findViewById<FrameLayout>(com.google.android.material.R.id.design_bottom_sheet) ?: return
        
        val layoutParams = bottomSheet.layoutParams
        if (layoutParams is CoordinatorLayout.LayoutParams) {
            layoutParams.height = getHeight()[0]
            behavior = BottomSheetBehavior.from(bottomSheet)
            behavior?.state = BottomSheetBehavior.STATE_EXPANDED
            behavior?.setPeekHeight(layoutParams.height, true)
            bottomSheet.layoutParams = layoutParams
            bottomSheet.requestLayout()
        } else {
            Log.w(TAG, "Unexpected layout params type: ${layoutParams.javaClass.simpleName}")
        }
    }

    protected fun getHeight(): IntArray {
        var height = 1920
        val point = Point()
        if (context != null) {
            val wm = requireContext().getSystemService(Context.WINDOW_SERVICE) as WindowManager
            if (wm != null) {
                wm.defaultDisplay.getRealSize(point)
                height = if(fixedHeight == 0) {
                    (point.y * activeAreaPercent - topOffset).toInt()
                }else{
                    fixedHeight
                }
            }
        }
        return intArrayOf(height,point.y - height)
    }


    private fun getBottomSheetRect(): Rect {
        val bottomSheetBounds = Rect()
        val dialog = dialog as BottomSheetDialog?
        val bottomSheet = dialog!!.delegate.findViewById<FrameLayout>(com.google.android.material.R.id.design_bottom_sheet)
        bottomSheet?.getGlobalVisibleRect(bottomSheetBounds)
        dialog!!.window?.attributes?.flags?.let {
            if ( it and WindowManager.LayoutParams.FLAG_FULLSCREEN != WindowManager.LayoutParams.FLAG_FULLSCREEN){
                val actionBarHeight = GPAppUtils.getStatusBarHeight(requireActivity())
                bottomSheetBounds.top += actionBarHeight
                bottomSheetBounds.bottom += actionBarHeight
            }
        }
        return bottomSheetBounds
    }
}

interface OnSoftInputChangedListener{
    fun onSoftInputHide()
    fun onSoftInputShow()
}

open class SimpleWindowCallback(private val rawCallback: Window.Callback): Window.Callback{
    override fun onActionModeFinished(mode: ActionMode?) {
        rawCallback.onActionModeFinished(mode)
    }

    override fun onCreatePanelView(featureId: Int): View? {
        return rawCallback.onCreatePanelView(featureId)
    }

    override fun dispatchTouchEvent(event: MotionEvent?): Boolean {
        return rawCallback.dispatchTouchEvent(event)
    }

    override fun onCreatePanelMenu(featureId: Int, menu: Menu): Boolean {
        return rawCallback.onCreatePanelMenu(featureId, menu)
    }

    override fun onWindowStartingActionMode(callback: ActionMode.Callback?): ActionMode? {
        return rawCallback.onWindowStartingActionMode(callback)
    }

    override fun onWindowStartingActionMode(callback: ActionMode.Callback?, type: Int): ActionMode? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            rawCallback.onWindowStartingActionMode(callback, type)
        } else {
            rawCallback.onWindowStartingActionMode(callback)
        }
    }

    override fun onAttachedToWindow() {
        rawCallback.onAttachedToWindow()
    }

    override fun dispatchGenericMotionEvent(event: MotionEvent?): Boolean {
        return rawCallback.dispatchGenericMotionEvent(event)
    }

    override fun dispatchPopulateAccessibilityEvent(event: AccessibilityEvent?): Boolean {
        return rawCallback.dispatchPopulateAccessibilityEvent(event)
    }

    override fun dispatchTrackballEvent(event: MotionEvent?): Boolean {
        return rawCallback.dispatchTrackballEvent(event)
    }

    override fun dispatchKeyShortcutEvent(event: KeyEvent?): Boolean {
        return rawCallback.dispatchKeyShortcutEvent(event)
    }

    override fun dispatchKeyEvent(event: KeyEvent?): Boolean {
        return rawCallback.dispatchKeyEvent(event)
    }

    override fun onMenuOpened(featureId: Int, menu: Menu): Boolean {
        return rawCallback.onMenuOpened(featureId, menu)
    }

    override fun onPanelClosed(featureId: Int, menu: Menu) {
        return rawCallback.onPanelClosed(featureId, menu)
    }

    override fun onMenuItemSelected(featureId: Int, item: MenuItem): Boolean {
        return rawCallback.onMenuItemSelected(featureId, item)
    }

    override fun onDetachedFromWindow() {
        rawCallback.onDetachedFromWindow()
    }

    override fun onPreparePanel(featureId: Int, view: View?, menu: Menu): Boolean {
        return rawCallback.onPreparePanel(featureId, view, menu)
    }

    override fun onWindowAttributesChanged(attrs: WindowManager.LayoutParams?) {
        rawCallback.onWindowAttributesChanged(attrs)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        rawCallback.onWindowFocusChanged(hasFocus)
    }

    override fun onContentChanged() {
        rawCallback.onContentChanged()
    }

    override fun onSearchRequested(): Boolean {
        return rawCallback.onSearchRequested()
    }

    override fun onSearchRequested(searchEvent: SearchEvent?): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            rawCallback.onSearchRequested(searchEvent)
        } else {
            rawCallback.onSearchRequested()
        }
    }

    override fun onActionModeStarted(mode: ActionMode?) {
        rawCallback.onActionModeStarted(mode)
    }

}