package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog

import android.app.Activity
import android.app.Dialog
import android.content.DialogInterface
import android.os.Bundle
import android.util.Log
import android.view.Gravity
import android.view.KeyEvent
import android.view.LayoutInflater
import android.view.View
import android.view.View.OnLayoutChangeListener
import android.view.ViewGroup
import android.view.WindowManager
import androidx.annotation.LayoutRes
import androidx.annotation.StyleRes
import androidx.core.util.Consumer
import androidx.fragment.app.DialogFragment
import androidx.fragment.app.FragmentManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GPAppUtils.getNavigationBarHeight
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GPAppUtils.getStatusBarHeight
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpKits

import kotlin.math.max


/**
 * 基础对话类
 */
abstract class GPBaseDialog : DialogFragment(), DialogInterface.OnKeyListener, OnLayoutChangeListener {
    companion object {
        private const val TAG = "GpBaseDialog"
        private const val MARGIN = "margin"
        private const val WIDTH = "width"
        private const val HEIGHT = "height"
        private const val DIM = "dim_amount"
        private const val BOTTOM = "show_bottom"
        private const val ABOVE_SOFT_KEY_BOARD = "above_soft_keyboard"
        private const val CANCEL = "out_cancel"
        private const val ANIM = "anim_style"
        private const val LAYOUT = "layout_id"
    }
    private var margin = 0 //左右边距
    private var width = 0 //宽度 px
    private var height = 0 //高度 px
    private var dimAmount = 0.5f //灰度深浅
    private var showBottom = false //是否底部显示
    private var showTop = false //是否顶部显示
    private var outCancel = true //是否点击外部取消

    private var left = 0
    private var top = 0
    private var showAboveSoftKeyBoard = false //是否在软键盘之上

    @StyleRes
    private var animStyle = 0

    @LayoutRes
    protected var layoutId: Int = 0
    private val configName = "ime_config"

    protected var contentView: View? = null

    private var mBackPressedListener: OnBackPressedListener? = null

    private var onMissCallback: OnMissCallback? =
        null
    private var onCancelCallback: OnCancelCallback? =
        null

    private var onCreateCallback: OnCreateCallback? =
        null

    private var iiMeListener: IIMeListener? = null
    private var showInput = false


    interface IIMeListener {
        fun onImeClose()

        fun onImeOpen()
    }

    var imeHeight: Int = 400

    private var statusBarHeight = 0
    private var navigatorBarHeight = 0

    private var isOpen = false // close

    override fun onLayoutChange(
        v: View,
        left: Int,
        top: Int,
        right: Int,
        bottom: Int,
        oldLeft: Int,
        oldTop: Int,
        oldRight: Int,
        oldBottom: Int
    ) {
        Log.d(
            TAG,
            "onLayoutChange() called with: " +
                    "v = [" + v + "], " +
                    "left = [" + left + "], " +
                    "top = [" + top + "], " +
                    "right = [" + right + "], " +
                    "bottom = [" + bottom + "], " +
                    "oldLeft = [" + oldLeft + "], " +
                    "oldTop = [" + oldTop + "], " +
                    "oldRight = [" + oldRight + "], " +
                    "oldBottom = [" + oldBottom + "] " +
                    "isOpen=" + isOpen
        )
        imeChecker(oldBottom, bottom)
    }


    fun imeChecker(oldBottom: Int, bottom: Int) {
        if (dialog != null && dialog!!.window != null) {
            if (oldBottom != 0 && bottom != 0 && oldBottom != bottom) {
                if (oldBottom > bottom && !isOpen) {
                    val newHeight = oldBottom - bottom
                    if (newHeight > max(
                            statusBarHeight.toDouble(),
                            navigatorBarHeight.toDouble()
                        )
                    ) {
                        isOpen = true // close
                        if (newHeight != imeHeight) {
                            try {
                                context?.getSharedPreferences(configName, 0)
                                    ?.edit()
                                    ?.putInt("height", imeHeight)
                                    ?.apply()
                            } catch (e: Throwable) {
                                e.printStackTrace()
                            }
                        }
                        imeHeight = newHeight
                        // 输入法等容器展开了

                        iiMeListener?.onImeOpen()

                    }
                } else if (oldBottom < bottom && isOpen) {
                    isOpen = false
                    // 输入法等容器收起来了
                    iiMeListener?.onImeClose()

                }
            }
        }
    }

    interface OnMissCallback {
        fun onDismiss()
    }

    fun interface OnCancelCallback {
        fun onCancel()
    }

    abstract fun intLayoutId(): Int

    fun interface OnCreateCallback {
        fun onCreate()
    }
    abstract val layoutView: View?

