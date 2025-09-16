package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models
import java.util.*


class BaseFiled<T> {

    constructor(value: T) {
        this.value = value;
    }

    private var getCnt = 0
    open var _changed = true
        set(value) {
            if (value == true) {
                getCnt = 0
            }
            field = value
        }
    open var value: T? = null
        set(value) {
            val changed = !Objects.equals(field, value)
            if (!changed && _changed) {
                field = value
                return
            }
            _changed = changed
            field = value
            if (_changed) {
                getCnt = 0
            }
            field = value
        }

    private fun updateChangeStatus() {
        if (_changed && getCnt > 0) {
            _changed = false
            getCnt = 0
        }
        if (_changed) {
            getCnt++
        }
    }

    fun ifChanged(): BaseFiled<T>? {
        updateChangeStatus()
        if (!_changed) {
            return null
        }
        return this
    }
}