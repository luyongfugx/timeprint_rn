package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils


import io.reactivex.rxjava3.core.Observable
import io.reactivex.rxjava3.core.Single
import io.reactivex.rxjava3.disposables.CompositeDisposable
import io.reactivex.rxjava3.disposables.Disposable
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.CoroutineContext
import kotlin.coroutines.EmptyCoroutineContext
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
//
//fun <T> Single<T>.toSuspend():suspend () -> T{
//    return suspend {
//        suspendCancellableCoroutine<T> { cancellableContinuation ->
//            val disposable = this.subscribe({
//                cancellableContinuation.resume(it)
//            },{
//                cancellableContinuation.resumeWithException(it)
//            })
//            cancellableContinuation.invokeOnCancellation {
//                disposable.dispose()
//            }
//        }
//    }
//}
//fun <T> Observable<T>.toSuspend(): suspend () -> T {
//    return suspend {
//        suspendCancellableCoroutine<T> { cancellableContinuation ->
//            val disposable = this.subscribe({
//                cancellableContinuation.resume(it)
//            },{
//                cancellableContinuation.resumeWithException(it)
//            })
//            cancellableContinuation.invokeOnCancellation {
//                disposable.dispose()
//            }
//        }
//    }
//}
//
//suspend fun <T> Single<T>.toSuspendAndInvoke():T{
//    return toSuspend().invoke()
//}
//
//suspend fun <T> Observable<T>.toSuspendAndInvoke():T{
//    return toSuspend().invoke()
//}

//suspend fun <T> Observable<T>.async(context: CoroutineContext = EmptyCoroutineContext):Deferred<T> = coroutineScope {
//    async(context) { this@async.toSuspendAndInvoke() }
//}

fun Disposable.addTo(compositeDisposable: CompositeDisposable){
    compositeDisposable.add(this)
}

operator fun CompositeDisposable.plusAssign(disposable: Disposable){
    add(disposable)
}