package com.jae.insaeng

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.text.Text
import androidx.glance.text.TextStyle

private val renderedTypes = setOf("column", "row", "container", "expanded", "spacer", "divider", "text")

private val dividerHeight = 16.dp

private val dividerThickness = 1.dp

@Composable
fun WidgetNodeView(node: WidgetNode, modifier: GlanceModifier = GlanceModifier) {
    when (node.type) {
        "column" -> ColumnView(node, modifier)
        "row" -> RowView(node, modifier)
        "container" -> ContainerView(node, modifier)
        "expanded" -> node.renderedChildren().firstOrNull()?.let { WidgetNodeView(it, modifier) }
        "spacer" -> Spacer(modifier.size(WidgetSpacing.of(node.string("size"), WidgetSpacing.MD).size))
        "divider" -> DividerView(modifier)
        "text" -> TextView(node, modifier)
    }
}

@Composable
private fun ColumnView(node: WidgetNode, modifier: GlanceModifier) {
    val spacing = WidgetSpacing.of(node.string("spacing")).size
    val alignment = WidgetAlignment.of(node.string("alignment"))
    val cross = if (alignment == WidgetAlignment.STRETCH) GlanceModifier.fillMaxWidth() else GlanceModifier
    Column(modifier = modifier, horizontalAlignment = alignment.horizontal) {
        node.renderedChildren().forEachIndexed { index, child ->
            val weighted = child.flex > 0
            val outer = if (weighted) cross.defaultWeight() else cross
            if (index == 0 || spacing == 0.dp) {
                WidgetNodeView(child, outer)
            } else {
                Box(modifier = outer.padding(top = spacing)) {
                    WidgetNodeView(child, if (weighted) cross.fillMaxHeight() else cross)
                }
            }
        }
    }
}

@Composable
private fun RowView(node: WidgetNode, modifier: GlanceModifier) {
    val spacing = WidgetSpacing.of(node.string("spacing")).size
    val alignment = WidgetAlignment.of(node.string("alignment"))
    val cross = if (alignment == WidgetAlignment.STRETCH) GlanceModifier.fillMaxHeight() else GlanceModifier
    Row(modifier = modifier, verticalAlignment = alignment.vertical) {
        node.renderedChildren().forEachIndexed { index, child ->
            val weighted = child.flex > 0
            val outer = if (weighted) cross.defaultWeight() else cross
            if (index == 0 || spacing == 0.dp) {
                WidgetNodeView(child, outer)
            } else {
                Box(modifier = outer.padding(start = spacing)) {
                    WidgetNodeView(child, if (weighted) cross.fillMaxWidth() else cross)
                }
            }
        }
    }
}

@Composable
private fun ContainerView(node: WidgetNode, modifier: GlanceModifier) {
    val padding = WidgetSpacing.of(node.string("padding")).size
    val alignment = WidgetAlignment.of(node.string("alignment"))
    Box(
        modifier = modifier.fillMaxWidth().padding(padding),
        contentAlignment = Alignment(alignment.horizontal, Alignment.Vertical.Top),
    ) {
        node.renderedChildren().firstOrNull()?.let { child ->
            WidgetNodeView(
                child,
                if (alignment == WidgetAlignment.STRETCH) GlanceModifier.fillMaxWidth() else GlanceModifier,
            )
        }
    }
}

@Composable
private fun DividerView(modifier: GlanceModifier) {
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

@Composable
private fun TextView(node: WidgetNode, modifier: GlanceModifier) {
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

private val WidgetNode.flex: Int
    get() = if (type == "expanded") int("flex") ?: 1 else 0

private fun WidgetNode.renderedChildren(): List<WidgetNode> = children.filter { it.type in renderedTypes }
