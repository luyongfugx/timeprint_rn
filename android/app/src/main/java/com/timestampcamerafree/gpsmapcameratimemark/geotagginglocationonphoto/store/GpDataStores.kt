package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store

import android.os.Looper
import android.util.Log
import androidx.annotation.MainThread
import androidx.lifecycle.*
import androidx.lifecycle.Observer
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GPCollectionUtil
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpUiUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.ref.SkipMethod
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.ref.getCurrentTopStack
import io.reactivex.rxjava3.android.schedulers.AndroidSchedulers


import java.util.*
import java.util.concurrent.ConcurrentHashMap
import kotlin.collections.ArrayList

object GpDataStores:LifecycleEventObserver {
    private val TAG = "DataStores"
    private val mMap = ConcurrentHashMap<String, MutableMap<String, GpLiveData<Any?>>>()

    val mPendingObserverMap = ConcurrentHashMap<GpStoreKey, MutableList<in InnerObserver<*>>?>()

    fun <T> get(key: GpStoreKey, tClass:Class<T>):T? {
        var map = this.mMap[key.sourceKey];
        var o:Any? = if (GPCollectionUtil.isEmpty(map)) null else map?.get(key.rawKey)
        return if (o is LiveData<*>) {
            o = if (o.value is WrapData<*> ) (o.value as WrapData<*>).data else o.value
            if (isInstance(o, tClass)) o as T? else null
        } else {
            null
        }
    }

    fun <T> get(key: GpStoreKey):T? {
        val map = this.mMap[key.sourceKey]
        val o:MutableLiveData<Any?>? =
            if (GPCollectionUtil.isEmpty(map)) null else map?.get(key.rawKey)
        if (o == null || o.value == null) {
            return null
        }
        try {
            return if (o.value is WrapData<*> ) (o.value as WrapData<*>).data as T? else o.value  as T?

        } catch (e:Throwable) {
            e.printStackTrace()
        }
        return null
    }


    fun <T> get(rawKey:String, tClass:Class<T>):T? {
        return get(rawKey, ProcessLifecycleOwner.get(), tClass)
    }

    fun <T> get(rawKey:String, sourceLifeOwner:LifecycleOwner, tClass:Class<T>):T? {
        val key = GpStoreKey.valueOf(rawKey, sourceLifeOwner)
        var map = this.mMap[key.sourceKey];
        var o:Any? = if (GPCollectionUtil.isEmpty(map)) null else map?.get(key.rawKey)
        return if (o is LiveData<*>) {
            o = o.value
            if (isInstance(o, tClass)) o as T? else null
        } else {
            null
        }
    }


    @MainThread fun <T> put(rawKey:String, clazz:Class<T>, data:T?) {
        put(rawKey, ProcessLifecycleOwner.get(), clazz, data)
    }


    @MainThread
    fun <T> put(rawKey:String, sourceLifeOwner:LifecycleOwner, clazz:Class<T>, data:T?) {
        put(GpStoreKey.valueOf(rawKey, sourceLifeOwner), sourceLifeOwner, clazz, data)
    }


    @MainThread
    @SkipMethod
    fun <T> put(storeKey: GpStoreKey, sourceLifeOwner:LifecycleOwner, clazz:Class<T>, data:T?) {
        val stackTraceElement = getCurrentTopStack()
        if (GpUiUtils.isMainThread()) {
            innterPut(storeKey, data, sourceLifeOwner, clazz, stackTraceElement)
        } else {
            AndroidSchedulers.from(Looper.getMainLooper()).scheduleDirect {
                innterPut(storeKey, data, sourceLifeOwner, clazz, stackTraceElement)
            }
        }
    }


   @SkipMethod
    @MainThread fun <T> put(storeKey: GpStoreKey, sourceLifeOwner:LifecycleOwner, data:T?) {
        val stackTraceElement = getCurrentTopStack()
        if (GpUiUtils.isMainThread()) {
            innterPut(storeKey, data, sourceLifeOwner, null, stackTraceElement)
        } else {
            AndroidSchedulers.from(Looper.getMainLooper()).scheduleDirect {
                innterPut(storeKey, data, sourceLifeOwner, null, stackTraceElement)
            }
        }
    }


    @SkipMethod
    @MainThread fun <T> set(storeKey: GpStoreKey, sourceLifeOwner:LifecycleOwner, data:T?) {
        set(storeKey, sourceLifeOwner, null, data)
    }


