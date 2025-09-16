package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.itemdialog

import android.content.DialogInterface
import android.text.Editable
import android.text.TextWatcher
import android.util.Log
import android.view.KeyEvent
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.FragmentActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.databinding.DialogGpEditInputBinding
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpDialogUtil
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpKits
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GPBaseDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpViewConvertListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpViewHolder
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.OnBackPressedListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.GpInputTextView
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItem
import java.util.concurrent.atomic.AtomicReference

/**
 *  item文本编辑框
 * @property activity
 * @property editItem
 * @property listener
 */
class GpWatermarkItemEditDialog(val activity: FragmentActivity, private val editItem: WatermarkItem, val listener: GpViewConvertListener ) {
    private val TAG = "GlobalWatermarkItemEditDialog"
    private var editDialog: GPBaseDialog? = null
    private var isSelectingItem = false
    private var isClickHistoryRecord = false
    private val binding: DialogGpEditInputBinding by lazy {
        DialogGpEditInputBinding.inflate(LayoutInflater.from(activity), null, false)
    }
    fun show(onMissCallback: GPBaseDialog.OnMissCallback?, onCancelCallback: GPBaseDialog.OnCancelCallback?) {
        val confirmBtn = binding.confirm
        val oldTitleText: String = editItem.title.toString()
        val oldContentText: String = editItem.content.toString()
        val oldHighLight: Int = 0
        binding.titleEdit.setText(oldTitleText)
        binding.contentEdit.setText(oldContentText)
        binding.contentEdit.setOnDelListener { v: View? ->
        }
        val focusedView = AtomicReference<View?>()
        binding.titleEdit.setOnFocusChangeListener { v: View, hasFocus: Boolean ->
            if (hasFocus) {
                focusedView.set(v)
                GpKits.KeyBoard.showSoftInput(App.context, v)
            }
        }

        binding.contentEdit.setOnFocusChangeListener { v: View, hasFocus: Boolean ->
            if (hasFocus) {
                binding.contentEdit.getText()
                focusedView.set(v)
                GpKits.KeyBoard.showSoftInput(App.context, v)
            }
        }

        editDialog = GpDialog.init()
            .setContentView(binding.root)
            .setConvertListener(object: GpViewConvertListener(){
                override fun convertView(holder: GpViewHolder?, dialog: GPBaseDialog?) {
                    dialog?.let {}
                    listener.convertView(holder,dialog)
                    binding.titleEdit.addTextChangedListener(object : TextWatcher {
                        override fun beforeTextChanged(s: CharSequence, start: Int, count: Int, after: Int) {}
                        override fun onTextChanged(s: CharSequence, start: Int, before: Int, count: Int) {}
                        override fun afterTextChanged(s: Editable) {
                            Log.d(TAG, "title edit afterTextChanged = $s")
                        }
                    })

                    binding.contentEdit.addTextChangedListener(object : TextWatcher {
                        override fun beforeTextChanged(s: CharSequence, start: Int, count: Int, after: Int) {}
                        override fun onTextChanged(s: CharSequence, start: Int, before: Int, count: Int) {}
                        override fun afterTextChanged(s: Editable) {
                            isSelectingItem = false
                            if(!isClickHistoryRecord) {
                                isHistoryRecord = false
                            }
                            isClickHistoryRecord = false
                        }
                    })
                }
            })
            .setDimAmount(0.5f)
            .setMargin(0)
            .setOutCancel(true)
            .setShowBottom(true)
            .setHeight(ViewGroup.LayoutParams.WRAP_CONTENT)
        editDialog?.setOnBackPressedListener(object : OnBackPressedListener() {
            override fun backPressedListener(
                dialog: DialogInterface?,
                keyCode: Int,
                event: KeyEvent?
            ) {
                if (event?.action == KeyEvent.ACTION_DOWN) {
                    showConfirmDialog(
                        activity, listener, editDialog!!, oldHighLight,
                        oldTitleText, binding.titleEdit,
                        oldContentText, binding.contentEdit, editItem,
                        onCancelCallback, confirmBtn
                    )
                }
            }
        })
        editDialog?.setMissCallback(onMissCallback)
        if (binding.contentEdit.viewTreeObserver != null) {
            binding.contentEdit.viewTreeObserver.addOnWindowFocusChangeListener { hasFocus: Boolean ->
                if (!hasFocus || hasCategory) {
                    return@addOnWindowFocusChangeListener
                }
                if (focusedView.get() != null) {
                    binding.contentEdit.postDelayed({
                        focusedView.get()!!.requestFocus()
                        GpKits.KeyBoard.showSoftInput(App.context, focusedView.get())
                    }, 10)
                } else {
                    binding.contentEdit.post {
                        binding.contentEdit.requestFocus(
                            View.FOCUS_RIGHT,
                            null
                        )
                    }
                }
            }
        }
        editDialog?.show(activity.supportFragmentManager)

    }


    private fun showConfirmDialog(
        activity: FragmentActivity,
        listener: GpViewConvertListener,
        show: GPBaseDialog,
        oldHighLight: Int,
        oldTitle: String,
        titleEdit: GpInputTextView,
        oldContent: String,
        contentEdit: GpInputTextView,
        editItem: WatermarkItem,
        onCancelCallback: GPBaseDialog.OnCancelCallback?,
        confirmBtn: View
    ) {
        confirmBtn.performClick()
        onCancelCallback?.onCancel()
        show.dismissAllowingStateLoss()
        GpKits.KeyBoard.hideSoftInput(activity, GpDialogUtil.getFocusView(show.dialog))
    }



    companion object{
        var isHistoryRecord = true
    }
    private var hasCategory = false


}