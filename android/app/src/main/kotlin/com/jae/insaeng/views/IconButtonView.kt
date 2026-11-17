package com.jae.insaeng.views

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.ImageProvider
import androidx.glance.action.action
import androidx.glance.appwidget.CircularProgressIndicator
import androidx.glance.appwidget.components.CircleIconButton
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.size
import androidx.glance.unit.ColorProvider
import com.jae.insaeng.R
import com.jae.insaeng.WidgetIcon
import com.jae.insaeng.WidgetNode

private val iconButtonSize = 48.dp

private val iconButtonSpinnerSize = 20.dp

@Composable
internal fun IconButtonView(node: WidgetNode, modifier: GlanceModifier) {
    val icon = WidgetIcon.of(node.string("icon")) ?: return
    val label = node.string("label")
    val color = GlanceTheme.colors.primary
    if (node.loading) {
        Box(modifier = modifier.size(iconButtonSize), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(modifier = GlanceModifier.size(iconButtonSpinnerSize), color = color)
        }
        return
    }
    val tap = node.tapAction()
    CircleIconButton(
        imageProvider = ImageProvider(icon.drawable),
        contentDescription = label,
        onClick = tap ?: action {},
        modifier = modifier,
        enabled = tap != null,
        backgroundColor = null,
        contentColor = if (tap != null) color else ColorProvider(R.color.widget_icon_disabled),
    )
}

internal val WidgetNode.loading: Boolean
    get() = boolean("loading") ?: false
