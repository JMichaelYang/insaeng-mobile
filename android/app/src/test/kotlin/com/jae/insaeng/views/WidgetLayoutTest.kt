package com.jae.insaeng.views

import androidx.compose.runtime.Composable
import androidx.glance.Emittable
import androidx.glance.EmittableWithChildren
import androidx.glance.EmittableImage
import androidx.glance.GlanceModifier
import androidx.glance.TintColorFilterParams
import androidx.glance.action.ActionModifier
import androidx.glance.appwidget.EnabledModifier
import androidx.glance.appwidget.testing.unit.runGlanceAppWidgetUnitTest
import androidx.glance.layout.Box
import androidx.glance.layout.EmittableBox
import androidx.glance.layout.EmittableColumn
import androidx.glance.layout.EmittableRow
import androidx.glance.layout.WidthModifier
import androidx.glance.layout.fillMaxSize
import androidx.glance.testing.GlanceNodeMatcher
import androidx.glance.semantics.semantics
import androidx.glance.semantics.testTag
import androidx.glance.testing.unit.hasTestTag
import androidx.glance.unit.Dimension
import androidx.glance.unit.ResourceColorProvider
import com.jae.insaeng.R
import com.jae.insaeng.WidgetNode
import com.jae.insaeng.WidgetSnapshot
import com.jae.insaeng.WidgetTap
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetLayoutTest {
    private fun myDayRoot(): WidgetNode {
        val fixture =
            requireNotNull(javaClass.classLoader?.getResource("widget_snapshots/my_day.json")) { "Missing fixture" }
                .readText()
        return requireNotNull(WidgetSnapshot.decode(fixture)).root.withoutTaps()
    }

    private fun WidgetNode.withoutTaps(): WidgetNode = copy(tap = null, children = children.map { it.withoutTaps() })

    private inline fun <reified T : Emittable> render(noinline content: @Composable () -> Unit): T {
        var found: Emittable? = null
        runGlanceAppWidgetUnitTest {
            provideComposable { Box(GlanceModifier.semantics { testTag = "host" }) { content() } }
            onNode(hasTestTag("host")).assert(
                GlanceNodeMatcher("captures the hosted view") {
                    found = (it.value.emittable as EmittableWithChildren).children.single()
                    true
                },
            )
        }
        return requireNotNull(found) as T
    }

    private val Emittable.width: Dimension?
        get() = modifier.foldIn<Dimension?>(null) { width, element -> (element as? WidthModifier)?.width ?: width }

    private inline fun <reified T : GlanceModifier.Element> Emittable.modifierOf(): T? =
        modifier.foldIn<T?>(null) { found, element -> found ?: element as? T }

    private fun chevron(tap: WidgetTap? = null, loading: Boolean = false) =
        WidgetNode(
            type = "iconButton",
            id = "dayNext",
            props =
                JsonObject(
                    mapOf(
                        "icon" to JsonPrimitive("chevronRight"),
                        "label" to JsonPrimitive("Next day"),
                        "loading" to JsonPrimitive(loading),
                    ),
                ),
            tap = tap,
        )

    private fun Emittable.descendants(): List<Emittable> =
        if (this is EmittableWithChildren) children.flatMap { listOf(it) + it.descendants() } else emptyList()

    @Test
    fun laysOutTheFooterRowEdgeToEdge() {
        val footer = myDayRoot().children.last()
        assertEquals("footer", footer.id)
        assertEquals(listOf("footerStart"), footer.renderedChildren().map { it.id })

        val row = render<EmittableRow> { RowView(footer, GlanceModifier) }

        assertEquals(Dimension.Fill, row.width)
        val slot = row.children.single()
        assertEquals(Dimension.Expand, slot.width)
        assertTrue(slot.descendants().none { it.width == Dimension.Expand })
    }

    @Test
    fun stretchesTheFooterAcrossTheSpacedRootColumn() {
        val column = render<EmittableColumn> { ColumnView(myDayRoot(), GlanceModifier.fillMaxSize()) }

        val footerBox = column.children.last()
        assertEquals(Dimension.Fill, footerBox.width)
        val row = (footerBox as EmittableWithChildren).children.single()
        assertTrue(row is EmittableRow)
        assertEquals(Dimension.Fill, row.width)
    }

    @Test
    fun wrapsRowsWithoutWeightedChildren() {
        val node =
            WidgetNode(
                type = "row",
                id = "row",
                children = listOf(WidgetNode(type = "container", id = "a"), WidgetNode(type = "container", id = "b")),
            )

        val row = render<EmittableRow> { RowView(node, GlanceModifier) }

        assertNotEquals(Dimension.Fill, row.width)
        assertFalse(node.fillsWidth)
    }

    @Test
    fun drawsTaplessIconButtonsAsDisabledButtons() {
        val button = render<EmittableBox> { IconButtonView(chevron(), GlanceModifier) }

        assertEquals(false, button.modifierOf<EnabledModifier>()?.enabled)
        assertNotNull(button.modifierOf<ActionModifier>())
        val icon = button.children.single() as EmittableImage
        val tint = icon.colorFilterParams as TintColorFilterParams
        assertEquals(R.color.widget_icon_disabled, (tint.colorProvider as ResourceColorProvider).resId)
    }

    @Test
    fun drawsTappableIconButtonsAsEnabledButtons() {
        val button = render<EmittableBox> { IconButtonView(chevron(tap = WidgetTap.OpenApp), GlanceModifier) }

        assertEquals(true, button.modifierOf<EnabledModifier>()?.enabled)
        assertNotNull(button.modifierOf<ActionModifier>())
    }

    @Test
    fun drawsLoadingIconButtonsAsSpinnersWithoutAButton() {
        val box = render<EmittableBox> { IconButtonView(chevron(tap = WidgetTap.OpenApp, loading = true), GlanceModifier) }

        assertNull(box.modifierOf<EnabledModifier>())
        assertNull(box.modifierOf<ActionModifier>())
        assertTrue(box.children.single() !is EmittableImage)
    }
}
