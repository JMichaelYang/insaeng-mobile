package com.jae.insaeng.views

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.ColorFilter
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.appwidget.CircularProgressIndicator
import androidx.glance.appwidget.components.CircleIconButton
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.size
import com.jae.insaeng.WidgetIcon
import com.jae.insaeng.WidgetNode

private val iconButtonSize = 48.dp

private val iconButtonSpinnerSize = 20.dp

private const val disabledIconAlpha = 0.38f

@Composable
internal fun IconButtonView(node: WidgetNode, modifier: GlanceModifier) {
    val icon = WidgetIcon.of(node.string("icon")) ?: return
    val label = node.string("label")
    val color = GlanceTheme.colors.primary
    val action = if (node.loading) null else node.tapAction()
    if (action != null) {
        CircleIconButton(
            imageProvider = ImageProvider(icon.drawable),
            contentDescription = label,
            onClick = action,
            modifier = modifier,
            backgroundColor = null,
            contentColor = color,
        )
        return
    }
    Box(modifier = modifier.size(iconButtonSize), contentAlignment = Alignment.Center) {
        if (node.loading) {
            CircularProgressIndicator(modifier = GlanceModifier.size(iconButtonSpinnerSize), color = color)
        } else {
            Image(
                provider = ImageProvider(icon.drawable),
                contentDescription = label,
                alpha = disabledIconAlpha,
                colorFilter = ColorFilter.tint(GlanceTheme.colors.onSurface),
            )
        }
    }
}

internal val WidgetNode.loading: Boolean
    get() = boolean("loading") ?: false
