package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.itemdialog
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.fragment.app.FragmentActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.databinding.DialogLogoUploadBinding
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.AnalyticsManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpCameraPermission
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpDialogUtil
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.SafeClickListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GPBaseDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpViewConvertListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpViewHolder
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItem


/**
 * logo选择
 *
 * @property activity
 * @property editItem
 * @property listener
 * @property saveItemFunc
 */
class GpLogoUploadDialog (val activity: FragmentActivity, private val editItem: WatermarkItem, val listener: GpViewConvertListener, private var onChangeLogo: (WatermarkItem, Boolean) -> Unit, private var saveItemFunc: (WatermarkItem, Boolean) -> Unit) {
    private val TAG = "GpLogoUploadDialog"
    private var editDialog: GPBaseDialog? = null
    private val binding: DialogLogoUploadBinding by lazy {
        DialogLogoUploadBinding.inflate(LayoutInflater.from(activity), null, false)
    }

    fun show(onMissCallback: GPBaseDialog.OnMissCallback?, onCancelCallback: GPBaseDialog.OnCancelCallback?,showPickerDialog: (() -> Unit)?) {
        editDialog = GpDialog.init()
            .setContentView(binding.root)
            .setConvertListener(object: GpViewConvertListener(){
                override fun convertView(holder: GpViewHolder?, dialog: GPBaseDialog?) {
                    dialog?.let {}
                    listener.convertView(holder,dialog)
                }
            })
            .setDimAmount(0.5f)
            .setMargin(0)
            .setOutCancel(true)
            .setShowBottom(true)
            .setHeight(ViewGroup.LayoutParams.WRAP_CONTENT)

        editDialog?.setMissCallback(onMissCallback)
        binding.uploadLogo.setOnClickListener(SafeClickListener(View.OnClickListener { v: View? ->
            activity?.let {
                GpCameraPermission.requestReadGalleryPermission(activity) { granted ->
                    if (granted) {
                        if (showPickerDialog != null) {
                            onCancelCallback?.onCancel()
                            editDialog?.dismissAllowingStateLoss()
                            showPickerDialog()
                            AnalyticsManager.logEvent("upload_logo_album")
                        }
                    }
                }
            }

        }))
        binding.searchLogo.setOnClickListener(SafeClickListener(View.OnClickListener { v: View? ->
            onCancelCallback?.onCancel()
            editDialog?.dismissAllowingStateLoss()
            AnalyticsManager.logEvent("search_logo")
            GpDialogUtil.showSearchLogoDialog(activity, editItem, object : GpViewConvertListener() {
                override fun convertView(holder: GpViewHolder?, dialog: GPBaseDialog?) {
                    if (holder != null) {
                        if (holder.convertView == null) {
                            dialog?.dismissAllowingStateLoss()
                            return
                        }
                    }
                }
            },onChangeLogo, saveItemFunc, {

            }
            ) {
               Log.d(TAG," binding.searchLogo.setOnClickListener callback")
            }
//            activity?.let {
//                GpCameraPermission.requestReadGalleryPermission(activity) { granted ->
//                    if (granted) {
//                        if (showPickerDialog != null) {
//                            onCancelCallback?.onCancel()
//                            editDialog?.dismissAllowingStateLoss()
//                            showPickerDialog()
//                        }
//                    }
//                }
//            }

        }))


        binding.backIv.setOnClickListener(SafeClickListener(View.OnClickListener { v: View? ->
            onCancelCallback?.onCancel()
            editDialog?.dismissAllowingStateLoss()
        }))
        editDialog?.show(activity.supportFragmentManager)
    }
}