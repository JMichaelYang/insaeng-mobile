package com.jae.insaeng.views

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.ColorFilter
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.ImageProvider
import androidx.glance.Visibility
import androidx.glance.appwidget.CircularProgressIndicator
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import androidx.glance.visibility
import com.jae.insaeng.R
import com.jae.insaeng.WidgetButtonVariant
import com.jae.insaeng.WidgetNode
import com.jae.insaeng.WidgetTextStyle

private val buttonHorizontalPadding = 24.dp

private val textButtonHorizontalPadding = 12.dp

private val buttonVerticalPadding = 10.dp

private val buttonSpinnerSize = 18.dp

@Composable
internal fun ButtonView(node: WidgetNode, modifier: GlanceModifier) {
    val variant = WidgetButtonVariant.of(node.string("variant"))
    val loading = node.boolean("loading") ?: false
    val content = buttonContentColor(variant)
    val style = WidgetTextStyle.LABEL_LARGE
    Box(
        modifier =
            buttonBackground(modifier, variant)
                .padding(
                    horizontal =
                        if (variant == WidgetButtonVariant.TEXT) textButtonHorizontalPadding else buttonHorizontalPadding,
                    vertical = buttonVerticalPadding,
                ),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = node.string("label").orEmpty(),
            modifier = if (loading) GlanceModifier.visibility(Visibility.Invisible) else GlanceModifier,
            style = TextStyle(color = content, fontSize = style.size, fontWeight = style.weight),
            maxLines = 1,
        )
        if (loading) {
            CircularProgressIndicator(modifier = GlanceModifier.size(buttonSpinnerSize), color = content)
        }
    }
}

@Composable
private fun buttonContentColor(variant: WidgetButtonVariant): ColorProvider =
    when (variant) {
        WidgetButtonVariant.PRIMARY -> GlanceTheme.colors.onPrimary
        WidgetButtonVariant.SECONDARY, WidgetButtonVariant.TEXT -> GlanceTheme.colors.primary
    }

@Composable
private fun buttonBackground(modifier: GlanceModifier, variant: WidgetButtonVariant): GlanceModifier =
    when (variant) {
        WidgetButtonVariant.PRIMARY ->
            modifier.background(
                ImageProvider(R.drawable.widget_button_filled),
                colorFilter = ColorFilter.tint(GlanceTheme.colors.primary),
            )
        WidgetButtonVariant.SECONDARY ->
            modifier.background(
                ImageProvider(R.drawable.widget_button_outline),
                colorFilter = ColorFilter.tint(GlanceTheme.colors.outline),
            )
        WidgetButtonVariant.TEXT -> modifier
    }
