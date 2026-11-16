package com.jae.insaeng.views

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.appwidget.CheckBox
import androidx.glance.appwidget.CircularProgressIndicator
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.jae.insaeng.WidgetNode
import com.jae.insaeng.WidgetSpacing
import com.jae.insaeng.WidgetTextStyle
import com.jae.insaeng.eventAction

private val trailingSize = 48.dp

private val spinnerSize = 20.dp

@Composable
internal fun CheckboxTileView(node: WidgetNode, modifier: GlanceModifier) {
    val emoji = node.string("emoji")
    val subtitle = node.string("subtitle")
    Row(
        modifier = modifier.fillMaxWidth().padding(vertical = WidgetSpacing.XS.size),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (emoji != null) {
            TileText(emoji, WidgetTextStyle.TITLE_LARGE, GlanceTheme.colors.onSurface)
        }
        Column(
            modifier =
                GlanceModifier
                    .defaultWeight()
                    .padding(start = if (emoji == null) 0.dp else WidgetSpacing.MD.size, end = WidgetSpacing.SM.size),
        ) {
            TileText(node.string("title").orEmpty(), WidgetTextStyle.BODY_LARGE, GlanceTheme.colors.onSurface)
            if (subtitle != null) {
                TileText(subtitle, WidgetTextStyle.BODY_MEDIUM, GlanceTheme.colors.onSurfaceVariant)
            }
        }
        if (node.boolean("busy") == true) {
            CircularProgressIndicator(
                modifier = GlanceModifier.size(spinnerSize),
                color = GlanceTheme.colors.primary,
            )
            Spacer(modifier = GlanceModifier.width(WidgetSpacing.SM.size))
        }
        Box(modifier = GlanceModifier.size(trailingSize), contentAlignment = Alignment.Center) {
            CheckBox(checked = node.boolean("checked") ?: false, onCheckedChange = node.eventAction())
        }
    }
}

@Composable
private fun TileText(text: String, style: WidgetTextStyle, color: ColorProvider) {
    Text(
        text = text,
        style = TextStyle(color = color, fontSize = style.size, fontWeight = style.weight),
        maxLines = 2,
    )
}