    @MainThread
    @SkipMethod
    fun <T> set(rawKey:String, sourceLifeOwner:LifecycleOwner, clazz:Class<T>, data:T?) {
        set(GpStoreKey.valueOf(rawKey, sourceLifeOwner), sourceLifeOwner, clazz, data)
    }
    @MainThread
    @SkipMethod
    fun <T> set(storeKey: GpStoreKey, sourceLifeOwner:LifecycleOwner, clazz:Class<T>?, data:T?) {
        val stackTraceElement = getCurrentTopStack()
        if (GpUiUtils.isMainThread()) {
            innterSet(storeKey, data, sourceLifeOwner, clazz, stackTraceElement)
        } else {
            Log.e(TAG, "set: $storeKey warning , do with put")
            AndroidSchedulers.from(Looper.getMainLooper()).scheduleDirect {
                innterSet(storeKey, data, sourceLifeOwner, clazz, stackTraceElement)
            }
        }
    }

    private fun <T> innterPut(storeKey: GpStoreKey, data:T?, sourceLifeOwner:LifecycleOwner, clazz:Class<T>?, stackTraceEle:StackTraceElement) {
        val liveData = getLiveData(storeKey)
        cacheStackTraceEle(storeKey,stackTraceEle)
        liveData.postValue(data)
        sourceLifeOwner.lifecycle.addObserver(this) // sticky observer
        notifyStickObserve(liveData,storeKey, data, clazz, stackTraceEle)
    }

    private fun <T>notifyStickObserve(liveData:MutableLiveData<Any?>, storeKey: GpStoreKey, data:T?, clazz:Class<T>?, stackTraceEle:StackTraceElement){
         if (clazz == null) {
             stickyObserve(storeKey, liveData, stackTraceEle)
         } else {
             stickyObserve(storeKey, data, clazz, liveData, stackTraceEle)
         }
    }

    private fun <T> innterSet(storeKey: GpStoreKey, data:T?, sourceLifeOwner:LifecycleOwner, clazz:Class<T>?, stackTraceEle:StackTraceElement) {
        val liveData = getLiveData(storeKey)
        cacheStackTraceEle(storeKey,stackTraceEle)
        liveData.setValue(data)
        sourceLifeOwner.lifecycle.addObserver(this) // sticky observer
        notifyStickObserve(liveData,storeKey, data, clazz, stackTraceEle)

    }

    var cacheStackTraceEle = ConcurrentHashMap<GpStoreKey,StackTraceElement>()

    private fun cacheStackTraceEle(storeKey: GpStoreKey, stackTraceEle:StackTraceElement){
       cacheStackTraceEle[storeKey] = stackTraceEle

    }




   data class WrapData<T> (var stackTraceElement:StackTraceElement,var data :T)

    private fun <T> stickyObserve(storeKey: GpStoreKey, data:T?, clazz:Class<T>, liveData:MutableLiveData<Any?>, stackTraceEle:StackTraceElement) {
        mPendingObserverMap[storeKey]?.let {
            synchronized(mPendingObserverMap[storeKey]!!) {
            for (any in it) {
                if (isInstance(data, clazz)) {
                    val innerObserver = any as InnerObserver<Any?>
                    if (innerObserver.observeLifeOwner == null) {
                        try {
                            innerObserver?.originStackList?.add(stackTraceEle)
                        }catch (e:Throwable){
                            e.printStackTrace()
                        }
                        liveData.observeForever(innerObserver)
                    } else {
                        innerObserver.observeLifeOwner?.also {
                            try {
                                innerObserver?.originStackList?.add(stackTraceEle)
                            }catch (e:Throwable){
                                e.printStackTrace()
                            }
                            liveData.observe(it, innerObserver)
                        }
                    }
                }
            }
            it.clear()
        } }
    }

    private fun stickyObserve(storeKey: GpStoreKey, liveData:MutableLiveData<Any?>, stackTraceEle:StackTraceElement) {
        mPendingObserverMap[storeKey]?.let {
            synchronized(mPendingObserverMap[storeKey]!!) {
                for (any in it) {
                    val innerObserver = any as InnerObserver<Any?>
                    if (innerObserver.observeLifeOwner == null) {
                        innerObserver?.originStackList?.add(stackTraceEle)
                        liveData.observeForever(innerObserver)
                    } else {
                        innerObserver.observeLifeOwner?.also {
                            innerObserver?.originStackList?.add(stackTraceEle)
                            liveData.observe(it, innerObserver)
                        }
                    }
                }
                it.clear()
            }
        }
    }



 @MainThread
    @SkipMethod
    fun <T> syncPut(storeKey: GpStoreKey, sourceLifeOwner:LifecycleOwner, clazz:Class<T>, data:T?) {
        val values = values(storeKey.sourceKey)

        var liveData = values[storeKey.rawKey]
        if (liveData == null) {
            liveData = GpLiveData<Any?>()
        }
        liveData.setValue( data)
        values[storeKey.rawKey] = liveData
        sourceLifeOwner.lifecycle.addObserver(this)

        // sticky observer
        stickyObserve(storeKey, data, clazz, liveData, getCurrentTopStack())
    }




