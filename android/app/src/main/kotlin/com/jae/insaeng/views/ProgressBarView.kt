package com.jae.insaeng.views

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.appwidget.LinearProgressIndicator
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import com.jae.insaeng.WidgetNode

private val progressHeight = 8.dp

@Composable
internal fun ProgressBarView(node: WidgetNode, modifier: GlanceModifier) {
    LinearProgressIndicator(
        progress = node.progress,
        modifier = modifier.fillMaxWidth().height(progressHeight),
        color = GlanceTheme.colors.primary,
        backgroundColor = GlanceTheme.colors.surfaceVariant,
    )
}

internal val WidgetNode.progress: Float
    get() {
        val max = int("max") ?: 0
        if (max <= 0) return 0f
        return ((int("value") ?: 0).toFloat() / max).coerceIn(0f, 1f)
    }
