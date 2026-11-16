package com.jae.insaeng.views

import androidx.compose.runtime.Composable
import androidx.glance.GlanceModifier
import androidx.glance.action.Action
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import com.jae.insaeng.MainActivity
import com.jae.insaeng.WidgetNode
import com.jae.insaeng.WidgetTap
import com.jae.insaeng.eventAction

internal fun WidgetTap?.toAction(): Action? =
    when (this) {
        WidgetTap.OpenApp -> actionStartActivity<MainActivity>()
        is WidgetTap.Event, null -> null
    }

@Composable
internal fun GlanceModifier.tappable(node: WidgetNode): GlanceModifier =
    (node.tap.toAction() ?: node.eventAction())?.let(::clickable) ?: this