  @MainThread
    fun <T> observe(storeKey: GpStoreKey, clazz:Class<T>, observer:Observer<T>, observeLifeOwner:LifecycleOwner):MutableLiveData<T> {
       return addObserve(this.liveData<T>(storeKey, clazz), storeKey, observer, observeLifeOwner)

    }

 @MainThread
    fun <T> observe(storeKey: GpStoreKey, observer:Observer<T>, observeLifeOwner:LifecycleOwner):MutableLiveData<T> {
        val liveData = this.liveData<T>(storeKey, null)
        return addObserve(liveData, storeKey, observer, observeLifeOwner)
    }

    private fun <T> addObserve(
        liveData:MutableLiveData<T>?,
        storeKey: GpStoreKey,
        observer:Observer<T>,
        observeLifeOwner:LifecycleOwner?,
    ):MutableLiveData<T> {
        liveData?.let {
            if (observeLifeOwner != null) {
                it.observe(observeLifeOwner, observer)
            } else {
                it.observeForever(observer)
            }
            return it
        }
        var list = mPendingObserverMap[storeKey]
        if (list == null) {
            list = ArrayList<Any>()
            mPendingObserverMap[storeKey] = list
        }
        val paddingLiveData = MutableLiveData<T>()
        paddingLiveData.observeForever {
            try {
                observer.onChanged(it)
            }catch (e: Throwable){
                e.printStackTrace()
            }
        }
        mPendingObserverMap[storeKey]!!.add(InnerObserver(storeKey, observeLifeOwner,paddingLiveData)) //        Xlog.d("hanLog", "observe error, live obj is null, storeKey:${storeKey.rawKey} observer:${observer}")
        return paddingLiveData
    }



    override fun toString():String {
        return mMap.toString()
    }

    override fun onStateChanged(source:LifecycleOwner, event:Lifecycle.Event) {
        if (event == Lifecycle.Event.ON_DESTROY) {
            val sourceKey = source.toString()
            val liveDataMap:MutableMap<String, GpLiveData<Any?>>? = mMap[sourceKey]
            liveDataMap?.clear()
        }
    }

    fun getLiveData(storeKey: GpStoreKey):GpLiveData<Any?> {
        val values = values(storeKey.sourceKey) // key：LifecycleOwner 维护了一个map集合
        val liveData:GpLiveData<Any?> = values[storeKey.rawKey] ?: GpLiveData<Any?>()
        values[storeKey.rawKey] = liveData
        liveData.storeKey = storeKey
        return liveData
    }

    private fun values(sourceKey:String):MutableMap<String, GpLiveData<Any?>> {
        var values = mMap[sourceKey]
        if (values == null) {
            values = HashMap()
            mMap[sourceKey] = values
        }
        return values
    }

    private fun <T> liveData(storeKey: GpStoreKey, tClazz:Class<T>?):MutableLiveData<T>? {
        val o: MutableLiveData<Any?>? = getLiveData(storeKey)
        return if (o is MutableLiveData<*> && (o.value == null || (tClazz != null && isInstance(o.value, tClazz)))) o as MutableLiveData<T> else null
    }

    private fun <T> isInstance(o:Any?, clazz:Class<T>):Boolean {
        if (o == null) {
            return false
        }
        if (o is Byte && clazz == Byte::class.java) {
            return true
        }
        if (o is Short && clazz == Short::class.java) {
            return true
        }
        if (o is Long && clazz == Long::class.java) {
            return true
        }
        if (o is Int && clazz == Int::class.java) {
            return true
        }
        if (o is Float && clazz == Float::class.java) {
            return true
        }
        if (o is Double && clazz == Double::class.java) {
            return true;
        }
        if (o is Boolean && clazz == Boolean::class.java) {
            return true
        }

        return clazz.isInstance(o)
    }

    class InnerObserver<T>(var storeKey: GpStoreKey, var observeLifeOwner:LifecycleOwner?, var  paddingLiveData:MutableLiveData<T>):Observer<T> {

        var originStackList = Vector<StackTraceElement>()


        init { // todo 测试线程安全的问题
            observeLifeOwner?.lifecycle?.addObserver(LifecycleEventObserver { source, event ->
                if (event == Lifecycle.Event.ON_DESTROY) {
                    mPendingObserverMap[storeKey]?.remove(this)
                }
            })
        }

        override fun onChanged(t:T) {
            try {
                originStackList.clear()
                originStackList.add(cacheStackTraceEle.get(storeKey))
            } catch (e:Throwable) {
                e.printStackTrace()
            }
            if (Looper.getMainLooper() == Looper.myLooper()) {
                paddingLiveData.value = t
            } else {
                paddingLiveData.postValue(t)
            }
        }
    }
}