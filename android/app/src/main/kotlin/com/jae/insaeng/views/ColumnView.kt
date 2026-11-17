package com.jae.insaeng.views

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceModifier
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import com.jae.insaeng.WidgetAlignment
import com.jae.insaeng.WidgetNode
import com.jae.insaeng.WidgetSpacing

@Composable
internal fun ColumnView(node: WidgetNode, modifier: GlanceModifier) {
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
                Box(modifier = (if (child.fillsWidth) outer.fillMaxWidth() else outer).padding(top = spacing)) {
                    WidgetNodeView(child, if (weighted) cross.fillMaxHeight() else cross)
                }
            }
        }
    }
}
