package com.jae.insaeng.views

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.ColorFilter
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.appwidget.cornerRadius
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.size
import com.jae.insaeng.WidgetIcon
import com.jae.insaeng.WidgetNode

private val iconButtonSize = 36.dp

private val iconSize = 20.dp

@Composable
internal fun IconButtonView(node: WidgetNode, modifier: GlanceModifier) {
    Box(
        modifier = modifier.size(iconButtonSize).cornerRadius(iconButtonSize / 2).tappable(node),
        contentAlignment = Alignment.Center,
    ) {
        Image(
            provider = ImageProvider(WidgetIcon.of(node.string("icon")).drawable),
            contentDescription = node.string("label"),
            modifier = GlanceModifier.size(iconSize),
            colorFilter = ColorFilter.tint(GlanceTheme.colors.onSurfaceVariant),
        )
    }
}
