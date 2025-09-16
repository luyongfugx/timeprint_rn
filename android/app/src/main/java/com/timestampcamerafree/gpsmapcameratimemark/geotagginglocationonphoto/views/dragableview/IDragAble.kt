package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.dragableview

import android.view.View;

/**
 * 拖动接口
 * waynelu
 */
public interface IDragAble {

    //    var dragable: Boolean
    fun getAngle(): Int

    fun getView(): View

    fun enableRotate(enable: Boolean);

    fun enableRotate(): Boolean;

    fun dragEnable():Boolean

}