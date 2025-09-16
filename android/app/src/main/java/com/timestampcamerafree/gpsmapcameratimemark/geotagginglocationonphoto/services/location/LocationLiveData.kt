package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.location


import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.GpLocationInfo
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.LocationInfoData

import io.reactivex.rxjava3.core.ObservableEmitter
import io.reactivex.rxjava3.disposables.Disposable
import java.util.*

class LocationLiveData(val type:LocationObserverType, var oldLocationInfo: GpLocationInfo<LocationInfoData>?, // 上次的定位信息（经纬度定位成功就刷新
                       oldPlaceLocationInfo:GpLocationInfo<LocationInfoData>?,
                       val emitter: ObservableEmitter<GpLocationInfo<LocationInfoData>>,
                       private val refreshStrategy: GpLocationStrategy){
    var parentType:LocationObserverType? = null
    var parentObserver:LocationLiveData? = null
    var disposable: Disposable? = null
    private val children = LinkedList<LocationLiveData>()
    // 上次的地点信息，用于地点更新策略（地点列表获取成功刷新
    var oldPlaceLocationInfo:GpLocationInfo<LocationInfoData>?
    get() { // 若有依赖的监听，使用它的上次的地点信息
        return if (hasParentObserver()){
            parentObserver!!.oldPlaceLocationInfo
        }else{
            field
        }
    }

    init {
        this.oldPlaceLocationInfo = oldPlaceLocationInfo
    }

    fun addChild(child:LocationLiveData):Boolean{
        // TODO 处理重复添加
        return children.add(child)
    }

    fun disposeChildren(){
        children.forEach {
            if (it.getOriginalRefreshStrategy() == EmptyRefreshStrategy){ // 没有独立刷新策略的去掉
                it.disposable?.dispose()
            }
        }
    }

    private fun hasParentObserver() = parentObserver?.emitter?.isDisposed == false

    private fun getOriginalRefreshStrategy() = refreshStrategy

    fun getRefreshStrategy():GpLocationStrategy{
        var root:LocationLiveData = this
        while (root.hasParentObserver()){
            root = root.parentObserver!!
        }
        return root.refreshStrategy
    }

    override fun toString(): String {
        return type.toString()
    }

}
// 定位监听的类型
enum class LocationObserverType{
    MAIN,
}