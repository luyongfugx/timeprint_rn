package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils


import android.util.Log
import android.widget.Toast
import androidx.fragment.app.Fragment
import kotlinx.coroutines.*
import java.math.BigDecimal
import kotlin.coroutines.CoroutineContext
import kotlin.coroutines.EmptyCoroutineContext

/**
 *  扩展
 *
 */


fun Double.scale(newScale:Int,roundMode:Int = BigDecimal.ROUND_HALF_UP):Double{
    return BigDecimal.valueOf(this).setScale(newScale, roundMode).toDouble()
}

fun Float.scale(newScale:Int,roundMode:Int = BigDecimal.ROUND_HALF_UP):Double{
    return BigDecimal.valueOf(this.toDouble()).setScale(newScale, roundMode).toDouble()
}
fun Fragment.toast(message:String){
    context?.let {
        Toast.makeText(it,message,Toast.LENGTH_SHORT).show()
    }
}

fun Float.toPxInt():Int{
    return GpUiUtils.dp2px(this)
}
fun CoroutineScope.launchSafe(
    context:CoroutineContext = EmptyCoroutineContext,
    start:CoroutineStart = CoroutineStart.DEFAULT,
    block:suspend CoroutineScope.() -> Unit,
): Job {
    val exceptionHandler = CoroutineExceptionHandler { coroutineContext, throwable ->
        Log.e("launchSafe", "coroutineContext=${coroutineContext}", throwable)
    }
    val newContext = context + exceptionHandler
    return launch(newContext, start, block)
}





