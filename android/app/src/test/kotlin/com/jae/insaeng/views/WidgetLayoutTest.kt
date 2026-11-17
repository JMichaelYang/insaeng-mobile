package com.jae.insaeng.views

import androidx.compose.runtime.Composable
import androidx.glance.Emittable
import androidx.glance.EmittableWithChildren
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.testing.unit.runGlanceAppWidgetUnitTest
import androidx.glance.layout.Box
import androidx.glance.layout.EmittableColumn
import androidx.glance.layout.EmittableRow
import androidx.glance.layout.WidthModifier
import androidx.glance.layout.fillMaxSize
import androidx.glance.testing.GlanceNodeMatcher
import androidx.glance.semantics.semantics
import androidx.glance.semantics.testTag
import androidx.glance.testing.unit.hasTestTag
import androidx.glance.unit.Dimension
import com.jae.insaeng.WidgetNode
import com.jae.insaeng.WidgetSnapshot
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
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

    private fun Emittable.descendants(): List<Emittable> =
        if (this is EmittableWithChildren) children.flatMap { listOf(it) + it.descendants() } else emptyList()

    @Test
    fun laysOutTheFooterRowEdgeToEdge() {
        val footer = myDayRoot().children.last()
        assertEquals("footer", footer.id)
        assertEquals(listOf("footerStart", "openClaude"), footer.renderedChildren().map { it.id })

        val row = render<EmittableRow> { RowView(footer, GlanceModifier) }

        assertEquals(Dimension.Fill, row.width)
        assertEquals(2, row.children.size)
        val (slot, button) = row.children
        assertEquals(Dimension.Expand, slot.width)
        assertTrue(slot.descendants().none { it.width == Dimension.Expand })
        assertNotEquals(Dimension.Expand, button.width)
        assertNotEquals(Dimension.Fill, button.width)
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
}
