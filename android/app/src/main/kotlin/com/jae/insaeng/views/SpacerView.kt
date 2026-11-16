package com.jae.insaeng.views

import androidx.compose.runtime.Composable
import androidx.glance.GlanceModifier
import androidx.glance.layout.Spacer
import androidx.glance.layout.size
import com.jae.insaeng.WidgetNode
import com.jae.insaeng.WidgetSpacing

@Composable
internal fun SpacerView(node: WidgetNode, modifier: GlanceModifier) {
    Spacer(modifier.size(WidgetSpacing.of(node.string("size"), WidgetSpacing.MD).size))
}
