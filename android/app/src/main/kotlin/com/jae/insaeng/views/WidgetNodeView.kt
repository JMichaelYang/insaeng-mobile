package com.jae.insaeng.views

import androidx.compose.runtime.Composable
import androidx.glance.GlanceModifier
import com.jae.insaeng.WidgetNode

private val renderedTypes =
    setOf("column", "row", "container", "expanded", "spacer", "divider", "text", "button", "checkboxTile", "scroll", "progressBar", "iconButton")

@Composable
fun WidgetNodeView(node: WidgetNode, modifier: GlanceModifier = GlanceModifier) {
    when (node.type) {
        "column" -> ColumnView(node, modifier)
        "row" -> RowView(node, modifier)
        "container" -> ContainerView(node, modifier)
        "expanded" -> node.renderedChildren().firstOrNull()?.let { WidgetNodeView(it, modifier) }
        "spacer" -> SpacerView(node, modifier)
        "divider" -> DividerView(modifier)
        "text" -> TextView(node, modifier)
        "button" -> ButtonView(node, modifier)
        "checkboxTile" -> CheckboxTileView(node, modifier)
        "scroll" -> ScrollView(node, modifier)
        "progressBar" -> ProgressBarView(node, modifier)
        "iconButton" -> IconButtonView(node, modifier)
    }
}

internal val WidgetNode.flex: Int
    get() = if (type == "expanded") int("flex") ?: 1 else 0

internal fun WidgetNode.renderedChildren(): List<WidgetNode> = children.filter { it.type in renderedTypes }