    abstract fun convertView(holder: GpViewHolder?, dialog: GPBaseDialog?)



    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setStyle(STYLE_NO_TITLE, R.style.GpDialog)
        imeHeight = requireContext().getSharedPreferences(configName, 0).getInt("height", 400)
        statusBarHeight = getStatusBarHeight(requireActivity())
        layoutId = intLayoutId()
        if (layoutId == 0) {
            contentView = layoutView
        }
        //设置

        this.onCreateCallback?.onCreate()
        //恢复保存的数据
        if (savedInstanceState != null) {
            margin = savedInstanceState.getInt(MARGIN)
            width = savedInstanceState.getInt(WIDTH)
            height = savedInstanceState.getInt(HEIGHT)
            dimAmount = savedInstanceState.getFloat(DIM)
            showBottom = savedInstanceState.getBoolean(BOTTOM)
            showAboveSoftKeyBoard = savedInstanceState.getBoolean(ABOVE_SOFT_KEY_BOARD)
            outCancel = savedInstanceState.getBoolean(CANCEL)
            animStyle = savedInstanceState.getInt(ANIM)
            layoutId = savedInstanceState.getInt(LAYOUT)
            // 报错，先注释掉   Fatal Exception: java.lang.RuntimeException: Unable to start activity ComponentInfo{com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto/com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity}: android.os.BadParcelableException: Parcelable protocol requires a Parcelable.Creator object called CREATOR on class q7.w
            //       at android.app.ActivityThread.performLaunchActivity(ActivityThread.java:4164)
           // mBackPressedListener = savedInstanceState.getParcelable("backListener")
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        if (layoutId != 0) {
            contentView = inflater.inflate(layoutId, container, false)
        }
        convertView(contentView?.let { GpViewHolder.create(it) }, this)
        return contentView
    }

