package com.jae.insaeng

import android.content.Context
import androidx.compose.runtime.Composable
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
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition

class GenericGlanceWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            GlanceTheme {
                Placeholder(snapshot(currentState()))
            }
        }
    }

    @Composable
    private fun Placeholder(snapshot: String?) {
        val context = LocalContext.current
        val message =
            if (snapshot == null) R.string.my_day_widget_loading else R.string.my_day_widget_label
        Box(
            modifier =
                GlanceModifier
                    .fillMaxSize()
                    .background(GlanceTheme.colors.widgetBackground)
                    .padding(16.dp),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = context.getString(message),
                style =
                    TextStyle(
                        color = GlanceTheme.colors.onSurface,
                        textAlign = TextAlign.Center,
                    ),
            )
        }
    }

    companion object {
        const val SNAPSHOT_KEY = "widget_snapshot_myDayWidget"

        fun snapshot(state: HomeWidgetGlanceState): String? =
            state.preferences.getString(SNAPSHOT_KEY, null)
    }
}
