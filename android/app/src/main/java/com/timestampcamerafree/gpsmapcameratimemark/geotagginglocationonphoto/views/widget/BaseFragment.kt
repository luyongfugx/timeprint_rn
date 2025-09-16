package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.inputmethod.InputMethodManager
import androidx.appcompat.app.ActionBar
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import io.reactivex.rxjava3.disposables.CompositeDisposable
import io.reactivex.rxjava3.disposables.Disposable


/**
 *  fragment 基础类
 *
 */
abstract class BaseFragment : Fragment() {

    private var activity: Activity? = null
    private val compositeDisposable: CompositeDisposable? = CompositeDisposable()
    private val disposableList: MutableList<Disposable>? = ArrayList()


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setHasOptionsMenu(true)
    }

    override fun onActivityCreated(savedInstanceState: Bundle?) {
        super.onActivityCreated(savedInstanceState)
    }

    override fun onPause() {
        super.onPause()
        hideKeyboard()
    }

    override fun onResume() {
        super.onResume()
    }

    override fun onStart() {
        super.onStart()
    }

    override fun onStop() {
        super.onStop()
        removeAllDisposable()
    }

    override fun onDestroy() {
        super.onDestroy()
        removeAllDisposable()
    }

    override fun onAttach(context: Context) {
        super.onAttach(context)
        if (context is Activity) {
            activity = context
        }
    }

    override fun onDetach() {
        activity = null
        super.onDetach()
    }

    abstract fun onBackPressed()

    protected fun showLoadingDialog() {
//        if (loadingDialog == null) {
//            loadingDialog = LoadingDialog()
//            loadingDialog.show(this)
//        }
    }

    protected fun hideLoadingDialog() {
//        if (loadingDialog != null) {
//            loadingDialog.dismissAllowingStateLoss()
//            loadingDialog = null
//        }
    }

    fun hideKeyboard() {
        if (view == null) {
            return
        }
        val view = this.requireView().findFocus() //getCurrentFocus();
        if (view != null && getActivity() != null) {
            val imm =
                requireActivity().getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
            imm.hideSoftInputFromWindow(view.windowToken, 0)
        }
    }

    protected fun startActivity(cls: Class<out Activity?>?) {
        val intent = Intent(this.getActivity(), cls)
        startActivity(intent)
    }

    protected val supportActionBar: ActionBar?
        get() {
            if (activity != null && activity is AppCompatActivity) {
                return (activity as AppCompatActivity).supportActionBar
            }
            return null
        }

    fun addDisposable(disposable: Disposable) {
        if (!disposable.isDisposed) {
            compositeDisposable!!.add(disposable)
            disposableList!!.add(disposable)
        }
        checkDisposableList()
    }

    fun checkDisposableList() {
        val it = disposableList!!.iterator()
        while (it.hasNext()) {
            val d = it.next()
            if (d.isDisposed) {
                compositeDisposable!!.remove(d)
                it.remove()
            }
        }
    }

    fun removeAllDisposable() {
        if (disposableList == null || disposableList.size == 0 || compositeDisposable == null || compositeDisposable.size() == 0) {
            return
        }
        val it = disposableList.iterator()
        while (it.hasNext()) {
            val d = it.next()
            if (!d.isDisposed) {
                d.dispose()
            }
            compositeDisposable.remove(d)
            it.remove()
        }

        compositeDisposable.clear()
        disposableList.clear()
    }
}
