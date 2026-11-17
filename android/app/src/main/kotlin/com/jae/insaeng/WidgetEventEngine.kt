package com.jae.insaeng

import android.content.Context
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.coroutines.resume
import kotlin.time.Duration

object WidgetEventEngine {
    const val CHANNEL = "com.jae.insaeng/widget_event"
    const val HANDLE_METHOD = "handle"
    const val READY_METHOD = "ready"
    const val ENTRYPOINT_LIBRARY = "package:insaeng/bootstrap.dart"
    const val ENTRYPOINT = "widgetEventMain"

    private var session: Session? = null

    private class Session(val engine: FlutterEngine, val channel: MethodChannel, val ready: CompletableDeferred<Unit>)

    suspend fun dispatch(context: Context, uri: String, timeout: Duration): Boolean =
        withContext(Dispatchers.Main) {
            val current = session ?: start(context.applicationContext).also { session = it }
            val answered =
                withTimeoutOrNull(timeout) {
                    current.ready.await()
                    current.channel.handle(uri)
                }
            if (answered == null && session === current) {
                session = null
                current.engine.destroy()
            }
            answered ?: false
        }

    private fun start(context: Context): Session {
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(context)
        loader.ensureInitializationComplete(context, null)
        val engine = FlutterEngine(context)
        val ready = CompletableDeferred<Unit>()
        val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            if (call.method == READY_METHOD) {
                ready.complete(Unit)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(loader.findAppBundlePath(), ENTRYPOINT_LIBRARY, ENTRYPOINT),
        )
        return Session(engine, channel, ready)
    }

    private suspend fun MethodChannel.handle(uri: String): Boolean =
        suspendCancellableCoroutine { continuation ->
            invokeMethod(
                HANDLE_METHOD,
                uri,
                object : MethodChannel.Result {
                    override fun success(result: Any?) = continuation.resume(true)

                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) =
                        continuation.resume(true)

                    override fun notImplemented() = continuation.resume(false)
                },
            )
        }
}
