package com.jae.insaeng.views

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceModifier
import androidx.glance.layout.Box
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import com.jae.insaeng.WidgetAlignment
import com.jae.insaeng.WidgetNode
import com.jae.insaeng.WidgetSpacing

@Composable
internal fun RowView(node: WidgetNode, modifier: GlanceModifier) {
    val spacing = WidgetSpacing.of(node.string("spacing")).size
    val alignment = WidgetAlignment.of(node.string("alignment"))
    val cross = if (alignment == WidgetAlignment.STRETCH) GlanceModifier.fillMaxHeight() else GlanceModifier
    Row(modifier = if (node.fillsWidth) modifier.fillMaxWidth() else modifier, verticalAlignment = alignment.vertical) {
        node.renderedChildren().forEachIndexed { index, child ->
            val weighted = child.flex > 0
            val outer = if (weighted) cross.defaultWeight() else cross
            val gap = if (index == 0) 0.dp else spacing
            if (!weighted && gap == 0.dp) {
                WidgetNodeView(child, outer)
            } else {
                Box(modifier = outer.padding(start = gap)) {
                    WidgetNodeView(child, if (weighted) cross.fillMaxWidth() else cross)
                }
            }
        }
    }
}

internal val WidgetNode.fillsWidth: Boolean
    get() = type == "row" && renderedChildren().any { it.flex > 0 }
