package com.jae.insaeng

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.LocalContext
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import com.jae.insaeng.views.WidgetNodeView
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition

class GenericGlanceWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val json = snapshot(currentState())
            val snapshot = remember(json) { json?.let(WidgetSnapshot::decode) }
            GlanceTheme {
                if (snapshot == null) Placeholder() else Content(snapshot)
            }
        }
    }

    @Composable
    private fun Content(snapshot: WidgetSnapshot) {
        Box(modifier = frameModifier()) {
            WidgetNodeView(snapshot.root, GlanceModifier.fillMaxSize())
        }
    }

    @Composable
    private fun Placeholder() {
        val context = LocalContext.current
        Box(modifier = frameModifier(), contentAlignment = Alignment.Center) {
            Text(
                text = context.getString(R.string.my_day_widget_loading),
                style =
                    TextStyle(
                        color = GlanceTheme.colors.onSurface,
                        textAlign = TextAlign.Center,
                    ),
            )
        }
    }

    @Composable
    private fun frameModifier(): GlanceModifier =
        GlanceModifier
            .fillMaxSize()
            .background(GlanceTheme.colors.widgetBackground)
            .padding(16.dp)

    companion object {
        const val SNAPSHOT_KEY = "widget_snapshot_myDayWidget"

        fun snapshot(state: HomeWidgetGlanceState): String? =
            state.preferences.getString(SNAPSHOT_KEY, null)
    }
}
