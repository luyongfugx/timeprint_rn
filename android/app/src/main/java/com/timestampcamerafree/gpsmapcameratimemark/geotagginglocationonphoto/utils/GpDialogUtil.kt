package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils

import android.annotation.SuppressLint
import android.app.Dialog
import android.util.Log
import android.view.View
import androidx.fragment.app.FragmentActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.AnalyticsManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GPBaseDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpViewConvertListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.itemdialog.GpAddressFormatDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.itemdialog.GpColorSizeDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.itemdialog.GpCoordinateFormatDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.itemdialog.GpLogoSearchDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.itemdialog.GpLogoStyleDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.itemdialog.GpLogoUploadDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.itemdialog.GpMapTypeDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.itemdialog.GpTimeFormatDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.itemdialog.GpWatermarkItemEditDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.itemdialog.GpWeatherStyleDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItem


/**
 * GpDialogUtil
 */
object GpDialogUtil {
    private const val TAG = "GpDialogUtil"
    @SuppressLint("ClickableViewAccessibility")
     fun showEditDialogTop(
        activity: FragmentActivity?,
        item: WatermarkItem,
        listener: GpViewConvertListener,
        onCancelCallback: GPBaseDialog.OnCancelCallback
    ) {
        AnalyticsManager.logEvent("edit_logo")
        showWatermarkItemEditDialog(
            activity,
            item,
            listener,
            null,
            onCancelCallback
        )
    }
    private fun showWatermarkItemEditDialog(
        activity: FragmentActivity?,
        editItem: WatermarkItem,
        listener: GpViewConvertListener,
        onMissCallback: GPBaseDialog.OnMissCallback?,
        onCancelCallback: GPBaseDialog.OnCancelCallback?
    ) {
            GpWatermarkItemEditDialog(
                activity!!,
                editItem,
                listener
            ).show(onMissCallback, onCancelCallback)

    }


    fun showColorSizeDialog( activity: FragmentActivity?,
                             listener: GpViewConvertListener,
                             saveFunc: (Boolean) -> Unit,
                             onMissCallback: GPBaseDialog.OnMissCallback?,
                             onCancelCallback: GPBaseDialog.OnCancelCallback?) {
        AnalyticsManager.logEvent("show_color_size")
        GpColorSizeDialog(
            activity!!,
            listener,
            saveFunc,
        ).show(onMissCallback, onCancelCallback)
    }
    fun showLogoStyleDialog(
        activity: FragmentActivity?,
        editItem: WatermarkItem,
        listener: GpViewConvertListener,
        saveItemFunc: (WatermarkItem, Boolean) -> Unit,
        showPickerDialog: (() -> Unit)?,
        onMissCallback: GPBaseDialog.OnMissCallback?,
        onCancelCallback: GPBaseDialog.OnCancelCallback?

    ) {
        Log.d(TAG,"6666")
        GpLogoStyleDialog(
        activity!!,
        editItem,
        listener,
        saveItemFunc,
        ).show(onMissCallback, onCancelCallback,showPickerDialog)

    }

    fun showEditLogoDialog(
        activity: FragmentActivity?,
        editItem: WatermarkItem,
        listener: GpViewConvertListener,
        onChangeLogo: (WatermarkItem, Boolean) -> Unit,
        saveItemFunc: (WatermarkItem, Boolean) -> Unit,
        showPickerDialog: (() -> Unit)?,
        onCancelCallback: GPBaseDialog.OnCancelCallback?
    ) {

        GpLogoUploadDialog(
            activity!!,
            editItem,
            listener,
            onChangeLogo,
            saveItemFunc
        ).show(null, onCancelCallback,showPickerDialog)
    }
    fun showSearchLogoDialog(
        activity: FragmentActivity?,
        editItem: WatermarkItem,
        listener: GpViewConvertListener,
        onChangeLogo: (WatermarkItem, Boolean) -> Unit,
        saveItemFunc: (WatermarkItem, Boolean) -> Unit,
        showPickerDialog: (() -> Unit)?,
        onCancelCallback: GPBaseDialog.OnCancelCallback?
    ) {

        GpLogoSearchDialog(
            activity!!,
            editItem,
            listener,
            onChangeLogo,
            saveItemFunc
        ).show(null, onCancelCallback,showPickerDialog)
    }



    fun showWeatherStyleDialog(        activity: FragmentActivity?,
                                       editItem: WatermarkItem,
                                       listener: GpViewConvertListener,
                                       saveItemFunc: (WatermarkItem, Boolean) -> Unit,
                                       onCancelCallback: GPBaseDialog.OnCancelCallback?) {

        GpWeatherStyleDialog(
            activity!!,
            editItem,
            listener,
            saveItemFunc
        ).show(null, onCancelCallback)
    }
    fun showMapTypeDialog(
        activity: FragmentActivity?,
        editItem: WatermarkItem,
        listener: GpViewConvertListener,
        saveItemFunc: (WatermarkItem, Boolean) -> Unit,
        onCancelCallback: GPBaseDialog.OnCancelCallback?
    ) {
        AnalyticsManager.logEvent("show_map_type")
        GpMapTypeDialog(
            activity!!,
            editItem,
            listener,
            saveItemFunc
        ).show(null, onCancelCallback)
    }
    fun showAddressFormatDialog(
        activity: FragmentActivity?,
        editItem: WatermarkItem,
        listener: GpViewConvertListener,
        saveItemFunc: (WatermarkItem, Boolean) -> Unit,
        onCancelCallback: GPBaseDialog.OnCancelCallback?
    ) {
        AnalyticsManager.logEvent("show_address_format")
        GpAddressFormatDialog(
            activity!!,
            editItem,
            listener,
            saveItemFunc
        ).show(null, onCancelCallback)

    }
    fun showCoordinateFormatDialog(
        activity: FragmentActivity?,
        editItem: WatermarkItem,
        listener: GpViewConvertListener,
        saveItemFunc: (WatermarkItem, Boolean) -> Unit,
        onCancelCallback: GPBaseDialog.OnCancelCallback?
    ) {
        AnalyticsManager.logEvent("show_coordinate_format")
        GpCoordinateFormatDialog(
            activity!!,
            editItem,
            listener,
            saveItemFunc
        ).show(null, onCancelCallback)

    }
     fun showTimeFormatDialog(
        activity: FragmentActivity?,
        editItem: WatermarkItem,
        listener: GpViewConvertListener,
        saveItemFunc: (WatermarkItem, Boolean) -> Unit,
        onCancelCallback: GPBaseDialog.OnCancelCallback?
    ) {
         AnalyticsManager.logEvent("show_time_format")
        GpTimeFormatDialog(
            activity!!,
            editItem,
            listener,
            saveItemFunc
        ).show(null, onCancelCallback)

    }


    fun getFocusView(dialog: Dialog?): View? {
        if (dialog == null) {
            return null
        }
        if (dialog.window == null) {
            return null
        }
        return dialog.window!!.currentFocus
    }



}

