package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.ref

@Target(AnnotationTarget.FUNCTION)
@Retention
annotation class SkipMethod

private const val TAG = "ClassUtils"


fun hasAnnotationStackMethod(className:String, methodName:String, annotationName:Class<*>):Boolean {
    val forName = Class.forName(className)
    val method = forName.declaredMethods.find { it.name.equals(methodName) }
    val findAnnotation = method?.annotations?.find { it.annotationClass.qualifiedName.equals(annotationName.name) }
    return findAnnotation != null
}

@SkipMethod
fun getCurrentTopStack():StackTraceElement {
      val stackTrace = Thread.currentThread().stackTrace
      var startRevCallMethod = false
      return stackTrace.find {
          val hasAnnotationStackMethod =
              hasAnnotationStackMethod(it.className, it.methodName, SkipMethod::class.java)
          if (!startRevCallMethod && hasAnnotationStackMethod) {
              startRevCallMethod = true
          } else if (startRevCallMethod&& !hasAnnotationStackMethod) {
              return@find true
          }
          return@find false
      } ?: StackTraceElement("", "", "", 0)
  }

