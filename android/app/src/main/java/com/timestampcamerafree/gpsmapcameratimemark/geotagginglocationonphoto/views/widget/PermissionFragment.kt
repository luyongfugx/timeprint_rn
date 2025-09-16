package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget

import android.os.Bundle
import androidx.fragment.app.Fragment
import androidx.lifecycle.Lifecycle

class PermissionFragment : Fragment() {
    private var paddingRequest: MutableList<Runnable> = ArrayList()
    private var PERMISSION_CODE = 44
    private var requestPermissionFlag = false
    private var requestResultFlag = false

    var permissionCallback: ((Array<out String>, IntArray) -> Unit)? = null
    override fun onActivityCreated(savedInstanceState: Bundle?) {
        super.onActivityCreated(savedInstanceState)
        paddingRequest.runAndRemove()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (PERMISSION_CODE == requestCode) {
            requestResultFlag = true

            permissionCallback?.invoke(permissions, grantResults)
        }
    }

    override fun onResume() {
        super.onResume()
        if (requestPermissionFlag && requestResultFlag){
            // normal
            requestPermissionFlag = false
            requestResultFlag = false
        } else if (requestPermissionFlag && !requestResultFlag){
            requestPermissionFlag = false
        }

    }
    fun postRequestPermission(ps: Array<String>) {
        try {
            if (lifecycle.currentState.ordinal == Lifecycle.State.INITIALIZED.ordinal) {
                paddingRequest.add(Runnable {
                    requestPermissionFlag = true
                    requestPermissions(ps, PERMISSION_CODE)
                })
            } else {
                requestPermissionFlag = true
                requestPermissions(ps, PERMISSION_CODE)
            }
        } catch (e: Throwable) {
            e.printStackTrace()
        }
    }

    override fun shouldShowRequestPermissionRationale(permission: String): Boolean {
        return super.shouldShowRequestPermissionRationale(permission)
    }


    fun MutableList<Runnable>.runAndRemove() {
        val iterator = this.iterator()
        while (iterator.hasNext()) {
            val next = iterator.next()
            next.run()
            iterator.remove()
        }
    }
}