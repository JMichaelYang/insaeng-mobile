package com.jae.insaeng

import androidx.work.NetworkType
import org.junit.Assert.assertEquals
import org.junit.Test

class WidgetEventWorkerTest {
    private val uri = "insaeng://widget/event?flavor=prod&page=myDayWidget&node=refresh&event=onTap"

    private val request = WidgetEventWorker.request(uri)

    @Test
    fun runsTheWidgetEventWorker() {
        assertEquals(WidgetEventWorker::class.java.name, request.workSpec.workerClassName)
    }

    @Test
    fun carriesTheEventUri() {
        assertEquals(uri, request.workSpec.input.getString(WidgetEventWorker.URI_KEY))
    }

    @Test
    fun holdsTheJobUntilTheNetworkIsConnected() {
        assertEquals(NetworkType.CONNECTED, request.workSpec.constraints.requiredNetworkType)
    }

    @Test
    fun startsTheDartEntrypointInBootstrap() {
        assertEquals("package:insaeng/bootstrap.dart", WidgetEventEngine.ENTRYPOINT_LIBRARY)
        assertEquals("widgetEventMain", WidgetEventEngine.ENTRYPOINT)
    }
}
