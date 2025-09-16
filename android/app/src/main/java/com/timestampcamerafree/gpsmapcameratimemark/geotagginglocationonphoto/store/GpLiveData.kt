package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store

import android.util.Log
import androidx.lifecycle.*
import io.reactivex.rxjava3.disposables.Disposable


class GpLiveData<T> : MutableLiveData<T> {
    var storeKey: GpStoreKey? = null
    val TAG = "GpLiveData"
    constructor(value: T) : super(value) {}
    constructor() {}
    private val observers: MutableList<InnerObserver<T>> = ArrayList()

    private var setStackEle:Array<StackTraceElement>? = null

    override fun setValue(value: T) {
        super.setValue(value)
        setStackEle = Throwable().stackTrace
        var tempCount = postEventCount
        if (tempCount > 0){
            synchronized(postEventCountSync){
                if (postEventCount > 0) {
                    tempCount = postEventCount
                }
                postEventCount = 0
            }
            for (index in 0 until tempCount){
                dispatchObservers(value)
            }
        }else {
            dispatchObservers(value)
        }
    }

    override fun getValue(): T? {
        return super.getValue()
    }


    @Volatile
    private var postEventCount:Int = 0
    private var postEventCountSync = Any()
    private var postStackEle:Array<StackTraceElement>? = null
    override fun postValue(value: T) {
        synchronized(postEventCountSync){
            postEventCount++
        }
        postStackEle  = Throwable().stackTrace
        super.postValue(value)
    }

    private fun dispatchObservers(value: T) {
        synchronized(observers) {
            try {
                val tempOs = ArrayList<InnerObserver<T>>()
                tempOs.addAll(observers)

                tempOs.forEach { observer->
                    observer.fromPostStackEle = postStackEle
                    observer.fromSetStackEle = setStackEle

                }
            }catch (e:Throwable){
                e.printStackTrace()
                Log.e(TAG,"dispatch $value error $e")
            }
        }
    }

    override fun observeForever(observer: Observer<in T>) {
        observerStickEvent(observer as Observer<T>)
    }

    override fun observe(owner: LifecycleOwner, observer: Observer<in T>) {
        super.observe(owner, addObserverSync(observer as Observer<T>).also { it.isOriginLiveDataObserver = true })
    }

    fun observe(owner: LifecycleOwner, observer: EqualObserver<in T>) {
        observe(owner, observer as Observer<T>)
    }

    private fun convertDispose(observer: InnerObserver<T>): Disposable {
        return object : Disposable {
            var isDisposable = false
            override fun dispose() {
                if (isDisposable){
                    return
                }
                isDisposable = true
                removeObserver(observer)
            }

            override fun isDisposed(): Boolean {
                return isDisposable
            }
        }
    }



    override fun removeObserver(observer: Observer<in T>) {
        super.removeObserver(observer)
        if (observer is InnerObserver){
            removeObserverSync(observer as InnerObserver<T>)
        }
    }

    private fun removeObserverSync(observer: InnerObserver<T>) {
        synchronized(observers) {
            observers.remove(observer)
            observer.dispose()
        }
    }


    private fun addObserverSync(observer: Observer<T>): InnerObserver<T> {
        val tInnerObserver = InnerObserver(observer)
        synchronized(observers) { observers.add(tInnerObserver) }
        return tInnerObserver
    }

    fun observeEvent(observer: Observer<T>): Disposable {
        val innerObserver = addObserverSync(observer)
        return convertDispose(innerObserver)
    }



    private fun observerStickEvent(observer: Observer<T>): Disposable {
        val value = getValue()
        val innerObserver = addObserverSync(observer)
        if (value != null) {
            innerObserver.onChanged(value)
        }
        return convertDispose(innerObserver)
    }






    interface EqualObserver<T> : Observer<T> {
        fun onEqual(value: T)
    }

    private class InnerObserver<T>(observer: Observer< T>) : Observer<T> {
        var lastValue: T? = null
        var hasChanged = false
        var realObserver: Observer< T>? = null
        var isOriginLiveDataObserver = false
        init {
            realObserver = observer
        }

        var fromPostStackEle:Array<StackTraceElement>? = null
        var fromSetStackEle :Array<StackTraceElement>? = null
        var stackEle = Throwable().stackTrace
        var isDispose = false

        override fun onChanged(t: T) {
            try {
                if (isDispose) {
                    return
                }
                if (realObserver is EqualObserver<*>) {
                    if (!hasChanged) {
                        realObserver?.onChanged(t)
                    } else if (lastValue === t && realObserver is EqualObserver<T>) {
                        (realObserver as EqualObserver<T>).onEqual(t)
                    } else if (lastValue != null && t != null) {
                        if (lastValue == t && realObserver is EqualObserver<T>) {
                            (realObserver as EqualObserver<T>).onEqual(t)
                        } else {
                            realObserver?.onChanged(t)
                        }
                    } else {
                        realObserver?.onChanged(t)
                    }
                } else {
                    realObserver?.onChanged(t)
                }
            }catch (e:Throwable){
            }

            hasChanged = true
            lastValue = t
        }

        fun dispose(){
            isDispose = true
            realObserver =  null
            lastValue = null
            hasChanged = false
        }
    }
}