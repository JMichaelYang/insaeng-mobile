package com.jae.insaeng.views

import androidx.compose.runtime.Composable
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.action.clickable
import androidx.glance.layout.Alignment
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxWidth
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import com.jae.insaeng.WidgetNode
import com.jae.insaeng.WidgetTextStyle

@Composable
internal fun DayPickerView(node: WidgetNode, modifier: GlanceModifier) {
    val style = WidgetTextStyle.TITLE_MEDIUM
    val tap = node.tapAction()
    Row(modifier = modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        node.previousChevron?.let { IconButtonView(it, GlanceModifier) }
        Text(
            text = node.string("label").orEmpty(),
            modifier = tap?.let { GlanceModifier.defaultWeight().clickable(it) } ?: GlanceModifier.defaultWeight(),
            style =
                TextStyle(
                    color = if (tap != null) GlanceTheme.colors.primary else GlanceTheme.colors.onSurface,
                    fontSize = style.size,
                    fontWeight = style.weight,
                    textAlign = TextAlign.Center,
                ),
            maxLines = 1,
        )
        node.nextChevron?.let { IconButtonView(it, GlanceModifier) }
    }
}

internal val WidgetNode.previousChevron: WidgetNode?
    get() = chevron(0)

internal val WidgetNode.nextChevron: WidgetNode?
    get() = chevron(1)

private fun WidgetNode.chevron(index: Int): WidgetNode? = children.getOrNull(index)?.takeIf { it.type == "iconButton" }
