package com.jae.insaeng.views

import androidx.compose.runtime.Composable
import androidx.glance.GlanceModifier
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import com.jae.insaeng.WidgetAlignment
import com.jae.insaeng.WidgetNode
import com.jae.insaeng.WidgetSpacing

@Composable
internal fun ContainerView(node: WidgetNode, modifier: GlanceModifier) {
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
