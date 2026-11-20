package com.jae.insaeng.views

import androidx.annotation.DrawableRes
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.ColorFilter
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.Action
import androidx.glance.action.clickable
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
import com.jae.insaeng.R
import com.jae.insaeng.WidgetNode
import com.jae.insaeng.WidgetSpacing
import com.jae.insaeng.WidgetTextStyle
import com.jae.insaeng.eventAction

private val trailingSize = 48.dp

private val checkboxSize = 24.dp

private val spinnerSize = 20.dp

@Composable
internal fun CheckboxTileView(node: WidgetNode, modifier: GlanceModifier) {
    val emoji = node.string("emoji")
    val subtitle = node.string("subtitle")
    val busy = node.boolean("busy") ?: false
    val action = node.eventAction()
    val rowModifier = if (busy || action == null) modifier else modifier.clickable(action)
    Row(
        modifier = rowModifier.fillMaxWidth().padding(vertical = WidgetSpacing.XS.size),
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
        if (busy) {
            CircularProgressIndicator(
                modifier = GlanceModifier.size(spinnerSize),
                color = GlanceTheme.colors.primary,
            )
            Spacer(modifier = GlanceModifier.width(WidgetSpacing.SM.size))
        }
        Box(modifier = GlanceModifier.size(trailingSize), contentAlignment = Alignment.Center) {
            CheckboxIcon(node, busy, action)
        }
    }
}

private enum class CheckboxState(@DrawableRes val drawable: Int, val description: String) {
    UNCHECKED(R.drawable.ic_checkbox_unchecked, "Not checked"),
    CHECKED(R.drawable.ic_checkbox_checked, "Checked"),
    DASHED(R.drawable.ic_checkbox_dash, "Checked"),
    ;

    val color: ColorProvider
        @Composable get() =
            when (this) {
                UNCHECKED -> GlanceTheme.colors.onSurfaceVariant
                CHECKED -> GlanceTheme.colors.primary
                DASHED -> GlanceTheme.colors.error
            }

    companion object {
        fun of(node: WidgetNode): CheckboxState {
            val checked = node.boolean("checked") ?: false
            return when {
                !checked -> UNCHECKED
                node.string("mark") == "dash" -> DASHED
                else -> CHECKED
            }
        }
    }
}

@Composable
private fun CheckboxIcon(node: WidgetNode, busy: Boolean, action: Action?) {
    val state = CheckboxState.of(node)
    val size = GlanceModifier.size(checkboxSize)
    Image(
        provider = ImageProvider(state.drawable),
        contentDescription = state.description,
        modifier = if (busy || action == null) size else size.clickable(action),
        colorFilter = ColorFilter.tint(if (busy) ColorProvider(R.color.widget_icon_disabled) else state.color),
    )
}

@Composable
private fun TileText(text: String, style: WidgetTextStyle, color: ColorProvider) {
    Text(
        text = text,
        style = TextStyle(color = color, fontSize = style.size, fontWeight = style.weight),
        maxLines = 2,
    )
}
