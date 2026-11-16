package com.jae.insaeng.views

import androidx.compose.runtime.Composable
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.jae.insaeng.WidgetNode
import com.jae.insaeng.WidgetTextStyle

@Composable
internal fun TextView(node: WidgetNode, modifier: GlanceModifier) {
    val style = WidgetTextStyle.of(node.string("style"))
    Text(
        text = node.string("text").orEmpty(),
        modifier = modifier,
        style =
            TextStyle(
                color = GlanceTheme.colors.onSurface,
                fontSize = style.size,
                fontWeight = style.weight,
            ),
    )
}
