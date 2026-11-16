package com.jae.insaeng.views

import androidx.compose.runtime.Composable
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.itemsIndexed
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import com.jae.insaeng.WidgetAlignment
import com.jae.insaeng.WidgetNode
import com.jae.insaeng.WidgetSpacing

private const val FNV_OFFSET_BASIS = -0x340d631b7bdddcdbL

private const val FNV_PRIME = 0x100000001b3L

@Composable
internal fun ScrollView(node: WidgetNode, modifier: GlanceModifier) {
    val list = node.renderedChildren().firstOrNull() ?: return
    val isColumn = list.type == "column"
    val spacing = if (isColumn) WidgetSpacing.of(list.string("spacing")).size else WidgetSpacing.NONE.size
    val alignment = if (isColumn) WidgetAlignment.of(list.string("alignment")) else WidgetAlignment.STRETCH
    val cross = if (alignment == WidgetAlignment.STRETCH) GlanceModifier.fillMaxWidth() else GlanceModifier
    LazyColumn(modifier = modifier.fillMaxWidth(), horizontalAlignment = alignment.horizontal) {
        itemsIndexed(node.scrollItems(), itemId = { _, item -> item.itemId }) { index, item ->
            WidgetNodeView(item, if (index == 0) cross else cross.padding(top = spacing))
        }
    }
}

internal fun WidgetNode.scrollItems(): List<WidgetNode> {
    val child = renderedChildren().firstOrNull() ?: return emptyList()
    return if (child.type == "column") child.renderedChildren() else listOf(child)
}

internal val WidgetNode.itemId: Long
    get() = id.fold(FNV_OFFSET_BASIS) { hash, char -> (hash xor char.code.toLong()) * FNV_PRIME } and Long.MAX_VALUE
