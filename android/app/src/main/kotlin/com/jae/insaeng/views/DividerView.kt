package com.jae.insaeng.views

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height

private val dividerHeight = 16.dp

private val dividerThickness = 1.dp

@Composable
internal fun DividerView(modifier: GlanceModifier) {
    Box(
        modifier = modifier.fillMaxWidth().height(dividerHeight),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier =
                GlanceModifier
                    .fillMaxWidth()
                    .height(dividerThickness)
                    .background(GlanceTheme.colors.surfaceVariant),
        ) {}
    }
}
