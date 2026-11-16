package com.jae.insaeng

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.glance.GlanceId
import androidx.glance.action.Action
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import java.net.URLEncoder

val LocalWidgetPageId = staticCompositionLocalOf { "" }

object WidgetEventUri {
    private const val BASE = "insaeng://widget/event"

    fun build(flavor: String, pageId: String, tap: WidgetTap.Event): String =
        listOf("flavor" to flavor, "page" to pageId, "node" to tap.nodeId, "event" to tap.event)
            .joinToString(separator = "&", prefix = "$BASE?") { (key, value) -> "$key=${encode(value)}" }

    private fun encode(value: String): String = URLEncoder.encode(value, Charsets.UTF_8.name())
}

class WidgetEventAction : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        val uri = parameters[uriKey] ?: return
        HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse(uri)).send()
    }

    companion object {
        val uriKey = ActionParameters.Key<String>("uri")
    }
}

@Composable
fun WidgetNode.eventAction(): Action? {
    val event = tap as? WidgetTap.Event ?: return null
    val uri = WidgetEventUri.build(BuildConfig.FLAVOR, LocalWidgetPageId.current, event)
    return actionRunCallback<WidgetEventAction>(actionParametersOf(WidgetEventAction.uriKey to uri))
}