    override fun onActivityCreated(savedInstanceState: Bundle?) {
        super.onActivityCreated(savedInstanceState)
        try {
            navigatorBarHeight =
                getNavigationBarHeight(resources, dialog!!.window!!.windowManager.defaultDisplay)
            view?.addOnLayoutChangeListener(this)
        } catch (t: Throwable) {
            t.printStackTrace()
        }
    }

    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        val dialog = super.onCreateDialog(savedInstanceState)
        if (showInput) {
            dialog.window!!.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE or WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_VISIBLE)
        }
        return dialog
    }


    override fun onStart() {
        super.onStart()
        initParams()
        dialog!!.setOnKeyListener(this)
    }


    override fun onDestroyView() {
        super.onDestroyView()
        try {
            if (dialog != null && dialog!!.window != null) {
                view?.removeOnLayoutChangeListener(this)
            }

            val focus = view?.findFocus()
            if (focus != null) {
                GpKits.KeyBoard.hideSoftInput(context, focus)
            }
        } catch (t: Throwable) {
            t.printStackTrace()
        }


        mBackPressedListener = null
        iiMeListener = null
    }

    /**
     * 屏幕旋转等导致DialogFragment销毁后重建时保存数据
     *
     * @param outState
     */
    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putInt(MARGIN, margin)
        outState.putInt(WIDTH, width)
        outState.putInt(HEIGHT, height)
        outState.putFloat(DIM, dimAmount)
        outState.putBoolean(BOTTOM, showBottom)
        outState.putBoolean(ABOVE_SOFT_KEY_BOARD, showAboveSoftKeyBoard)
        outState.putBoolean(CANCEL, outCancel)
        outState.putInt(ANIM, animStyle)
        outState.putInt(LAYOUT, layoutId)
        outState.putParcelable("backListener", mBackPressedListener)
    }

    private fun initParams() {
        val window = dialog!!.window
        if (window != null) {
            val lp = window.attributes
            //调节灰色背景透明度[0-1]，默认0.5f
            lp.dimAmount = dimAmount
            //是否在底部显示d
            if (showBottom) {
                lp.gravity = Gravity.BOTTOM
                if (animStyle == 0) {
                    animStyle = R.style.DefaultAnimation
                }
            } else if (showTop) {
                lp.gravity = Gravity.TOP
                if (animStyle == 0) {
                    animStyle = R.style.DefaultAnimation
                }
            } else if (showAboveSoftKeyBoard) {
                lp.x = left
                lp.y = top
            }

            if (activity == null) {
                return
            }
            //设置dialog宽度
            if (width == 0) {
                lp.width = GpKits.Device.getScreenWidth(activity) - 2 * GpKits.Dimens.dpToPxInt(
                    activity,
                    margin.toFloat()
                )
            } else if (width == -1) {
                lp.width = WindowManager.LayoutParams.WRAP_CONTENT
            } else {
                lp.width = width
            }

            //设置dialog高度
            if (height == 0) {
                lp.height = WindowManager.LayoutParams.WRAP_CONTENT
            } else {
                lp.height = height
            }

            //设置dialog进入、退出的动画
            window.setWindowAnimations(animStyle)
            window.attributes = lp
        }
        isCancelable = outCancel
    }

    fun setIiMeListener(iiMeListener: IIMeListener?): GPBaseDialog {
        if (this.iiMeListener != null) {
            Log.e(TAG, "iiMeListener has override")
        }
        this.iiMeListener = iiMeListener
        return this
    }

    fun setOnBackPressedListener(backPressedListener: OnBackPressedListener): GPBaseDialog {
        this.mBackPressedListener = backPressedListener
        return this
    }

    fun setMargin(margin: Int): GPBaseDialog {
        this.margin = margin
        return this
    }

    fun setWidth(width: Int): GPBaseDialog {
        this.width = width
        return this
    }

    fun setHeight(height: Int): GPBaseDialog {
        this.height = height
        return this
    }

    fun setDimAmount(dimAmount: Float): GPBaseDialog {
        this.dimAmount = dimAmount
        return this
    }

    fun setShowBottom(showBottom: Boolean): GPBaseDialog {
        this.showBottom = showBottom
        return this
    }


    fun setShowTop(showTop: Boolean): GPBaseDialog {
        this.showTop = showTop
        return this
    }

    fun setMissCallback(onMissCallback: OnMissCallback?): GPBaseDialog {
        this.onMissCallback = onMissCallback
        return this
    }
    fun setCancelCallback(onCancelCallback: OnCancelCallback?): GPBaseDialog {
        this.onCancelCallback = onCancelCallback
        return this
    }

    fun setOnCreateCallback(onCreateCallback: OnCreateCallback?): GPBaseDialog {
        this.onCreateCallback = onCreateCallback
        return this
    }

    fun setShowAboveSoftKeyBoard(
        showAboveSoftKeyBoard: Boolean,
        left: Int,
        top: Int
    ): GPBaseDialog {
        this.showAboveSoftKeyBoard = showAboveSoftKeyBoard
        this.left = left
        this.top = top
        return this
    }

    fun setOutCancel(outCancel: Boolean): GPBaseDialog {
        this.outCancel = outCancel
        return this
    }

    fun setAnimStyle(@StyleRes animStyle: Int): GPBaseDialog {
        this.animStyle = animStyle
        return this
    }

    fun setShowInput(input: Boolean): GPBaseDialog {
        this.showInput = input
        return this
    }
    fun show(manager: FragmentManager): GPBaseDialog {
        if (context is Activity && (context as Activity).isFinishing) {
            return this
        }
//        val activity = context as? Activity
//        if (activity == null || activity.isFinishing || activity.isDestroyed) {
//            return this
//        }
        val ft = manager.beginTransaction()
        if (this.isAdded) {
            ft.remove(this).commit()
        }
        ft.add(this, System.currentTimeMillis().toString())
        ft.commitAllowingStateLoss()
        return this
    }

    override fun onKey(dialog: DialogInterface, keyCode: Int, event: KeyEvent): Boolean {
       // Log.d(TAG,"GpBaseDialog mBackPressedListener on kEY ${keyCode} ${KeyEvent.KEYCODE_BACK}")
        if (keyCode == KeyEvent.KEYCODE_BACK && mBackPressedListener != null) {
          //  Log.d(TAG,"mBackPressedListener != null invoke")
            mBackPressedListener?.backPressedListener(dialog, keyCode, event)
            return true
        } else {
           // Log.d(TAG,"mBackPressedListener == null not  invoke")
            return false
        }
    }


    override fun onDismiss(dialog: DialogInterface) {
        super.onDismiss(dialog)
        Log.e("DIALOG", "onDismiss......")
        onMissCallback?.onDismiss()

    }

    override fun dismiss() {
        try {
            super.dismiss()
        } catch (t: Throwable) {
            t.printStackTrace()
        }
    }

    override fun dismissAllowingStateLoss() {
        try {
            super.dismissAllowingStateLoss()
        } catch (t: Throwable) {
            t.printStackTrace()
        }
    }

    override fun onCancel(dialog: DialogInterface) {
        super.onCancel(dialog)
        Log.e("DIALOG", "onCancel")
        onCancelCallback?.onCancel()

    }

    private var onResume: Consumer<*>? = null

    fun setOnResume(consumer: Consumer<*>?): GPBaseDialog {
        onResume = consumer
        return this
    }

    override fun onResume() {
        super.onResume()
        onResume?.accept(true as Nothing)
    }


}